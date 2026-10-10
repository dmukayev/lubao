import 'package:lubao_core/lubao_core.dart';

/// Пределы размеров машины — те же, что проверяет сервер (CreateVehicleDto).
abstract final class VehicleLimits {
  static const double lengthM = 25;
  static const double capacityTons = 60;
  static const double innerLengthM = 20;
  static const double innerWidthM = 3;
  static const double innerHeightM = 4.5;
}

/// Число из поля: «13,6» и «13.6» — одинаково; пусто — null.
double? parseDecimal(String raw) {
  final text = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  return text.isEmpty ? null : double.tryParse(text);
}

/// «20», «4,5» — предел так, как его пишут люди.
String formatLimit(double value) {
  final text = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
  return text.replaceAll('.', ',');
}

/// Ошибка под числовым полем: не число / не больше 0 / больше предела.
/// Пустое поле — ошибка только если [required].
String? numberFieldError(LubaoLocalizations t, String raw, {required double max, bool required = false}) {
  if (raw.trim().isEmpty) return required ? t.fieldNotNumber : null;
  final value = parseDecimal(raw);
  if (value == null) return t.fieldNotNumber;
  if (value <= 0) return t.fieldPositive;
  if (value > max) return t.fieldMax(formatLimit(max));
  return null;
}
