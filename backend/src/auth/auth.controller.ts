import { BadRequestException, Body, Controller, Delete, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { ClientIp } from '../common/client-ip.decorator';
import { CurrentUser } from '../common/current-user.decorator';
import { Public } from '../common/public.decorator';
import { RequestContext } from '../common/request-context';
import { AuthService } from './auth.service';
import { SessionService } from './session.service';
import {
  AdminLoginDto,
  CompanyPasswordLoginDto,
  LogoutDto,
  RefreshDto,
  RequestCodeDto,
  RequestPasswordResetDto,
  ResetPasswordDto,
  VerifyCodeDto,
  VerifyEmailDto,
} from './dto/login.dto';
import { RegisterCompanyAuthDto } from './dto/register-company.dto';
import { AcceptInviteDto } from '../companies/dto/invite.dto';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly sessions: SessionService,
  ) {}

  @Public()
  @Post('phone/request-code')
  async requestCode(@Body() dto: RequestCodeDto, @ClientIp() ip: string) {
    await this.auth.requestDriverCode(dto.phone, ip);
    return { success: true };
  }

  @Public()
  @Post('phone/verify')
  verifyCode(@Body() dto: VerifyCodeDto) {
    return this.auth.verifyDriverCode(dto.phone, dto.code, dto.deviceName, dto.platform);
  }

  @Public()
  @Post('company/login')
  loginCompany(@Body() dto: CompanyPasswordLoginDto, @ClientIp() ip: string) {
    return this.auth.loginCompany(dto.email, dto.password, ip, dto.deviceName, dto.platform);
  }

  @Public()
  @Post('company/register')
  registerCompany(@Body() dto: RegisterCompanyAuthDto, @ClientIp() ip: string) {
    return this.auth.registerCompany(dto, ip);
  }

  @Public()
  @Post('company/invites/:token/accept')
  acceptInvite(@Param('token') token: string, @Body() dto: AcceptInviteDto) {
    return this.auth.acceptInvite(token, dto);
  }

  @Public()
  @Post('company/forgot-password')
  async requestPasswordReset(@Body() dto: RequestPasswordResetDto, @ClientIp() ip: string) {
    await this.auth.requestPasswordReset(dto.email, ip);
    return { success: true };
  }

  @Public()
  @Post('company/reset-password')
  async resetPassword(@Body() dto: ResetPasswordDto) {
    await this.auth.resetPassword(dto.email, dto.code, dto.newPassword);
    return { success: true };
  }

  @Post('company/resend-verification')
  async resendVerification(@CurrentUser() ctx: RequestContext, @ClientIp() ip: string) {
    await this.auth.requestEmailVerification(ctx.user.id, ip);
    return { success: true };
  }

  @Post('company/verify-email')
  async verifyEmail(@CurrentUser() ctx: RequestContext, @Body() dto: VerifyEmailDto) {
    await this.auth.verifyEmail(ctx.user.id, dto.code);
    return { success: true };
  }

  @Public()
  @Post('admin/login')
  loginAdmin(@Body() dto: AdminLoginDto, @ClientIp() ip: string) {
    return this.auth.loginAdmin(dto.email, dto.password, ip, dto.deviceName, dto.platform);
  }

  @Public()
  @Post('refresh')
  refresh(@Body() dto: RefreshDto) {
    return this.auth.refresh(dto.refreshToken);
  }

  @Public()
  @Post('logout')
  @HttpCode(200)
  async logout(@Body() dto: LogoutDto) {
    await this.auth.logout(dto.refreshToken);
    return { success: true };
  }

  @Get('me')
  me(@CurrentUser() ctx: RequestContext) {
    return this.auth.me(ctx.user.id);
  }

  @Get('sessions')
  listSessions(@CurrentUser() ctx: RequestContext) {
    return this.sessions.listActiveSessions(ctx.user.id, ctx.sessionId);
  }

  @Delete('sessions/:id')
  @HttpCode(200)
  async revokeSession(@Param('id') id: string, @CurrentUser() ctx: RequestContext) {
    await this.sessions.revokeSession(id, ctx.user.id);
    return { success: true };
  }

  @Delete('sessions')
  @HttpCode(200)
  async revokeAllExceptCurrent(@Query('except') except: string | undefined, @CurrentUser() ctx: RequestContext) {
    if (except !== 'current') {
      throw new BadRequestException('Specify ?except=current');
    }
    await this.sessions.revokeAllExceptCurrent(ctx.user.id, ctx.sessionId);
    return { success: true };
  }
}
