import { IsIn, IsOptional, IsString } from 'class-validator';

export class UpdateResponseDto {
  @IsIn(['SELECTED', 'REJECTED'])
  status!: 'SELECTED' | 'REJECTED';
}

export class CreateResponseDto {
  @IsOptional()
  @IsString()
  message?: string;
}
