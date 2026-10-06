import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Подмена выбора фото в сквозных сценариях: системная камера/галерея
/// роботу недоступны, тест подставляет синтетическое изображение.
@visibleForTesting
Future<XFile?> Function(ImageSource source)? debugPhotoPicker;

Future<XFile?> pickPhoto(ImageSource source) {
  final override = debugPhotoPicker;
  if (override != null) return override(source);
  return ImagePicker().pickImage(source: source, imageQuality: 85);
}
