import '../api/api_client.dart';

/// 052: что делим — груз, все грузы компании, анонс водителя.
enum ShareKind { cargo, company, driver }

String shareKindToJson(ShareKind k) => switch (k) { ShareKind.cargo => 'CARGO', ShareKind.company => 'COMPANY', ShareKind.driver => 'DRIVER' };

ShareKind shareKindFromJson(String v) => switch (v) { 'COMPANY' => ShareKind.company, 'DRIVER' => ShareKind.driver, _ => ShareKind.cargo };

/// Куда ведёт ссылка (для открытия в приложении).
class ShareTarget {
  const ShareTarget({required this.kind, required this.targetId});
  final ShareKind kind;
  final String targetId;

  factory ShareTarget.fromJson(Map<String, dynamic> json) =>
      ShareTarget(kind: shareKindFromJson(json['type'] as String), targetId: json['targetId'] as String);
}

/// 052: короткие ссылки «Поделиться».
class ShareRepository {
  ShareRepository(this._client);
  final ApiClient _client;

  /// Ссылка автора на объект (та же при повторном «Поделиться»).
  Future<String> link(ShareKind kind, String targetId) async {
    final res = await _client.dio.post('/share', data: {'type': shareKindToJson(kind), 'targetId': targetId});
    return (res.data as Map<String, dynamic>)['url'] as String;
  }

  Future<ShareTarget> resolve(String code) async {
    final res = await _client.dio.get('/share/$code');
    return ShareTarget.fromJson(res.data as Map<String, dynamic>);
  }

  /// Первый вход по ссылке (после установки) — засчитать автору.
  Future<ShareTarget> claim(String code) async {
    final res = await _client.dio.post('/share/$code/claim');
    return ShareTarget.fromJson(res.data as Map<String, dynamic>);
  }
}
