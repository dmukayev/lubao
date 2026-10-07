import { LoginCodeChannel } from '../sms/login-code-channels';
import { OFFER_VERSION, PD_CONSENT_VERSION, pdConsentRequired } from './legal-consent';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { DriversService } from '../drivers/drivers.service';
import { CompaniesService } from '../companies/companies.service';
import { SmsService } from '../sms/sms.service';
import { EmailService } from '../email/email.service';
import { SessionService, TokenPair } from './session.service';
import { RegisterCompanyAuthDto } from './dto/register-company.dto';
import { AcceptInviteDto } from '../companies/dto/invite.dto';

const LOCKOUT_THRESHOLD = 5;
const LOCKOUT_SECONDS = 15 * 60;

function toUserDto(user: User) {
  return {
    id: user.id,
    role: user.role,
    phone: user.phone,
    email: user.email,
    locale: user.locale,
    emailVerifiedAt: user.emailVerifiedAt,
    pdConsentRequired: pdConsentRequired(user),
  };
}

/** Убирает пробелы/скобки/дефисы, которые пользователь обычно вставляет при наборе номера. */
function normalizePhone(phone: string): string {
  return phone.trim().replace(/[^\d+]/g, '');
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

/// Без этой проверки заблокированный пользователь получал бы токены при
/// входе и только потом ловил 401 от JwtAuthGuard на первом же запросе —
/// непонятный бесконечный цикл релогина вместо явного «аккаунт заблокирован»
/// (задача 026, п.5). Код ACCOUNT_BLOCKED в теле ответа, не просто текст,
/// чтобы клиент мог показать отдельный экран, а не трактовать как 401.
function assertNotBlocked(user: { isBlocked: boolean }): void {
  if (user.isBlocked) {
    throw new ForbiddenException({ code: 'ACCOUNT_BLOCKED', message: 'Аккаунт заблокирован' });
  }
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly drivers: DriversService,
    private readonly companies: CompaniesService,
    private readonly sms: SmsService,
    private readonly email: EmailService,
    private readonly sessions: SessionService,
  ) {}

  async requestDriverCode(phone: string, ip: string, channel?: LoginCodeChannel) {
    return this.sms.requestCode(normalizePhone(phone), ip, { channel });
  }

  /// Каналы кода, которые видит водитель на экране входа (042 п.3).
  async driverCodeChannels() {
    return { channels: await this.sms.channels() };
  }

  /**
   * Вход и регистрация водителя в одном шаге (как у Uber/inDrive): если
   * код верный, но пользователя с этим телефоном ещё нет — создаём его
   * сразу (анкета водителя донаполняется следующим экраном — см.
   * DriversService.updateProfile, он же обрабатывает первое заполнение).
   */
  async verifyDriverCode(phone: string, code: string, ip?: string, deviceName?: string, platform?: string) {
    const normalized = normalizePhone(phone);
    const ok = await this.sms.verifyCode(normalized, code, ip);
    if (!ok) throw new BadRequestException('Неверный или истёкший код');

    let user = await this.prisma.user.findUnique({ where: { phone: normalized } });
    if (!user) {
      user = await this.prisma.user.create({ data: { role: 'DRIVER', phone: normalized } });
    } else if (user.role !== 'DRIVER') {
      throw new BadRequestException('Этот номер уже используется другой ролью');
    }
    assertNotBlocked(user);

    // Телефон в чёрном списке → снять «Проверен», завести идентификатор (039, п.2).
    await this.drivers.applyPhoneBlacklist(user.id);
    const driver = await this.drivers.findByUserId(user.id);
    const tokens = await this.sessions.createSession(user.id, user.role, deviceName, platform);
    return { user: toUserDto(user), driver, company: null, companyMember: null, ...tokens };
  }

  /**
   * Вход логиста по email и паролю (задача 025, заменяет вход по коду из
   * 006/022 — см. docs/decisions.md). Та же защита, что у админа: 5
   * неверных паролей → блокировка на 15 минут, одинаковая ошибка для
   * неверного email и пароля (не раскрываем, существует ли аккаунт).
   */
  async loginCompany(email: string, password: string, ip: string, deviceName?: string, platform?: string) {
    const normalizedEmail = normalizeEmail(email);
    const locked = await this.isLockedOut('company', normalizedEmail);
    if (locked) {
      throw new UnauthorizedException('Слишком много неверных попыток, попробуйте через 15 минут');
    }

    const user = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });
    const passwordOk =
      user?.role === 'COMPANY' && user.passwordHash ? await bcrypt.compare(password, user.passwordHash) : false;

    if (!passwordOk) {
      await this.recordFailure('company', normalizedEmail);
      throw new UnauthorizedException('Invalid email or password');
    }
    await this.clearLockout('company', normalizedEmail);
    assertNotBlocked(user!);

    const member = await this.prisma.companyMember.findUnique({
      where: { userId: user!.id },
      include: { company: true },
    });
    const tokens = await this.sessions.createSession(user!.id, user!.role, deviceName, platform);
    return {
      user: toUserDto(user!),
      driver: null,
      company: member ? this.companies.toCompanyDto(member.company) : null,
      companyMember: member ? this.companies.toMemberDto(member) : null,
      ...tokens,
    };
  }

  /**
   * Регистрация компании в один шаг — email, пароль, имя владельца,
   * название компании, страна (задача 025). Переиспользует
   * CompaniesService для создания Company+CompanyMember. Письмо
   * подтверждения отправляется, но не блокирует (п. 7 задачи) — доходимость
   * на qq.com/163.com ненадёжна.
   */
  async registerCompany(dto: RegisterCompanyAuthDto, ip: string) {
    if (dto.offerVersion !== OFFER_VERSION) {
      throw new BadRequestException({ code: 'OFFER_VERSION_MISMATCH', version: OFFER_VERSION });
    }
    const normalizedEmail = normalizeEmail(dto.email);
    const existing = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: { role: 'COMPANY', email: normalizedEmail, passwordHash },
    });

    const { company, companyMember } = await this.companies.registerOwnedCompany(user.id, dto, { offerVersion: dto.offerVersion });

    try {
      await this.email.requestCode(normalizedEmail, ip, user.locale, 'CONFIRM_EMAIL');
    } catch {
      // Письмо подтверждения — не блокирует регистрацию (п. 7); пользователь
      // может запросить его повторно из кабинета (resendVerification).
    }

    const tokens = await this.sessions.createSession(user.id, user.role);
    return { user: toUserDto(user), driver: null, company, companyMember, ...tokens };
  }

  /// Принять приглашение сотрудника (задача 025, «Путь Б» из 022) — создание
  /// пользователя/членства живёт в CompaniesService, сессия — здесь (та же
  /// причина разделения, что у registerCompany: CompaniesService не должен
  /// зависеть от AuthModule).
  async acceptInvite(token: string, dto: AcceptInviteDto) {
    const { user, company, companyMember } = await this.companies.acceptInvite(token, dto);
    const tokens = await this.sessions.createSession(user.id, user.role);
    return { user: toUserDto(user), driver: null, company, companyMember, ...tokens };
  }

  async requestEmailVerification(userId: string, ip: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.email) throw new NotFoundException('User has no email');
    if (user.emailVerifiedAt) return;
    await this.email.requestCode(normalizeEmail(user.email), ip, user.locale, 'CONFIRM_EMAIL');
  }

  async verifyEmail(userId: string, code: string, ip?: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.email) throw new NotFoundException('User has no email');

    const ok = await this.email.verifyCode(normalizeEmail(user.email), code, ip);
    if (!ok) throw new BadRequestException('Неверный или истёкший код');

    await this.prisma.user.update({ where: { id: userId }, data: { emailVerifiedAt: new Date() } });
  }

  /// «Забыли пароль» (п. 9) — не раскрываем, существует ли email: всегда
  /// отвечаем успехом, код отправляем только если аккаунт реально есть.
  async requestPasswordReset(email: string, ip: string) {
    const normalizedEmail = normalizeEmail(email);
    const user = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });
    if (user?.role === 'COMPANY') {
      await this.email.requestCode(normalizedEmail, ip, user.locale, 'RESET_PASSWORD');
    }
  }

  async resetPassword(email: string, code: string, newPassword: string, ip?: string) {
    const normalizedEmail = normalizeEmail(email);
    const ok = await this.email.verifyCode(normalizedEmail, code, ip);
    if (!ok) throw new BadRequestException('Неверный или истёкший код');

    const user = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });
    if (!user || user.role !== 'COMPANY') throw new NotFoundException('User not found');

    const passwordHash = await bcrypt.hash(newPassword, 10);
    await this.prisma.user.update({ where: { id: user.id }, data: { passwordHash } });
    // Пароль мог утечь — разлогиниваем все устройства, новый вход только с новым паролем.
    await this.sessions.revokeAllForUser(user.id);
  }

  async loginAdmin(email: string, password: string, ip: string, deviceName?: string, platform?: string) {
    const normalizedEmail = normalizeEmail(email);

    const locked = await this.isLockedOut('admin', normalizedEmail);
    if (locked) {
      await this.logAdminAttempt(null, normalizedEmail, ip, 'ADMIN_LOGIN_LOCKED');
      throw new UnauthorizedException('Слишком много неверных попыток, попробуйте через 15 минут');
    }

    const user = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });
    const passwordOk =
      user?.role === 'ADMIN' && user.passwordHash ? await bcrypt.compare(password, user.passwordHash) : false;

    if (!passwordOk) {
      await this.recordFailure('admin', normalizedEmail);
      await this.logAdminAttempt(user?.id ?? null, normalizedEmail, ip, 'ADMIN_LOGIN_FAILURE');
      throw new UnauthorizedException('Invalid email or password');
    }

    await this.clearLockout('admin', normalizedEmail);
    await this.logAdminAttempt(user!.id, normalizedEmail, ip, 'ADMIN_LOGIN_SUCCESS');

    const tokens = await this.sessions.createSession(user!.id, user!.role, deviceName, platform);
    return { user: toUserDto(user!), driver: null, company: null, companyMember: null, ...tokens };
  }

  /// Общая защита от перебора пароля — один и тот же Redis-паттерн для
  /// админа (задача 006) и логиста (задача 025), с отдельным неймспейсом
  /// по `scope`, чтобы блокировки не пересекались между ролями.
  private async isLockedOut(scope: 'admin' | 'company', email: string): Promise<boolean> {
    return (await this.redis.client.get(`${scope}:lockout:${email}`)) !== null;
  }

  private async recordFailure(scope: 'admin' | 'company', email: string): Promise<void> {
    const client = this.redis.client;
    const failKey = `${scope}:fail:${email}`;
    const lockKey = `${scope}:lockout:${email}`;
    const attempts = await client.incr(failKey);
    if (attempts === 1) await client.expire(failKey, LOCKOUT_SECONDS);
    if (attempts >= LOCKOUT_THRESHOLD) {
      await client.set(lockKey, '1', 'EX', LOCKOUT_SECONDS);
      await client.del(failKey);
    }
  }

  private async clearLockout(scope: 'admin' | 'company', email: string): Promise<void> {
    await Promise.all([this.redis.client.del(`${scope}:fail:${email}`), this.redis.client.del(`${scope}:lockout:${email}`)]);
  }

  private async logAdminAttempt(actorUserId: string | null, email: string, ip: string, action: string) {
    await this.prisma.auditLog.create({
      data: { actorUserId, action, entityType: 'User', entityId: actorUserId, metadata: { ip, email } },
    });
  }

  async refresh(refreshToken: string): Promise<TokenPair> {
    return this.sessions.rotateSession(refreshToken);
  }

  async logout(refreshToken: string): Promise<void> {
    await this.sessions.revokeByRefreshToken(refreshToken);
  }

  /// 043 п.2: согласие на обработку ПДн — версия должна совпадать с текущей
  /// (клиент со старым текстом не может согласиться «за» новый).
  async acceptPdConsent(userId: string, version: string) {
    if (version !== PD_CONSENT_VERSION) throw new BadRequestException({ code: 'PD_CONSENT_VERSION_MISMATCH', version: PD_CONSENT_VERSION });
    await this.prisma.user.update({ where: { id: userId }, data: { pdConsentAt: new Date(), pdConsentVersion: version } });
  }

  async setLocale(userId: string, locale: 'kk' | 'ru' | 'zh' | 'en') {
    await this.prisma.user.update({ where: { id: userId }, data: { locale } });
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const driver = await this.drivers.findByUserId(user.id);
    const member = await this.prisma.companyMember.findUnique({ where: { userId: user.id }, include: { company: true } });

    return {
      user: toUserDto(user),
      driver,
      company: member ? this.companies.toCompanyDto(member.company) : null,
      companyMember: member ? this.companies.toMemberDto(member) : null,
    };
  }
}
