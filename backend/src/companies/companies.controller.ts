import { Body, Controller, ForbiddenException, Get, Param, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { Public } from '../common/public.decorator';
import { RequestContext } from '../common/request-context';
import { CompaniesService } from './companies.service';
import { CreateCompanyVerificationDocumentDto } from './dto/create-company-verification-document.dto';
import { CreateInviteDto } from './dto/invite.dto';
import { SetPasswordDto } from './dto/set-password.dto';
import { UpdateCompanyProfileDto } from './dto/update-company-profile.dto';
import { UpdateMyContactDto } from './dto/update-my-contact.dto';
import { UpdateWeComWebhookDto } from './dto/update-wecom-webhook.dto';

@Controller('companies')
export class CompaniesController {
  constructor(private readonly companies: CompaniesService) {}

  @Post('me/invites')
  createInvite(@CurrentUser() ctx: RequestContext, @Body() dto: CreateInviteDto) {
    if (!ctx.companyMember || ctx.companyMember.role !== 'OWNER') {
      throw new ForbiddenException('Only the owner can invite employees');
    }
    return this.companies.createInvite(ctx.companyMember.companyId, ctx.user.id, dto);
  }

  @Public()
  @Get('invites/:token')
  getInvite(@Param('token') token: string) {
    return this.companies.getInvite(token);
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

  @Patch('me')
  updateMe(@CurrentUser() ctx: RequestContext, @Body() dto: UpdateCompanyProfileDto) {
    if (!ctx.companyMember || ctx.companyMember.role !== 'OWNER') {
      throw new ForbiddenException('Only the owner can edit company details');
    }
    return this.companies.updateProfile(ctx.companyMember.companyId, dto);
  }

  @Patch('me/contact')
  updateMyContact(@CurrentUser() ctx: RequestContext, @Body() dto: UpdateMyContactDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.companies.updateMyContact(ctx.user.id, dto);
  }

  @Get('me/members')
  members(@CurrentUser() ctx: RequestContext) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.companies.members(ctx.companyMember.companyId);
  }

  @Get('me/verification-documents')
  verificationDocuments(@CurrentUser() ctx: RequestContext) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.companies.listVerificationDocuments(ctx.companyMember.companyId);
  }

  @Post('me/verification-documents')
  submitVerificationDocument(@CurrentUser() ctx: RequestContext, @Body() dto: CreateCompanyVerificationDocumentDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.companies.submitVerificationDocument(ctx.user.id, ctx.companyMember.companyId, dto);
  }

  @Patch('me/wecom-webhook')
  updateWeComWebhook(@CurrentUser() ctx: RequestContext, @Body() dto: UpdateWeComWebhookDto) {
    if (!ctx.companyMember || ctx.companyMember.role !== 'OWNER') {
      throw new ForbiddenException('Only the owner can change the WeCom webhook');
    }
    return this.companies.updateWeComWebhook(ctx.companyMember.companyId, dto.wecomWebhookUrl);
  }

  @Post('me/wecom-test')
  testWeComWebhook(@CurrentUser() ctx: RequestContext) {
    if (!ctx.companyMember || ctx.companyMember.role !== 'OWNER') {
      throw new ForbiddenException('Only the owner can test the WeCom webhook');
    }
    return this.companies.testWeComWebhook(ctx.companyMember.companyId);
  }
}
