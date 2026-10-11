import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_app/services/stale_refresh.dart';

void main() {
  test('061 п.10: после фона дольше 3 минут — обновить, короче — нет', () {
    final now = DateTime(2026, 10, 11, 12);
    expect(isStaleOnResume(null, now), isFalse);
    expect(isStaleOnResume(now.subtract(const Duration(minutes: 2)), now), isFalse);
    expect(isStaleOnResume(now.subtract(const Duration(minutes: 4)), now), isTrue);
  });
}
