import { ExecutionContext, Injectable } from '@nestjs/common';
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
