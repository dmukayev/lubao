import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

DioException _err(int status, Map<String, dynamic> body) {
  final req = RequestOptions(path: '/auth/company/login');
  return DioException(requestOptions: req, response: Response(requestOptions: req, statusCode: status, data: body), type: DioExceptionType.badResponse);
}

void main() {
  final t = lookupLubaoLocalizations(const Locale('ru'));

  test('073: код ошибки входа → понятный текст, без «Что-то пошло не так»', () {
    expect(authErrorText(t, _err(401, {'code': 'INVALID_CREDENTIALS'})), 'Неверный email или пароль');
    expect(authErrorText(t, _err(429, {'code': 'LOCKED_OUT', 'retryAfterSec': 840})), 'Слишком много попыток. Попробуйте через 14 мин');
    expect(lockedOutSeconds(_err(429, {'code': 'LOCKED_OUT', 'retryAfterSec': 840})), 840);
    expect(authErrorText(t, _err(400, {'code': 'INVALID_CODE'})), 'Неверный код');
    expect(authErrorText(t, _err(400, {'code': 'CODE_EXPIRED'})), 'Код устарел — отправьте новый');
    expect(authErrorText(t, _err(403, {'code': 'ACCOUNT_BLOCKED'})), t.accountBlockedMessage);
    expect(authErrorText(t, DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError)), t.errorNetwork);
    expect(authErrorText(t, _err(500, {'message': 'boom'})), isNull, reason: 'неизвестная 5xx — общий текст у вызывающего');
  });

  test('073: запросы входа — без обновления токена при 401', () {
    expect(ApiClient.isLoginPath('/auth/company/login'), isTrue);
    expect(ApiClient.isLoginPath('/auth/admin/login'), isTrue);
    expect(ApiClient.isLoginPath('/auth/phone/verify'), isTrue);
    expect(ApiClient.isLoginPath('/cargos'), isFalse);
  });

  test('074: общий текст ошибки — код → вид ответа → «Что-то пошло не так» с номером', () {
    expect(apiErrorText(t, _err(404, {'code': 'CARGO_NOT_FOUND'})), t.errCargoNotFound);
    expect(apiErrorText(t, _err(404, {'code': 'SOMETHING_NEW'})), t.errNotFound, reason: 'неизвестный код — по статусу');
    expect(apiErrorText(t, _err(409, {})), t.errConflict);
    expect(apiErrorText(t, _err(413, {})), t.errFileTooLarge);
    expect(apiErrorText(t, _err(503, {'code': 'SERVER_ERROR', 'requestId': 'ab12cd34'})), t.errServerError);
    expect(apiErrorText(t, _err(418, {'requestId': 'ab12cd34'})), t.errUnknownWithId('ab12cd34'));
    expect(apiErrorText(t, DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.receiveTimeout)), t.errTimeout);
    expect(apiErrorText(t, DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError)), t.errNoInternet);
    expect(apiErrorText(t, StateError('x')), t.commonError);
  });
}
