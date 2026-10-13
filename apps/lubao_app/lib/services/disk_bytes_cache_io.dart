import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 060 п.4 (телефоны): кэш картинок на диске — аватары (по версии), фото машин и груза
/// (по id/адресу). Документы водителя (права, удостоверение) сюда НЕ кладём —
/// это персональные данные. В вебе — без диска (только память браузера).
class DiskBytesCache {
  DiskBytesCache._();
  static final instance = DiskBytesCache._();

  /// Не больше этого — самые старые файлы удаляются уборкой (раз в несколько записей).
  static const maxFiles = 1000;

  /// 078: фото хранятся неделю — потом скачиваются заново.
  static const maxAge = Duration(days: 7);

  Directory? _dir;

  Future<Directory?> _directory() async {
    if (kIsWeb) return null;
    if (_dir != null) return _dir;
    try {
      final base = await getApplicationCacheDirectory();
      _dir = await Directory('${base.path}/lubao_images').create(recursive: true);
    } catch (_) {
      _dir = null;
    }
    return _dir;
  }

  /// FNV-1a (64 бита) — имя файла из ключа без лишних зависимостей.
  static String fileName(String key) {
    var hash = 0xcbf29ce484222325;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }

  Future<Uint8List?> read(String key) async {
    final dir = await _directory();
    if (dir == null) return null;
    final file = File('${dir.path}/${fileName(key)}');
    try {
      if (!await file.exists()) return null;
      if (DateTime.now().difference(await file.lastModified()) > maxAge) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Записей с последней уборки — убираем не на каждую запись (061 п.12).
  int _writesSinceTrim = 0;
  static const _trimEvery = 40;
  bool _trimming = false;

  Future<void> write(String key, Uint8List bytes) async {
    final dir = await _directory();
    if (dir == null) return;
    try {
      // 061 п.12: сначала во временный файл, потом переименование — оборванная
      // запись не оставит битую картинку под настоящим именем.
      final name = fileName(key);
      final tmp = File('${dir.path}/$name.tmp');
      await tmp.writeAsBytes(bytes, flush: false);
      await tmp.rename('${dir.path}/$name');
    } catch (_) {
      // Кэш — не критично.
    }
    if (++_writesSinceTrim >= _trimEvery) {
      _writesSinceTrim = 0;
      unawaited(_trim(dir));
    }
  }

  /// Самые старые файлы сверх [maxFiles] — удалить; асинхронно, без
  /// синхронных обращений к диску в кадре.
  Future<void> _trim(Directory dir) async {
    if (_trimming) return;
    _trimming = true;
    try {
      final entries = <(File, DateTime)>[];
      await for (final e in dir.list()) {
        if (e is File) entries.add((e, (await e.stat()).modified));
      }
      // Старше недели — удалить; сверх лимита — самые старые.
      final now = DateTime.now();
      for (final e in entries.where((e) => now.difference(e.$2) > maxAge).toList()) {
        await e.$1.delete().catchError((_) => e.$1);
        entries.remove(e);
      }
      if (entries.length <= maxFiles) return;
      entries.sort((a, b) => a.$2.compareTo(b.$2));
      for (final old in entries.take(entries.length - maxFiles)) {
        await old.$1.delete().catchError((_) => old.$1);
      }
    } catch (_) {
      // Кэш — не критично.
    } finally {
      _trimming = false;
    }
  }

  /// Сколько картинок на диске — для сквозных сценариев (061 п.9).
  @visibleForTesting
  Future<int> debugFileCount() async {
    final dir = await _directory();
    if (dir == null) return 0;
    return dir.list().where((e) => e is File).length;
  }

  /// 061 п.9: выход и удаление аккаунта — чужие фото на телефоне не остаются.
  Future<void> clear() async {
    final dir = await _directory();
    if (dir == null) return;
    try {
      await dir.delete(recursive: true);
    } catch (_) {
      // Нет папки — уже чисто.
    }
    _dir = null;
    _writesSinceTrim = 0;
  }

  /// Сначала диск, потом сеть; удачный ответ сети — на диск. 078: сети нет,
  /// а на диске есть фото старше недели — лучше старое, чем пусто.
  Future<Uint8List> getOrFetch(String key, Future<Uint8List> Function() fetch) async {
    final cached = await read(key);
    if (cached != null && cached.isNotEmpty) return cached;
    try {
      final bytes = await fetch();
      await write(key, bytes);
      return bytes;
    } catch (_) {
      final stale = await _readAnyAge(key);
      if (stale != null && stale.isNotEmpty) return stale;
      rethrow;
    }
  }

  Future<Uint8List?> _readAnyAge(String key) async {
    final dir = await _directory();
    if (dir == null) return null;
    final file = File('${dir.path}/${fileName(key)}');
    try {
      return await file.exists() ? await file.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }
}
