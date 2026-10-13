import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsNotEmpty, IsObject, IsOptional, IsString, Matches, MaxLength, Min } from 'class-validator';

/// 075: товар в админке — названия и синонимы на 4 языках, код, категория, кузов, ADR.
export class AdminGoodsDto {
  @IsOptional()
  @IsString()
  @Matches(/^[a-z0-9_]{2,60}$/)
  slug?: string;

  @IsOptional()
  @IsObject()
  name?: Record<string, string>;

  @IsOptional()
  @IsObject()
  synonyms?: Record<string, string[]>;

  /// 077: код необязателен — позиция (4 знака) или субпозиция (6).
  @IsOptional()
  @Matches(/^(\d{4}|\d{6})?$/)
  hsCode?: string | null;

  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsString()
  suggestedBodyTypeId?: string | null;

  @IsOptional()
  @IsBoolean()
  isDangerous?: boolean;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsNotEmpty()
  @IsString()
  @MaxLength(1000)
  reason!: string;
}

export class AdminHsNameDto {
  @IsObject()
  name!: Record<string, string>;

  @IsNotEmpty()
  @IsString()
  @MaxLength(1000)
  reason!: string;
}

export class AdminHsChapterDto {
  @IsString()
  categoryId!: string;

  @IsNotEmpty()
  @IsString()
  @MaxLength(1000)
  reason!: string;
}
