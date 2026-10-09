import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

/// 052 п.6: тексты «Поделиться» — 4 языка, формат как в группах, без телефона.
const _almaty = LoadingPoint(id: 'p-almaty', cityId: 'c-almaty', name: I18nText(kk: 'Алматы', ru: 'Алматы', zh: '阿拉木图', en: 'Almaty'), isActive: true);
final _ref = ReferenceData(
  countries: const [Country(id: 'kz', code: 'KZ', name: I18nText(kk: 'Қазақстан', ru: 'Казахстан', zh: '哈萨克斯坦', en: 'Kazakhstan'), isCisMember: true)],
  cities: const [City(id: 'c-astana', countryId: 'kz', name: I18nText(kk: 'Астана', ru: 'Астана', zh: '阿斯塔纳', en: 'Astana'), isCapital: true)],
  bodyTypes: const [BodyType(id: 'bt1', code: 'TENT', name: I18nText(kk: 'Тент', ru: 'Тент', zh: '篷布', en: 'Tent'))],
  cargoCategories: const [CargoCategory(id: 'cat1', code: 'CONSTRUCTION', name: I18nText(kk: 'Құрылыс материалдары', ru: 'Стройматериалы', zh: '建材', en: 'Building materials'))],
  permits: const [],
  points: const [_almaty],
);

final _cargo = Cargo(
  id: 'c1',
  companyId: 'co',
  companyName: 'ТОО «Транс-Азия»',
  pointId: 'p-almaty',
  destinationCountryId: 'kz',
  destinationCityId: 'c-astana',
  bodyTypeId: 'bt1',
  categoryId: 'cat1',
  weightKg: 20000,
  distanceKm: 1230,
  price: 850000,
  pricePerKm: 691,
  currency: Currency.kzt,
  readyDate: DateTime(2026, 10, 9),
  status: CargoStatus.published,
  publishedAt: DateTime(2026, 10, 8),
  expiresAt: DateTime(2026, 10, 12),
);

Future<LubaoLocalizations> _t(String lang) => LubaoLocalizations.delegate.load(Locale(lang));

void main() {
  test('груз по-русски — как на эталоне 30', () async {
    final text = cargoShareText(await _t('ru'), _ref, _cargo, 'https://lubao.kz/c/7Kx2abc', 'ru');
    expect(text, '🚛 Алматы → Астана · 1 230 км\nСтройматериалы · 20 т · тент\n💰 ₸850 000 (₸691/км)\n📅 погрузка 9 окт\nОткликнуться: https://lubao.kz/c/7Kx2abc');
  });

  test('4 языка: города и кузов из справочника, ссылка на месте, телефона нет', () async {
    for (final lang in ['ru', 'kk', 'zh', 'en']) {
      final t = await _t(lang);
      final text = cargoShareText(t, _ref, _cargo, 'https://lubao.kz/c/7Kx2abc', lang);
      expect(text, contains(_almaty.name.forLanguageCode(lang)));
      expect(text, contains('https://lubao.kz/c/7Kx2abc'));
      expect(text, isNot(matches(RegExp(r'\+7\d|\d{3}[ -]?\d{3}[ -]?\d{2}[ -]?\d{2}'))));
    }
    expect(cargoShareText(await _t('zh'), _ref, _cargo, 'u', 'zh'), contains('装货 10月9日'));
    expect(cargoShareText(await _t('en'), _ref, _cargo, 'u', 'en'), contains('loading Oct 9'));
  });

  test('все грузы — до 10 строк и ссылка /co', () async {
    final t = await _t('ru');
    final text = companyShareText(t, _ref, 'ТОО «Транс-Азия»', List.filled(12, _cargo), 'https://lubao.kz/co/abcdefg', 'ru');
    expect(text.split('\n').first, '📦 ТОО «Транс-Азия» — грузы на сегодня');
    expect(text, contains('1. Алматы → Астана · 20 т тент · ₸850 000'));
    expect(text, contains('10. '));
    expect(text, isNot(contains('11. ')));
    expect(text.split('\n').last, 'Все грузы и отклик: https://lubao.kz/co/abcdefg');
  });

  test('свой анонс водителя', () async {
    final t = await _t('ru');
    final text = driverShareText(t,
        lang: 'ru', url: 'https://lubao.kz/d/Q9m4abc', bodyTypeName: 'Тент', capacityTons: 20, volumeM3: 86,
        cityName: 'Алматы', fromDate: DateTime(2026, 10, 9), countries: ['Россия'], ratingAvg: 4.8, ratingCount: 3, verified: true);
    expect(text, '🚚 Свободна фура · тент 20 т, 86 м³\n📍 Алматы, с 9 окт → направление: Россия\n★ 4,8 · Проверен\nПредложить груз: https://lubao.kz/d/Q9m4abc');
  });
}
