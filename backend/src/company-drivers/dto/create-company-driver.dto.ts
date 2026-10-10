import { IsString, Length } from 'class-validator';

/// 058 п.6: «Создать водителя» — имя и телефон (+7 / +998 / +996 / +86 …).
export class CreateCompanyDriverDto {
  @IsString()
  @Length(2, 80)
  name!: string;

  @IsString()
  @Length(8, 24)
  phone!: string;
}
