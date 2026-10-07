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
}
