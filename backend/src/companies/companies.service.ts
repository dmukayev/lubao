import { Injectable } from '@nestjs/common';
import { Company, CompanyMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CompaniesService {
  constructor(private readonly prisma: PrismaService) {}

  toCompanyDto(company: Company) {
    return {
      id: company.id,
      name: company.name,
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
}
