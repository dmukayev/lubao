import { Body, Controller, ForbiddenException, Get, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { CompaniesService } from './companies.service';
import { RegisterCompanyDto } from './dto/register-company.dto';
import { SetPasswordDto } from './dto/set-password.dto';

@Controller('companies')
export class CompaniesController {
  constructor(private readonly companies: CompaniesService) {}

  @Post('register')
  register(@CurrentUser() ctx: RequestContext, @Body() dto: RegisterCompanyDto) {
    if (ctx.user.role !== 'COMPANY') throw new ForbiddenException('Not a company account');
    return this.companies.registerOwnedCompany(ctx.user.id, dto);
  }

  @Post('me/password')
  setPassword(@CurrentUser() ctx: RequestContext, @Body() dto: SetPasswordDto) {
    if (ctx.user.role !== 'COMPANY') throw new ForbiddenException('Not a company account');
    return this.companies.setPassword(ctx.user.id, dto.password);
  }

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
