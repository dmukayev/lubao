import { BadRequestException, HttpException, HttpStatus, UnauthorizedException } from '@nestjs/common';

/// 073: ошибки входа — кодом, а текст на языке пользователя подставляет
/// клиент (ARB). Ответ одинаковый для «нет такого email» и «неверный пароль»:
/// не раскрываем, есть ли аккаунт.
export const AuthErrors = {
  invalidCredentials: () => new UnauthorizedException({ code: 'INVALID_CREDENTIALS', message: 'Invalid email or password' }),
  lockedOut: (retryAfterSec: number) =>
    new HttpException({ code: 'LOCKED_OUT', retryAfterSec, message: 'Too many failed attempts, try again later' }, HttpStatus.TOO_MANY_REQUESTS),
  invalidCode: () => new BadRequestException({ code: 'INVALID_CODE', message: 'Invalid code' }),
  codeExpired: () => new BadRequestException({ code: 'CODE_EXPIRED', message: 'Code expired, request a new one' }),
  codeAttemptsExceeded: () => new BadRequestException({ code: 'CODE_ATTEMPTS_EXCEEDED', message: 'Too many attempts, request a new code' }),
  rateLimited: (message: string) => new HttpException({ code: 'RATE_LIMITED', message }, HttpStatus.TOO_MANY_REQUESTS),
  phoneOtherRole: () => new BadRequestException({ code: 'PHONE_OTHER_ROLE', message: 'This phone belongs to another role' }),
};

/// Итог проверки одноразового кода (SMS / письмо).
export type CodeCheck = 'ok' | 'invalid' | 'expired';

export function throwForCode(result: CodeCheck): void {
  if (result === 'expired') throw AuthErrors.codeExpired();
  if (result === 'invalid') throw AuthErrors.invalidCode();
}
