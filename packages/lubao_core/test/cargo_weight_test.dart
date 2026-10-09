import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

/// 055: вес груза — ввод в кг или т, водителю в тоннах.
void main() {
  test('перевод кг↔т из поля', () {
    expect(weightInputToKg('18500', WeightUnit.kg), 18500);
    expect(weightInputToKg('18,5', WeightUnit.t), 18500);
    expect(weightInputToKg('18.5', WeightUnit.t), 18500);
    expect(weightInputToKg('18 500', WeightUnit.kg), 18500);
    expect(weightInputToKg('', WeightUnit.kg), isNull);
    expect(weightKgToInput(18500, WeightUnit.t), '18,5');
    expect(weightKgToInput(18500, WeightUnit.kg), '18500');
    expect(weightKgToInput(20000, WeightUnit.t, languageCode: 'en'), '20');
  });

  test('показ водителю: 800 кг, 18,5 т, 20 т', () {
    String f(double kg, [String lang = 'ru']) => formatCargoWeight(kg, tonUnit: 'т', kgUnit: 'кг', languageCode: lang);
    expect(f(800), '800 кг');
    expect(f(18500), '18,5 т');
    expect(f(20000), '20 т');
    expect(f(18540), '18,5 т');
    expect(f(18500, 'en'), '18.5 т');
  });

  test('пересчёт под полем', () {
    expect(weightConversionLine('18500', WeightUnit.kg, tonUnit: 'т', kgUnit: 'кг'), '= 18,5 т');
    expect(weightConversionLine('18,5', WeightUnit.t, tonUnit: 'т', kgUnit: 'кг'), '= 18 500 кг');
    expect(weightConversionLine('', WeightUnit.t, tonUnit: 'т', kgUnit: 'кг'), isNull);
  });

  test('подсказки против лишних нулей', () {
    final asKg = weightHint('18500', WeightUnit.t);
    expect(asKg, isA<WeightLooksLikeKg>());
    expect((asKg! as WeightLooksLikeKg).kg, 18500);
    final asTons = weightHint('18', WeightUnit.kg);
    expect(asTons, isA<WeightLooksLikeTons>());
    expect((asTons! as WeightLooksLikeTons).tons, 18);
    expect(weightHint('18500', WeightUnit.kg), isNull);
    expect(weightHint('18', WeightUnit.t), isNull);
    expect(weightHint('60', WeightUnit.t), isNull, reason: 'ровно предел — не подсказываем');
  });
}
