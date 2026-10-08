import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

void main() {
  test('isVersionBelow: сравнение x.y.z по числам, суффиксы сборки не важны', () {
    expect(isVersionBelow('1.0.0', '1.0.1'), isTrue);
    expect(isVersionBelow('1.9.0', '1.10.0'), isTrue);
    expect(isVersionBelow('1.10.0', '1.9.9'), isFalse);
    expect(isVersionBelow('1.2.0', '1.2.0'), isFalse);
    expect(isVersionBelow('1.2.0+7', '1.2.0'), isFalse);
    expect(isVersionBelow('2.0', '1.9.9'), isFalse);
    expect(isVersionBelow('1.0.0', '99.0.0'), isTrue);
  });

  test('isVolumeBodyType (045 п.6): тент/изотерм/реф и неизвестные — да; цистерна, трал, автовоз — нет', () {
    for (final code in ['TENT', 'ISOTHERM', 'REFRIGERATOR', 'NEW_FROM_ADMIN', null]) {
      expect(isVolumeBodyType(code), isTrue, reason: '$code');
    }
    for (final code in ['FLATBED', 'CONTAINER', 'DUMP', 'LOWLOADER', 'CARCARRIER', 'GRAIN', 'TANK']) {
      expect(isVolumeBodyType(code), isFalse, reason: code);
    }
  });
}
