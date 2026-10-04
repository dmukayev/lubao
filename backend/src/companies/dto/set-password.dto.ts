import { IsString, Length } from 'class-validator';

export class SetPasswordDto {
  @IsString()
  @Length(8, 100)
  password!: string;
}
