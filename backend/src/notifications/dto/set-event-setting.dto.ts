import { IsBoolean } from 'class-validator';

export class SetEventSettingDto {
  @IsBoolean()
  enabled!: boolean;
}
