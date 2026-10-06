import 'package:flutter_test/flutter_test.dart';

import 'package:lubao_core/lubao_core.dart';

void main() {
  test('I18nText resolves the right language', () {
    const text = I18nText(kk: 'Қазақша', ru: 'Русский', zh: '中文');
    expect(text.forLanguageCode('kk'), 'Қазақша');
    expect(text.forLanguageCode('zh'), '中文');
    expect(text.forLanguageCode('ru'), 'Русский');
    // Нет en в справочнике -> фолбэк на ru (задача 013).
    expect(text.forLanguageCode('en'), 'Русский');
  });

  test('I18nText.forLanguageCode("en") returns en when the dictionary has it', () {
    const text = I18nText(kk: 'Қазақстан', ru: 'Казахстан', zh: '哈萨克斯坦', en: 'Kazakhstan');
    expect(text.forLanguageCode('en'), 'Kazakhstan');
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

  test('ymd: календарная дата без времени и часового пояса (041, п.5)', () {
    expect(ymd(DateTime(2026, 10, 6, 23, 59)), '2026-10-06');
    expect(ymd(DateTime.utc(2026, 1, 5, 0, 0)), '2026-01-05');
  });
}
