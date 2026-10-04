import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Company, CompanyMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterCompanyDto } from './dto/register-company.dto';

@Injectable()
export class CompaniesService {
  constructor(private readonly prisma: PrismaService) {}

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

  /// Самостоятельная регистрация компании владельцем после входа по коду
  /// на email (задачи 006, 022, «Путь А»): новый COMPANY-пользователь
  /// (company: null после /auth/email/verify) заполняет имя и компанию на
  /// одном экране и сразу попадает в кабинет. Владелец получает все права
  /// логиста (решение 2026-10-04) — отдельных прав для CompanyMemberRole.OWNER
  /// не заводим, это уже так во всех местах, где проверяется роль.
  async registerOwnedCompany(userId: string, dto: RegisterCompanyDto) {
    const existingMember = await this.prisma.companyMember.findUnique({ where: { userId } });
    if (existingMember) throw new BadRequestException('User is already a member of a company');

    const country = await this.prisma.country.findUnique({ where: { id: dto.countryId } });
    if (!country) throw new NotFoundException('Country not found');

    const { company, member } = await this.prisma.$transaction(async (tx) => {
      const company = await tx.company.create({
        data: { name: dto.companyName, nameRu: dto.companyNameRu ?? dto.companyName, countryId: dto.countryId },
      });
      const member = await tx.companyMember.create({
        data: { companyId: company.id, userId, role: 'OWNER' },
      });
      await tx.user.update({ where: { id: userId }, data: { name: dto.ownerName } });
      return { company, member };
    });

    return { company: this.toCompanyDto(company), companyMember: this.toMemberDto(member) };
  }

  /// Пароль — альтернатива коду на email (решение 2026-10-04): компания
  /// сама заводит/меняет пароль себе в любой момент, вход по коду при этом
  /// никуда не девается — это просто второй способ для тех, кому так
  /// удобнее. Минимум 8 символов — короче, чем у админа (12), пароль здесь
  /// необязателен, а не единственная защита аккаунта.
  async setPassword(userId: string, password: string) {
    const passwordHash = await bcrypt.hash(password, 10);
    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });
    return { success: true };
  }
}
