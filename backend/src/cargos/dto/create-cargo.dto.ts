import { IsArray, IsBoolean, IsIn, IsISO8601, IsNumber, IsOptional, IsString, Min, IsInt } from 'class-validator';

export class CreateCargoDto {
  /// Город погрузки — обязательное поле (задача 040, п.7): выбор из
  /// справочника точек/городов, а не «первая активная точка».
  @IsString()
  pointId!: string;

  @IsString()
  destinationCountryId!: string;

  @IsOptional()
  @IsString()
  destinationCityId?: string;

  @IsString()
  bodyTypeId!: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  weightKg?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  volumeM3?: number;

  /// Паллеты (задача 033, п.4) — вместо/вместе с объёмом.
  @IsOptional()
  @IsInt()
  @Min(1)
  palletCount?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];

  @IsNumber()
  @Min(0)
  price!: number;

  @IsIn(['USD', 'CNY', 'KZT'])
  currency!: 'USD' | 'CNY' | 'KZT';

  @IsISO8601()
  readyDate!: string;

  /// «Можно догрузом» (задача 040, п.6).
  @IsOptional()
  @IsBoolean()
  allowPartial?: boolean;

  @IsOptional()
  @IsString()
  description?: string;
}
