import { IsArray, IsBoolean, IsEmail, IsIn, IsInt, IsISO8601, IsNotEmpty, IsNumber, IsObject, IsOptional, IsString, MaxLength, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { BooleanQuery } from '../../common/boolean-query.decorator';
import { IsPersonName } from '../../common/validators/person-name.validator';

export class ReviewVerificationDocumentDto {
  @IsIn(['APPROVED', 'REJECTED'])
  status!: 'APPROVED' | 'REJECTED';

  @IsOptional()
  @IsString()
  rejectReason?: string;

  /// Задача 031, п.22-23 — поля, принятые/исправленные админом в блоке
  /// «Распознано» (сейчас используются `iin`/`licenseNumber` — у них нет
  /// своей колонки в БД, госномер/VIN/БИН по-прежнему идут через Vehicle/
  /// Company). Отличие от распознанного значения пишется в audit_log.
  @IsOptional()
  @IsObject()
  confirmedFields?: Record<string, string>;
}

export class ResolveComplaintDto {
  @IsIn(['DISMISSED', 'WARNED', 'CARGO_UNPUBLISHED', 'BLOCKED'])
  resolution!: 'DISMISSED' | 'WARNED' | 'CARGO_UNPUBLISHED' | 'BLOCKED';

  /// Ответ автору жалобы — обязателен (п.24d): автор видит его в своём
  /// языке в «Мои жалобы» (когда появится модуль уведомлений/экран —
  /// см. заметку в статусе задачи 028).
  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  resolutionNote!: string;
}

export class SetVerifiedDto {
  @IsBoolean()
  isVerified!: boolean;

  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  reason!: string;

  /// Поставить «Проверен» без всех одобренных обязательных документов —
  /// только с явным флагом и причиной (задача 026, п.5: «проверил лично»).
  @IsOptional()
  @IsBoolean()
  force?: boolean;

  /// Отметки сверки профиля с документами (имя/фото/номер и т.п., задача
  /// 028, п.9) — раньше жили только в состоянии экрана и терялись при
  /// перезагрузке (задача 029, п.16). Ключи задаёт клиент (`name`,
  /// `photo`, `plate`, …) — тут не валидируем состав, пишем как есть в
  /// audit_log.
  @IsOptional()
  @IsObject()
  crossChecks?: Record<string, boolean | null>;
}

export class BlockUserDto {
  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  reason!: string;
}

export class SearchQueryDto {
  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @BooleanQuery()
  @IsBoolean()
  verified?: boolean;

  @IsOptional()
  @BooleanQuery()
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

/// Шаблон размера кузова (задача 033, п.11) — CRUD в админке, без релиза.
export class CreateBodySizePresetDto {
  @IsString()
  code!: string;

  name!: UpsertI18nNameDto;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  bodyTypeIds?: string[];

  @IsOptional()
  @IsNumber()
  innerLengthM?: number;

  @IsOptional()
  @IsNumber()
  innerWidthM?: number;

  @IsOptional()
  @IsNumber()
  innerHeightM?: number;

  @IsOptional()
  @IsNumber()
  volumeM3?: number;

  @IsOptional()
  @IsInt()
  palletsEuro?: number;

  @IsOptional()
  @IsInt()
  palletsStandard?: number;

  @IsOptional()
  @IsInt()
  sortOrder?: number;
}

export class AdminUpdateBodySizePresetDto {
  @IsOptional()
  name?: UpsertI18nNameDto;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  bodyTypeIds?: string[];

  @IsOptional()
  @IsNumber()
  innerLengthM?: number;

  @IsOptional()
  @IsNumber()
  innerWidthM?: number;

  @IsOptional()
  @IsNumber()
  innerHeightM?: number;

  @IsOptional()
  @IsNumber()
  volumeM3?: number;

  @IsOptional()
  @IsInt()
  palletsEuro?: number;

  @IsOptional()
  @IsInt()
  palletsStandard?: number;

  @IsOptional()
  @IsInt()
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  reason!: string;
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
  @BooleanQuery()
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

  /// См. SetVerifiedDto.crossChecks — та же сверка сохраняется и при
  /// возврате на доработку, не только при подтверждении (задача 029, п.16).
  @IsOptional()
  @IsObject()
  crossChecks?: Record<string, boolean | null>;
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

  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  reason!: string;
}

export class AdminReasonDto {
  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  reason!: string;
}

/// «Исправить статус» — только на соседний (п.17: вперёд/назад на один шаг).
export class AdminDealStatusDto {
  @IsIn(['SELECTED', 'CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED'])
  status!: 'SELECTED' | 'CONFIRMED_BY_DRIVER' | 'LOADED' | 'IN_TRANSIT' | 'DELIVERED';

  @IsNotEmpty()
  @MaxLength(1000)
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

  // Задача 032, п.6 — раньше была одна `vehicle` на обе машины гаража;
  // Flutter-панель брала поля из driver.vehicles.first (порядок не
  // гарантирован — у пары после миграции одинаковый createdAt), и если
  // первым приходил прицеп, его null-госномер уходил пустой строкой в
  // тягач. Разделены по смыслу — тягач/прицеп правятся каждый своим
  // набором полей, перепутать нечем.
  @IsOptional()
  @ValidateNested()
  @Type(() => AdminDriverVehicleUpdateDto)
  tractorVehicle?: AdminDriverVehicleUpdateDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => AdminDriverVehicleUpdateDto)
  trailerVehicle?: AdminDriverVehicleUpdateDto;

  @IsNotEmpty()
  @MaxLength(1000)
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

  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  reason!: string;
}

export class AdminSetMemberRoleDto {
  @IsIn(['OWNER', 'LOGIST'])
  role!: 'OWNER' | 'LOGIST';

  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  reason!: string;
}

export class AdminChangeMemberEmailDto {
  @IsEmail()
  email!: string;

  @IsNotEmpty()
  @MaxLength(1000)
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

  @IsNotEmpty()
  @MaxLength(1000)
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

  @IsNotEmpty()
  @MaxLength(1000)
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

  @IsNotEmpty()
  @MaxLength(1000)
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
