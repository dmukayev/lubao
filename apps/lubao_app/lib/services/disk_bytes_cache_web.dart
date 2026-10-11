import 'dart:typed_data';

/// 060 п.4 (веб): диска нет — только сеть (браузер кэширует сам).
class DiskBytesCache {
  DiskBytesCache._();
  static final instance = DiskBytesCache._();

  Future<Uint8List?> read(String key) async => null;
  Future<void> write(String key, Uint8List bytes) async {}
  Future<Uint8List> getOrFetch(String key, Future<Uint8List> Function() fetch) => fetch();
}
