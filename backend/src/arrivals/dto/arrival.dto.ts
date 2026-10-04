import { IsArray, IsBoolean, IsDateString, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class AnnounceArrivalDto {
  @IsString()
  pointId!: string;

  /// ISO-дата/время прибытия — проверяется в сервисе (не раньше сейчас,
  /// не позже +14 дней, п. 1 задачи 015).
  @IsDateString()
  plannedAt!: string;

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
}
