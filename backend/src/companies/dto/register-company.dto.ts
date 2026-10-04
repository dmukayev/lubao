import { IsOptional, IsString, Length } from 'class-validator';
import { IsPersonName } from '../../common/validators/person-name.validator';

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

  @IsString()
  countryId!: string;
}
