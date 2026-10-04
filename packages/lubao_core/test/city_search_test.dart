import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

City _city(String id, {required String kk, required String ru, String zh = '', String en = ''}) => City(
      id: id,
      countryId: 'kz',
      name: I18nText(kk: kk, ru: ru, zh: zh, en: en),
      isCapital: false,
    );

void main() {
  final countries = [const Country(id: 'kz', code: 'KZ', name: I18nText(kk: 'Қазақстан', ru: 'Казахстан', zh: '哈萨克斯坦'), isCisMember: true)];

  final cities = [
    _city('shymkent', kk: 'Шымкент', ru: 'Шымкент', zh: '奇姆肯特'),
    _city('almaty', kk: 'Алматы', ru: 'Алматы', zh: '阿拉木图'),
    _city('astana', kk: 'Астана', ru: 'Астана', zh: '阿斯塔纳'),
  ];

  group('searchCities', () {
    test('finds Shymkent by its Russian/Kazakh name typed in Cyrillic', () {
      final result = searchCities(cities, countries, 'шымкент');
      expect(result.map((c) => c.id), contains('shymkent'));
    });

    test('finds Shymkent when typed in Latin regardless of interface language', () {
      final result = searchCities(cities, countries, 'Shymkent');
      expect(result.map((c) => c.id), contains('shymkent'));
    });

    test('finds Shymkent by its Chinese name', () {
      final result = searchCities(cities, countries, '奇姆肯特');
      expect(result.map((c) => c.id), contains('shymkent'));
    });

    test('ranks a prefix match above a substring match', () {
      final fixture = [
        _city('prefix', kk: 'Алатау', ru: 'Алатау'), // starts with "ал"
        _city('substring', kk: 'Байкал', ru: 'Байкал'), // contains "ал", not a prefix
      ];
      final result = searchCities(fixture, countries, 'ал');
      expect(result.first.id, 'prefix');
      expect(result.map((c) => c.id), containsAll(['prefix', 'substring']));
    });

    test('caps results at the given limit', () {
      final many = List.generate(25, (i) => _city('c$i', kk: 'Тест$i', ru: 'Тест$i'));
      final result = searchCities(many, countries, 'тест', limit: 20);
      expect(result.length, 20);
    });

    test('returns empty for a blank query', () {
      expect(searchCities(cities, countries, '   '), isEmpty);
    });
  });
}
