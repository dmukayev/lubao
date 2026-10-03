import { IsArray, IsIn, IsISO8601, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateCargoDto {
  @IsString()
  destinationCountryId!: string;

  @IsOptional()
  @IsString()
  destinationCityId?: string;

  @IsString()
  bodyTypeId!: string;

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

  @IsNumber()
  @Min(0)
  price!: number;

  @IsIn(['USD', 'CNY', 'KZT'])
  currency!: 'USD' | 'CNY' | 'KZT';

  @IsISO8601()
  readyDate!: string;

  @IsOptional()
  @IsString()
  description?: string;
}
