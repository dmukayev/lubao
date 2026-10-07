import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Карта, в которой можно открыть точку. Без привязки к Google: у логистов
/// в Китае его нет — на iPhone показываем только установленные карты (+
/// Apple Карты всегда), на Android — системный выбор (geo:), в вебе — OSM.
class MapApp {
  const MapApp(this.id, this.uri);

  final String id;
  final Uri uri;
}

/// Ссылки на точку для разных карт (iOS: схемы перечислены в
/// LSApplicationQueriesSchemes Info.plist). Координаты — WGS-84 с телефона;
/// 高德 и Baidu сами пересчитывают их в свои системы (dev=1 / coord_type).
List<MapApp> mapAppsFor(double lat, double lng, String label, {required bool ios, required bool web}) {
  final q = Uri.encodeComponent(label);
  if (web) {
    return [MapApp('osm', Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=15/$lat/$lng'))];
  }
  if (!ios) {
    return [MapApp('system', Uri.parse('geo:$lat,$lng?q=$lat,$lng($q)'))];
  }
  return [
    MapApp('apple', Uri.parse('https://maps.apple.com/?ll=$lat,$lng&q=$q')),
    MapApp('google', Uri.parse('comgooglemaps://?q=$lat,$lng&center=$lat,$lng')),
    MapApp('yandex', Uri.parse('yandexmaps://maps.yandex.ru/?pt=$lng,$lat&z=14&l=map')),
    MapApp('2gis', Uri.parse('dgis://2gis.ru/geo/$lng,$lat')),
    MapApp('amap', Uri.parse('iosamap://viewMap?sourceApplication=lubao&poiname=$q&lat=$lat&lon=$lng&dev=1')),
    MapApp('baidu', Uri.parse('baidumap://map/marker?location=$lat,$lng&title=$q&coord_type=wgs84&src=lubao')),
  ];
}

String _mapLabel(LubaoLocalizations t, String id) => switch (id) {
      'apple' => t.mapsApple,
      'google' => t.mapsGoogle,
      'yandex' => t.mapsYandex,
      '2gis' => t.maps2gis,
      'amap' => t.mapsAmap,
      'baidu' => t.mapsBaidu,
      _ => t.mapsOpen,
    };

/// Шторка «Открыть в картах»: установленные карты + «Скопировать координаты».
Future<void> showOpenInMaps(BuildContext context, {required double lat, required double lng, required String label}) async {
  final t = context.l10n;
  final ios = !kIsWeb && Platform.isIOS;
  final candidates = mapAppsFor(lat, lng, label, ios: ios, web: kIsWeb);
  final available = <MapApp>[];
  for (final app in candidates) {
    // Apple Карты / geo: / OSM открываются всегда; остальные — если стоят.
    if (app.id == 'apple' || app.id == 'system' || app.id == 'osm' || await canLaunchUrl(app.uri)) {
      available.add(app);
    }
  }
  if (!context.mounted) return;
  final coords = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final app in available)
              ListTile(
                key: Key('openInMaps-${app.id}'),
                leading: const Icon(LucideIcons.map),
                title: Text(_mapLabel(t, app.id)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await launchUrl(app.uri, mode: LaunchMode.externalApplication);
                },
              ),
            ListTile(
              key: const Key('openInMaps-copy'),
              leading: const Icon(LucideIcons.copy),
              title: Text(t.mapsCopyCoordinates),
              subtitle: Text(coords),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Clipboard.setData(ClipboardData(text: coords));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.mapsCoordinatesCopied)));
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
