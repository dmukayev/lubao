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
  });

  final String id;
  final String? cargoId;
  final String? dealId;
  final String driverId;
  final String companyId;
  final String counterpartName;
  final String? counterpartLocale;

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'] as String,
        cargoId: json['cargoId'] as String?,
        dealId: json['dealId'] as String?,
        driverId: json['driverId'] as String,
        companyId: json['companyId'] as String,
        counterpartName: json['counterpartName'] as String? ?? '',
        counterpartLocale: json['counterpartLocale'] as String?,
      );
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
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String displayText(String languageCode) {
    if (languageCode == originalLang) return originalText;
    return translations?.forLanguageCode(languageCode) ?? originalText;
  }
}
