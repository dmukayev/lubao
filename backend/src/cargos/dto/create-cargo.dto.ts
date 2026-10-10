import { ArrayMaxSize, IsArray, IsBoolean, IsISO8601, IsIn, IsInt, IsNumber, IsObject, IsOptional, IsString, Max, Min } from 'class-validator';
import { CARGO_CURRENCIES, CargoCurrency, PAYMENT_FORMS, PaymentFormCode } from '../../common/currencies';

export class CreateCargoDto {
  /// 047: категория груза из справочника — обязательна при публикации.
  @IsString()
  categoryId!: string;

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
  /// До 60 т: защита от «20000» в поле тонн (живая проверка 2026-10-07).
  @Max(60_000)
  weightKg?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(200) // как «Объём кузова» в профилях (до 200 м³)
  volumeM3?: number;

  /// Паллеты (задача 033, п.4) — вместо/вместе с объёмом.
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(60) // как «Европаллеты» в профилях
  palletCount?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];

  @IsNumber()
  @Min(0)
  price!: number;

  @IsIn(CARGO_CURRENCIES)
  currency!: CargoCurrency;

  /// 058 п.1: аванс (в валюте груза, не больше цены), форма оплаты, отсрочка в днях.
  @IsOptional()
  @IsNumber()
  @Min(0)
  advanceAmount?: number | null;

  @IsOptional()
  @IsIn(PAYMENT_FORMS)
  paymentForm?: PaymentFormCode | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(365)
  paymentDelayDays?: number | null;

  /// 058 п.2: сколько машин нужно — 1–20.
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  trucksNeeded?: number;

  @IsISO8601()
  readyDate!: string;

  /// «Можно догрузом» (задача 040, п.6).
  @IsOptional()
  @IsBoolean()
  allowPartial?: boolean;

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
