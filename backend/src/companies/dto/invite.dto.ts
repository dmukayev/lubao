import { IsEmail, IsIn, IsOptional, IsString, Length } from 'class-validator';
import { IsPersonName } from '../../common/validators/person-name.validator';

export class CreateInviteDto {
  @IsEmail()
  email!: string;

  @IsIn(['OWNER', 'LOGIST'])
  role!: 'OWNER' | 'LOGIST';
}

export class AcceptInviteDto {
  @IsString()
  @Length(8, 100)
  password!: string;

  @IsPersonName()
  name!: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  wechat?: string;
}
