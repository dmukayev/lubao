import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import 'cached_photo.dart';
import 'fullscreen_photos.dart';
import 'status_helpers.dart';

/// Общие блоки полной карточки груза — у водителя (`cargo_detail_screen`) и у
/// логиста на экране своего груза (071): маршрут с ценой, параметры, фото.

/// Маршрут, км, дата, цена (столбец 065: ≈ ₸, ₸/км), условия оплаты, аванс,
/// число машин; «Рынок за месяц» — только водителю.
class CargoMainCard extends StatelessWidget {
  const CargoMainCard({super.key, required this.cargo, required this.refData, this.showMarket = true});

  final Cargo cargo;
  final ReferenceData refData;
  final bool showMarket;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    // 058 п.3: флаги стран маршрута.
    final route = cargoRouteLabels(refData, pointId: cargo.pointId, destinationCountryId: cargo.destinationCountryId, destinationCityId: cargo.destinationCityId, languageCode: locale, withCountry: true);
    // 063: под ценой — когда и как платят всю сумму; аванс — отдельной плашкой.
    final terms = paymentWhenHowLine(t, paymentForm: cargo.paymentForm, paymentDelayDays: cargo.paymentDelayDays);
    final advance = advancePillText(t, advanceAmount: cargo.advanceAmount, currency: cargo.currency);
    final kzt = refData.convertToKzt(cargo.price, cargo.currency);
    final usd = refData.convertToUsd(cargo.price, cargo.currency);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 062: номер груза — назвать по телефону, нажатие копирует.
          if (cargo.number != null) ...[CargoNumberText(number: cargo.number!), const SizedBox(height: AppSpacing.xs)],
          CargoRoutePoint(
            color: AppColors.primary,
            title: route.origin ?? '',
            // 047: категория и км по дороге — как в строке ленты.
            subtitle: [
              if (refData.categoryById(cargo.categoryId) case final c?) c.name.forLanguageCode(locale),
              if (cargo.distanceKm != null && cargo.distanceKm! > 0) '${formatThousands(cargo.distanceKm!)} ${t.unitKm}',
              formatDate(cargo.readyDate),
            ].join(' · '),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(width: 2, height: 20, color: AppColors.divider),
          ),
          CargoRoutePoint(color: AppColors.accent, title: route.destination, subtitle: null),
          const Divider(height: AppSpacing.xl * 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.cargoDetailPriceLabel, style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text(formatMoney(cargo.price, cargo.currency), style: AppTextStyles.priceDetail),
                    if (terms.isNotEmpty) Text(terms, key: const Key('cargoDetailTerms'), style: AppTextStyles.body),
                    if (advance != null) ...[const SizedBox(height: AppSpacing.xs), AdvancePill(advance, key: const Key('cargoDetailAdvance'))],
                    if (cargoTrucksLabel(t, needed: cargo.trucksNeeded, taken: cargo.trucksTaken) case final trucks?)
                      Text(trucks, key: const Key('cargoDetailTrucks'), style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (formatKztConversion(kzt) != null) Text(formatKztConversion(kzt)!, style: AppTextStyles.caption),
                  if (usd != null) Text(formatMoney(usd, Currency.usd), style: AppTextStyles.caption),
                  if ((cargo.pricePerKm == null ? null : refData.convertToKzt(cargo.pricePerKm!, cargo.currency)) case final perKm?)
                    Text(
                      t.perKmKzt(formatThousands(perKm.round())),
                      key: const Key('cargoDetailPerKm'),
                      style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ],
          ),
          // 047 п.6: «Рынок за месяц: 650–720 ₸/км» — если есть статистика по маршруту.
          if (showMarket && cargo.market != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.cargoMarketMonth(formatThousands(cargo.market!.p25.round()), formatThousands(cargo.market!.p75.round())),
              key: const Key('cargoDetailMarket'),
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

/// Кузов (миниатюра), вес, объём; ниже — параметры по профилю кузова и
/// другие подходящие кузова.
class CargoParamsBlock extends StatelessWidget {
  const CargoParamsBlock({super.key, required this.cargo, required this.refData});

  final Cargo cargo;
  final ReferenceData refData;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final bodyType = refData.bodyTypeById(cargo.bodyTypeId);
    final specs = cargo.cargoSpecs == null || cargo.cargoSpecs!.isEmpty ? '' : specsSummary(t, locale, bodyType, cargo.cargoSpecs, cargo: true);
    final extra = [for (final id in cargo.extraBodyTypeIds) if (id != cargo.bodyTypeId) refData.bodyTypeById(id).name.forLanguageCode(locale)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CargoDetailChip(label: t.cargoBodyType, value: bodyType.name.forLanguageCode(locale), leading: BodyTypeIcon(bodyTypeCode: bodyType.code, width: 40)),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (cargo.weightKg != null)
                Expanded(
                  child: CargoDetailChip(label: t.cargoWeight, value: formatCargoWeight(cargo.weightKg!, tonUnit: t.unitTon, kgUnit: t.unitKg, languageCode: locale)),
                ),
              if (cargo.weightKg != null) const SizedBox(width: AppSpacing.sm),
              if (cargo.volumeM3 != null) Expanded(child: CargoDetailChip(label: t.cargoVolume, value: '${cargo.volumeM3} ${t.unitM3}')),
            ],
          ),
          if (specs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(specs, key: const Key('cargoDetailSpecs'), style: AppTextStyles.body),
          ],
          if (extra.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('${t.cargoExtraBodyTypes}: ${extra.join(', ')}', key: const Key('cargoDetailExtraBodies'), style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

/// Фото груза лентой миниатюр; нажатие — на весь экран с листанием (✕ или
/// свайп вниз). Фото нет — блока нет.
class CargoPhotosStrip extends StatelessWidget {
  const CargoPhotosStrip({super.key, required this.photoUrls});

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('cargoPhotos'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Text(context.l10n.cargoPhotos, style: AppTextStyles.title),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            itemCount: photoUrls.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.field),
              child: GestureDetector(
                key: Key('cargoPhoto-$index'),
                onTap: () => showFullScreenPhotos(
                  context,
                  initialIndex: index,
                  photos: [for (final url in photoUrls) CachedPhoto(url, fit: BoxFit.contain)],
                ),
                child: CachedPhoto(photoUrls[index], size: 96),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CargoRoutePoint extends StatelessWidget {
  const CargoRoutePoint({super.key, required this.color, required this.title, required this.subtitle});

  final Color color;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.route),
              if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: AppTextStyles.caption)],
            ],
          ),
        ),
      ],
    );
  }
}

class CargoDetailChip extends StatelessWidget {
  const CargoDetailChip({super.key, required this.label, required this.value, this.leading});

  final String label;
  final String value;

  /// Миниатюра кузова у «Тип кузова» (045 п.4).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.field)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          if (leading != null) ...[leading!, const SizedBox(height: AppSpacing.xs)],
          Text(value, style: AppTextStyles.bodyStrong),
        ],
      ),
    );
  }
}
