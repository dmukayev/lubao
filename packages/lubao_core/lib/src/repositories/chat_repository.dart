import '../api/api_client.dart';
import '../models/chat.dart';

class ChatRepository {
  ChatRepository(this._client);

  final ApiClient _client;

  Future<ChatThread> threadForDeal(String dealId) async {
    final res = await _client.dio.get('/chats/$dealId');
    return ChatThread.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> messages(String dealId) async {
    final res = await _client.dio.get('/chats/$dealId/messages');
    return (res.data as List<dynamic>).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> send(String dealId, String text) async {
    final res = await _client.dio.post('/chats/$dealId/messages', data: {'text': text});
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
  }
}
