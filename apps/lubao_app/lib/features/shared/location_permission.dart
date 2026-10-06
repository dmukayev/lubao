import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lubao_core/lubao_core.dart';

/// Текущая позиция по осознанному действию пользователя (041, п.8): сначала
/// объясняем, зачем нужна геопозиция, и только потом показываем системный
/// запрос. `null` — пользователь отказался в нашем диалоге; запрет в системе
/// или выключенная служба — исключение (вызывающий покажет понятный текст).
///
/// Это РАЗОВОЕ согласие («один раз, без слежки»); слежка на время рейса и
/// проверка отъезда с терминала — отдельные согласия (tracking_consent_sheet.dart).
/// [rationaleBody] — зачем именно сейчас (чат — «ссылка на карту», выбор города
/// — «ближайший город»); по умолчанию — текст для чата.
Future<Position?> currentPositionWithRationale(
  BuildContext context, {
  LocationAccuracy accuracy = LocationAccuracy.high,
  String? rationaleBody,
}) async {
  final t = context.l10n;
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.locationRationaleTitle),
        content: Text(rationaleBody ?? t.locationRationaleBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.locationRationaleContinue)),
        ],
      ),
    );
    if (agreed != true) return null;
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw Exception('location permission denied');
  }
  return Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: accuracy));
}
