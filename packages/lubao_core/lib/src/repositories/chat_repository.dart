import '../api/api_client.dart';
import '../models/chat.dart';

class ChatRepository {
  ChatRepository(this._client);

  final ApiClient _client;

  /// Чат — пара водитель+компания(+груз), не только сделка (задача 017,
  /// п.1): водитель передаёт `cargoId` (чат с карточки груза), компания —
  /// `driverId` (чат с карточки водителя/ленты «Кто будет на точке»).
  Future<ChatThread> findOrCreate({String? driverId, String? cargoId}) async {
    final res = await _client.dio.post('/chats', data: {
      if (driverId != null) 'driverId': driverId,
      if (cargoId != null) 'cargoId': cargoId,
    });
    return ChatThread.fromJson(res.data as Map<String, dynamic>);
  }

  /// Мои чаты — у логиста это чаты всей компании, не только свои
  /// (decisions.md «Кабинет логиста», задача 012).
  Future<List<MyChatEntry>> myChats() async {
    final res = await _client.dio.get('/chats');
    return (res.data as List<dynamic>).map((e) => MyChatEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChatThread> thread(String chatId) async {
    final res = await _client.dio.get('/chats/$chatId');
    return ChatThread.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> messages(String chatId) async {
    final res = await _client.dio.get('/chats/$chatId/messages');
    return (res.data as List<dynamic>).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> send(String chatId, String text) async {
    final res = await _client.dio.post('/chats/$chatId/messages', data: {'text': text});
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
  }

  /// Проставить «прочитано» на чужих сообщениях (задача 011, п.6 —
  /// закрывает пробел из 017 п.9) — собеседник получит message:read.
  Future<void> markRead(String chatId) async {
    await _client.dio.post('/chats/$chatId/read');
  }

  /// «Перевод недоступен · повторить» (задача 010, п.7).
  Future<ChatMessage> retryTranslation(String chatId, String messageId) async {
    final res = await _client.dio.post('/chats/$chatId/messages/$messageId/retry-translation');
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
  }
}
