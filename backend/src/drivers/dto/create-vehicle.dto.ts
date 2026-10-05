import { IsIn, IsNumber, IsOptional, IsString, Min } from 'class-validator';

const VEHICLE_KINDS = ['TRACTOR', 'TRAILER', 'RIGID'] as const;

/// Задача 031, этап B — «Мой гараж»: добавление машины. Без распознавания
/// (этап D ещё не подключён) — водитель заполняет поля вручную, ничего не
/// блокируется (решение 2026-10-05, «Несколько машин: гараж»).
export class CreateVehicleDto {
  @IsIn(VEHICLE_KINDS)
  kind!: (typeof VEHICLE_KINDS)[number];

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
  capacityTons?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  lengthM?: number;

  /// Размер кузова (задача 033) — шаблон ИЛИ свой размер (Д/Ш/В).
  @IsOptional()
  @IsString()
  sizePresetId?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  innerLengthM?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  innerWidthM?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  innerHeightM?: number;
}

/// «Размер кузова» отдельно от создания (задача 033, п.5) — существующим
/// машинам размер не проставляется автоматически, водитель выбирает при
/// следующем открытии гаража.
export class SetVehicleSizeDto {
  @IsOptional()
  @IsString()
  sizePresetId?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  innerLengthM?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  innerWidthM?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  innerHeightM?: number;
}
