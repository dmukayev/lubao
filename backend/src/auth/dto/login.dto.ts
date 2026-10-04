import { IsOptional, IsString } from 'class-validator';

export class RequestCodeDto {
  @IsString()
  phone!: string;
}

export class VerifyCodeDto {
  @IsString()
  phone!: string;

  @IsString()
  code!: string;

  @IsOptional()
  @IsString()
  deviceName?: string;

  @IsOptional()
  @IsString()
  platform?: string;
}

export class RequestEmailCodeDto {
  @IsString()
  email!: string;
}

/// Пароль — альтернатива коду на email для логиста (решение 2026-10-04,
/// «Вход логиста — код ИЛИ пароль»): у кого задан пароль, может не ждать
/// письмо каждый раз. У новых компаний пароля нет, пока не зададут сами
/// (см. CompaniesService.setPassword) — тогда остаётся только код.
export class CompanyPasswordLoginDto {
  @IsString()
  email!: string;

  @IsString()
  password!: string;

  @IsOptional()
  @IsString()
  deviceName?: string;

  @IsOptional()
  @IsString()
  platform?: string;
}

export class VerifyEmailCodeDto {
  @IsString()
  email!: string;

  @IsString()
  code!: string;

  @IsOptional()
  @IsString()
  deviceName?: string;

  @IsOptional()
  @IsString()
  platform?: string;
}

export class AdminLoginDto {
  @IsString()
  email!: string;

  @IsString()
  password!: string;

  @IsOptional()
  @IsString()
  deviceName?: string;

  @IsOptional()
  @IsString()
  platform?: string;
}

export class RefreshDto {
  @IsString()
  refreshToken!: string;
}

export class LogoutDto {
  @IsString()
  refreshToken!: string;
}
