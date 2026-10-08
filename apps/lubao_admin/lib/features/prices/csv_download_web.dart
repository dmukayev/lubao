import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Скачать CSV в браузере (047 п.8): ссылка data: с атрибутом download —
/// без внешних пакетов и запросов наружу.
Future<bool> downloadCsv(String fileName, List<int> bytes) async {
  final document = globalContext['document'] as JSObject;
  final anchor = document.callMethod<JSObject>('createElement'.toJS, 'a'.toJS);
  anchor['href'] = 'data:text/csv;charset=utf-8;base64,${base64Encode(bytes)}'.toJS;
  anchor['download'] = fileName.toJS;
  final body = document['body'] as JSObject;
  body.callMethod<JSAny?>('appendChild'.toJS, anchor);
  anchor.callMethod<JSAny?>('click'.toJS);
  body.callMethod<JSAny?>('removeChild'.toJS, anchor);
  return true;
}
