import { Controller, ForbiddenException, Get } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { CompaniesService } from './companies.service';

@Controller('companies')
export class CompaniesController {
  constructor(private readonly companies: CompaniesService) {}

  @Get('me')
  me(@CurrentUser() ctx: RequestContext) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.companies.toCompanyDto(ctx.companyMember.company);
  }

  @Get('me/members')
  members(@CurrentUser() ctx: RequestContext) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.companies.members(ctx.companyMember.companyId);
  }
}
