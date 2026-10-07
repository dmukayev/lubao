import { ExecutionContext, Injectable } from '@nestjs/common';
import type { Request } from 'express';
import { ThrottlerGuard } from '@nestjs/throttler';

/// Глобальный лимит запросов на IP (задача 043, п.4). Только HTTP: WebSocket-
/// шлюз защищён своей авторизацией, а ThrottlerGuard на не-HTTP контексте
/// падает.
@Injectable()
export class AppThrottlerGuard extends ThrottlerGuard {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (context.getType() !== 'http') return true;
    return super.canActivate(context);
  }
}

/// Лимиты по умолчанию: общий — с запасом для обычной работы клиента;
/// строгий (`AUTH_THROTTLE`) — для регистрации, входа, «забыли пароль» и
/// проверки кода: перебор паролей/кодов и массовая регистрация идут с одного IP.
/// Переопределяются env: THROTTLE_LIMIT / THROTTLE_AUTH_LIMIT (запросов в минуту).
export const THROTTLE_TTL_MS = 60_000;
export const defaultLimit = () => Number(process.env.THROTTLE_LIMIT || 300);
export const authLimit = () => Number(process.env.THROTTLE_AUTH_LIMIT || 20);

/// Лимит на пользователя (043 п.11, защита от парсинга): ≤ 60 запросов в
/// минуту с одного аккаунта, сколько бы IP он ни менял. Ключ — `sub` из
/// access-токена (подпись здесь не проверяем: поддельный токен всё равно
/// отсечёт JwtAuthGuard, а лимит по IP остаётся). Без токена и у админа —
/// не применяется.
export const userLimit = () => Number(process.env.THROTTLE_USER_LIMIT || 60);

function tokenPayload(req: Request): { sub?: string; role?: string } | null {
  const header = req.headers?.authorization;
  if (!header?.startsWith('Bearer ')) return null;
  const part = header.slice(7).split('.')[1];
  if (!part) return null;
  try {
    return JSON.parse(Buffer.from(part, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
}

export const userThrottler = () => ({
  name: 'user',
  ttl: THROTTLE_TTL_MS,
  limit: userLimit(),
  getTracker: (req: Record<string, any>) => `user:${tokenPayload(req as Request)?.sub ?? ''}`,
  skipIf: (context: ExecutionContext) => {
    const payload = tokenPayload(context.switchToHttp().getRequest<Request>());
    return !payload?.sub || payload.role === 'ADMIN';
  },
});

