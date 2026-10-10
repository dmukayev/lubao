import { ArrayMaxSize, IsArray, IsBoolean, IsISO8601, IsIn, IsInt, IsNumber, IsObject, IsOptional, IsString, Max, Min } from 'class-validator';
import { CARGO_CURRENCIES, CargoCurrency, PAYMENT_FORMS, PaymentFormCode } from '../../common/currencies';

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
  @Max(200) // как «Объём кузова» в профилях (до 200 м³)
  volumeM3?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(60) // как «Европаллеты» в профилях
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
  @IsIn(CARGO_CURRENCIES)
  currency?: CargoCurrency;

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
