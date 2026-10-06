import 'dart:async';

import '../api/api_client.dart';
import 'socket_like.dart';

/// Чат в реальном времени (задача 011, п.6-7; исправления — задача 029,
/// п.3 и п.10): один сокет на сессию, авторизация тем же access-токеном,
/// что и обычные запросы. Комнаты по chatId — сервер сам проверяет, что
/// сокет имеет право туда войти (RealtimeGateway.handleJoin), клиент
/// здесь ничего не решает.
///
/// Переподключение — на socket_io_client из коробки (reconnection: true),
/// но сам факт переподключения раньше "молчал": сервис не запоминал,
/// какие `chat:<id>`-комнаты были открыты, и не перезаходил в них после
/// нового handshake — после любого обрыва (на границе — норма) чат
/// замолкал навсегда, даже когда сокет формально был `isConnected`.
/// Теперь — [joinChat]/[leaveChat] пишут/чистят [_joinedChatIds], и на
/// каждый `connect` (включая автопереподключения) сервис перезаходит во
/// все запомненные комнаты и шлёт [onReconnected] — экраны чата по этому
/// сигналу делают один догоняющий рефетч (полный, не инкрементальный —
/// это пропорционально объёму чата на пилоте).
///
/// Если сокет совсем не поднимается (например, прокси блокирует WS —
/// актуально для Китая, задача 020), экраны чата сами переходят на опрос
/// раз в 10с, проверяя [isConnected] — см. ChatScreen/MyChatsScreen.
///
/// [socketFactory] — точка подмены для тестов (задача 029, п.3: «тест с
/// фейковым сокетом»); по умолчанию — настоящий socket_io_client.
class RealtimeService {
  RealtimeService({required String baseUrl, required ApiClient apiClient, SocketFactory socketFactory = createRealSocket})
      : _baseUrl = baseUrl,
        _apiClient = apiClient,
        _socketFactory = socketFactory;

  final String _baseUrl;
  final ApiClient _apiClient;
  final SocketFactory _socketFactory;
  SocketLike? _socket;
  final Set<String> _joinedChatIds = {};
  bool _hasConnectedBefore = false;

  final _messageNewController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();
  final _messageTranslatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _dealUpdatedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessageNew => _messageNewController.stream;
  Stream<Map<String, dynamic>> get onMessageRead => _messageReadController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  /// Перевод подъехал отдельно от самого сообщения (задача 029, п.6 —
  /// `send()` на сервере не ждёт DeepSeek, доставляет оригинал сразу).
  Stream<Map<String, dynamic>> get onMessageTranslated => _messageTranslatedController.stream;
  /// Чат обновился у пользователя (новое сообщение в одном из его чатов),
  /// независимо от того, открыт ли этот конкретный `chat:<id>` (задача 029,
  /// п.3) — сервер шлёт это в личную комнату пользователя. Экран «Мои
  /// чаты» слушает именно это, не [onMessageNew].
  Stream<Map<String, dynamic>> get onChatUpdated => _chatUpdatedController.stream;
  /// Статус сделки сменился (задача 038, п.12) — шлётся в комнату чата
  /// сделки, собеседник обновляет карточку без перезахода.
  Stream<Map<String, dynamic>> get onDealUpdated => _dealUpdatedController.stream;
  /// Сокет (пере)подключился — после первого раза это сигнал «могли
  /// пропустить сообщения, догоните рефетчем».
  Stream<void> get onReconnected => _reconnectedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    final token = await _apiClient.tokenStorage.readAccess();
    if (token == null) return;
    disconnect();
    _hasConnectedBefore = false;

    final socket = _socketFactory(_baseUrl, () => _apiClient.tokenStorage.readAccess());

    socket.onConnect((_) {
      // Перезаходим во все комнаты, которые были открыты до обрыва —
      // иначе после реконнекта у сокета новый id без единой комнаты, и
      // чат молчит навсегда, хотя isConnected уже снова true (задача 029,
      // п.3 — это и была суть бага).
      for (final chatId in _joinedChatIds) {
        socket.emit('join', {'chatId': chatId});
      }
      if (_hasConnectedBefore) _reconnectedController.add(null);
      _hasConnectedBefore = true;
    });

    socket.on('connect_error', (data) {
      final message = data?.toString() ?? '';
      if (message.contains('Invalid token') || message.contains('Invalid session')) {
        // Не ждём ответа — следующая попытка socket.io сама подхватит
        // новый токен через setAuthFn, если refresh успеет раньше.
        unawaited(_apiClient.refreshAccessToken());
      }
    });

    socket.on('message:new', (data) => _messageNewController.add(Map<String, dynamic>.from(data as Map)));
    socket.on('message:read', (data) => _messageReadController.add(Map<String, dynamic>.from(data as Map)));
    socket.on('typing', (data) => _typingController.add(Map<String, dynamic>.from(data as Map)));
    socket.on('chat:updated', (data) => _chatUpdatedController.add(Map<String, dynamic>.from(data as Map)));
    socket.on('message:translated', (data) => _messageTranslatedController.add(Map<String, dynamic>.from(data as Map)));
    socket.on('deal:updated', (data) => _dealUpdatedController.add(Map<String, dynamic>.from(data as Map)));
    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _joinedChatIds.clear();
    _hasConnectedBefore = false;
  }

  void joinChat(String chatId) {
    _joinedChatIds.add(chatId);
    _socket?.emit('join', {'chatId': chatId});
  }

  void leaveChat(String chatId) {
    _joinedChatIds.remove(chatId);
    _socket?.emit('leave', {'chatId': chatId});
  }

  void sendTyping(String chatId) => _socket?.emit('typing', {'chatId': chatId});
}
