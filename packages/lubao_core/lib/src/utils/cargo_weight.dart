/// 055: вес груза. В базе — кг (`cargos.weightKg`); логист вводит в кг или т,
/// водитель везде видит тонны («18,5 т», «20 т»), груз меньше тонны — в кг
/// («800 кг»). Одна функция на все места показа.
enum WeightUnit { kg, t }

/// Предел веса груза в тоннах (проверка формы; сервер проверяет свой максимум).
const maxCargoTons = 60;

/// Порог подсказки «Может, 18 т?» в режиме кг.
const suspiciousKg = 100;

/// Число из поля ввода (запятая или точка, пробелы-разряды).
double? parseWeightNumber(String text) {
  final cleaned = text.trim().replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Значение поля в выбранной единице → кг.
double? weightInputToKg(String text, WeightUnit unit) {
  final v = parseWeightNumber(text);
  if (v == null) return null;
  return (unit == WeightUnit.t ? v * 1000 : v).roundToDouble();
}

/// Кг → текст поля в выбранной единице (редактирование груза): «18,5» / «18500».
String weightKgToInput(double kg, WeightUnit unit, {String languageCode = 'ru'}) {
  if (unit == WeightUnit.kg) return kg.round().toString();
  return _trimDecimal(kg / 1000, 3, languageCode);
}

String _decimalSeparator(String languageCode) => languageCode == 'ru' || languageCode == 'kk' ? ',' : '.';

String _trimDecimal(double v, int digits, String languageCode) {
  var s = v.toStringAsFixed(digits);
  if (s.contains('.')) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  return s.replaceAll('.', _decimalSeparator(languageCode));
}

String _groupThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

/// Показ веса водителю (и везде, кроме поля ввода): «18,5 т», «20 т», «800 кг».
String formatCargoWeight(double kg, {required String tonUnit, required String kgUnit, String languageCode = 'ru'}) {
  if (kg < 1000) return '${_groupThousands(kg.round())} $kgUnit';
  return '${_trimDecimal(kg / 1000, 1, languageCode)} $tonUnit';
}

/// Пересчёт под полем: в режиме кг — «= 18,5 т», в режиме т — «= 18 500 кг».
String? weightConversionLine(String text, WeightUnit unit, {required String tonUnit, required String kgUnit, String languageCode = 'ru'}) {
  final kg = weightInputToKg(text, unit);
  if (kg == null || kg <= 0) return null;
  return unit == WeightUnit.kg
      ? '= ${_trimDecimal(kg / 1000, 3, languageCode)} $tonUnit'
      : '= ${_groupThousands(kg.round())} $kgUnit';
}

/// Подсказка против лишних нулей. В режиме «т» больше предела — вероятно,
/// это килограммы: «Это 18 500 кг = 18,5 т?». В режиме «кг» меньше 100 —
/// вероятно, тонны: «Может, 18 т?». null — всё правдоподобно.
sealed class WeightHint {
  const WeightHint();
}

/// Введено в т, но похоже на кг: [kg] — то же число как килограммы.
class WeightLooksLikeKg extends WeightHint {
  const WeightLooksLikeKg(this.kg);
  final double kg;
}

/// Введено в кг, но похоже на т: [tons] — то же число как тонны.
class WeightLooksLikeTons extends WeightHint {
  const WeightLooksLikeTons(this.tons);
  final double tons;
}

WeightHint? weightHint(String text, WeightUnit unit) {
  final v = parseWeightNumber(text);
  if (v == null || v <= 0) return null;
  if (unit == WeightUnit.t && v > maxCargoTons) return WeightLooksLikeKg(v);
  if (unit == WeightUnit.kg && v < suspiciousKg) return WeightLooksLikeTons(v);
  return null;
}

/// Текст числа для подсказок: «18 500» (кг) / «18,5» (т).
String formatWeightKgNumber(double kg) => _groupThousands(kg.round());
String formatWeightTonsNumber(double tons, {String languageCode = 'ru'}) => _trimDecimal(tons, 3, languageCode);
