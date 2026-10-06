import { Throttle } from '@nestjs/throttler';
import { THROTTLE_TTL_MS, authLimit } from '../common/app-throttler.guard';
import { BadRequestException, Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query } from '@nestjs/common';
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
  UpdateLocaleDto,
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
  @Throttle({ default: { limit: authLimit(), ttl: THROTTLE_TTL_MS } })
  @Post('phone/request-code')
  async requestCode(@Body() dto: RequestCodeDto, @ClientIp() ip: string) {
    const { channel } = await this.auth.requestDriverCode(dto.phone, ip, dto.channel);
    return { success: true, channel };
  }

  @Public()
  @Throttle({ default: { limit: authLimit(), ttl: THROTTLE_TTL_MS } })
  @Post('phone/verify')
  verifyCode(@Body() dto: VerifyCodeDto, @ClientIp() ip: string) {
    return this.auth.verifyDriverCode(dto.phone, dto.code, ip, dto.deviceName, dto.platform);
  }

  @Public()
  @Throttle({ default: { limit: authLimit(), ttl: THROTTLE_TTL_MS } })
  @Post('company/login')
  loginCompany(@Body() dto: CompanyPasswordLoginDto, @ClientIp() ip: string) {
    return this.auth.loginCompany(dto.email, dto.password, ip, dto.deviceName, dto.platform);
  }

  @Public()
  @Throttle({ default: { limit: authLimit(), ttl: THROTTLE_TTL_MS } })
  @Post('company/register')
  registerCompany(@Body() dto: RegisterCompanyAuthDto, @ClientIp() ip: string) {
    return this.auth.registerCompany(dto, ip);
  }

  @Public()
  @Throttle({ default: { limit: authLimit(), ttl: THROTTLE_TTL_MS } })
  @Post('company/invites/:token/accept')
  acceptInvite(@Param('token') token: string, @Body() dto: AcceptInviteDto) {
    return this.auth.acceptInvite(token, dto);
  }

  @Public()
  @Throttle({ default: { limit: authLimit(), ttl: THROTTLE_TTL_MS } })
  @Post('company/forgot-password')
  async requestPasswordReset(@Body() dto: RequestPasswordResetDto, @ClientIp() ip: string) {
    await this.auth.requestPasswordReset(dto.email, ip);
    return { success: true };
  }

  @Public()
  @Throttle({ default: { limit: authLimit(), ttl: THROTTLE_TTL_MS } })
  @Post('company/reset-password')
  async resetPassword(@Body() dto: ResetPasswordDto, @ClientIp() ip: string) {
    await this.auth.resetPassword(dto.email, dto.code, dto.newPassword, ip);
    return { success: true };
  }

  @Throttle({ default: { limit: authLimit(), ttl: THROTTLE_TTL_MS } })
  @Post('company/resend-verification')
  async resendVerification(@CurrentUser() ctx: RequestContext, @ClientIp() ip: string) {
    await this.auth.requestEmailVerification(ctx.user.id, ip);
    return { success: true };
  }

  @Throttle({ default: { limit: authLimit(), ttl: THROTTLE_TTL_MS } })
  @Post('company/verify-email')
  async verifyEmail(@CurrentUser() ctx: RequestContext, @Body() dto: VerifyEmailDto, @ClientIp() ip: string) {
    await this.auth.verifyEmail(ctx.user.id, dto.code, ip);
    return { success: true };
  }

  @Public()
  @Throttle({ default: { limit: authLimit(), ttl: THROTTLE_TTL_MS } })
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

  @Patch('me/locale')
  async setLocale(@CurrentUser() ctx: RequestContext, @Body() dto: UpdateLocaleDto) {
    await this.auth.setLocale(ctx.user.id, dto.locale);
    return { success: true };
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
