import { IsString, Matches } from 'class-validator';

/// 054: ключ файла из `POST /uploads/document` (UUID.расширение).
export class SetAvatarDto {
  @IsString()
  @Matches(/^[0-9a-f-]{36}\.[A-Za-z0-9]{1,10}$/)
  fileKey!: string;
}
