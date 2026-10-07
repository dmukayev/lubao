import { IsIn, IsOptional, IsString } from 'class-validator';

/// «Позвонить»/WhatsApp (043 п.11): номер выдаётся этим запросом, не списком.
export class RevealContactDto {
  @IsIn(['CALL', 'WHATSAPP'])
  type!: 'CALL' | 'WHATSAPP';

  /// Для номера водителя — груз, из карточки которого звонит логист (в contact_events).
  @IsOptional()
  @IsString()
  cargoId?: string;
}
