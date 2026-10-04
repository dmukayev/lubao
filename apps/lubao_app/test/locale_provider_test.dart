import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/providers/auth_provider.dart';
import 'package:lubao_app/providers/locale_provider.dart';

AppUser _user({required String locale}) =>
    AppUser(id: 'u1', role: UserRole.driver, phone: '+77011234567', locale: locale);

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({Session? restoreResult}) : _restoreResult = restoreResult, super(ApiClient(baseUrl: 'http://localhost'));

  final Session? _restoreResult;
  String? lastUpdatedLocale;

  @override
  Future<Session?> restore() async => _restoreResult;

  @override
  Future<void> updateLocale(String locale) async {
    lastUpdatedLocale = locale;
  }
}

void main() {
  // Задача 013, п.7: язык по умолчанию при первом запуске зависит от языка
  // устройства — kk/ru/zh/en проходят как есть, любой другой падает в ru.
  group('_initialLocale (default on first launch)', () {
    for (final entry in {
      'en': 'en',
      'kk': 'kk',
      'zh': 'zh',
      'ru': 'ru',
      'de': 'ru', // unsupported device language -> ru fallback
      'fr': 'ru',
    }.entries) {
      test('device locale "${entry.key}" -> app locale "${entry.value}"', () {
        TestWidgetsFlutterBinding.ensureInitialized();
        TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue = Locale(entry.key);
        addTearDown(TestWidgetsFlutterBinding.instance.platformDispatcher.clearLocaleTestValue);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(localeProvider).languageCode, entry.value);
      });
    }
  });

  // Задача 013 / decisions.md «Смена языка»: язык хранится на сервере — при
  // восстановлении сессии локальный выбор должен подстроиться под
  // users.locale, а не остаться на языке устройства.
  group('SessionController syncs localeProvider from the server on restore', () {
    test('restoring a session with locale=zh switches the app to zh even if the device is ru', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue = const Locale('ru');
      addTearDown(TestWidgetsFlutterBinding.instance.platformDispatcher.clearLocaleTestValue);

      final fakeAuth = _FakeAuthRepository(restoreResult: Session(user: _user(locale: 'zh')));
      final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(fakeAuth)]);
      addTearDown(container.dispose);

      container.read(sessionProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(localeProvider).languageCode, 'zh');
    });
  });

  group('SessionController.setLocale', () {
    test('persists the new locale via the repository and updates localeProvider + session.user', () async {
      // restoreResult, не ручной .state= после создания контейнера — иначе
      // асинхронный _restore() конструктора SessionController может
      // перезаписать состояние позже это же тика (гонка).
      final fakeAuth = _FakeAuthRepository(restoreResult: Session(user: _user(locale: 'ru')));
      final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(fakeAuth)]);
      addTearDown(container.dispose);

      container.read(sessionProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(sessionProvider.notifier).setLocale('en');

      expect(fakeAuth.lastUpdatedLocale, 'en');
      expect(container.read(localeProvider).languageCode, 'en');
      expect(container.read(sessionProvider)!.user.locale, 'en');
    });
  });
}
