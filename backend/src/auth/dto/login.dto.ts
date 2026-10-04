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
