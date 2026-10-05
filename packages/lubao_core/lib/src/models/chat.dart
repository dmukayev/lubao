import 'common.dart';

class ChatThread {
  const ChatThread({
    required this.id,
    this.cargoId,
    this.dealId,
    required this.driverId,
    required this.companyId,
    required this.counterpartName,
    this.counterpartLocale,
    this.counterpartPhone,
    this.counterpartWechatId,
  });

  final String id;
  final String? cargoId;
  final String? dealId;
  final String driverId;
  final String companyId;
  final String counterpartName;
  final String? counterpartLocale;
  final String? counterpartPhone;
  final String? counterpartWechatId;

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'] as String,
        cargoId: json['cargoId'] as String?,
        dealId: json['dealId'] as String?,
        driverId: json['driverId'] as String,
        companyId: json['companyId'] as String,
        counterpartName: json['counterpartName'] as String? ?? '',
        counterpartLocale: json['counterpartLocale'] as String?,
        counterpartPhone: json['counterpartPhone'] as String?,
        counterpartWechatId: json['counterpartWechatId'] as String?,
      );
}

/// Строка списка «Мои чаты» (задача 017, п.1) — `ChatThread` + превью
/// последнего сообщения и счётчик непрочитанных.
class MyChatEntry {
  const MyChatEntry({required this.thread, this.cargoPointName, this.lastMessageText, required this.lastMessageAt, required this.unreadCount});

  final ChatThread thread;
  final I18nText? cargoPointName;
  final String? lastMessageText;
  final DateTime lastMessageAt;
  final int unreadCount;

  factory MyChatEntry.fromJson(Map<String, dynamic> json) => MyChatEntry(
        thread: ChatThread.fromJson(json),
        cargoPointName: json['cargoPointName'] == null ? null : I18nText.fromJson(json['cargoPointName'] as Map<String, dynamic>),
        lastMessageText: json['lastMessageText'] as String?,
        lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
        unreadCount: json['unreadCount'] as int? ?? 0,
      );
}

/// Зеркало backend-enum `TranslationStatus` (задача 010).
enum ChatMessageTranslationStatus { skipped, done, failed }

ChatMessageTranslationStatus _translationStatusFromJson(String? value) {
  switch (value) {
    case 'DONE':
      return ChatMessageTranslationStatus.done;
    case 'FAILED':
      return ChatMessageTranslationStatus.failed;
    default:
      return ChatMessageTranslationStatus.skipped;
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderUserId,
    required this.isMine,
    required this.originalText,
    required this.originalLang,
    this.translations,
    this.translationStatus = ChatMessageTranslationStatus.skipped,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String chatId;
  final String senderUserId;
  final bool isMine;
  final String originalText;
  final String originalLang;
  final I18nText? translations;
  final ChatMessageTranslationStatus translationStatus;
  final bool isRead;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        chatId: json['chatId'] as String,
        senderUserId: json['senderUserId'] as String,
        isMine: json['isMine'] as bool? ?? false,
        originalText: json['originalText'] as String,
        originalLang: json['originalLang'] as String,
        translations: json['translations'] == null ? null : I18nText.fromJson(json['translations'] as Map<String, dynamic>),
        translationStatus: _translationStatusFromJson(json['translationStatus'] as String?),
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// `message:new` с сокета не содержит `isMine` (сервер шлёт одно и то же
  /// всем в комнате) — клиент сам сравнивает senderUserId со своим id.
  factory ChatMessage.fromRealtimeJson(Map<String, dynamic> json, String viewerUserId) => ChatMessage(
        id: json['id'] as String,
        chatId: json['chatId'] as String,
        senderUserId: json['senderUserId'] as String,
        isMine: json['senderUserId'] == viewerUserId,
        originalText: json['originalText'] as String,
        originalLang: json['originalLang'] as String,
        translations: json['translations'] == null ? null : I18nText.fromJson(json['translations'] as Map<String, dynamic>),
        translationStatus: _translationStatusFromJson(json['translationStatus'] as String?),
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String displayText(String languageCode) {
    if (languageCode == originalLang) return originalText;
    return translations?.forLanguageCode(languageCode) ?? originalText;
  }
}
