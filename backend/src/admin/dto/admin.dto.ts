import { IsBoolean, IsIn, IsOptional, IsString } from 'class-validator';

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
}

export class UpsertI18nNameDto {
  @IsString()
  kk!: string;

  @IsString()
  ru!: string;

  @IsString()
  zh!: string;
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
