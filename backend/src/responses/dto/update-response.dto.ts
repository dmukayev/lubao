import { IsIn, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class UpdateResponseDto {
  @IsIn(['SELECTED', 'REJECTED'])
  status!: 'SELECTED' | 'REJECTED';
}

export class CreateResponseDto {
  @IsOptional()
  @IsString()
  message?: string;

  /// 058 п.5: своя цена (в валюте груза) и комментарий к ней.
  @IsOptional()
  @IsNumber()
  @Min(0.01)
  @Max(1_000_000_000)
  proposedPrice?: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  proposedComment?: string;
}

/// 058 п.5: изменить свою цену (null — по цене груза).
export class UpdateOfferDto {
  @IsOptional()
  @IsNumber()
  @Min(0.01)
  @Max(1_000_000_000)
  proposedPrice?: number | null;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  proposedComment?: string | null;
}

/// 058 п.5: встречная цена логиста.
export class CounterOfferDto {
  @IsNumber()
  @Min(0.01)
  @Max(1_000_000_000)
  price!: number;
}
