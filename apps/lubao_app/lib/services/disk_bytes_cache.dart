import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 060 п.4: кэш картинок на диске — аватары (по версии), фото машин и груза
/// (по id/адресу). Документы водителя (права, удостоверение) сюда НЕ кладём —
/// это персональные данные. В вебе — без диска (только память браузера).
class DiskBytesCache {
  DiskBytesCache._();
  static final instance = DiskBytesCache._();

  /// Не больше этого — самые старые файлы удаляются при записи.
  static const maxFiles = 400;

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
      return await file.exists() ? await file.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Uint8List bytes) async {
    final dir = await _directory();
    if (dir == null) return;
    try {
      await File('${dir.path}/${fileName(key)}').writeAsBytes(bytes, flush: false);
      final files = dir.listSync().whereType<File>().toList();
      if (files.length > maxFiles) {
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        for (final old in files.take(files.length - maxFiles)) {
          old.deleteSync();
        }
      }
    } catch (_) {
      // Кэш — не критично.
    }
  }

  /// Сначала диск, потом сеть; удачный ответ сети — на диск.
  Future<Uint8List> getOrFetch(String key, Future<Uint8List> Function() fetch) async {
    final cached = await read(key);
    if (cached != null && cached.isNotEmpty) return cached;
    final bytes = await fetch();
    await write(key, bytes);
    return bytes;
  }
}
