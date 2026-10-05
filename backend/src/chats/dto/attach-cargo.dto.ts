import { IsString } from 'class-validator';

/// «Предложить груз» из чата без груза (задача 035, п.3).
export class AttachCargoDto {
  @IsString()
  cargoId!: string;
}
