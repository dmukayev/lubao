import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

void main() {
  late LubaoLocalizations t;
  setUpAll(() async => t = await LubaoLocalizations.delegate.load(const Locale('ru')));
  final now = DateTime(2026, 10, 10, 21, 0);

  test('058 п.7: «в сети» до 5 минут, «сегодня в 20:15», «вчера», дата', () {
    expect(formatLastSeen(t, now.subtract(const Duration(minutes: 4)), now: now), 'в сети');
    expect(formatLastSeen(t, DateTime(2026, 10, 10, 20, 15), now: now), 'был сегодня в 20:15');
    expect(formatLastSeen(t, DateTime(2026, 10, 9, 23, 0), now: now), 'был вчера');
    expect(formatLastSeen(t, DateTime(2026, 10, 1, 9, 0), now: now), 'был 01.10');
    expect(formatLastSeen(t, DateTime(2025, 12, 31, 9, 0), now: now), 'был 31.12.2025');
    expect(formatLastSeen(t, null, now: now), isNull);
  });

  test('058 п.1/4: цена и условия оплаты', () {
    expect(formatCurrencyAmount(1250000, Currency.rub), '1 250 000 ₽');
    expect(formatCurrencyAmount(95000000, Currency.uzs), '95 000 000 сум');
    // 063: под ценой — когда и как платят всю сумму; аванс — отдельной плашкой.
    expect(paymentWhenHowLine(t, paymentForm: PaymentForm.cash, paymentDelayDays: 5), 'через 5 дн. · нал.');
    expect(paymentWhenHowLine(t, paymentForm: PaymentForm.card), 'сразу · на карту');
    expect(paymentWhenHowLine(t, paymentDelayDays: 10), 'через 10 дн.');
    expect(paymentWhenHowLine(t), '');
    expect(advancePillText(t, advanceAmount: 5300, currency: Currency.usd), r'Аванс $5 300 при погрузке');
    expect(advancePillText(t, advanceAmount: 0, currency: Currency.usd), isNull);
    expect(cargoTrucksLabel(t, needed: 3, taken: 1), 'нужно 3 · осталось 2');
    expect(cargoTrucksLabel(t, needed: 1, taken: 0), isNull);
  });
}
