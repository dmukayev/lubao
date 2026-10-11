// 060 п.4: кэш картинок — на телефонах на диске, в вебе без dart:io.
export 'disk_bytes_cache_io.dart' if (dart.library.js_interop) 'disk_bytes_cache_web.dart';
