import '../api/api_client.dart';
import '../models/common.dart';
import '../models/user.dart';

class CompanyRepository {
  CompanyRepository(this._client);

  final ApiClient _client;

  Future<Company> me() async {
    final res = await _client.dio.get('/companies/me');
    return Company.fromJson(res.data as Map<String, dynamic>);
  }

  /// Сменить пароль, уже находясь в аккаунте (отдельно от «Забыли пароль» —
  /// AuthRepository.resetPassword, для разлогиненных).
  Future<void> setPassword(String password) async {
    await _client.dio.post('/companies/me/password', data: {'password': password});
  }

  Future<List<CompanyMember>> members() async {
    final res = await _client.dio.get('/companies/me/members');
    return (res.data as List<dynamic>).map((e) => CompanyMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Пригласить сотрудника по ссылке (задача 025, «Путь Б» из 022) —
  /// только владелец. Возвращает токен, чтобы показать ссылку с кнопками
  /// «Скопировать» / «Поделиться» сразу, не дожидаясь письма.
  Future<String> createInvite({required String email, required CompanyMemberRole role}) async {
    final res = await _client.dio.post('/companies/me/invites', data: {
      'email': email,
      'role': role == CompanyMemberRole.owner ? 'OWNER' : 'LOGIST',
    });
    return (res.data as Map<String, dynamic>)['token'] as String;
  }

  /// Вебхук группового бота WeCom (задача 011, п.2) — только владелец.
  Future<Company> updateWeComWebhook(String? url) async {
    final res = await _client.dio.patch('/companies/me/wecom-webhook', data: {'wecomWebhookUrl': url});
    return Company.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> testWeComWebhook() async {
    await _client.dio.post('/companies/me/wecom-test');
  }

  /// Данные компании, которые правит владелец (задача 012) — город,
  /// юр. адрес, рег. номер (формат проверяется на бэкенде по стране).
  Future<Company> updateProfile({String? city, String? legalAddress, String? taxId}) async {
    final res = await _client.dio.patch('/companies/me', data: {
      if (city != null) 'city': city,
      if (legalAddress != null) 'legalAddress': legalAddress,
      if (taxId != null) 'taxId': taxId,
    });
    return Company.fromJson(res.data as Map<String, dynamic>);
  }

  /// «Мой профиль» (задача 012) — у владельца и у логиста отдельно; то,
  /// что видит водитель по грузу, который этот сотрудник опубликовал.
  Future<CompanyMember> updateMyContact({required String fullName, String? contactPhone, String? wechatId}) async {
    final res = await _client.dio.patch('/companies/me/contact', data: {
      'fullName': fullName,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (wechatId != null) 'wechatId': wechatId,
    });
    return CompanyMember.fromJson(res.data as Map<String, dynamic>);
  }

  /// Единственный документ, подтверждающий компанию (задача 012, п.5) —
  /// до него непроверенная компания не может опубликовать ни одного
  /// груза (COMPANY_NOT_VERIFIED).
  Future<List<VerificationDocument>> verificationDocuments() async {
    final res = await _client.dio.get('/companies/me/verification-documents');
    return (res.data as List<dynamic>).map((e) => VerificationDocument.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VerificationDocument> submitVerificationDocument({required String fileUrl}) async {
    final res = await _client.dio.post('/companies/me/verification-documents', data: {
      'type': verificationDocTypeToJson(VerificationDocType.companyRegistration),
      'fileUrl': fileUrl,
    });
    return VerificationDocument.fromJson(res.data as Map<String, dynamic>);
  }
}
