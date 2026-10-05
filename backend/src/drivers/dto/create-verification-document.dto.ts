import { IsIn, IsOptional, IsString } from 'class-validator';

const DRIVER_DOC_TYPES = ['SELFIE', 'VEHICLE_PASSPORT', 'TRAILER_PASSPORT', 'DRIVER_LICENSE'] as const;

export class CreateVerificationDocumentDto {
  @IsIn(DRIVER_DOC_TYPES)
  type!: (typeof DRIVER_DOC_TYPES)[number];

  @IsString()
  fileUrl!: string;

  /// Задача 031 (гараж, Stage B) — для VEHICLE_PASSPORT/TRAILER_PASSPORT
  /// можно указать, к какой машине гаража относится документ. Необязательно:
  /// текущий экран проверки (до Stage B) его не присылает — сервер сам
  /// находит тягач/прицеп водителя.
  @IsOptional()
  @IsString()
  vehicleId?: string;
}
