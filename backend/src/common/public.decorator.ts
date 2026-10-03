import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/** Маршрут доступен без заголовка X-User-Id (dev-авторизация). */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
