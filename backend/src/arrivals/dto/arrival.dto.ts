import { IsArray, IsBoolean, IsDateString, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class AnnounceArrivalDto {
  /// Правка конкретного анонса (задача 040: анонсов может быть несколько).
  @IsOptional()
  @IsString()
  arrivalId?: string;

  @IsString()
  pointId!: string;

  /// ISO-дата/время прибытия — проверяется в сервисе (не раньше сейчас,
  /// не позже +14 дней, п. 1 задачи 015).
  @IsDateString()
  plannedAt!: string;

  /// Календарный день приезда `YYYY-MM-DD` (041, п.5) — без часового пояса.
  @IsOptional()
  @IsString()
  plannedDay?: string;

  @IsOptional()
  @IsBoolean()
  anyCountry?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  countryIds?: string[];

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(3)
  waitDays?: number;

  /// Связка на эту поездку (задача 031, этап B, п.9) — чипы из гаража;
  /// если не указаны, сервис сам подставляет связку прошлого анонса или
  /// текущую машину водителя (этап A).
  @IsOptional()
  @IsString()
  tractorId?: string;

  @IsOptional()
  @IsString()
  trailerId?: string;
}

export class ArrivalActionDto {
  @IsOptional()
  @IsString()
  arrivalId?: string;

  /// Только для «Я на месте» без анонса: в каком городе.
  @IsOptional()
  @IsString()
  pointId?: string;
}
