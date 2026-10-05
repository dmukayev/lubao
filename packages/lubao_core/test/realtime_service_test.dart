import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lubao_core/src/api/token_storage.dart';
import 'package:lubao_core/src/realtime/socket_like.dart';

/// Не трогает flutter_secure_storage/платформенные каналы — см. тот же
/// паттерн в api_client_test.dart.
class _FakeTokenStorage extends TokenStorage {
  String? access = 'fake-access-token';

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => null;

  @override
  Future<void> save(String accessToken, String refreshToken) async {
    access = accessToken;
  }

  @override
  Future<void> clear() async {
    access = null;
  }
}

class FakeSocket implements SocketLike {
  bool _connected = false;
  void Function(dynamic)? _onConnect;
  final Map<String, void Function(dynamic)> _listeners = {};
  final List<(String, dynamic)> emitted = [];
  bool disposed = false;

  @override
  bool get connected => _connected;

  @override
  void onConnect(void Function(dynamic) callback) => _onConnect = callback;

  @override
  void on(String event, void Function(dynamic) callback) => _listeners[event] = callback;

  @override
  void emit(String event, [dynamic data]) => emitted.add((event, data));

  @override
  void dispose() => disposed = true;

  void connectNow() {
    _connected = true;
    _onConnect?.call(null);
  }

  void disconnectNow() => _connected = false;

  void receive(String event, dynamic data) => _listeners[event]?.call(data);
}

void main() {
  late FakeSocket fakeSocket;
  late RealtimeService service;

  setUp(() {
    fakeSocket = FakeSocket();
    final apiClient = ApiClient(baseUrl: 'http://localhost', tokenStorage: _FakeTokenStorage());
    service = RealtimeService(
      baseUrl: 'http://localhost',
      apiClient: apiClient,
      socketFactory: (_, _) => fakeSocket,
    );
  });

  test('rejoins every previously-joined chat room on (re)connect — задача 029, п.3', () async {
    await service.connect();
    service.joinChat('chat-1');
    service.joinChat('chat-2');
    fakeSocket.emitted.clear();

    // Симулируем обрыв и восстановление связи — ровно то, что происходит
    // на границе, когда сеть на секунду пропадает.
    fakeSocket.disconnectNow();
    fakeSocket.connectNow();

    final joinCalls = fakeSocket.emitted.where((e) => e.$1 == 'join').map((e) => (e.$2 as Map)['chatId']).toSet();
    expect(joinCalls, {'chat-1', 'chat-2'});
  });

  test('a new message after reconnect still arrives via onMessageNew — задача 029, п.3', () async {
    await service.connect();
    service.joinChat('chat-1');

    fakeSocket.disconnectNow();
    fakeSocket.connectNow();

    final received = <Map<String, dynamic>>[];
    service.onMessageNew.listen(received.add);
    fakeSocket.receive('message:new', {'chatId': 'chat-1', 'id': 'm1'});

    await Future<void>.delayed(Duration.zero);
    expect(received, [{'chatId': 'chat-1', 'id': 'm1'}]);
  });

  test('onChatUpdated fires even for a chat the screen never joined — "Мои чаты" updates without opening the chat', () async {
    await service.connect();
    // Намеренно НЕ зовём joinChat — экран «Мои чаты» не состоит в
    // комнате конкретного чата.

    final received = <Map<String, dynamic>>[];
    service.onChatUpdated.listen(received.add);
    fakeSocket.receive('chat:updated', {'chatId': 'chat-99'});

    await Future<void>.delayed(Duration.zero);
    expect(received, [{'chatId': 'chat-99'}]);
  });

  test('onReconnected fires on the second connect, not the first', () async {
    await service.connect();

    var reconnectedCount = 0;
    service.onReconnected.listen((_) => reconnectedCount++);

    fakeSocket.connectNow(); // первый connect — не "пере"-подключение
    await Future<void>.delayed(Duration.zero); // broadcast-контроллер доставляет асинхронно
    expect(reconnectedCount, 0);

    fakeSocket.disconnectNow();
    fakeSocket.connectNow(); // второй — уже реконнект
    await Future<void>.delayed(Duration.zero);
    expect(reconnectedCount, 1);
  });

  test('leaveChat stops that room from being rejoined on reconnect', () async {
    await service.connect();
    service.joinChat('chat-1');
    service.joinChat('chat-2');
    service.leaveChat('chat-1');
    fakeSocket.emitted.clear();

    fakeSocket.disconnectNow();
    fakeSocket.connectNow();

    final joinCalls = fakeSocket.emitted.where((e) => e.$1 == 'join').map((e) => (e.$2 as Map)['chatId']).toSet();
    expect(joinCalls, {'chat-2'});
  });
}

