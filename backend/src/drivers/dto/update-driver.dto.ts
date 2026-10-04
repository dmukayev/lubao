import { ArrayUnique, IsArray, IsBoolean, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { IsPersonName } from '../../common/validators/person-name.validator';

export class UpdateDriverDto {
  @IsPersonName()
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
