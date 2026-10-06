import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

City _city(String id, {required String kk, required String ru, String zh = '', String en = ''}) => City(
      id: id,
      countryId: 'kz',
      name: I18nText(kk: kk, ru: ru, zh: zh, en: en),
      isCapital: false,
    );

void main() {
  pointSearchTests();
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

// Задача 040: выбор города погрузки и «рядом со мной».
LoadingPoint _point(String id, String ru, {String kk = '', String zh = '', String en = '', double? lat, double? lng, bool active = true}) =>
    LoadingPoint(id: id, cityId: 'c-$id', name: I18nText(kk: kk, ru: ru, zh: zh, en: en), isActive: active, lat: lat, lng: lng);

void pointSearchTests() {
  group('searchPoints — поиск по четырём языкам (040)', () {
    final points = [
      _point('almaty', 'Алматы', kk: 'Алматы', zh: '阿拉木图', en: 'Almaty', lat: 43.2389, lng: 76.8897),
      _point('astana', 'Астана', kk: 'Астана', zh: '阿斯塔纳', en: 'Astana', lat: 51.1694, lng: 71.4491),
      _point('shymkent', 'Шымкент', kk: 'Шымкент', zh: '奇姆肯特', en: 'Shymkent', lat: 42.3417, lng: 69.5901),
      _point('khorgos', 'Хоргос', kk: 'Қорғас', zh: '霍尔果斯', en: 'Khorgos'),
    ];

    test('по-русски, по-казахски (қ→к), по-китайски и латиницей находят один и тот же город', () {
      expect(searchPoints(points, 'алм').map((p) => p.id), ['almaty']);
      expect(searchPoints(points, 'корг').map((p) => p.id), ['khorgos']);
      expect(searchPoints(points, 'Қорғас').map((p) => p.id), ['khorgos']);
      expect(searchPoints(points, '阿斯').map((p) => p.id), ['astana']);
      expect(searchPoints(points, 'Shymkent').map((p) => p.id), ['shymkent']);
    });

    test('латиница транслитерируется: «shym» → Шымкент, «almat» → Алматы', () {
      expect(searchPoints(points, 'shym').map((p) => p.id), ['shymkent']);
      expect(searchPoints(points, 'almat').map((p) => p.id), ['almaty']);
    });

    test('префикс выше вхождения; пустой запрос и «ничего» → пусто', () {
      expect(searchPoints(points, 'ста').map((p) => p.id), ['astana']);
      expect(searchPoints(points, ''), isEmpty);
      expect(searchPoints(points, 'зззз'), isEmpty);
    });
  });

  group('nearestPoint — «рядом со мной» (040)', () {
    final points = [
      _point('almaty', 'Алматы', lat: 43.2389, lng: 76.8897),
      _point('konaev', 'Конаев', lat: 43.8667, lng: 77.0667),
      _point('astana', 'Астана', lat: 51.1694, lng: 71.4491),
      _point('off', 'Выключен', lat: 43.24, lng: 76.9, active: false),
      _point('nocoords', 'Без координат'),
    ];

    test('человек в Алматы → Алматы (выключенные и без координат пропускаются)', () {
      expect(nearestPoint(points, 43.25, 76.95)?.id, 'almaty');
    });

    test('в 70 км от Алматы, но рядом с Конаевым → Конаев', () {
      expect(nearestPoint(points, 43.85, 77.05)?.id, 'konaev');
    });

    test('в степи дальше 100 км от любого города → null', () {
      expect(nearestPoint(points, 47.0, 60.0), isNull);
    });

    test('haversineKm: Алматы — Астана ≈ 970 км', () {
      expect(haversineKm(43.2389, 76.8897, 51.1694, 71.4491), closeTo(970, 30));
    });
  });
}
