import 'package:dio/dio.dart';

import '../l10n/generated/lubao_localizations.dart';

/// 073: код ошибки входа из ответа сервера (`INVALID_CREDENTIALS`, `LOCKED_OUT`…).
String? authErrorCode(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  return data is Map ? data['code'] as String? : null;
}

/// Сколько секунд ещё действует блокировка входа (`LOCKED_OUT`), иначе null.
int? lockedOutSeconds(Object error) {
  if (authErrorCode(error) != 'LOCKED_OUT') return null;
  final data = (error as DioException).response!.data as Map;
  return (data['retryAfterSec'] as num?)?.toInt() ?? 15 * 60;
}

/// 073: понятный текст ошибки входа / кода по коду сервера; не ошибка входа — null.
/// «Что-то пошло не так» — не отсюда: только для неизвестных 5xx.
String? authErrorText(LubaoLocalizations t, Object error) {
  if (error is DioException && (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout || error.type == DioExceptionType.sendTimeout)) {
    return t.errorNetwork;
  }
  return switch (authErrorCode(error)) {
    'INVALID_CREDENTIALS' => t.companyLoginInvalidCredentials,
    'LOCKED_OUT' => t.authLockedOut('${((lockedOutSeconds(error) ?? 900) / 60).ceil()}'),
    'INVALID_CODE' => t.authInvalidCode,
    'CODE_EXPIRED' => t.authCodeExpired,
    'CODE_ATTEMPTS_EXCEEDED' => t.authCodeAttempts,
    'RATE_LIMITED' => t.tooManyRequests,
    'ACCOUNT_BLOCKED' => t.accountBlockedMessage,
    'PHONE_OTHER_ROLE' => t.authPhoneOtherRole,
    _ => null,
  };
}
