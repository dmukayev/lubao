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

  test('Cargo.fromJson: поля ленты с сервера (040) и догруз', () {
    final cargo = Cargo.fromJson({
      'id': 'c1',
      'companyId': 'co',
      'companyName': 'Co',
      'pointId': 'p',
      'destinationCountryId': 'kz',
      'bodyTypeId': 'bt',
      'price': 100,
      'currency': 'USD',
      'readyDate': '2026-10-08',
      'status': 'PUBLISHED',
      'publishedAt': '2026-10-01T00:00:00.000Z',
      'expiresAt': '2026-10-10T00:00:00.000Z',
      'allowPartial': true,
      'pickupRank': 0,
      'feedSection': 'home',
    });
    expect(cargo.allowPartial, isTrue);
    expect(cargo.pickupRank, 0);
    expect(cargo.feedSection, CargoFeedSection.home);
  });

  test('Cargo.fromJson: без полей ленты — не догруз, без ранга', () {
    final cargo = Cargo.fromJson({
      'id': 'c1',
      'companyId': 'co',
      'pointId': 'p',
      'destinationCountryId': 'kz',
      'bodyTypeId': 'bt',
      'price': 100,
      'currency': 'USD',
      'readyDate': '2026-10-08',
      'status': 'PUBLISHED',
      'publishedAt': '2026-10-01T00:00:00.000Z',
      'expiresAt': '2026-10-10T00:00:00.000Z',
    });
    expect(cargo.allowPartial, isFalse);
    expect(cargo.pickupRank, isNull);
    expect(cargo.feedSection, isNull);
  });

  test('CargoFeedPage: hasMore считается по total', () {
    Map<String, dynamic> item(String id) => {
          'id': id,
          'companyId': 'co',
          'pointId': 'p',
          'destinationCountryId': 'kz',
          'bodyTypeId': 'bt',
          'price': 1,
          'currency': 'USD',
          'readyDate': '2026-10-08',
          'status': 'PUBLISHED',
          'publishedAt': '2026-10-01T00:00:00.000Z',
          'expiresAt': '2026-10-10T00:00:00.000Z',
        };
    final page = CargoFeedPage.fromJson({'items': [item('a'), item('b')], 'total': 5, 'offset': 0, 'originCityId': 'almaty'});
    expect(page.items.length, 2);
    expect(page.hasMore, isTrue);
    expect(page.originCityId, 'almaty');
    final last = CargoFeedPage.fromJson({'items': [item('c')], 'total': 3, 'offset': 2});
    expect(last.hasMore, isFalse);
  });

  test('CreateCargoInput: город погрузки и догруз уходят на сервер', () {
    final json = CreateCargoInput(
      pointId: 'almaty',
      allowPartial: true,
      destinationCountryId: 'uz',
      bodyTypeId: 'bt',
      price: 100,
      currency: Currency.usd,
      readyDate: DateTime(2026, 10, 8),
    ).toJson();
    expect(json['pointId'], 'almaty');
    expect(json['allowPartial'], true);
    expect(json['readyDate'], '2026-10-08');
  });

  test('ymd: календарная дата без времени и часового пояса (041, п.5)', () {
    expect(ymd(DateTime(2026, 10, 6, 23, 59)), '2026-10-06');
    expect(ymd(DateTime.utc(2026, 1, 5, 0, 0)), '2026-01-05');
  });

  test('City/LoadingPoint: координаты принимаются и числом, и строкой Decimal, и null (040)', () {
    final city = City.fromJson({
      'id': 'c',
      'countryId': 'kz',
      'name': {'ru': 'Алматы'},
      'lat': '43.238900',
      'lng': 43.5,
    });
    expect(city.lat, 43.2389);
    expect(city.lng, 43.5);
    final point = LoadingPoint.fromJson({
      'id': 'p',
      'cityId': 'c',
      'name': {'ru': 'Хоргос'},
      'isActive': true,
      'kind': 'TERMINAL',
      'radiusM': 3000,
      'lat': '44.2167',
      'lng': null,
    });
    expect(point.kind, PointKind.terminal);
    expect(point.radiusM, 3000);
    expect(point.lat, 44.2167);
    expect(point.lng, isNull);
  });
}
