import 'dart:math' as math;

import '../models/reference_data.dart';

/// Расстояние по большому кругу, км.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final h = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadiusKm * math.asin(math.sqrt(h));
}

/// Ближайший активный город погрузки с координатами в пределах [maxKm]
/// («рядом со мной» в выборе города, 040 п.2); `null` — рядом ничего нет.
LoadingPoint? nearestPoint(List<LoadingPoint> points, double lat, double lng, {double maxKm = 100}) {
  LoadingPoint? best;
  var bestKm = double.infinity;
  for (final p in points) {
    if (!p.isActive || p.lat == null || p.lng == null) continue;
    final km = haversineKm(lat, lng, p.lat!, p.lng!);
    if (km < bestKm) {
      bestKm = km;
      best = p;
    }
  }
  return bestKm <= maxKm ? best : null;
}
