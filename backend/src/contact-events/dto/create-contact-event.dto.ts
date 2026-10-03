import { IsIn, IsOptional, IsString } from 'class-validator';

export class CreateContactEventDto {
  @IsString()
  driverId!: string;

  @IsString()
  companyId!: string;

  @IsOptional()
  @IsString()
  cargoId?: string;

  @IsOptional()
  @IsString()
  dealId?: string;

  @IsIn(['CALL', 'WHATSAPP'])
  type!: 'CALL' | 'WHATSAPP';
}
