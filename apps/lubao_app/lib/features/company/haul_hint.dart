import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import '../shared/status_helpers.dart';

/// «Уже везёт: 8 т из 20 т · Алматы · погрузка 07.10» (задача 038, п.8) —
/// одна строка для «Кто будет на точке», списка откликов и диалога выбора.
/// `null` — активных сделок нет, ничего не показываем.
String? haulHintText(
  LubaoLocalizations t,
  ReferenceData refData,
  String locale, {
  required int activeDealsCount,
  required double committedWeightKg,
  required bool hasUnknownWeight,
  double? capacityTons,
  String? destinationCountryId,
  String? destinationCityId,
  DateTime? readyDate,
}) {
  if (activeDealsCount == 0) return null;

  final parts = <String>[];
  if (hasUnknownWeight) {
    parts.add(t.driverHaulingBusyNoWeight);
  } else if (capacityTons != null) {
    parts.add(t.driverAlreadyHaulingOf(
      (committedWeightKg / 1000).toStringAsFixed(0),
      capacityTons.toStringAsFixed(0),
      t.unitTon,
    ));
  } else {
    parts.add(t.driverAlreadyHauling((committedWeightKg / 1000).toStringAsFixed(0), t.unitTon));
  }

  final city = refData.cityById(destinationCityId);
  final destination = city?.name.forLanguageCode(locale) ??
      (destinationCountryId != null ? refData.countryById(destinationCountryId).name.forLanguageCode(locale) : null);
  if (destination != null && destination.isNotEmpty) parts.add(destination);
  if (readyDate != null) parts.add(t.driverHaulingLoading(formatDate(readyDate)));
  return parts.join(' · ');
}

/// true — по данным «Уже везёт…» новый груз, похоже, не поместится, и
/// водитель не сможет подтвердить (та же логика, что жёсткая проверка на
/// сервере, но мягко): груз/вместимость без цифр считаются «занято».
bool haulLooksFull({
  required int activeDealsCount,
  required double committedWeightKg,
  required bool hasUnknownWeight,
  double? capacityTons,
  double? newCargoWeightKg,
}) {
  if (activeDealsCount == 0) return false;
  if (hasUnknownWeight) return true;
  if (capacityTons == null) return true;
  if (newCargoWeightKg == null) return true;
  return committedWeightKg + newCargoWeightKg > capacityTons * 1000;
}

/// Мягкое предупреждение логисту при выборе занятого водителя (задача 038,
/// п.9 / 037, п.3): true — «Выбрать всё равно», false/null — отмена.
Future<bool> confirmSelectBusyDriver(BuildContext context, String haulHint) async {
  final t = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.selectDriverVehicleFullTitle),
      content: Text(t.selectDriverVehicleFullBody(haulHint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.selectDriverAnywayButton)),
      ],
    ),
  );
  return result ?? false;
}
