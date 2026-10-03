import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

(String, Color) cargoStatusPresentation(LubaoLocalizations t, CargoStatus status) {
  switch (status) {
    case CargoStatus.published:
      return (t.cargoStatusPublished, StatusBadge.success);
    case CargoStatus.archived:
      return (t.cargoStatusArchived, StatusBadge.neutral);
    case CargoStatus.expired:
      return (t.cargoStatusExpired, StatusBadge.warning);
    case CargoStatus.cancelled:
      return (t.cargoStatusCancelled, StatusBadge.danger);
  }
}

(String, Color) responseStatusPresentation(LubaoLocalizations t, ResponseStatus status) {
  switch (status) {
    case ResponseStatus.pending:
      return (t.responseStatusPending, StatusBadge.warning);
    case ResponseStatus.selected:
      return (t.responseStatusSelected, StatusBadge.success);
    case ResponseStatus.rejected:
      return (t.responseStatusRejected, StatusBadge.danger);
    case ResponseStatus.cancelled:
      return (t.responseStatusCancelled, StatusBadge.neutral);
  }
}

(String, Color) dealStatusPresentation(LubaoLocalizations t, DealStatus status) {
  switch (status) {
    case DealStatus.selected:
      return (t.dealStatusSelected, StatusBadge.info);
    case DealStatus.confirmedByDriver:
      return (t.dealStatusConfirmed, StatusBadge.info);
    case DealStatus.loaded:
      return (t.dealStatusLoaded, StatusBadge.warning);
    case DealStatus.inTransit:
      return (t.dealStatusInTransit, StatusBadge.warning);
    case DealStatus.delivered:
      return (t.dealStatusDelivered, StatusBadge.success);
    case DealStatus.cancelled:
      return (t.dealStatusCancelled, StatusBadge.danger);
  }
}

String _groupThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-${buffer.toString()}' : buffer.toString();
}

String formatMoney(double price, Currency currency) {
  return '${currencySymbol(currency)}${_groupThousands(price.round())}';
}

/// Пересчёт в тенге мелким шрифтом под ценой груза. `null`, если курса нет.
String? formatKztConversion(double? amountInKzt) {
  if (amountInKzt == null) return null;
  return '≈ ${_groupThousands(amountInKzt.round())} ₸';
}

String formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}';
}

String formatDateTime(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${formatDate(local)} ${two(local.hour)}:${two(local.minute)}';
}

/// true, если бэкенд отклонил действие с ForbiddenException('DRIVER_NOT_VERIFIED')
/// (см. cargos.controller.ts/deals.controller.ts) — водителю нужно сначала
/// пройти верификацию документов.
bool isDriverNotVerifiedError(Object error) {
  if (error is! DioException) return false;
  final data = error.response?.data;
  return data is Map && data['message'] == 'DRIVER_NOT_VERIFIED';
}

/// Шторка «Чтобы откликнуться/подтвердить, подтвердите личность — 2 минуты»
/// с переходом на экран верификации.
Future<void> showVerificationRequiredSheet(BuildContext context) {
  final t = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge))),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.driverVerificationRequiredPrompt, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.lg),
            _VerificationBullet(index: 1, label: t.driverVerificationSelfie),
            const SizedBox(height: AppSpacing.sm),
            _VerificationBullet(
              index: 2,
              label: '${t.driverVerificationVehiclePassport} · ${t.driverVerificationTrailerPassport}',
            ),
            const SizedBox(height: AppSpacing.sm),
            _VerificationBullet(index: 3, label: t.driverVerificationLicense),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: t.driverVerificationRequiredAction,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                sheetContext.push('/driver/verification');
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _VerificationBullet extends StatelessWidget {
  const _VerificationBullet({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: Text('$index', style: AppTextStyles.small.copyWith(color: AppColors.primary)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTextStyles.body)),
      ],
    );
  }
}
