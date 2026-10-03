import { IsIn, IsString } from 'class-validator';

const DRIVER_DOC_TYPES = ['SELFIE', 'VEHICLE_PASSPORT', 'TRAILER_PASSPORT', 'DRIVER_LICENSE'] as const;

export class CreateVerificationDocumentDto {
  @IsIn(DRIVER_DOC_TYPES)
  type!: (typeof DRIVER_DOC_TYPES)[number];

  @IsString()
  fileUrl!: string;
}
