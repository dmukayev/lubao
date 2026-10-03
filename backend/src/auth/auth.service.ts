import { BadRequestException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { DriversService } from '../drivers/drivers.service';
import { CompaniesService } from '../companies/companies.service';
import { SmsService } from '../sms/sms.service';

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
    private readonly drivers: DriversService,
    private readonly companies: CompaniesService,
    private readonly sms: SmsService,
  ) {}

  async requestDriverCode(phone: string) {
    await this.sms.requestCode(normalizePhone(phone));
  }

  /**
   * Вход и регистрация водителя в одном шаге (как у Uber/inDrive): если
   * код верный, но пользователя с этим телефоном ещё нет — создаём его
   * сразу (анкета водителя донаполняется следующим экраном — см.
   * DriversService.updateProfile, он же обрабатывает первое заполнение).
   */
  async verifyDriverCode(phone: string, code: string) {
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
    return { user: toUserDto(user), driver, company: null, companyMember: null };
  }

  async loginCompany(email: string, password: string) {
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
    if (!member) throw new NotFoundException('Company membership not found');

    return {
      user: toUserDto(user),
      driver: null,
      company: this.companies.toCompanyDto(member.company),
      companyMember: this.companies.toMemberDto(member),
    };
  }

  async loginAdmin(email: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { email: normalizeEmail(email) } });
    if (!user || user.role !== 'ADMIN' || !user.passwordHash) {
      throw new UnauthorizedException('Invalid email or password');
    }
    const passwordOk = await bcrypt.compare(password, user.passwordHash);
    if (!passwordOk) {
      throw new UnauthorizedException('Invalid email or password');
    }
    return { user: toUserDto(user), driver: null, company: null, companyMember: null };
  }
}
