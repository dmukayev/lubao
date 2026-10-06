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
    this.counterpartCountryCode,
    this.cargoResponseId,
    this.cargoResponseStatus,
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
  /// Страна компании-получателя (задача 032, п.15) — только когда viewer —
  /// водитель; решает, какую карту открыть в ссылке «моё место»: Amap для
  /// Китая, 2ГИС для остальных. Не язык интерфейса сотрудника.
  final String? counterpartCountryCode;
  /// Отклик ЭТОГО водителя на груз чата, если груз есть (задача 035) —
  /// решает, какую кнопку показать в закреплённой карточке: нет отклика —
  /// «Готов взять», `PENDING` — «Отклик отправлен»+«Отозвать».
  final String? cargoResponseId;
  final String? cargoResponseStatus;

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
        counterpartCountryCode: json['counterpartCountryCode'] as String?,
        cargoResponseId: json['cargoResponseId'] as String?,
        cargoResponseStatus: json['cargoResponseStatus'] as String?,
      );
}

/// Строка списка «Мои чаты» (задача 017, п.1) — `ChatThread` + превью
/// последнего сообщения и счётчик непрочитанных.
class MyChatEntry {
  const MyChatEntry({
    required this.thread,
    this.cargoPointName,
    this.lastMessageText,
    this.lastMessageSystemCode,
    this.lastMessageSystemParams = const {},
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final ChatThread thread;
  final I18nText? cargoPointName;
  final String? lastMessageText;

  /// Превью системной строки (038, п.25) — текст строится из ARB на языке
  /// читателя; null — последнее сообщение обычное.
  final String? lastMessageSystemCode;
  final Map<String, String> lastMessageSystemParams;
  final DateTime lastMessageAt;
  final int unreadCount;

  factory MyChatEntry.fromJson(Map<String, dynamic> json) => MyChatEntry(
        thread: ChatThread.fromJson(json),
        cargoPointName: json['cargoPointName'] == null ? null : I18nText.fromJson(json['cargoPointName'] as Map<String, dynamic>),
        lastMessageText: json['lastMessageText'] as String?,
        lastMessageSystemCode: json['lastMessageKind'] == 'SYSTEM' ? json['lastMessageSystemCode'] as String? : null,
        lastMessageSystemParams: ChatMessage.systemParamsFromJson(json['lastMessageSystemParams']),
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
    this.isSystem = false,
    this.systemCode,
    this.systemParams = const {},
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

  /// Системное сообщение (задача 038, п.11) — «водитель готов взять»,
  /// «выбран водитель» и т.п.: показывается по центру нейтральной плашкой,
  /// текст строится на клиенте из ARB по systemCode+systemParams на языке
  /// читателя; originalText — лишь русский фолбэк для неизвестных кодов.
  final bool isSystem;
  final String? systemCode;
  final Map<String, String> systemParams;

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
        isSystem: json['kind'] == 'SYSTEM',
        systemCode: json['systemCode'] as String?,
        systemParams: systemParamsFromJson(json['systemParams']),
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
        isSystem: json['kind'] == 'SYSTEM',
        systemCode: json['systemCode'] as String?,
        systemParams: systemParamsFromJson(json['systemParams']),
      );

  static Map<String, String> systemParamsFromJson(Object? raw) =>
      raw is Map ? raw.map((k, v) => MapEntry(k.toString(), v.toString())) : const {};

  String displayText(String languageCode) {
    if (languageCode == originalLang) return originalText;
    return translations?.forLanguageCode(languageCode) ?? originalText;
  }
}
