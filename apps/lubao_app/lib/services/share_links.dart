import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../router/app_router.dart';

/// Путь ссылки «Поделиться»: `/c|co|d/<код>` (App/Universal Links) или
/// `/open/c|co|d/<код>` (кнопка на публичной странице → веб-приложение).
final shareLinkPath = RegExp(r'^/(?:open/)?(c|co|d)/([A-Za-z0-9]{4,12})$');

/// 052 п.3: ссылка открывает нужный экран. Вошёл — сразу; не вошёл — код
/// запоминается и после входа ведёт туда же. Отложенная ссылка (после установки):
/// 057 п.8 — Android: код из Play Install Referrer (`referrer=share_<код>` в
/// ссылке на магазин), буфер не трогаем; iOS: буфер молча не читаем (системный
/// запрос «вставить из…»), а один раз показываем «Пришли по ссылке? Открыть груз»
/// и читаем буфер только по нажатию.
class ShareLinkHandler {
  ShareLinkHandler(this._ref) {
    _ref.listen<Session?>(sessionProvider, (previous, next) {
      if (next == null) return;
      // Вход — или (057 п.1) новый водитель только что заполнил анкету: до неё
      // профиля нет и экран груза открывать рано, поэтому ждём и этот переход.
      final loggedIn = previous == null;
      final registered = previous?.driver == null && next.driver != null && next.user.role == UserRole.driver;
      if (loggedIn || registered) unawaited(consume(firstRun: true));
    });
  }

  final Ref _ref;
  static const _storage = FlutterSecureStorage();
  static const _pendingKey = 'lubao.pendingShareCode';
  static const _firstRunKey = 'lubao.shareFirstRunChecked';
  static final _codeInClipboard = RegExp(r'^LUBAO-([A-Za-z0-9]{4,12})$');

  /// iOS: показать «Пришли по ссылке? Открыть груз» (первый запуск, кода нет).
  final prompt = ValueNotifier<bool>(false);
  String? _pending;
  bool _busy = false;

  /// Код из открытой ссылки — помнить до входа (и после перезапуска).
  void remember(String code) {
    _pending = code;
    _write = _storage.write(key: _pendingKey, value: code).catchError((_) {});
  }

  /// Запись кода в хранилище — асинхронная; удаление ждёт её, иначе код мог
  /// записаться уже после удаления и сработать при следующем входе (057).
  Future<void> _write = Future.value();

  Future<String?> _takeCode({required bool firstRun}) async {
    var code = _pending;
    _pending = null;
    try {
      await _write;
      code ??= await _storage.read(key: _pendingKey);
      await _storage.delete(key: _pendingKey);
    } catch (_) {}
    if (code != null || !firstRun) return code;
    try {
      if (await _storage.read(key: _firstRunKey) != null) return null;
      await _storage.write(key: _firstRunKey, value: '1');
    } catch (_) {
      return null;
    }
    if (kIsWeb) return null;
    if (defaultTargetPlatform == TargetPlatform.android) return _fromInstallReferrer();
    // hasStrings на iOS не вызывает запрос «вставить из…»: пустой буфер — без кнопки.
    if (defaultTargetPlatform == TargetPlatform.iOS && await Clipboard.hasStrings()) prompt.value = true;
    return null;
  }

  /// Android: `referrer=share_<код>` из ссылки «Установить» на странице.
  Future<String?> _fromInstallReferrer() async {
    try {
      final details = await PlayInstallReferrer.installReferrer;
      final raw = Uri.decodeComponent(details.installReferrer ?? '');
      return RegExp(r'(?:^|[&=])share_([A-Za-z0-9]{4,12})').firstMatch(raw)?.group(1);
    } catch (_) {
      // Нет Google Play (Android в Китае) — отложенной ссылки нет, страница и так открыла груз.
      return null;
    }
  }

  /// iOS: «Открыть груз» — только по нажатию читаем буфер (код положила страница).
  Future<bool> openFromClipboard() async {
    prompt.value = false;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final code = _codeInClipboard.firstMatch(data?.text?.trim() ?? '')?.group(1);
      if (code == null) return false;
      remember(code);
      await consume();
      return true;
    } catch (_) {
      return false;
    }
  }

  void dismissPrompt() => prompt.value = false;

  /// Засчитать вход по ссылке её автору и открыть экран.
  Future<void> consume({bool firstRun = false}) async {
    final session = _ref.read(sessionProvider);
    if (_busy || session == null) return;
    if (session.user.role == UserRole.driver && session.driver == null) return;
    _busy = true;
    try {
      final code = await _takeCode(firstRun: firstRun);
      if (code == null) return;
      final target = await _ref.read(shareRepositoryProvider).claim(code);
      var ownCargo = false;
      // 057 п.6: свой груз логиста — экран этого груза, чужой — «Грузы».
      if (target.kind == ShareKind.cargo && session.user.role != UserRole.driver) {
        try {
          final cargo = await _ref.read(cargoRepositoryProvider).byId(target.targetId);
          ownCargo = cargo.companyId == session.companyMember?.companyId;
        } catch (_) {}
      }
      _ref.read(routerProvider).go(targetPath(target, isDriver: session.user.role == UserRole.driver, ownCargo: ownCargo));
    } catch (_) {
      // Ссылка устарела или сеть — остаёмся на текущем экране.
    } finally {
      _busy = false;
    }
  }

  /// Куда ведёт ссылка: водителю — груз / грузы компании; логисту — свой груз
  /// (экран груза; чужой — «Грузы») / карточка этого водителя (057 п.6).
  static String targetPath(ShareTarget target, {required bool isDriver, bool ownCargo = false}) => switch (target.kind) {
        ShareKind.cargo => isDriver ? '/driver/cargo/${target.targetId}' : (ownCargo ? '/company/cargos/${target.targetId}/responses' : '/company/cargos'),
        ShareKind.company => isDriver ? '/driver/company/${target.targetId}' : '/company/cargos',
        ShareKind.driver => isDriver ? '/driver/feed' : '/company/driver/${target.targetId}',
      };
}

final shareLinkHandlerProvider = Provider<ShareLinkHandler>((ref) => ShareLinkHandler(ref));
