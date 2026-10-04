import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Хранение access/refresh токенов. flutter_secure_storage — Keychain на
/// iOS, Keystore на Android, localStorage на web (без доступа JS-кода
/// соседних доменов).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'lubao.accessToken';
  static const _refreshKey = 'lubao.refreshToken';

  Future<void> save(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> readAccess() => _storage.read(key: _accessKey);

  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
