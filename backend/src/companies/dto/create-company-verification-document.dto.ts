import { IsIn, IsString } from 'class-validator';

/// Один документ подтверждает компанию (задача 012, п.5) — свидетельство
/// о регистрации (营业执照 / справка с БИН). В отличие от водителя
/// (4 типа документов), здесь ровно один тип.
const COMPANY_DOC_TYPES = ['COMPANY_REGISTRATION'] as const;

export class CreateCompanyVerificationDocumentDto {
  @IsIn(COMPANY_DOC_TYPES)
  type!: (typeof COMPANY_DOC_TYPES)[number];

  @IsString()
  fileUrl!: string;
}
