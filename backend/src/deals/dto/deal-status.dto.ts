import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength, ValidateIf } from 'class-validator';
import { CANCEL_REASON_CODES, CancelReasonCode } from '../cancel-policy';

export class UpdateDealStatusDto {
  @IsIn(['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED'])
  status!: 'CONFIRMED_BY_DRIVER' | 'LOADED' | 'IN_TRANSIT' | 'DELIVERED';
}

export class CancelDealDto {
  /// Причина из списка (046 п.1). Старые клиенты шлют только текст — тогда «Другое».
  @IsOptional()
  @IsIn(CANCEL_REASON_CODES as unknown as string[])
  reasonCode?: CancelReasonCode;

  /// Текст обязателен только для «Другое».
  @ValidateIf((o: CancelDealDto) => !o.reasonCode || o.reasonCode === 'OTHER' || o.reason != null)
  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  reason?: string;
}

/// «Пожаловаться» по сделке (046 п.6) — сразу после отмены после загрузки.
export class DealComplaintDto {
  @IsNotEmpty()
  @MaxLength(200)
  @IsString()
  reason!: string;

  @IsOptional()
  @MaxLength(2000)
  @IsString()
  description?: string;
}

/// «Оспорить» запрос отмены (046 п.5) — позиция второй стороны для админа.
export class DisputeCancelDto {
  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  reason!: string;
}
