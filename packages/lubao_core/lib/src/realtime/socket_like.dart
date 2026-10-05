import 'package:socket_io_client/socket_io_client.dart' as socket_io;

/// Минимальный интерфейс над socket_io_client (задача 029, п.3) — чтобы
/// в тестах [RealtimeService] можно было подставить фейковый сокет без
/// реальной сети. `socket_io.Socket` — конкретный класс с большой
/// поверхностью, этот интерфейс — только то, что сервис реально
/// использует.
abstract class SocketLike {
  bool get connected;
  void onConnect(void Function(dynamic) callback);
  void on(String event, void Function(dynamic) callback);
  void emit(String event, [dynamic data]);
  void dispose();
}

class RealSocket implements SocketLike {
  RealSocket(this._socket);

  final socket_io.Socket _socket;

  @override
  bool get connected => _socket.connected;

  @override
  void onConnect(void Function(dynamic) callback) => _socket.onConnect(callback);

  @override
  void on(String event, void Function(dynamic) callback) => _socket.on(event, callback);

  @override
  void emit(String event, [dynamic data]) => _socket.emit(event, data);

  @override
  void dispose() => _socket.dispose();
}

typedef SocketFactory = SocketLike Function(String baseUrl, Future<String?> Function() readToken);

SocketLike createRealSocket(String baseUrl, Future<String?> Function() readToken) {
  final socket = socket_io.io(
    baseUrl,
    socket_io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuthFn((callback) async {
          final current = await readToken();
          callback({'token': current});
        })
        .enableReconnection()
        .build(),
  );
  return RealSocket(socket);
}
