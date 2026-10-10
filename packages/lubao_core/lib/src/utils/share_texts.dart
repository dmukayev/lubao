import '../l10n/generated/lubao_localizations.dart';
import '../models/cargo.dart';
import '../models/common.dart';
import '../models/reference_data.dart';
import 'cargo_display.dart';
import 'cargo_weight.dart';

/// 052 п.6: тексты «Поделиться» — на языке интерфейса того, кто делится,
/// формат как в группах (эмодзи, без телефона). Числа и валюта — как в ленте.

String _group(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

/// «₸850 000», «1 250 000 ₽» — как в ленте.
String shareMoney(double amount, Currency currency) => formatCurrencyAmount(amount, currency);

const _monthsRu = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
const _monthsKk = ['қаң', 'ақп', 'нау', 'сәу', 'мам', 'мау', 'шіл', 'там', 'қыр', 'қаз', 'қар', 'жел'];
const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// «9 окт» / «10月9日» / «Oct 9».
String shareDate(DateTime d, String languageCode) => switch (languageCode) {
      'zh' => '${d.month}月${d.day}日',
      'en' => '${_monthsEn[d.month - 1]} ${d.day}',
      'kk' => '${d.day} ${_monthsKk[d.month - 1]}',
      _ => '${d.day} ${_monthsRu[d.month - 1]}',
    };

/// Маршрут с флагами стран (058 п.3) — как в ленте.
String _route(ReferenceData refData, Cargo c, String lang) {
  final r = cargoRouteLabels(refData, pointId: c.pointId, destinationCountryId: c.destinationCountryId, destinationCityId: c.destinationCityId, languageCode: lang);
  return r.origin == null ? r.destination : '${r.origin} → ${r.destination}';
}

String _weightBody(LubaoLocalizations t, ReferenceData refData, Cargo c, String lang) => [
      if (c.weightKg != null) formatCargoWeight(c.weightKg!, tonUnit: t.unitTon, kgUnit: t.unitKg, languageCode: lang),
      refData.bodyTypeById(c.bodyTypeId).name.forLanguageCode(lang).toLowerCase(),
    ].join(' ');

/// Один груз:
/// 🚛 Алматы → Астана · 1 230 км
/// Стройматериалы · 20 т · тент
/// 💰 ₸850 000 (₸690/км)
/// 📅 погрузка 9 окт
/// Откликнуться: lubao.kz/c/7Kx2
String cargoShareText(LubaoLocalizations t, ReferenceData refData, Cargo c, String url, String lang) {
  final km = c.distanceKm == null ? '' : ' · ${_group(c.distanceKm!.round())} ${t.unitKm}';
  final category = refData.categoryById(c.categoryId)?.name.forLanguageCode(lang);
  final size = cargoSizeLabel(t, weightKg: c.weightKg, volumeM3: c.volumeM3, languageCode: lang);
  final facts = [
    if (category != null) category,
    if (size.isNotEmpty) size,
    refData.bodyTypeById(c.bodyTypeId).name.forLanguageCode(lang).toLowerCase(),
  ].join(' · ');
  final perKm = c.pricePerKm == null ? '' : ' (${shareMoney(c.pricePerKm!, c.currency)}/${t.unitKm})';
  final terms = paymentTermsLine(t, advanceAmount: c.advanceAmount, paymentForm: c.paymentForm, paymentDelayDays: c.paymentDelayDays, currency: c.currency);
  return [
    '🚛 ${_route(refData, c, lang)}$km',
    facts,
    '💰 ${shareMoney(c.price, c.currency)}$perKm',
    // 058 п.1: «аванс $5 300 · нал.»
    if (terms.isNotEmpty) terms,
    '📅 ${t.shareCargoLoading(shareDate(c.readyDate, lang))}',
    t.shareCargoRespond(url),
  ].join('\n');
}

/// Все активные грузы компании (до 10):
/// 📦 ТОО «Транс-Азия» — грузы на сегодня
/// 1. Алматы → Астана · 20 т тент · ₸850 000
/// Все грузы и отклик: lubao.kz/co/…
String companyShareText(LubaoLocalizations t, ReferenceData refData, String companyName, List<Cargo> cargos, String url, String lang) {
  final lines = <String>['📦 ${t.shareAllTitle(companyName)}'];
  var n = 0;
  for (final c in cargos.take(10)) {
    n++;
    lines.add('$n. ${_route(refData, c, lang)} · ${_weightBody(t, refData, c, lang)} · ${shareMoney(c.price, c.currency)}');
  }
  lines.add(t.shareAllFooter(url));
  return lines.join('\n');
}

/// Свой анонс водителя:
/// 🚚 Свободна фура · тент 20 т, 86 м³
/// 📍 Алматы, с 9 окт → в сторону России
/// ★ 4,8 · Проверен
/// Предложить груз: lubao.kz/d/…
String driverShareText(
  LubaoLocalizations t, {
  required String lang,
  required String url,
  String? bodyTypeName,
  double? capacityTons,
  double? volumeM3,
  String? cityName,
  DateTime? fromDate,
  List<String> countries = const [],
  bool anyCountry = false,
  double ratingAvg = 0,
  int ratingCount = 0,
  bool verified = false,
}) {
  final vehicle = [
    if (bodyTypeName != null) bodyTypeName.toLowerCase(),
    if (capacityTons != null) '${_trim(capacityTons, lang)} ${t.unitTon}',
  ].join(' ');
  final vehicleLine = [vehicle, if (volumeM3 != null) '${_trim(volumeM3, lang)} ${t.unitM3}'].where((s) => s.isNotEmpty).join(', ');
  final direction = anyCountry || countries.isEmpty ? t.shareDriverAnyDirection : t.shareDriverDirection(countries.join(', '));
  final place = cityName == null ? null : (fromDate == null ? cityName : t.shareDriverFrom(cityName, shareDate(fromDate, lang)));
  final trust = [if (ratingCount > 0) '★ ${_trim(ratingAvg, lang)}', if (verified) t.shareVerified];
  return [
    '🚚 ${t.shareDriverTitle}${vehicleLine.isEmpty ? '' : ' · $vehicleLine'}',
    if (place != null) '📍 $place → $direction',
    if (trust.isNotEmpty) trust.join(' · '),
    t.shareDriverOffer(url),
  ].join('\n');
}

String _trim(double v, String lang) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return lang == 'ru' || lang == 'kk' ? s.replaceAll('.', ',') : s;
}
