import { IsIn, IsString } from 'class-validator';

export class UpdateDealStatusDto {
  @IsIn(['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED'])
  status!: 'CONFIRMED_BY_DRIVER' | 'LOADED' | 'IN_TRANSIT' | 'DELIVERED';
}

export class CancelDealDto {
  @IsString()
  reason!: string;
}
