import { IsEmail, IsIn, IsOptional, IsString, Length } from 'class-validator';

export class RequestCodeDto {
  @IsString()
  phone!: string;

  /// «Не пришло? Отправить SMS» — тот же код SMS-ом, если первым был WhatsApp (042, п.3).
  @IsOptional()
  @IsIn(['sms'])
  channel?: 'sms';
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

/// Вход логиста — email и пароль (задача 025, заменяет код на email из
/// 006/022). Защита — 5 неверных попыток → блокировка 15 минут.
export class CompanyPasswordLoginDto {
  @IsEmail()
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

export class RequestPasswordResetDto {
  @IsEmail()
  email!: string;
}

export class ResetPasswordDto {
  @IsEmail()
  email!: string;

  @IsString()
  code!: string;

  @IsString()
  @Length(8, 100)
  newPassword!: string;
}

export class VerifyEmailDto {
  @IsString()
  code!: string;
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

/// Смена языка (задача 013) — хранится на сервере (`users.locale`), не
/// только в состоянии клиента: push/WeCom/перевод чата и выбор языка
/// синхронизируются на все устройства пользователя (decisions.md «Смена
/// языка»).
export class UpdateLocaleDto {
  @IsIn(['kk', 'ru', 'zh', 'en'])
  locale!: 'kk' | 'ru' | 'zh' | 'en';
}
