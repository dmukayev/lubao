import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import 'status_helpers.dart';

/// 065 (эталон 35): правый столбец цены — одинаковый у логиста и в ленте
/// водителя, сверху вниз:
/// 1. цена в валюте груза — крупно;
/// 2. груз не в тенге — «≈ 45 393 000 ₸» серым;
/// 3. «27 135 ₸/км» синим (нет км — строки нет);
/// 4. «через 5 дн. · нал.» серым.
/// Строки 2–4 не переносятся и не обрезаются — не хватает места, шрифт
/// уменьшается. [inline] — узкий экран: тот же столбец блоком под описанием,
/// «≈ ₸ · ₸/км» одной строкой.
class CargoPriceColumn extends StatelessWidget {
  const CargoPriceColumn({super.key, required this.cargo, required this.refData, required this.keyPrefix, this.inline = false});

  final Cargo cargo;
  final ReferenceData? refData;

  /// «feedCargo» / «companyCargo» → ключи `feedCargoKzt-<id>`, `…PerKm-<id>`, `…Terms-<id>`.
  final String keyPrefix;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final rd = refData;
    final kzt = cargo.currency == Currency.kzt || rd == null ? null : formatKztConversion(rd.convertToKzt(cargo.price, cargo.currency));
    final perKmKzt = cargo.pricePerKm == null || rd == null ? null : rd.convertToKzt(cargo.pricePerKm!, cargo.currency);
    final perKm = perKmKzt == null ? null : t.perKmKzt(formatThousands(perKmKzt.round()));
    final terms = paymentWhenHowLine(t, paymentForm: cargo.paymentForm, paymentDelayDays: cargo.paymentDelayDays);
    final grey = AppTextStyles.small.copyWith(color: AppColors.textSecondary, fontSize: 12);
    final blue = AppTextStyles.small.copyWith(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700);
    final align = inline ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd;

    Widget line(Widget child) => FittedBox(fit: BoxFit.scaleDown, alignment: align, child: child);
    Text one(String text, TextStyle style, String name) => Text(text, key: Key('$keyPrefix$name-${cargo.id}'), style: style, maxLines: 1, softWrap: false);

    final price = Text(formatMoney(cargo.price, cargo.currency), key: Key('${keyPrefix}Price-${cargo.id}'), style: AppTextStyles.priceCard, maxLines: 1, softWrap: false);
    return Column(
      crossAxisAlignment: inline ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        line(price),
        if (inline) ...[
          if (kzt != null || perKm != null)
            line(Row(mainAxisSize: MainAxisSize.min, children: [
              if (kzt != null) one(kzt, grey, 'Kzt'),
              if (kzt != null && perKm != null) Text(' · ', style: grey),
              if (perKm != null) one(perKm, blue, 'PerKm'),
            ])),
        ] else ...[
          if (kzt != null) line(one(kzt, grey, 'Kzt')),
          if (perKm != null) line(one(perKm, blue, 'PerKm')),
        ],
        if (terms.isNotEmpty) line(one(terms, grey, 'Terms')),
      ],
    );
  }
}
