import 'dart:io';

import 'package:lubao_core/lubao_core.dart';
import 'package:path_provider/path_provider.dart';

import 'disk_bytes_cache.dart';

/// 078: ответы сервера — файлом на запись в `<support>/lubao_data` (не в
/// кэше ОС: система может стереть его в любой момент, а это данные для
/// работы без связи). Чужих телефонов здесь нет (ApiClient вырезает их).
class DataCacheStore implements CacheStore {
  DataCacheStore({this.folder = 'lubao_data'});

  final String folder;
  Directory? _dir;

  Future<Directory?> _directory() async {
    if (_dir != null) return _dir;
    try {
      final base = await getApplicationSupportDirectory();
      _dir = await Directory('${base.path}/$folder').create(recursive: true);
    } catch (_) {
      _dir = null;
    }
    return _dir;
  }

  Future<File?> _file(String key) async {
    final dir = await _directory();
    return dir == null ? null : File('${dir.path}/${DiskBytesCache.fileName(key)}.json');
  }

  @override
  Future<String?> read(String key) async {
    try {
      final file = await _file(key);
      return file != null && await file.exists() ? await file.readAsString() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    final file = await _file(key);
    if (file == null) return;
    try {
      // Сначала во временный файл — оборванная запись не оставит битый JSON.
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(value, flush: false);
      await tmp.rename(file.path);
    } catch (_) {}
  }

  @override
  Future<void> remove(String key) async {
    try {
      final file = await _file(key);
      if (file != null && await file.exists()) await file.delete();
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    final dir = await _directory();
    if (dir == null) return;
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
    _dir = null;
  }
}
