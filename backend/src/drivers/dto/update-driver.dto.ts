import { ArrayUnique, IsArray, IsBoolean, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdateDriverDto {
  @IsString()
  fullName!: string;

  @IsString()
  homeCityId!: string;

  @IsBoolean()
  anyCountry!: boolean;

  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  directionCountryIds!: string[];

  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  permitIds!: string[];

  @IsString()
  bodyTypeId!: string;

  @IsOptional()
  @IsString()
  plateNumber?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  capacityTons?: number;
}
