import { IsIn, IsOptional, IsString, Length, Matches } from 'class-validator';
import { IsPersonName } from '../../common/validators/person-name.validator';
import { LATIN_NAME_PATTERN } from '../../companies/latin-name';

export class RegisterCompanyDto {
  @IsPersonName()
  ownerName!: string;

  @IsString()
  @Length(2, 120)
  companyName!: string;

  /// Русское название — предзаполняется на клиенте (пока без реального
  /// перевода, транслитерацией — задача 010), можно поправить. Если не
  /// пришло, используем companyName как есть (решение 2026-10-04).
  @IsOptional()
  @IsString()
  @Length(2, 120)
  companyNameRu?: string;

  /// 069: латинское название — обязательно, если в названии иероглифы.
  @IsOptional()
  @IsString()
  @Matches(LATIN_NAME_PATTERN)
  companyNameLatin?: string;

  @IsString()
  countryId!: string;

  /// 058 п.8а: грузовладелец / экспедитор / перевозчик (по умолчанию экспедитор).
  @IsOptional()
  @IsIn(['SHIPPER', 'FORWARDER', 'CARRIER'])
  kind?: 'SHIPPER' | 'FORWARDER' | 'CARRIER';
}
