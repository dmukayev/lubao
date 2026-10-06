import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import 'status_helpers.dart';

/// Единый обработчик ошибок API (задача 041, п.7): сеть/таймаут, сессия,
/// запрещено, 4xx с кодом (занят груз, отклик закрыт…), 5xx — текст из ARB на
/// языке пользователя; молчаливых `catch (_)` в действиях быть не должно.
/// [fallback] — свой текст для «прочих» ошибок (например, «Не удалось загрузить фото»).
String errorMessage(LubaoLocalizations t, Object error, {String? fallback}) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return t.errorNetwork;
      default:
        break;
    }
    final coded = responseConflictText(t, error);
    if (coded != null) return coded;
    final status = error.response?.statusCode;
    if (status == 401) return t.errorSessionExpired;
    if (status == 403) return t.errorForbidden;
    if (status == 400 || status == 422) return fallback ?? t.errorInvalidData;
    if (status != null && status >= 500) return t.errorServer;
  }
  return fallback ?? t.commonError;
}

/// SnackBar с понятной причиной; при [onRetry] — кнопка «Повторить».
void showApiError(BuildContext context, Object error, {String? fallback, VoidCallback? onRetry}) {
  if (!context.mounted) return;
  final t = context.l10n;
  debugPrint('API error: $error');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(errorMessage(t, error, fallback: fallback)),
    action: onRetry == null ? null : SnackBarAction(label: t.commonRetry, onPressed: onRetry),
  ));
}
