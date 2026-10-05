// Задача 034, сценарии 4 и 5 (упрощённый вариант, см. docs/tasks/034-e2e-scenarios.md
// «Итог»): водитель входит по телефону, публикует анонс «Буду на точке»,
// затем из ленты открывает карточку груза и пишет в чат. Данные —
// фиксированный сид `backend/prisma/seed-e2e.ts`, запускается
// `scripts/e2e.sh`. Тексты — через ARB-ключи (`t.xxx`), не строками.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_core/lubao_core.dart';

const _driverPhoneLocal = '7010000001'; // полный номер +77010000001 — seed-e2e.ts
const _devCode = '1111';

/// На реальном устройстве/симуляторе первый сетевой запрос (восстановление
/// сессии, справочники) может занять больше одного кадра — `pumpAndSettle`
/// считает кадры осевшими раньше, чем приходит ответ сети. Ждём появления
/// виджета реальным временем, а не количеством кадров.
Future<void> _waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      for (final w in find.byType(Text).evaluate().map((e) => e.widget).whereType<Text>().take(20)) {
        debugPrint('[E2E-DEBUG] Text: ${w.data}');
      }
      for (final w in find.byType(Scaffold).evaluate()) {
        debugPrint('[E2E-DEBUG] Scaffold found: $w');
      }
      fail('Не нашли виджет за $timeout: $finder');
    }
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.pumpAndSettle();
}

/// Сессия (flutter_secure_storage → Keychain) переживает `simctl uninstall`
/// — iOS не чистит Keychain при удалении приложения. Чтобы повторный
/// прогон был детерминирован независимо от того, кто входил в прошлый раз,
/// чистим токены ДО того, как `LubaoApp` вообще собран — через отдельный
/// `ProviderContainer` с тем же `TokenStorage` (реальный Keychain, не
/// in-memory фейк). Через экран профиля это не сделать надёжно: если старый
/// access-токен успел протухнуть (15 мин), экран профиля падает на 401
/// (известный баг вне рамок 034 — `_CompletenessBanner` читает `.value` у
/// `AsyncValue` без обработки ошибки) до того, как успеешь дотянуться до
/// кнопки «Выйти».
Future<void> _clearPersistedSession() async {
  final container = ProviderContainer();
  try {
    await container.read(authRepositoryProvider).logout();
  } catch (_) {
    // offline/401 — не важно, только бы tokenStorage.clear() выполнился.
  } finally {
    container.dispose();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('водитель: вход → анонс → лента → чат → сообщение', (tester) async {
    await _clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));

    // --- Выбор роли «водитель» (ждём восстановления сессии/сплэша) ---
    await _waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;
    await tester.tap(find.byKey(const Key('roleSelectDriverButton')));
    await tester.pumpAndSettle();

    // --- Вход по телефону ---
    await tester.enterText(find.byKey(const Key('driverLoginPhoneField')), _driverPhoneLocal);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('driverLoginSendCodeButton')));
    await _waitFor(tester, find.byKey(const Key('driverLoginCodeDigit0')));

    for (var i = 0; i < 4; i++) {
      await tester.enterText(find.byKey(Key('driverLoginCodeDigit$i')), _devCode[i]);
      await tester.pump(const Duration(milliseconds: 300));
    }

    // --- Главная (лента): анонс «Буду на точке» ---
    await _waitFor(tester, find.byKey(const Key('driverAnnounceArrivalButton')));
    await tester.tap(find.byKey(const Key('driverAnnounceArrivalButton')));
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('announceArrivalSubmitButton'));
    await tester.scrollUntilVisible(submitButton, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(submitButton);

    // Анонс опубликован — кнопка «Буду на точке» сменилась на «Я на месте».
    await _waitFor(tester, find.byKey(const Key('driverCheckInButton')));

    // --- Лента → карточка груза (фиксированный id из seed-e2e.ts) ---
    final cargoCardFinder = find.byKey(const Key('feedCargoCard-11111111-1111-4111-8111-111111111001'));
    await tester.scrollUntilVisible(cargoCardFinder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(cargoCardFinder);
    await _waitFor(tester, find.byKey(const Key('cargoDetailChatButton')));

    // --- Карточка груза → «Написать» ---
    await tester.tap(find.byKey(const Key('cargoDetailChatButton')));
    await _waitFor(tester, find.byKey(const Key('chatMessageInput')));

    // --- Чат: отправить сообщение ---
    const messageText = 'E2E: проверка сквозного сценария';
    await tester.enterText(find.byKey(const Key('chatMessageInput')), messageText);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await _waitFor(tester, find.text(messageText));

    // --- Список «Чаты» — сообщение видно в превью чата ---
    // `pageBack()` ищет Cupertino-кнопку независимо от того, что приложение
    // на Material (`AppBar` с `automaticallyImplyLeading`) — на симуляторе
    // iPhone находит 0 виджетов. Жмём на сам `BackButton` напрямую.
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.navChats));
    await _waitFor(tester, find.textContaining(messageText));
  });
}
