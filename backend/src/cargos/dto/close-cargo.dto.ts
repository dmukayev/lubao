import { IsIn, IsOptional, IsString } from 'class-validator';

/// Груз нельзя закрыть без выбора исхода (задача 017, п.6).
export class CloseCargoDto {
  @IsIn(['FOUND_IN_APP', 'FOUND_OUTSIDE', 'CARGO_CANCELLED'])
  outcome!: 'FOUND_IN_APP' | 'FOUND_OUTSIDE' | 'CARGO_CANCELLED';

  @IsOptional()
  @IsString()
  driverId?: string;
}
