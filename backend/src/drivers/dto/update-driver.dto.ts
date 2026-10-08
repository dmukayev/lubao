import { ArrayUnique, IsArray, IsBoolean, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { IsPersonName } from '../../common/validators/person-name.validator';

export class UpdateDriverDto {
  @IsPersonName()
  fullName!: string;

  @IsString()
  homeCityId!: string;

  @IsBoolean()
  anyCountry!: boolean;

  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  directionCountryIds!: string[];

  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  permitIds!: string[];

  /// Области внутри выбранных стран (045 п.7) — плоский список; сервер
  /// раскладывает по странам. Страна без своих областей — «вся страна».
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  directionRegionIds?: string[];

  /// Нужен при регистрации — предпочтение водителя (045 п.5), машины не создаются.
  @IsOptional()
  @IsString()
  bodyTypeId?: string;

  @IsOptional()
  @IsString()
  plateNumber?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  capacityTons?: number;
}
