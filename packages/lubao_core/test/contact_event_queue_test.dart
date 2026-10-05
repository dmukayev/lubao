import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/src/offline/contact_event_queue.dart';
import 'package:lubao_core/src/offline/pending_contact_event.dart';

/// Задача 029, п.14 — очередь контакт-событий, не отправленных из-за
/// отсутствия сети (типично на границе), должна переживать до следующей
/// успешной попытки, а не теряться вместе с `unawaited`-вызовом.
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

  PendingContactEvent event({String driverId = 'd1'}) =>
      PendingContactEvent(driverId: driverId, companyId: 'c1', cargoId: 'cargo1', type: 'CALL');

  test('flush() on an empty queue does not call send', () async {
    final queue = ContactEventQueue();
    var called = false;
    await queue.flush((e) async => called = true);
    expect(called, isFalse);
  });

  test('enqueue() persists the event, flush() sends it and clears the queue on success', () async {
    final queue = ContactEventQueue();
    await queue.enqueue(event());

    final sent = <PendingContactEvent>[];
    await queue.flush((e) async => sent.add(e));

    expect(sent, hasLength(1));
    expect(sent.first.driverId, 'd1');

    // Повторный flush — очередь уже пуста, send больше не вызывается.
    final secondRun = <PendingContactEvent>[];
    await queue.flush((e) async => secondRun.add(e));
    expect(secondRun, isEmpty);
  });

  test('an event that fails again during flush stays queued for the next attempt', () async {
    final queue = ContactEventQueue();
    await queue.enqueue(event(driverId: 'still-offline'));

    await queue.flush((e) async => throw Exception('still no network'));

    // Следующая попытка снова видит то же событие — оно не потерялось.
    final sent = <PendingContactEvent>[];
    await queue.flush((e) async => sent.add(e));
    expect(sent, hasLength(1));
    expect(sent.first.driverId, 'still-offline');
  });

  test('flush() sends events still queued after a prior partial failure, keeps only the ones that still fail', () async {
    final queue = ContactEventQueue();
    await queue.enqueue(event(driverId: 'a'));
    await queue.enqueue(event(driverId: 'b'));

    await queue.flush((e) async {
      if (e.driverId == 'b') throw Exception('fails again');
    });

    final sent = <PendingContactEvent>[];
    await queue.flush((e) async => sent.add(e));
    expect(sent.map((e) => e.driverId), ['b']);
  });
}
