import { Transform } from 'class-transformer';

/// `@Type(() => Boolean)` на query-параметре превращает ЛЮБУЮ непустую
/// строку в `true` — `Boolean('false')` === `true` в JS (задача 029, п.1:
/// `?verified=false` в админке на самом деле означало «только
/// проверенные», `?stale=false` — «только зависшие», и т.п., ровно
/// наоборот тому, что ожидал фронтенд). Разбираем строку явно: 'true'/'1'
/// → true, 'false'/'0' → false, иначе (включая undefined) — не трогаем,
/// чтобы @IsOptional() пропустил поле, если фильтр не выбран.
export function BooleanQuery(): PropertyDecorator {
  return Transform(({ value }) => {
    if (typeof value === 'boolean') return value;
    if (value === 'true' || value === '1') return true;
    if (value === 'false' || value === '0') return false;
    return value;
  });
}
