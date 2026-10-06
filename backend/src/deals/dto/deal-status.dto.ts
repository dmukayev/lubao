import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateDealStatusDto {
  @IsIn(['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED'])
  status!: 'CONFIRMED_BY_DRIVER' | 'LOADED' | 'IN_TRANSIT' | 'DELIVERED';
}

export class CancelDealDto {
  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  reason!: string;

  /// Код причины (задача 038, п.15) — статистика по причинам считается
  /// кодом, а не переведённой строкой. Пока единственный пресет.
  @IsOptional()
  @IsIn(['TOOK_OTHER_CARGO'])
  reasonCode?: 'TOOK_OTHER_CARGO';
}
