import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/** Маршрут доступен без access-токена (JwtAuthGuard пропускает его без проверки). */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
