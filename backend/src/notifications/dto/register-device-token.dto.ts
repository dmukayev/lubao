import { IsEnum, IsString, MinLength } from 'class-validator';
import { DevicePlatform } from '@prisma/client';

export class RegisterDeviceTokenDto {
  @IsString()
  @MinLength(8)
  token!: string;

  @IsEnum(DevicePlatform)
  platform!: DevicePlatform;
}
