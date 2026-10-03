import 'package:flutter_test/flutter_test.dart';

import 'package:lubao_core/lubao_core.dart';

void main() {
  test('I18nText resolves the right language', () {
    const text = I18nText(kk: 'Қазақша', ru: 'Русский', zh: '中文');
    expect(text.forLanguageCode('kk'), 'Қазақша');
    expect(text.forLanguageCode('zh'), '中文');
    expect(text.forLanguageCode('ru'), 'Русский');
    expect(text.forLanguageCode('en'), 'Русский');
  });

  test('cargo feed sorts home, then selected directions, then the rest', () {
    Cargo cargoTo(String countryId) => Cargo(
          id: countryId,
          companyId: 'c',
          companyName: 'Co',
          pointId: 'p',
          destinationCountryId: countryId,
          bodyTypeId: 'bt',
          price: 100,
          currency: Currency.usd,
          readyDate: DateTime(2026, 1, 1),
          status: CargoStatus.published,
          publishedAt: DateTime(2026, 1, 1),
          expiresAt: DateTime(2026, 1, 3),
        );

    final items = sortCargoFeed(
      cargos: [cargoTo('other'), cargoTo('home'), cargoTo('selected')],
      driverHomeCountryId: 'home',
      driverDirectionCountryIds: {'selected'},
      anyCountry: false,
    );

    expect(items.map((e) => e.section).toList(), [
      CargoFeedSection.home,
      CargoFeedSection.selected,
      CargoFeedSection.other,
    ]);
  });
}
