import { IsString } from 'class-validator';

export class RequestCodeDto {
  @IsString()
  phone!: string;
}

export class VerifyCodeDto {
  @IsString()
  phone!: string;

  @IsString()
  code!: string;
}

export class CompanyLoginDto {
  @IsString()
  email!: string;

  @IsString()
  password!: string;
}

export class AdminLoginDto {
  @IsString()
  email!: string;

  @IsString()
  password!: string;
}
