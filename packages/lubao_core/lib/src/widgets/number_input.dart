import '../l10n/generated/lubao_localizations.dart';

/// Число из поля: «13,6» и «13.6» — одинаково; пусто или не число — null.
double? parseDecimal(String raw) {
  final text = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  return text.isEmpty ? null : double.tryParse(text);
}

/// Предел так, как его пишут люди: «20», «4,5», «30 000».
String formatLimit(double value) {
  if (value != value.roundToDouble()) return value.toString().replaceAll('.', ',');
  final s = value.toStringAsFixed(0);
  return s.length > 4 ? s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ') : s;
}

/// Ошибка под числовым полем — конкретная причина: не число / меньше [min]
/// (без [min] и с [positive] — должно быть больше 0) / больше [max]. Пусто —
/// ошибка только при [required]. [positive] = false — для полей, где бывает
/// минус (температура рефрижератора).
String? numberFieldError(LubaoLocalizations t, String raw, {double? max, double? min, bool required = false, bool positive = true}) {
  if (raw.trim().isEmpty) return required ? t.fieldRequired : null;
  final value = parseDecimal(raw);
  if (value == null) return t.fieldNotNumber;
  if (min != null && value < min) return t.fieldMin(formatLimit(min));
  if (min == null && positive && value <= 0) return t.fieldPositive;
  if (max != null && value > max) return t.fieldMax(formatLimit(max));
  return null;
}
