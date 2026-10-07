import { IsEmail, IsOptional, IsString, Length } from 'class-validator';
import { IsPersonName } from '../../common/validators/person-name.validator';

/// Регистрация логиста в один экран — email, пароль, имя, компания, страна
/// (задача 025). `ownerName`/`companyName`/`companyNameRu`/`countryId` те
/// же, что в CompaniesService.registerOwnedCompany (022) — переиспользуется
/// напрямую, без дублирования логики создания Company/CompanyMember.
export class RegisterCompanyAuthDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(8, 100)
  password!: string;

  @IsPersonName()
  ownerName!: string;

  @IsString()
  @Length(2, 120)
  companyName!: string;

  @IsOptional()
  @IsString()
  @Length(2, 120)
  companyNameRu?: string;

  @IsString()
  countryId!: string;

  /// Версия принятой оферты (043 п.2) — галочка на экране регистрации.
  @IsString()
  @Length(1, 32)
  offerVersion!: string;
}
