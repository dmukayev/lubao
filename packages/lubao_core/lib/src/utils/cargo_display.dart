import '../l10n/generated/lubao_localizations.dart';
import '../models/common.dart';
import '../models/reference_data.dart';
import 'cargo_weight.dart';

/// 058: как показывать груз одинаково в ленте, карточке, «Моих рейсах»,
/// сделке, у логиста и в «Поделиться».

/// «аванс $5 300 · нал. · отсрочка 10 дн.» — пусто, если условий нет (058 п.1).
String paymentTermsLine(LubaoLocalizations t, {double? advanceAmount, PaymentForm? paymentForm, int? paymentDelayDays, required Currency currency}) {
  return [
    if (advanceAmount != null && advanceAmount > 0) t.cargoAdvance(formatCurrencyAmount(advanceAmount, currency)),
    if (paymentForm != null) paymentFormShort(t, paymentForm),
    if (paymentDelayDays != null && paymentDelayDays > 0) t.paymentDelayShort('$paymentDelayDays'),
  ].join(' · ');
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

/// «🇰🇿 Хоргос» / «🇬🇪 Тбилиси, Грузия» — флаги только если страны маршрута
/// разные (058 п.3). Города нет в справочнике — `null` для отправления.
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
  final flags = originCountryId != null && originCountryId != destinationCountryId;
  String flagged(String? code, String text) => flags && flagEmoji(code).isNotEmpty ? '${flagEmoji(code)} $text' : text;

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
