import * as crypto from 'crypto';
import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Company, CompanyMember, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { EmailService } from '../email/email.service';
import { RegisterCompanyDto } from './dto/register-company.dto';
import { CreateInviteDto, AcceptInviteDto } from './dto/invite.dto';

const INVITE_TTL_DAYS = 7;

@Injectable()
export class CompaniesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly email: EmailService,
  ) {}

  toCompanyDto(company: Company) {
    return {
      id: company.id,
      name: company.name,
      nameRu: company.nameRu,
      countryId: company.countryId,
      city: company.city,
      isVerified: company.isVerified,
      ratingAvg: Number(company.ratingAvg),
      ratingCount: company.ratingCount,
    };
  }

  toMemberDto(member: CompanyMember) {
    return { id: member.id, companyId: member.companyId, userId: member.userId, role: member.role };
  }

  async members(companyId: string) {
    const members = await this.prisma.companyMember.findMany({ where: { companyId } });
    return members.map((m) => this.toMemberDto(m));
  }

  /// Создание Company + CompanyMember{OWNER} для уже существующего User
  /// (задачи 006/022/025 — вызывается из AuthService.registerCompany сразу
  /// после создания пользователя). Владелец получает все права логиста
  /// (решение 2026-10-04) — отдельных прав для CompanyMemberRole.OWNER не
  /// заводим, это уже так во всех местах, где проверяется роль.
  async registerOwnedCompany(userId: string, dto: RegisterCompanyDto) {
    const existingMember = await this.prisma.companyMember.findUnique({ where: { userId } });
    if (existingMember) throw new BadRequestException('User is already a member of a company');

    const country = await this.prisma.country.findUnique({ where: { id: dto.countryId } });
    if (!country) throw new NotFoundException('Country not found');

    let company: Company;
    let member: CompanyMember;
    try {
      ({ company, member } = await this.prisma.$transaction(async (tx) => {
        const company = await tx.company.create({
          data: { name: dto.companyName, nameRu: dto.companyNameRu ?? dto.companyName, countryId: dto.countryId },
        });
        const member = await tx.companyMember.create({
          data: { companyId: company.id, userId, role: 'OWNER' },
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
      await this.email.sendMessage(
        email,
        `Приглашение в ${invite.company.name} на Lubao`,
        `Вас пригласили в компанию «${invite.company.name}» на Lubao.\n` +
          `Перейдите по ссылке, чтобы принять приглашение (действует 7 дней):\n` +
          `lubao://invite/${token}`,
      );
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
      const member = await tx.companyMember.create({
        data: { companyId: invite.companyId, userId: user.id, role: invite.role },
      });
      await tx.companyInvite.update({ where: { id: invite.id }, data: { usedAt: new Date() } });
      return { user, member };
    });

    const company = await this.prisma.company.findUniqueOrThrow({ where: { id: invite.companyId } });

    return { user, company: this.toCompanyDto(company), companyMember: this.toMemberDto(member) };
  }
}
