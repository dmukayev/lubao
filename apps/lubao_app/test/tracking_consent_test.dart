import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/shared/tracking_consent_sheet.dart';
import 'package:lubao_app/providers/locale_provider.dart';
import 'package:lubao_app/providers/tracking_provider.dart';

/// 041, п.11: два отдельных согласия на геопозицию; без второго репортер не
/// стартует; пауза не снимает согласие.
class _MemoryStore extends TrackingConsentStore {
  TrackingConsent value = const TrackingConsent();

  @override
  Future<TrackingConsent> load() async => value;
  @override
  Future<void> setTrip(bool granted) async => value = value.copyWith(trip: granted);
  @override
  Future<void> setTripPaused(bool paused) async => value = value.copyWith(tripPaused: paused);
  @override
  Future<void> setTerminal(bool granted) async => value = value.copyWith(terminal: granted);
  @override
  Future<void> clear() async => value = const TrackingConsent();
}

void main() {
  group('shouldSendLocation — когда вообще можно слать координаты', () {
    const none = TrackingConsent();
    const trip = TrackingConsent(trip: true);
    const tripPaused = TrackingConsent(trip: true, tripPaused: true);
    const terminal = TrackingConsent(terminal: true);

    test('есть рейс, но нет согласия на рейс — не шлём (репортер не запускается)', () {
      expect(shouldSendLocation(consent: none, hasTrackedDeal: true, onSiteAtTerminal: false), isFalse);
    });

    test('рейс + согласие — шлём; на паузе — нет', () {
      expect(shouldSendLocation(consent: trip, hasTrackedDeal: true, onSiteAtTerminal: false), isTrue);
      expect(shouldSendLocation(consent: tripPaused, hasTrackedDeal: true, onSiteAtTerminal: false), isFalse);
    });

    test('согласие есть, а рейса нет — не шлём (трекинг только при активной сделке)', () {
      expect(shouldSendLocation(consent: trip, hasTrackedDeal: false, onSiteAtTerminal: false), isFalse);
    });

    test('терминал: нужно и «на месте» в терминале, и своё согласие; согласие на рейс его не заменяет', () {
      expect(shouldSendLocation(consent: terminal, hasTrackedDeal: false, onSiteAtTerminal: true), isTrue);
      expect(shouldSendLocation(consent: trip, hasTrackedDeal: false, onSiteAtTerminal: true), isFalse);
      expect(shouldSendLocation(consent: terminal, hasTrackedDeal: false, onSiteAtTerminal: false), isFalse);
    });

    test('согласие на терминал не включает передачу на время рейса', () {
      expect(shouldSendLocation(consent: terminal, hasTrackedDeal: true, onSiteAtTerminal: false), isFalse);
    });
  });

  group('шторка согласия', () {
    late _MemoryStore store;
    late int osRequests;
    late WidgetRef capturedRef;
    late BuildContext capturedContext;

    Future<void> pump(WidgetTester tester) async {
      store = _MemoryStore();
      osRequests = 0;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          trackingConsentStoreProvider.overrideWithValue(store),
          osLocationPermissionRequestProvider.overrideWithValue(() async => osRequests++),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: supportedLocales,
          localizationsDelegates: LubaoLocalizations.localizationsDelegates,
          home: Consumer(builder: (context, ref, _) {
            capturedRef = ref;
            capturedContext = context;
            return const Scaffold(body: Column(children: [TripTrackingSwitch()]));
          }),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('«Понятно» — согласие записано и запрошено разрешение ОС; повторно шторка не показывается', (tester) async {
      await pump(tester);

      final future = ensureTripTrackingConsent(capturedContext, capturedRef);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tripTrackingConsentSheet')), findsOneWidget);
      expect(find.text('На время рейса приложение будет передавать ваше местоположение логисту. Это можно поставить на паузу в карточке сделки.'), findsOneWidget);
      expect(osRequests, 0, reason: 'системный запрос — только после нашего объяснения');

      await tester.tap(find.byKey(const Key('consentUnderstoodButton')));
      await tester.pumpAndSettle();
      expect(await future, isTrue);
      expect(store.value.trip, isTrue);
      expect(osRequests, 1);

      expect(await ensureTripTrackingConsent(capturedContext, capturedRef), isTrue);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tripTrackingConsentSheet')), findsNothing);
    });

    testWidgets('шторку закрыли — согласия нет, запрос ОС не отправлялся (сделка при этом идёт дальше)', (tester) async {
      await pump(tester);

      final future = ensureTripTrackingConsent(capturedContext, capturedRef);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(await future, isFalse);
      expect(store.value.trip, isFalse);
      expect(osRequests, 0);
    });

    testWidgets('согласие на терминал — отдельная шторка со своим текстом и своим флагом', (tester) async {
      await pump(tester);

      final future = ensureTerminalWatchConsent(capturedContext, capturedRef);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('terminalWatchConsentSheet')), findsOneWidget);
      expect(find.byKey(const Key('tripTrackingConsentSheet')), findsNothing);
      await tester.tap(find.byKey(const Key('consentUnderstoodButton')));
      await tester.pumpAndSettle();

      expect(await future, isTrue);
      expect(store.value.terminal, isTrue);
      expect(store.value.trip, isFalse, reason: 'согласие на терминал не даёт согласия на рейс');
    });

    testWidgets('переключатель: пауза/возобновление не снимают согласие; включение без согласия — шторка', (tester) async {
      await pump(tester);
      final switchFinder = find.byKey(const Key('tripTrackingSwitch'));
      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
      expect(find.text('На паузе — логист не видит, где вы'), findsOneWidget);

      // Включили без согласия — открылась шторка; «Понятно» включает передачу.
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tripTrackingConsentSheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('consentUnderstoodButton')));
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
      expect(find.text('Включено на время рейса'), findsOneWidget);

      // Пауза.
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(store.value.trip, isTrue, reason: 'пауза — не отзыв согласия');
      expect(store.value.tripPaused, isTrue);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);

      // Возобновление без повторной шторки.
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tripTrackingConsentSheet')), findsNothing);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
    });

    testWidgets('выход из аккаунта (reset) снимает согласия — следующий пользователь соглашается сам', (tester) async {
      await pump(tester);
      await capturedRef.read(trackingConsentProvider.notifier).grantTrip();
      await capturedRef.read(trackingConsentProvider.notifier).grantTerminal();
      await capturedRef.read(trackingConsentProvider.notifier).reset();
      expect(capturedRef.read(trackingConsentProvider).trip, isFalse);
      expect(capturedRef.read(trackingConsentProvider).terminal, isFalse);
      expect(store.value.trip, isFalse);
    });
  });

  testWidgets('тексты согласий на всех языках: рейс и «📍 в чате» не смешаны', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      home: Builder(builder: (context) {
        final t = context.l10n;
        expect(t.tripTrackingConsentBody, contains('During the trip'));
        expect(t.locationRationaleBody, contains('this chat only'));
        expect(t.locationRationaleBody, contains('There is no tracking'));
        expect(t.locationRationaleNearbyBody, contains('nearest city'));
        return const SizedBox();
      }),
    ));
  });
}
