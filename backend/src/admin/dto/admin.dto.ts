import { IsArray, IsBoolean, IsIn, IsInt, IsISO8601, IsNumber, IsOptional, IsString, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class ReviewVerificationDocumentDto {
  @IsIn(['APPROVED', 'REJECTED'])
  status!: 'APPROVED' | 'REJECTED';

  @IsOptional()
  @IsString()
  rejectReason?: string;
}

export class ResolveComplaintDto {
  @IsIn(['IN_REVIEW', 'RESOLVED', 'REJECTED'])
  status!: 'IN_REVIEW' | 'RESOLVED' | 'REJECTED';
}

export class SetVerifiedDto {
  @IsBoolean()
  isVerified!: boolean;

  @IsString()
  reason!: string;

  /// Поставить «Проверен» без всех одобренных обязательных документов —
  /// только с явным флагом и причиной (задача 026, п.5: «проверил лично»).
  @IsOptional()
  @IsBoolean()
  force?: boolean;
}

export class BlockUserDto {
  @IsString()
  reason!: string;
}

export class SearchQueryDto {
  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  verified?: boolean;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  blocked?: boolean;

  /// Водитель сейчас ON_SITE (п.3 задачи 028 — плитка «на точке сегодня»
  /// на сводке ссылается на `/drivers?onSite=today`).
  @IsOptional()
  @IsString()
  onSite?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  pageSize?: number;
}

export class UpsertI18nNameDto {
  @IsString()
  kk!: string;

  @IsString()
  ru!: string;

  @IsString()
  zh!: string;

  @IsOptional()
  @IsString()
  en?: string;
}

export class CreateBodyTypeDto {
  @IsString()
  code!: string;

  name!: UpsertI18nNameDto;
}

export class CreatePermitDto {
  @IsString()
  code!: string;

  name!: UpsertI18nNameDto;
}

export class CreatePointDto {
  @IsString()
  cityId!: string;

  name!: UpsertI18nNameDto;
}

export class SetActiveDto {
  @IsBoolean()
  isActive!: boolean;
}

export class SetAppSettingDto {
  @IsString()
  value!: string;
}

export class StatsQueryDto {
  @IsOptional()
  @IsIn(['today', '7d', '30d'])
  period?: 'today' | '7d' | '30d';
}

export class SearchDto {
  @IsString()
  q!: string;
}

export class CargoSearchQueryDto {
  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  companyId?: string;

  @IsOptional()
  @IsString()
  destinationCountryId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  pageSize?: number;
}

export class DealSearchQueryDto {
  @IsOptional()
  @IsString()
  q?: string;

  /// 'active' = не DELIVERED/CANCELLED (п. 16 задачи 028).
  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  stale?: boolean;

  @IsOptional()
  @IsString()
  driverId?: string;

  @IsOptional()
  @IsString()
  companyId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  pageSize?: number;
}

/// Один документ в решении «Вернуть на доработку» (задача 028, п.10).
export class DocumentDecisionDto {
  @IsString()
  documentId!: string;

  @IsString()
  rejectReason!: string;
}

export class ReturnForReworkDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DocumentDecisionDto)
  decisions!: DocumentDecisionDto[];

  @IsOptional()
  @IsString()
  note?: string;
}

/// Те же поля, что у company-эндпоинта публикации груза (п.15: «Исправить»
/// — те же поля, что при публикации), плюс обязательная причина — у
/// company-версии (`UpdateCargoDto`) её нет, т.к. там это не чужое
/// редактирование, а правка собственного груза.
export class AdminUpdateCargoDto {
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
  weightKg?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  volumeM3?: number;

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

  @IsString()
  reason!: string;
}

export class AdminReasonDto {
  @IsString()
  reason!: string;
}

/// «Исправить статус» — только на соседний (п.17: вперёд/назад на один шаг).
export class AdminDealStatusDto {
  @IsIn(['SELECTED', 'CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED'])
  status!: 'SELECTED' | 'CONFIRMED_BY_DRIVER' | 'LOADED' | 'IN_TRANSIT' | 'DELIVERED';

  @IsString()
  reason!: string;
}

export class ModerateCityDto {
  @IsIn(['APPROVE', 'MERGE', 'REJECT'])
  action!: 'APPROVE' | 'MERGE' | 'REJECT';

  @IsOptional()
  name?: UpsertI18nNameDto;

  @IsOptional()
  @IsString()
  mergeIntoCityId?: string;

  @IsOptional()
  @IsString()
  rejectReason?: string;
}
