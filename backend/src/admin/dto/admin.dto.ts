import { IsBoolean, IsIn, IsInt, IsOptional, IsString, Min } from 'class-validator';
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
