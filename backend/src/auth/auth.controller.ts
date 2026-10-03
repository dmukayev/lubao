import { Body, Controller, Post } from '@nestjs/common';
import { Public } from '../common/public.decorator';
import { AuthService } from './auth.service';
import { AdminLoginDto, CompanyLoginDto, RequestCodeDto, VerifyCodeDto } from './dto/login.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Public()
  @Post('driver/request-code')
  async requestCode(@Body() dto: RequestCodeDto) {
    await this.auth.requestDriverCode(dto.phone);
    return { success: true };
  }

  @Public()
  @Post('driver/verify-code')
  verifyCode(@Body() dto: VerifyCodeDto) {
    return this.auth.verifyDriverCode(dto.phone, dto.code);
  }

  @Public()
  @Post('dev-login/company')
  loginCompany(@Body() dto: CompanyLoginDto) {
    return this.auth.loginCompany(dto.email, dto.password);
  }

  @Public()
  @Post('dev-login/admin')
  loginAdmin(@Body() dto: AdminLoginDto) {
    return this.auth.loginAdmin(dto.email, dto.password);
  }
}
