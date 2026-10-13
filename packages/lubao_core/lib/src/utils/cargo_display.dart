import 'share_texts.dart';
import '../l10n/generated/lubao_localizations.dart';
import '../models/common.dart';
import '../models/reference_data.dart';
import 'cargo_weight.dart';

/// 058: как показывать груз одинаково в ленте, карточке, «Моих рейсах»,
/// сделке, у логиста и в «Поделиться».

/// 058 п.1 (уточнение 2026-10-10): аванс — при погрузке, отсрочка — остаток
/// после выгрузки. «аванс $5 300 при погрузке · остаток через 5 дн. · нал.»;
/// без аванса — «оплата через 5 дн. после выгрузки · на счёт»; «сразу» не пишем.
/// 063: под ценой — когда и как платят **всю** сумму: «через 5 дн. · нал.»,
/// «сразу · на карту». Ничего не указано — пусто. Аванс — отдельно
/// ([advancePillText]), не в этой строке.
String paymentWhenHowLine(LubaoLocalizations t, {PaymentForm? paymentForm, int? paymentDelayDays}) {
  final later = paymentDelayDays != null && paymentDelayDays > 0;
  if (!later && paymentForm == null) return '';
  return [
    later ? t.paymentWhenDays('$paymentDelayDays') : t.paymentWhenNow,
    if (paymentForm != null) paymentFormShort(t, paymentForm),
  ].join(' · ');
}

/// 063: «Аванс $5 300 при погрузке» — отдельной плашкой; нет аванса — null.
String? advancePillText(LubaoLocalizations t, {double? advanceAmount, required Currency currency}) =>
    advanceAmount != null && advanceAmount > 0 ? t.advancePill(formatCurrencyAmount(advanceAmount, currency)) : null;

/// 063 (эталон 35): машины у логиста — «1 машина», «нужно 5 машин», взяли часть — «нужно 2 · осталось 1».
String logistTrucksLabel(LubaoLocalizations t, {required int needed, required int taken}) {
  if (needed <= 1) return t.logistOneTruck;
  if (taken > 0) return cargoTrucksLabel(t, needed: needed, taken: taken) ?? t.logistTrucksNeeded(needed);
  return t.logistTrucksNeeded(needed);
}

/// 063 (эталон 35): когда опубликован — всегда с временем: «сегодня 14:20»,
/// «вчера 18:05», «9 окт 11:40».
String formatPublishedAt(LubaoLocalizations t, DateTime at, {required String languageCode, DateTime? now}) {
  final local = at.toLocal();
  final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  final today = now ?? DateTime.now();
  final days = DateTime(today.year, today.month, today.day).difference(DateTime(local.year, local.month, local.day)).inDays;
  if (days <= 0) return t.publishedToday(time);
  if (days == 1) return t.publishedYesterday(time);
  return '${shareDate(local, languageCode)} $time';
}

String paymentFormShort(LubaoLocalizations t, PaymentForm form) => switch (form) {
      PaymentForm.cash => t.paymentFormCashShort,
      PaymentForm.card => t.paymentFormCardShort,
      PaymentForm.cashless => t.paymentFormCashlessShort,
    };

String paymentFormLabel(LubaoLocalizations t, PaymentForm form) => switch (form) {
      PaymentForm.cash => t.paymentFormCash,
      PaymentForm.card => t.paymentFormCard,
      PaymentForm.cashless => t.paymentFormCashless,
    };

String companyKindLabel(LubaoLocalizations t, CompanyKind kind) => switch (kind) {
      CompanyKind.shipper => t.companyKindShipper,
      CompanyKind.forwarder => t.companyKindForwarder,
      CompanyKind.carrier => t.companyKindCarrier,
    };

/// «🇰🇿 Хоргос» / «🇬🇪 Тбилиси, Грузия» — флаг у каждого города маршрута
/// (decisions.md 2026-10-13, раньше — только при разных странах, 058 п.3).
/// Города нет в справочнике — `null` для отправления.
({String? origin, String destination}) cargoRouteLabels(
  ReferenceData refData, {
  String? pointId,
  required String destinationCountryId,
  String? destinationCityId,
  required String languageCode,
  bool withCountry = false,
}) {
  final point = pointId == null ? null : refData.pointOrNull(pointId);
  final originCountryId = point == null ? null : refData.cityById(point.cityId)?.countryId;
  final destCountry = refData.countryById(destinationCountryId);
  // decisions.md 2026-10-13: флаги всегда, и внутри одной страны.
  String flagged(String? code, String text) => flagEmoji(code).isNotEmpty ? '${flagEmoji(code)} $text' : text;

  final originName = point?.name.forLanguageCode(languageCode);
  final city = refData.cityById(destinationCityId)?.name.forLanguageCode(languageCode);
  final countryName = destCountry.name.forLanguageCode(languageCode);
  final destName = city == null ? countryName : (withCountry ? '$city, $countryName' : city);
  return (
    origin: originName == null ? null : flagged(originCountryId == null ? null : refData.countryById(originCountryId).code, originName),
    destination: flagged(destCountry.code, destName),
  );
}

/// «21 т · 35 м³» (058 п.3) — объём, только если указан.
String cargoSizeLabel(LubaoLocalizations t, {double? weightKg, double? volumeM3, required String languageCode}) {
  return [
    if (weightKg != null) formatCargoWeight(weightKg, tonUnit: t.unitTon, kgUnit: t.unitKg, languageCode: languageCode),
    if (volumeM3 != null && volumeM3 > 0) '${volumeM3 == volumeM3.roundToDouble() ? volumeM3.round() : volumeM3} ${t.unitM3}',
  ].join(' · ');
}

/// «нужно 3 · осталось 2» — только если машин больше одной (058 п.2).
String? cargoTrucksLabel(LubaoLocalizations t, {required int needed, required int taken}) =>
    needed > 1 ? t.cargoTrucksLeft('$needed', '${(needed - taken).clamp(0, needed)}') : null;

/// 058 п.7: «в сети» (≤ 5 мин), «был сегодня в 20:15», «был вчера», «был 08.10».
/// null — неизвестно (не показываем).
String? formatLastSeen(LubaoLocalizations t, DateTime? lastSeenAt, {DateTime? now}) {
  if (lastSeenAt == null) return null;
  final current = now ?? DateTime.now();
  final seen = lastSeenAt.toLocal();
  if (current.difference(seen).inMinutes <= 5) return t.lastSeenOnline;
  String two(int n) => n.toString().padLeft(2, '0');
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(seen.year, seen.month, seen.day);
  if (day == today) return t.lastSeenToday('${two(seen.hour)}:${two(seen.minute)}');
  if (day == today.subtract(const Duration(days: 1))) return t.lastSeenYesterday;
  return t.lastSeenDate('${two(seen.day)}.${two(seen.month)}${seen.year == current.year ? '' : '.${seen.year}'}');
}

/// Подпись шаблона размера кузова: «Стандарт\n≈ 90 м³», паллеты — только если
/// у кузова включено поле паллет (068): «≈ 90 м³ · 33 пал.».
String presetLabel(LubaoLocalizations t, String locale, BodySizePreset preset, {required bool showPallets}) {
  final name = preset.name.forLanguageCode(locale);
  if (preset.volumeM3 == null) return name;
  final size = [
    '≈ ${preset.volumeM3!.toStringAsFixed(0)} ${t.unitM3}',
    if (showPallets && preset.palletsEuro != null) '${preset.palletsEuro} ${t.unitPallets}',
  ].join(' · ');
  return '$name\n$size';
}
