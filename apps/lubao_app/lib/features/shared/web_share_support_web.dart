import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// 057 п.10: есть ли в браузере Web Share (`navigator.share`). Без него
/// share_plus в вебе открывает `mailto:` — вместо этого своё меню.
bool browserCanShare() {
  final navigator = globalContext.getProperty<JSObject?>('navigator'.toJS);
  return navigator != null && navigator.has('share');
}
