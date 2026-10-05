import { IsArray, IsBoolean, IsEmail, IsIn, IsInt, IsISO8601, IsNumber, IsOptional, IsString, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { IsPersonName } from '../../common/validators/person-name.validator';

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

export class SetAppSettingDto {
  @IsString()
  value!: string;

  @IsOptional()
  @IsString()
  reason?: string;
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

/// Правки машины водителя внутри общей панели редактирования (п.19) — одна
/// вложенная DTO, не отдельный эндпоинт, т.к. правится как часть одной
/// причины/одной записи в audit_log.
export class AdminDriverVehicleUpdateDto {
  @IsOptional()
  @IsString()
  bodyTypeId?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  capacityTons?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  lengthM?: number;

  @IsOptional()
  @IsString()
  plateNumber?: string;

  @IsOptional()
  @IsString()
  brand?: string;
}

export class AdminUpdateDriverDto {
  @IsOptional()
  @IsPersonName()
  fullName?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  homeCityId?: string;

  @IsOptional()
  @IsBoolean()
  anyCountry?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  countryIds?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  permitIds?: string[];

  @IsOptional()
  @ValidateNested()
  @Type(() => AdminDriverVehicleUpdateDto)
  vehicle?: AdminDriverVehicleUpdateDto;

  @IsString()
  reason!: string;
}

export class AdminUpdateCompanyDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  nameRu?: string;

  @IsOptional()
  @IsString()
  countryId?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  legalAddress?: string;

  @IsOptional()
  @IsString()
  taxId?: string;

  @IsString()
  reason!: string;
}

export class AdminSetMemberRoleDto {
  @IsIn(['OWNER', 'LOGIST'])
  role!: 'OWNER' | 'LOGIST';

  @IsString()
  reason!: string;
}

export class AdminChangeMemberEmailDto {
  @IsEmail()
  email!: string;

  @IsString()
  reason!: string;
}

/// Правка уже существующего справочного элемента (не создание — оно уже
/// есть в Create*Dto выше). `UpsertI18nNameDto.en` опционален, как и везде
/// в справочниках.
export class AdminUpdateReferenceItemDto {
  @IsOptional()
  name?: UpsertI18nNameDto;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsInt()
  sortOrder?: number;

  @IsString()
  reason!: string;
}

export class AdminUpdatePointDto {
  @IsOptional()
  name?: UpsertI18nNameDto;

  @IsOptional()
  @IsString()
  cityId?: string;

  @IsOptional()
  @IsNumber()
  lat?: number;

  @IsOptional()
  @IsNumber()
  lng?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsString()
  reason!: string;
}

/// Правка уже APPROVED города (область/координаты нужны «Близко к дому»,
/// задача 016) — отдельно от `ModerateCityDto`, который только для очереди
/// PENDING-городов.
export class AdminUpdateCityDto {
  @IsOptional()
  name?: UpsertI18nNameDto;

  @IsOptional()
  @IsString()
  regionId?: string;

  @IsOptional()
  @IsNumber()
  lat?: number;

  @IsOptional()
  @IsNumber()
  lng?: number;

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
