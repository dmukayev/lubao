import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'api_providers.dart';
import 'locale_provider.dart';
import 'data_providers.dart';
import 'tracking_provider.dart';

/// true, пока идёт попытка восстановить сессию из secure storage при
/// старте приложения (см. SessionController._restore) — роутер показывает
/// сплэш, пока это не завершится, чтобы не мигнуть экраном входа.
final sessionRestoringProvider = StateProvider<bool>((ref) => true);

class SessionController extends StateNotifier<Session?> {
  SessionController(this._ref) : super(null) {
    _sessionExpiredSub = _ref.read(apiClientProvider).onSessionExpired.listen((_) {
      state = null;
      _ref.read(trackingConsentProvider.notifier).reset();
    });
    _restore();
  }

  final Ref _ref;
  late final StreamSubscription<void> _sessionExpiredSub;

  Future<void> _restore() async {
    try {
      final session = await _ref.read(authRepositoryProvider).restore();
      state = session;
      if (session != null) _applyUserLocale(session.user.locale);
    } finally {
      _ref.read(sessionRestoringProvider.notifier).state = false;
    }
  }

  /// Язык хранится на сервере (задача 013, decisions.md «Смена языка») —
  /// после входа/восстановления сессии локальный выбор языка подстраивается
  /// под то, что сохранено для этого пользователя, а не под язык устройства,
  /// чтобы выбор был одинаковым на всех устройствах.
  void _applyUserLocale(String locale) {
    final match = supportedLocales.where((l) => l.languageCode == locale);
    if (match.isNotEmpty) {
      _ref.read(localeProvider.notifier).state = match.first;
    }
  }

  Future<String> requestDriverCode(String phone, {String? channel}) {
    return _ref.read(authRepositoryProvider).requestDriverCode(phone: phone, channel: channel);
  }

  Future<void> verifyDriverCode(String phone, String code) async {
    final session = await _ref.read(authRepositoryProvider).verifyDriverCode(phone: phone, code: code);
    state = session;
    _applyUserLocale(session.user.locale);
  }

  /// 050: вход через бот Telegram — true, когда водитель поделился номером.
  Future<bool> pollTelegramLogin(String nonce) async {
    final session = await _ref.read(authRepositoryProvider).pollTelegramLogin(nonce);
    if (session == null) return false;
    state = session;
    _applyUserLocale(session.user.locale);
    return true;
  }

  Future<Session> loginCompany(String email, String password) async {
    final session = await _ref.read(authRepositoryProvider).loginCompany(email: email, password: password);
    state = session;
    _applyUserLocale(session.user.locale);
    return session;
  }

  Future<Session> registerCompany({
    required String email,
    required String password,
    required String ownerName,
    required String companyName,
    String? companyNameRu,
    required String countryId,
    CompanyKind? kind,
  }) async {
    final session = await _ref.read(authRepositoryProvider).registerCompany(
          email: email,
          password: password,
          ownerName: ownerName,
          companyName: companyName,
          companyNameRu: companyNameRu,
          countryId: countryId,
          kind: kind,
        );
    state = session;
    _applyUserLocale(session.user.locale);
    return session;
  }

  Future<Session> acceptInvite(
    String token, {
    required String password,
    required String name,
    String? phone,
    String? wechat,
  }) async {
    final session = await _ref
        .read(authRepositoryProvider)
        .acceptInvite(token, password: password, name: name, phone: phone, wechat: wechat);
    state = session;
    _applyUserLocale(session.user.locale);
    return session;
  }

  /// Вызывается переключателем языка в профиле (задача 013) — сохраняет на
  /// сервере и применяет сразу, одним действием.
  Future<void> setLocale(String locale) async {
    await _ref.read(authRepositoryProvider).updateLocale(locale);
    final current = state;
    if (current != null) {
      state = current.copyWith(
        user: AppUser(
          id: current.user.id,
          role: current.user.role,
          phone: current.user.phone,
          email: current.user.email,
          locale: locale,
          emailVerifiedAt: current.user.emailVerifiedAt,
        ),
      );
    }
    _ref.read(localeProvider.notifier).state = Locale(locale);
  }

  /// Подтверждение email не блокирует вход (задача 025) — только снимает
  /// плашку-напоминание в кабинете после успешного кода.
  Future<void> verifyEmail(String code) async {
    await _ref.read(authRepositoryProvider).verifyEmail(code: code);
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      user: AppUser(
        id: current.user.id,
        role: current.user.role,
        phone: current.user.phone,
        email: current.user.email,
        locale: current.user.locale,
        emailVerifiedAt: DateTime.now(),
      ),
    );
  }

  void updateDriver(Driver driver) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(driver: driver);
  }

  void updateCompany(Company company, CompanyMember companyMember) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(company: company, companyMember: companyMember);
  }

  /// Что сделать перед выходом, пока авторизация ещё есть (042 п.1:
  /// PushService снимает токен). Сервисы подписываются сами — сессия про них
  /// не знает, иначе цикл зависимостей провайдеров (push зависит от сессии).
  final _beforeLogout = <Future<void> Function()>[];

  void addBeforeLogout(Future<void> Function() hook) => _beforeLogout.add(hook);

  Future<void> logout() async {
    for (final hook in _beforeLogout) {
      try {
        await hook();
      } catch (e) {
        debugPrint('SessionController: before-logout: $e');
      }
    }
    await _ref.read(authRepositoryProvider).logout();
    state = null;
    // Согласия на геопозицию относятся к человеку, а не к устройству (041, п.11).
    await _ref.read(trackingConsentProvider.notifier).reset();
    // 059: фильтр ленты — тоже его, не следующего на этом телефоне.
    await _ref.read(feedFilterStoreProvider).clear();
    _ref.invalidate(feedFilterProvider);
  }

  /// 043 п.2: согласие на обработку ПДн дано — экран больше не показываем.
  Future<void> acceptPdConsent() async {
    await _ref.read(authRepositoryProvider).acceptPdConsent();
    final current = state;
    if (current != null) state = current.copyWith(user: current.user.copyWith(pdConsentRequired: false));
  }

  /// 043 п.1: удалить аккаунт. Сначала сервер (при 409 — активная сделка,
  /// сотрудники — пользователь остаётся в приложении), потом локальная уборка
  /// хуков выхода: push-токены сервер уже удалил, ошибки хуков не важны.
  Future<void> deleteAccount() async {
    await _ref.read(authRepositoryProvider).deleteAccount();
    for (final hook in _beforeLogout) {
      try {
        await hook();
      } catch (e) {
        debugPrint('SessionController: after-delete: $e');
      }
    }
    state = null;
    await _ref.read(trackingConsentProvider.notifier).reset();
  }

  @override
  void dispose() {
    _sessionExpiredSub.cancel();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionController, Session?>((ref) => SessionController(ref));
