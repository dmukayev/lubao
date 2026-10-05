import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../api/token_storage.dart';

/// Чат в реальном времени (задача 011, п.6-7): один сокет на сессию,
/// авторизация тем же access-токеном, что и обычные запросы. Комнаты по
/// chatId — сервер сам проверяет, что сокет имеет право туда войти
/// (RealtimeGateway.handleJoin), клиент здесь ничего не решает.
///
/// Переподключение — на socket_io_client из коробки (reconnection: true).
/// Если сокет совсем не поднимается (например, прокси блокирует WS —
/// актуально для Китая, задача 020), экраны чата сами переходят на опрос
/// раз в 10с, проверяя [isConnected] — см. ChatScreen/MyChatsScreen.
class RealtimeService {
  RealtimeService({required String baseUrl, TokenStorage? tokenStorage})
      : _baseUrl = baseUrl,
        _tokenStorage = tokenStorage ?? TokenStorage();

  final String _baseUrl;
  final TokenStorage _tokenStorage;
  socket_io.Socket? _socket;

  final _messageNewController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessageNew => _messageNewController.stream;
  Stream<Map<String, dynamic>> get onMessageRead => _messageReadController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    final token = await _tokenStorage.readAccess();
    if (token == null) return;
    disconnect();

    final socket = socket_io.io(
      _baseUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .build(),
    );
    socket.onConnect((_) {});
    socket.on('message:new', (data) => _messageNewController.add(Map<String, dynamic>.from(data as Map)));
    socket.on('message:read', (data) => _messageReadController.add(Map<String, dynamic>.from(data as Map)));
    socket.on('typing', (data) => _typingController.add(Map<String, dynamic>.from(data as Map)));
    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void joinChat(String chatId) => _socket?.emit('join', {'chatId': chatId});

  void leaveChat(String chatId) => _socket?.emit('leave', {'chatId': chatId});

  void sendTyping(String chatId) => _socket?.emit('typing', {'chatId': chatId});
}
