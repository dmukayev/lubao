// Задача 050: вход через бот Telegram без кода — «Войти через Telegram» →
// (бот: «Старт» → «Поделиться номером») → приложение входит само. Telegram в
// e2e не настоящий: апдейты бота шлёт тест в webhook с секретом, как Telegram.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

/// Синтетический номер и id Telegram — только для e2e.
const _phone = '77010000089';
const _telegramUserId = 905001;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('водитель входит через бот Telegram без кода', (tester) async {
    final run = E2eRun(binding, 'telegram_login');
    await clearPersistedSession();
    final launcher = useFakeUrlLauncher();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));
    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;
    final bot = Dio(BaseOptions(baseUrl: e2eApiBase, headers: {'X-Telegram-Bot-Api-Secret-Token': 'e2e-telegram-secret'}));
    Future<void> update(Map<String, dynamic> message) =>
        bot.post('/telegram/webhook', data: {'update_id': DateTime.now().microsecondsSinceEpoch, 'message': {'chat': {'id': _telegramUserId}, 'from': {'id': _telegramUserId, 'language_code': 'ru'}, ...message}});

    late String nonce;
    await run.step(tester, 'кнопка-войти-через-telegram', () async {
      await tester.tap(find.byKey(const Key('roleSelectDriverButton')));
      await tester.pumpAndSettle();
      await waitFor(tester, find.byKey(const Key('driverLoginTelegramButton')));
      await tester.tap(find.byKey(const Key('driverLoginTelegramButton')));
      await waitFor(tester, find.byKey(const Key('driverLoginTelegramWaiting')));
      final url = launcher.launched.lastWhere((u) => u.contains('t.me/'));
      expect(url, startsWith('https://t.me/lubao_e2e_bot?start='));
      nonce = Uri.parse(url).queryParameters['start']!;
      expect(find.text(t.driverLoginTelegramWaiting), findsOneWidget);
      expectInsideSafeZone(tester);
    });

    await run.step(tester, 'чужой-контакт-не-принимается', () async {
      await update({'text': '/start $nonce'});
      await update({'contact': {'phone_number': '77019999999', 'user_id': 1}});
      await tester.pump(const Duration(seconds: 3));
      expect(find.byKey(const Key('driverLoginTelegramWaiting')), findsOneWidget, reason: 'пересланный чужой номер не входит');
    });

    await run.step(tester, 'свой-номер-вход-и-регистрация', () async {
      await update({'contact': {'phone_number': _phone, 'user_id': _telegramUserId}});
      // Новый номер — сразу анкета водителя, как после SMS-кода.
      await waitFor(tester, find.byKey(const Key('driverSetupFullName')), timeout: const Duration(seconds: 20));
      final reuse = await Dio(BaseOptions(baseUrl: e2eApiBase, validateStatus: (_) => true)).get('/auth/telegram/$nonce');
      expect(reuse.statusCode, 409, reason: 'nonce одноразовый');
      expectNoOverflow(tester);
    });
  });
}
