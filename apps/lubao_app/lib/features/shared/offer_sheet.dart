import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

/// 058 п.5: ввод цены — своя цена водителя (с комментарием) или встречная
/// логиста (без комментария, с подсказкой «один раз»). Сумма — в валюте груза.
Future<({double price, String? comment})?> showOfferSheet(
  BuildContext context, {
  required Currency currency,
  required String title,
  double? initialPrice,
  String? initialComment,
  bool withComment = true,
  String? hint,
}) {
  return showModalBottomSheet<({double price, String? comment})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _OfferSheet(currency: currency, title: title, initialPrice: initialPrice, initialComment: initialComment, withComment: withComment, hint: hint),
  );
}

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({required this.currency, required this.title, this.initialPrice, this.initialComment, required this.withComment, this.hint});

  final Currency currency;
  final String title;
  final double? initialPrice;
  final String? initialComment;
  final bool withComment;
  final String? hint;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  late final _price = TextEditingController(text: widget.initialPrice == null ? '' : formatLimit(widget.initialPrice!).replaceAll(' ', ''));
  late final _comment = TextEditingController(text: widget.initialComment ?? '');
  bool _tried = false;

  @override
  void dispose() {
    _price.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final error = numberFieldError(t, _price.text, required: _tried);
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: AppTextStyles.headline),
            if (widget.hint != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(widget.hint!, style: AppTextStyles.caption),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const Key('offerPrice'),
              label: t.offerPriceLabel(currencySymbol(widget.currency)),
              controller: _price,
              errorText: error,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            if (widget.withComment) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(key: const Key('offerComment'), label: t.offerCommentLabel, controller: _comment, maxLines: 2),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              key: const Key('offerSend'),
              label: t.offerSend,
              onPressed: () {
                final price = parseDecimal(_price.text);
                if (price == null || price <= 0) return setState(() => _tried = true);
                final comment = _comment.text.trim();
                Navigator.pop(context, (price: price, comment: comment.isEmpty ? null : comment));
              },
            ),
          ],
        ),
      ),
    );
  }
}
