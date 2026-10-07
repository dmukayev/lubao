import * as crypto from 'crypto';
import { inviteLink } from '../email/email-messages';
import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Company, CompanyMember, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { EmailService } from '../email/email.service';
import { WeComService } from '../notifications/wecom.service';
import { RecognitionService } from '../recognition/recognition.service';
import { UploadsService } from '../uploads/uploads.service';
import { RegisterCompanyDto } from './dto/register-company.dto';
import { CreateInviteDto, AcceptInviteDto } from './dto/invite.dto';
import { UpdateCompanyProfileDto } from './dto/update-company-profile.dto';
import { UpdateMyContactDto } from './dto/update-my-contact.dto';
import { CreateCompanyVerificationDocumentDto } from './dto/create-company-verification-document.dto';
import { isValidRegistrationNumber } from './registration-number';

const INVITE_TTL_DAYS = 7;

@Injectable()
export class CompaniesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly email: EmailService,
    private readonly wecom: WeComService,
    private readonly recognition?: RecognitionService,
    private readonly uploads?: UploadsService,
  ) {}

  toCompanyDto(company: Company) {
    return {
      id: company.id,
      name: company.name,
      nameRu: company.nameRu,
      countryId: company.countryId,
      city: company.city,
      legalAddress: company.legalAddress,
      taxId: company.taxId,
      isVerified: company.isVerified,
      wecomWebhookUrl: company.wecomWebhookUrl,
      ratingAvg: Number(company.ratingAvg),
      ratingCount: company.ratingCount,
    };
  }

  toMemberDto(member: CompanyMember) {
    return {
      id: member.id,
      companyId: member.companyId,
      userId: member.userId,
      role: member.role,
      fullName: member.fullName,
      contactPhone: member.contactPhone,
      wechatId: member.wechatId,
    };
  }

  async members(companyId: string) {
    const members = await this.prisma.companyMember.findMany({ where: { companyId } });
    return members.map((m) => this.toMemberDto(m));
  }

  /// Задача 012, п.1/8 — «Мой профиль»: имя, телефон для водителей, WeChat
  /// конкретного сотрудника (не компании). И владелец, и логист правят
  /// это у себя — отдельно от данных компании (только владелец).
  async updateMyContact(userId: string, dto: UpdateMyContactDto) {
    const member = await this.prisma.companyMember.update({
      where: { userId },
      data: { fullName: dto.fullName, contactPhone: dto.contactPhone, wechatId: dto.wechatId },
    });
    return this.toMemberDto(member);
  }

  /// Данные компании, которые правит владелец (задача 012, п.8: город —
  /// по желанию, рег. номер — до первой публикации, формат по стране).
  async updateProfile(companyId: string, dto: UpdateCompanyProfileDto) {
    const company = await this.prisma.company.findUniqueOrThrow({ where: { id: companyId }, include: { country: { select: { code: true } } } });
    if (dto.taxId !== undefined && !isValidRegistrationNumber(company.country.code, dto.taxId)) {
      throw new BadRequestException('Invalid registration number format for this country');
    }
    const updated = await this.prisma.company.update({
      where: { id: companyId },
      data: { city: dto.city, legalAddress: dto.legalAddress, taxId: dto.taxId },
    });
    return this.toCompanyDto(updated);
  }

  /// Единственный документ, подтверждающий компанию (задача 012, п.5) —
  /// свидетельство о регистрации. Загрузка не требует isVerified: до
  /// проверки его как раз и не хватает, чтобы админу было что проверять
  /// (ревью задачи 012 — главный найденный пробел).
  async submitVerificationDocument(userId: string, companyId: string, dto: CreateCompanyVerificationDocumentDto) {
    // Задача 032, п.1 — то же, что у drivers.service.ts: fileUrl только
    // ключ из нашего же POST /uploads/document, загруженный этим пользователем.
    if (this.uploads && !(await this.uploads.verifyDocumentOwnership(dto.fileUrl, userId))) {
      throw new BadRequestException('fileUrl must be a key returned by POST /uploads/document for this user');
    }

    const doc = await this.prisma.verificationDocument.create({
      data: { userId, companyId, type: dto.type, fileUrl: dto.fileUrl, status: 'PENDING' },
    });
    await this.recognition?.enqueue(doc.id);
    return this.docToDto(doc);
  }

  async listVerificationDocuments(companyId: string) {
    const docs = await this.prisma.verificationDocument.findMany({
      where: { companyId },
      orderBy: { createdAt: 'desc' },
    });
    return docs.map((d) => this.docToDto(d));
  }

  private docToDto(doc: { id: string; type: string; fileUrl: string; status: string; rejectReason: string | null; createdAt: Date }) {
    return {
      id: doc.id,
      type: doc.type,
      fileUrl: doc.fileUrl,
      status: doc.status,
      rejectReason: doc.rejectReason,
      createdAt: doc.createdAt,
    };
  }

  /// Создание Company + CompanyMember{OWNER} для уже существующего User
  /// (задачи 006/022/025 — вызывается из AuthService.registerCompany сразу
  /// после создания пользователя). Владелец получает все права логиста
  /// (решение 2026-10-04) — отдельных прав для CompanyMemberRole.OWNER не
  /// заводим, это уже так во всех местах, где проверяется роль.
  async registerOwnedCompany(userId: string, dto: RegisterCompanyDto, opts: { offerVersion?: string } = {}) {
    const existingMember = await this.prisma.companyMember.findUnique({ where: { userId } });
    if (existingMember) throw new BadRequestException('User is already a member of a company');

    const country = await this.prisma.country.findUnique({ where: { id: dto.countryId } });
    if (!country) throw new NotFoundException('Country not found');

    let company: Company;
    let member: CompanyMember;
    try {
      ({ company, member } = await this.prisma.$transaction(async (tx) => {
        const company = await tx.company.create({
          data: {
            name: dto.companyName,
            nameRu: dto.companyNameRu ?? dto.companyName,
            countryId: dto.countryId,
            ...(opts.offerVersion ? { offerAcceptedAt: new Date(), offerVersion: opts.offerVersion } : {}),
          },
        });
        const member = await tx.companyMember.create({
          data: { companyId: company.id, userId, role: 'OWNER', fullName: dto.ownerName },
        });
        await tx.user.update({ where: { id: userId }, data: { name: dto.ownerName } });
        return { company, member };
      }));
    } catch (e) {
      // Параллельная регистрация той же учётки (двойной клик/повтор запроса) —
      // первая проверка existingMember выше не ловит гонку, т.к. она не в
      // транзакции; вторая попытка падает на уникальном CompanyMember.userId.
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        throw new BadRequestException('User is already a member of a company');
      }
      throw e;
    }

    return { company: this.toCompanyDto(company), companyMember: this.toMemberDto(member) };
  }

  /// Сменить пароль, уже будучи в аккаунте (отдельно от «Забыли пароль» —
  /// AuthService.resetPassword, для разлогиненных).
  async setPassword(userId: string, password: string) {
    const passwordHash = await bcrypt.hash(password, 10);
    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });
    return { success: true };
  }

  /// Приглашение сотрудника по ссылке (задача 025, «Путь Б» из 022):
  /// владелец шлёт email+роль, получает одноразовый токен на 7 дней.
  async createInvite(companyId: string, invitedByUserId: string, dto: CreateInviteDto) {
    const token = crypto.randomBytes(24).toString('hex');
    const expiresAt = new Date(Date.now() + INVITE_TTL_DAYS * 24 * 60 * 60 * 1000);
    const email = dto.email.trim().toLowerCase();

    const invite = await this.prisma.companyInvite.create({
      data: { companyId, invitedByUserId, email, role: dto.role, token, expiresAt },
      include: { company: true },
    });

    try {
      const inviter = await this.prisma.user.findUnique({ where: { id: invitedByUserId }, select: { locale: true } });
      // https-ссылка (042, п.2): на вебе открывает экран принятия, в приложении — universal/app link.
      await this.email.sendTemplate(email, 'INVITE', inviter?.locale, {
        company: invite.company.name,
        days: INVITE_TTL_DAYS,
        link: inviteLink(token),
      });
    } catch {
      // Письмо не блокирует создание приглашения — ссылку можно переслать
      // вручную (п. 11 задачи 025: «Скопировать ссылку» / «Поделиться»).
    }

    return {
      id: invite.id,
      email: invite.email,
      role: invite.role,
      token: invite.token,
      expiresAt: invite.expiresAt,
    };
  }

  async getInvite(token: string) {
    const invite = await this.prisma.companyInvite.findUnique({ where: { token }, include: { company: true } });
    if (!invite || invite.usedAt || invite.expiresAt < new Date()) {
      throw new NotFoundException('Invite not found or expired');
    }
    return {
      companyName: invite.company.name,
      role: invite.role,
      email: invite.email,
    };
  }

  /// Принять приглашение: создаёт пользователя (email из приглашения,
  /// подтверждённый — переход по ссылке уже это доказывает) + членство в
  /// компании, одноразово помечает приглашение использованным.
  async acceptInvite(token: string, dto: AcceptInviteDto) {
    const invite = await this.prisma.companyInvite.findUnique({ where: { token } });
    if (!invite || invite.usedAt || invite.expiresAt < new Date()) {
      throw new NotFoundException('Invite not found or expired');
    }

    const existingUser = await this.prisma.user.findUnique({ where: { email: invite.email } });
    if (existingUser) throw new BadRequestException('Email already registered');

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const { user, member } = await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          role: 'COMPANY',
          email: invite.email,
          passwordHash,
          name: dto.name,
          emailVerifiedAt: new Date(),
        },
      });
      // Задача 012 — телефон/WeChat из формы приглашения раньше просто
      // игнорировались (DTO их принимал, но ни одного столбца для записи
      // не было). CompanyMember.fullName заполняем именем из формы —
      // то же имя уже уходит в User.name.
      const member = await tx.companyMember.create({
        data: { companyId: invite.companyId, userId: user.id, role: invite.role, fullName: dto.name, contactPhone: dto.phone, wechatId: dto.wechat },
      });
      await tx.companyInvite.update({ where: { id: invite.id }, data: { usedAt: new Date() } });
      return { user, member };
    });

    const company = await this.prisma.company.findUniqueOrThrow({ where: { id: invite.companyId } });

    return { user, company: this.toCompanyDto(company), companyMember: this.toMemberDto(member) };
  }

  /// Вебхук группового бота WeCom (задача 011, п.2) — владелец вставляет
  /// адрес в профиле компании.
  async updateWeComWebhook(companyId: string, wecomWebhookUrl: string | null | undefined) {
    const company = await this.prisma.company.update({ where: { id: companyId }, data: { wecomWebhookUrl } });
    return this.toCompanyDto(company);
  }

  async testWeComWebhook(companyId: string) {
    const company = await this.prisma.company.findUniqueOrThrow({ where: { id: companyId } });
    if (!company.wecomWebhookUrl) throw new BadRequestException('WeCom webhook is not configured');
    await this.wecom.send(company.wecomWebhookUrl, `Lubao: тестовое сообщение от ${company.name}. Если вы видите это — бот настроен верно.`);
    return { success: true };
  }
}
