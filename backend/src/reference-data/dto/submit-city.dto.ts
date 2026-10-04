import { IsString, Length } from 'class-validator';

export class SubmitCityDto {
  @IsString()
  @Length(2, 80)
  settlementName!: string;

  @IsString()
  regionId!: string;
}
