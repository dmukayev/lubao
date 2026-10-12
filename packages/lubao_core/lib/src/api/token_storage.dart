import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Хранение access/refresh токенов. flutter_secure_storage — Keychain на
/// iOS, Keystore на Android, localStorage на web (без доступа JS-кода
/// соседних доменов).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'lubao.accessToken';
  static const _refreshKey = 'lubao.refreshToken';

  /// Браузер по http-адресу (не localhost) не даёт WebCrypto — защищённое
  /// хранилище падает, и вход «не проходил» при верном пароле. Тогда токены
  /// живут в памяти вкладки (до её закрытия), а не теряются.
  final Map<String, String> _memory = {};

  Future<void> _write(String key, String value) async {
    _memory[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Остаётся в памяти.
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key) ?? _memory[key];
    } catch (_) {
      return _memory[key];
    }
  }

  Future<void> save(String accessToken, String refreshToken) async {
    await _write(_accessKey, accessToken);
    await _write(_refreshKey, refreshToken);
  }

  Future<String?> readAccess() => _read(_accessKey);

  Future<String?> readRefresh() => _read(_refreshKey);

  Future<void> clear() async {
    _memory.clear();
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
  }
}
