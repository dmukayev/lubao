import { IsIn, IsNumber, IsObject, IsOptional, IsString, Max, Min } from 'class-validator';

const VEHICLE_KINDS = ['TRACTOR', 'TRAILER', 'RIGID'] as const;

/// Задача 031, этап B — «Мой гараж»: добавление машины. Без распознавания
/// (этап D ещё не подключён) — водитель заполняет поля вручную, ничего не
/// блокируется (решение 2026-10-05, «Несколько машин: гараж»).
export class CreateVehicleDto {
  @IsIn(VEHICLE_KINDS)
  kind!: (typeof VEHICLE_KINDS)[number];

  /// Задача 032, п.12 (038) — техпаспорт прикладывается прямо при создании:
  /// файл загружен заранее (POST /uploads/document), машина и документ
  /// создаются одной транзакцией — упавший между двумя запросами клиент
  /// больше не оставляет машину-сироту без документа.
  @IsOptional()
  @IsString()
  documentFileUrl?: string;

  @IsOptional()
  @IsString()
  bodyTypeId?: string;

  @IsOptional()
  @IsString()
  plateNumber?: string;

  @IsOptional()
  @IsString()
  vin?: string;

  @IsOptional()
  @IsString()
  brand?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(80) // как в профилях кузова (body-type-profiles: capacityTons до 80 т)
  capacityTons?: number;

  /// Длина машины/прицепа снаружи: автопоезд — до ~25 м.
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(25)
  lengthM?: number;

  /// Размер кузова (задача 033) — шаблон ИЛИ свой размер (Д/Ш/В).
  @IsOptional()
  @IsString()
  sizePresetId?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(20)
  innerLengthM?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(3)
  innerWidthM?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(4.5)
  innerHeightM?: number;

  /// 048: параметры по профилю кузова (литры, продукт, места под машины…);
  /// проверяются по полям типа кузова. Старые клиенты шлют колонки — их тоже учитываем.
  @IsOptional()
  @IsObject()
  specs?: Record<string, unknown>;
}

export class SetVehicleSizeDto {
  @IsOptional()
  @IsString()
  sizePresetId?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(20)
  innerLengthM?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(3)
  innerWidthM?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(4.5)
  innerHeightM?: number;

}

/// 048 п.3: параметры машины по профилю кузова.
export class SetVehicleSpecsDto {
  @IsObject()
  specs!: Record<string, unknown>;
}
