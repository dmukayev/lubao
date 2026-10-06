import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

/// 041, п.11: согласия на геопозицию хранятся отдельно, переживают перезапуск
/// и сбрасываются при выходе; рейтинг без отзывов — «—» (п.13).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final backing = <String, String>{};

  setUp(() {
    backing.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          return backing[call.arguments['key'] as String];
        case 'write':
          backing[call.arguments['key'] as String] = call.arguments['value'] as String;
          return null;
        case 'delete':
          backing.remove(call.arguments['key'] as String);
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('по умолчанию ни одного согласия', () async {
    final consent = await TrackingConsentStore().load();
    expect(consent.trip, isFalse);
    expect(consent.tripPaused, isFalse);
    expect(consent.terminal, isFalse);
    expect(consent.tripSharingActive, isFalse);
  });

  test('согласия независимы: рейс не включает проверку терминала и наоборот', () async {
    final store = TrackingConsentStore();
    await store.setTrip(true);
    var consent = await store.load();
    expect(consent.trip, isTrue);
    expect(consent.terminal, isFalse);

    await store.setTrip(false);
    await store.setTerminal(true);
    consent = await store.load();
    expect(consent.trip, isFalse);
    expect(consent.terminal, isTrue);
  });

  test('пауза: согласие остаётся, передача выключена', () async {
    final store = TrackingConsentStore();
    await store.setTrip(true);
    await store.setTripPaused(true);
    final consent = await store.load();
    expect(consent.trip, isTrue);
    expect(consent.tripSharingActive, isFalse);
    await store.setTripPaused(false);
    expect((await store.load()).tripSharingActive, isTrue);
  });

  test('clear() (выход из аккаунта) снимает все согласия', () async {
    final store = TrackingConsentStore();
    await store.setTrip(true);
    await store.setTripPaused(true);
    await store.setTerminal(true);
    await store.clear();
    final consent = await store.load();
    expect([consent.trip, consent.tripPaused, consent.terminal], [false, false, false]);
    expect(backing, isEmpty);
  });

  test('согласие переживает «перезапуск» — новый экземпляр читает то же хранилище', () async {
    await TrackingConsentStore().setTrip(true);
    expect((await TrackingConsentStore().load()).trip, isTrue);
  });

  test('formatRating: без отзывов «—», а не «0.0»', () {
    expect(formatRating(0, 0), '—');
    expect(formatRating(4.84, 3), '4.8');
    expect(formatRating(0, 1), '0.0');
  });
}
