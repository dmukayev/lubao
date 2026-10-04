import { BadRequestException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { DriversService } from '../drivers/drivers.service';
import { CompaniesService } from '../companies/companies.service';
import { SmsService } from '../sms/sms.service';
import { EmailService } from '../email/email.service';
import { SessionService, TokenPair } from './session.service';

const ADMIN_LOCKOUT_THRESHOLD = 5;
const ADMIN_LOCKOUT_SECONDS = 15 * 60;

function toUserDto(user: User) {
  return { id: user.id, role: user.role, phone: user.phone, email: user.email, locale: user.locale };
}

/** Убирает пробелы/скобки/дефисы, которые пользователь обычно вставляет при наборе номера. */
function normalizePhone(phone: string): string {
  return phone.trim().replace(/[^\d+]/g, '');
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
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

  async requestDriverCode(phone: string, ip: string) {
    await this.sms.requestCode(normalizePhone(phone), ip);
  }

  /**
   * Вход и регистрация водителя в одном шаге (как у Uber/inDrive): если
   * код верный, но пользователя с этим телефоном ещё нет — создаём его
   * сразу (анкета водителя донаполняется следующим экраном — см.
   * DriversService.updateProfile, он же обрабатывает первое заполнение).
   */
  async verifyDriverCode(phone: string, code: string, deviceName?: string, platform?: string) {
    const normalized = normalizePhone(phone);
    const ok = await this.sms.verifyCode(normalized, code);
    if (!ok) throw new BadRequestException('Неверный или истёкший код');

    let user = await this.prisma.user.findUnique({ where: { phone: normalized } });
    if (!user) {
      user = await this.prisma.user.create({ data: { role: 'DRIVER', phone: normalized } });
    } else if (user.role !== 'DRIVER') {
      throw new BadRequestException('Этот номер уже используется другой ролью');
    }

    const driver = await this.drivers.findByUserId(user.id);
    const tokens = await this.sessions.createSession(user.id, user.role, deviceName, platform);
    return { user: toUserDto(user), driver, company: null, companyMember: null, ...tokens };
  }

  async requestEmailCode(email: string, ip: string) {
    const normalized = normalizeEmail(email);
    const existing = await this.prisma.user.findUnique({ where: { email: normalized } });
    if (existing && existing.role !== 'COMPANY') {
      throw new BadRequestException('Этот email уже используется другой ролью');
    }
    await this.email.requestCode(normalized, ip);
  }

  /**
   * Пароль — альтернатива коду (решение 2026-10-04, «Вход логиста — код
   * ИЛИ пароль»): у компании, которая задала пароль (CompaniesService.
   * setPassword), можно войти сразу, не дожидаясь письма. У большинства
   * новых компаний пароля нет — для них только verifyEmailCode.
   */
  async loginCompanyPassword(email: string, password: string, deviceName?: string, platform?: string) {
    const user = await this.prisma.user.findUnique({ where: { email: normalizeEmail(email) } });
    if (!user || user.role !== 'COMPANY' || !user.passwordHash) {
      throw new UnauthorizedException('Invalid email or password');
    }
    const passwordOk = await bcrypt.compare(password, user.passwordHash);
    if (!passwordOk) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const member = await this.prisma.companyMember.findUnique({
      where: { userId: user.id },
      include: { company: true },
    });
    const tokens = await this.sessions.createSession(user.id, user.role, deviceName, platform);
    return {
      user: toUserDto(user),
      driver: null,
      company: member ? this.companies.toCompanyDto(member.company) : null,
      companyMember: member ? this.companies.toMemberDto(member) : null,
      ...tokens,
    };
  }

  /**
   * Вход и начало регистрации логиста в одном шаге — без пароля (задачи
   * 006, 022), по аналогии с verifyDriverCode: известный email — сразу
   * вход, новый — создаём пользователя роли COMPANY без компании
   * (company: null), регистрация компании продолжается через
   * POST /companies/register (задача 022).
   */
  async verifyEmailCode(email: string, code: string, deviceName?: string, platform?: string) {
    const normalized = normalizeEmail(email);
    const ok = await this.email.verifyCode(normalized, code);
    if (!ok) throw new BadRequestException('Неверный или истёкший код');

    let user = await this.prisma.user.findUnique({ where: { email: normalized } });
    if (!user) {
      user = await this.prisma.user.create({ data: { role: 'COMPANY', email: normalized } });
    } else if (user.role !== 'COMPANY') {
      throw new BadRequestException('Этот email уже используется другой ролью');
    }

    const member = await this.prisma.companyMember.findUnique({
      where: { userId: user.id },
      include: { company: true },
    });
    const tokens = await this.sessions.createSession(user.id, user.role, deviceName, platform);
    return {
      user: toUserDto(user),
      driver: null,
      company: member ? this.companies.toCompanyDto(member.company) : null,
      companyMember: member ? this.companies.toMemberDto(member) : null,
      ...tokens,
    };
  }

  async loginAdmin(email: string, password: string, ip: string, deviceName?: string, platform?: string) {
    const normalizedEmail = normalizeEmail(email);
    const client = this.redis.client;
    const failKey = `admin:fail:${normalizedEmail}`;
    const lockKey = `admin:lockout:${normalizedEmail}`;

    const locked = await client.get(lockKey);
    if (locked) {
      await this.logAdminAttempt(null, normalizedEmail, ip, 'ADMIN_LOGIN_LOCKED');
      throw new UnauthorizedException('Слишком много неверных попыток, попробуйте через 15 минут');
    }

    const user = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });
    const passwordOk = user?.role === 'ADMIN' && user.passwordHash ? await bcrypt.compare(password, user.passwordHash) : false;

    if (!passwordOk) {
      const attempts = await client.incr(failKey);
      if (attempts === 1) await client.expire(failKey, ADMIN_LOCKOUT_SECONDS);
      if (attempts >= ADMIN_LOCKOUT_THRESHOLD) {
        await client.set(lockKey, '1', 'EX', ADMIN_LOCKOUT_SECONDS);
        await client.del(failKey);
      }
      await this.logAdminAttempt(user?.id ?? null, normalizedEmail, ip, 'ADMIN_LOGIN_FAILURE');
      throw new UnauthorizedException('Invalid email or password');
    }

    await Promise.all([client.del(failKey), client.del(lockKey)]);
    await this.logAdminAttempt(user!.id, normalizedEmail, ip, 'ADMIN_LOGIN_SUCCESS');

    const tokens = await this.sessions.createSession(user!.id, user!.role, deviceName, platform);
    return { user: toUserDto(user!), driver: null, company: null, companyMember: null, ...tokens };
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
