import { IsArray, IsIn, IsISO8601, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdateCargoDto {
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
}
