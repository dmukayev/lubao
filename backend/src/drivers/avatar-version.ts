/// 054: версия фото профиля для клиентов (кэш миниатюры по `?v=`); null — фото
/// нет, у логиста буквы имени. Файл отдаёт только `GET /drivers/:id/avatar`.
export function avatarVersion(driver: { avatarFileKey?: string | null; avatarUpdatedAt?: Date | null } | null | undefined): string | null {
  return driver?.avatarFileKey && driver.avatarUpdatedAt ? driver.avatarUpdatedAt.toISOString() : null;
}
