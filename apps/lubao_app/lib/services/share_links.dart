import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lubao_core/lubao_core.dart';

import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../router/app_router.dart';

/// Путь ссылки «Поделиться»: `/c|co|d/<код>` (App/Universal Links) или
/// `/open/c|co|d/<код>` (кнопка на публичной странице → веб-приложение).
final shareLinkPath = RegExp(r'^/(?:open/)?(c|co|d)/([A-Za-z0-9]{4,12})$');

/// 052 п.3: ссылка открывает нужный экран. Вошёл — сразу; не вошёл — код
/// запоминается и после входа ведёт туда же. Отложенная ссылка без сторонних
/// сервисов: страница перед магазином кладёт `LUBAO-<код>` в буфер, приложение
/// один раз после первого входа его забирает.
class ShareLinkHandler {
  ShareLinkHandler(this._ref) {
    _ref.listen<Session?>(sessionProvider, (previous, next) {
      if (next == null) return;
      // Вход — или (057 п.1) новый водитель только что заполнил анкету: до неё
      // профиля нет и экран груза открывать рано, поэтому ждём и этот переход.
      final loggedIn = previous == null;
      final registered = previous?.driver == null && next.driver != null && next.user.role == UserRole.driver;
      if (loggedIn || registered) unawaited(consume(checkClipboard: true));
    });
  }

  final Ref _ref;
  static const _storage = FlutterSecureStorage();
  static const _pendingKey = 'lubao.pendingShareCode';
  static const _clipboardCheckedKey = 'lubao.shareClipboardChecked';
  String? _pending;
  bool _busy = false;

  /// Код из открытой ссылки — помнить до входа (и после перезапуска).
  void remember(String code) {
    _pending = code;
    unawaited(_storage.write(key: _pendingKey, value: code).catchError((_) {}));
  }

  Future<String?> _takeCode({required bool checkClipboard}) async {
    var code = _pending;
    _pending = null;
    try {
      code ??= await _storage.read(key: _pendingKey);
      await _storage.delete(key: _pendingKey);
    } catch (_) {}
    if (code != null || !checkClipboard) return code;
    try {
      if (await _storage.read(key: _clipboardCheckedKey) != null) return null;
      await _storage.write(key: _clipboardCheckedKey, value: '1');
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return RegExp(r'^LUBAO-([A-Za-z0-9]{4,12})$').firstMatch(data?.text?.trim() ?? '')?.group(1);
    } catch (_) {
      return null;
    }
  }

  /// Засчитать вход по ссылке её автору и открыть экран.
  Future<void> consume({bool checkClipboard = false}) async {
    final session = _ref.read(sessionProvider);
    if (_busy || session == null) return;
    if (session.user.role == UserRole.driver && session.driver == null) return;
    _busy = true;
    try {
      final code = await _takeCode(checkClipboard: checkClipboard);
      if (code == null) return;
      final target = await _ref.read(shareRepositoryProvider).claim(code);
      _ref.read(routerProvider).go(targetPath(target, isDriver: session.user.role == UserRole.driver, companyId: session.companyMember?.companyId));
    } catch (_) {
      // Ссылка устарела или сеть — остаёмся на текущем экране.
    } finally {
      _busy = false;
    }
  }

  /// Куда ведёт ссылка: водителю — груз / грузы компании; логисту — свой груз
  /// (чужой — «Грузы») / «Водители».
  static String targetPath(ShareTarget target, {required bool isDriver, String? companyId}) => switch (target.kind) {
        ShareKind.cargo => isDriver ? '/driver/cargo/${target.targetId}' : '/company/cargos',
        ShareKind.company => isDriver ? '/driver/company/${target.targetId}' : '/company/cargos',
        ShareKind.driver => isDriver ? '/driver/feed' : '/company/drivers',
      };
}

final shareLinkHandlerProvider = Provider<ShareLinkHandler>((ref) => ShareLinkHandler(ref));
