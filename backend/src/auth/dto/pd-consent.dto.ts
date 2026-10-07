import { IsString, MaxLength } from 'class-validator';

export class PdConsentDto {
  @IsString()
  @MaxLength(32)
  version!: string;
}
