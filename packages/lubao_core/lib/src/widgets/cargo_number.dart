import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/context_extension.dart';
import '../theme/app_theme.dart';

/// 062: «482 915» — 6 цифр группами по 3 (так легче диктовать).
String formatCargoNumber(int number) {
  final digits = number.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Номер сделки: номер груза + машина — «482 915-1».
String formatDealNumber(int cargoNumber, int seq) => '${formatCargoNumber(cargoNumber)}-$seq';

/// «№ 482 915» (или «№ 482 915-1» для сделки) мелким текстом; нажатие —
/// копирует номер без пробелов, чтобы вставить в мессенджер или поиск.
class CargoNumberText extends StatelessWidget {
  const CargoNumberText({super.key, required this.number, this.seq, this.style});

  final int number;
  final int? seq;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final shown = seq == null ? formatCargoNumber(number) : formatDealNumber(number, seq!);
    final plain = seq == null ? '$number' : '$number-$seq';
    return InkWell(
      key: key == null ? Key('cargoNumber-$plain') : null,
      borderRadius: BorderRadius.circular(6),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: plain));
        if (!context.mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.cargoNumberCopied(plain))));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(t.cargoNumberLabel(shown), style: style ?? AppTextStyles.caption),
      ),
    );
  }
}
