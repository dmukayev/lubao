import { IsIn, IsOptional, IsString, Length } from 'class-validator';

/// Поля компании, которые может менять сама компания (владелец) — не всё,
/// что видит админ (задача 012: «Город — нет, по желанию в профиле»;
/// юр. адрес не спрашиваем при регистрации, но можно указать позже).
/// `taxId` — рег. номер (统一社会信用代码/БИН), формат проверяется по
/// стране компании в CompaniesService.updateProfile, не здесь: DTO не
/// знает страну.
export class UpdateCompanyProfileDto {
  @IsOptional()
  @IsString()
  @Length(1, 200)
  city?: string;

  @IsOptional()
  @IsString()
  @Length(1, 300)
  legalAddress?: string;

  @IsOptional()
  @IsString()
  @Length(1, 50)
  taxId?: string;

  /// 058 п.8а: грузовладелец / экспедитор / перевозчик (по умолчанию экспедитор).
  @IsOptional()
  @IsIn(['SHIPPER', 'FORWARDER', 'CARRIER'])
  kind?: 'SHIPPER' | 'FORWARDER' | 'CARRIER';
}
