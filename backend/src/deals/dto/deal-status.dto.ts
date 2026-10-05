import { IsIn, IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class UpdateDealStatusDto {
  @IsIn(['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED'])
  status!: 'CONFIRMED_BY_DRIVER' | 'LOADED' | 'IN_TRANSIT' | 'DELIVERED';
}

export class CancelDealDto {
  @IsNotEmpty()
  @MaxLength(1000)
  @IsString()
  reason!: string;
}
