import { ArrayMaxSize, IsArray, IsBoolean, IsISO8601, IsIn, IsInt, IsNumber, IsObject, IsOptional, IsString, Max, Min } from 'class-validator';

export class UpdateCargoDto {
  /// 047: категория груза.
  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsString()
  pointId?: string;

  @IsOptional()
  @IsBoolean()
  allowPartial?: boolean;

  @IsOptional()
  @IsString()
  destinationCountryId?: string;

  @IsOptional()
  @IsString()
  destinationCityId?: string;

  @IsOptional()
  @IsString()
  bodyTypeId?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  /// До 60 т: защита от «20000» в поле тонн (живая проверка 2026-10-07).
  @Max(60_000)
  weightKg?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  volumeM3?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  palletCount?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];

  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;

  @IsOptional()
  @IsIn(['USD', 'CNY', 'KZT'])
  currency?: 'USD' | 'CNY' | 'KZT';

  @IsOptional()
  @IsISO8601()
  readyDate?: string;

  @IsOptional()
  @IsString()
  description?: string;

  /// 048: другие подходящие кузова (кроме основного) — груз виден и им.
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  extraBodyTypeIds?: string[];

  /// 048: параметры груза по профилю кузова (продукт и литры, тип контейнера, число машин…).
  @IsOptional()
  @IsObject()
  specs?: Record<string, unknown>;
}
