import { IsOptional, IsString } from 'class-validator';

/// Водитель передаёт `cargoId` (чат на карточке груза), компания —
/// `driverId` (чат из ленты «Кто будет на точке»/карточки водителя),
/// опционально вместе с `cargoId`, если контакт идёт с отклика/приглашения
/// по конкретному грузу (задача 017, п.1).
export class FindOrCreateChatDto {
  @IsOptional()
  @IsString()
  driverId?: string;

  @IsOptional()
  @IsString()
  cargoId?: string;
}
