import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_app/features/shared/map_links.dart';

void main() {
  const lat = 44.21670, lng = 80.41670;

  test('Android — один системный выбор карт по geo:', () {
    final apps = mapAppsFor(lat, lng, 'Ерлан', ios: false, web: false);
    expect(apps.map((a) => a.id), ['system']);
    expect(apps.single.uri.toString(), startsWith('geo:44.2167,80.4167?q=44.2167,80.4167('));
  });

  test('iPhone — Apple Карты первыми, дальше карты по схемам (для КНР — 高德 и Baidu)', () {
    final apps = mapAppsFor(lat, lng, 'Ерлан', ios: true, web: false);
    expect(apps.first.id, 'apple');
    expect(apps.map((a) => a.id), containsAll(['google', 'yandex', '2gis', 'amap', 'baidu']));
    expect(apps.firstWhere((a) => a.id == 'yandex').uri.toString(), contains('pt=80.4167,44.2167'));
    expect(apps.firstWhere((a) => a.id == 'baidu').uri.toString(), contains('coord_type=wgs84'));
  });

  test('веб — OpenStreetMap, без Google', () {
    final apps = mapAppsFor(lat, lng, 'Ерлан', ios: false, web: true);
    expect(apps.single.uri.host, 'www.openstreetmap.org');
  });
}
