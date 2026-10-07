import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';

(String, Color) cargoStatusPresentation(LubaoLocalizations t, CargoStatus status) {
  switch (status) {
    case CargoStatus.published:
      return (t.cargoStatusPublished, StatusBadge.success);
    case CargoStatus.inDeal:
      return (t.cargoStatusInDeal, StatusBadge.info);
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
    case ResponseStatus.invited:
      return (t.responseStatusInvited, StatusBadge.info);
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

/// true, если подтверждение упёрлось в НЕпроверенную/отсутствующую машину
/// связки (VEHICLE_NOT_VERIFIED / VEHICLE_REQUIRED, deals.service.ts) —
/// вместо «Ошибка» показываем «Машина ещё на проверке — откройте гараж»
/// (задача 032, п.12 / 038).
bool isVehicleNotVerifiedError(Object error) {
  if (error is! DioException) return false;
  final data = error.response?.data;
  return data is Map && (data['message'] == 'VEHICLE_NOT_VERIFIED' || data['message'] == 'VEHICLE_REQUIRED');
}

/// Машина уже занята активными сделками (задача 037) — догруз не помещается
/// или это вообще следующий рейс. `null`, если ошибка другая.
VehicleFullError? asVehicleFullError(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map || data['code'] != 'VEHICLE_FULL') return null;
  return VehicleFullError(
    isNextTrip: data['reason'] == 'NEXT_TRIP',
    usedWeightKg: (data['usedWeightKg'] as num?)?.toDouble(),
    capacityKg: (data['capacityKg'] as num?)?.toDouble(),
    dealIds: ((data['deals'] as List<dynamic>?) ?? []).map((d) => (d as Map)['dealId'] as String).toList(),
  );
}

class VehicleFullError {
  const VehicleFullError({required this.isNextTrip, this.usedWeightKg, this.capacityKg, this.dealIds = const []});

  /// true — грузы с разными датами погрузки: это не догруз, а следующий
  /// рейс, подтверждать после доставки текущего.
  final bool isNextTrip;
  final double? usedWeightKg;
  final double? capacityKg;
  final List<String> dealIds;
}

/// Шторка «Машина заполнена» (задача 037, п.4 / 038, п.10) — общая для
/// карточки сделки и чата: объяснение вместо «Ошибка» + переход к сделке,
/// которая занимает машину.
Future<void> showVehicleFullSheet(BuildContext context, VehicleFullError full) async {
  final t = context.l10n;
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.dealVehicleFullTitle, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              full.isNextTrip
                  ? t.dealVehicleFullNextTrip
                  : t.dealVehicleFullBody(
                      ((full.usedWeightKg ?? 0) / 1000).toStringAsFixed(0),
                      ((full.capacityKg ?? 0) / 1000).toStringAsFixed(0),
                      t.unitTon,
                    ),
              style: AppTextStyles.body,
            ),
            if (full.dealIds.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push('/deals/${full.dealIds.first}');
                },
                child: Text(t.dealVehicleFullOpenCurrent),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Понятный текст для 409-ошибок действий с откликом/выбором водителя
/// (задача 038, п.1–2) — `null`, если ошибка не из этого семейства
/// (вызывающий показывает `commonError`).
String? responseConflictText(LubaoLocalizations t, Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map) return null;
  switch (data['code']) {
    case 'CARGO_ALREADY_HAS_DEAL':
      return t.chatCargoAlreadyHasDeal;
    case 'RESPONSE_NOT_PENDING':
      return t.chatResponseClosed;
    case 'RESPONSE_ALREADY_EXISTS':
      return t.cargoAlreadyResponded;
    case 'CARGO_NOT_AVAILABLE':
      return t.cargoNotAvailable;
    default:
      return null;
  }
}

/// true, если SMS-код сгорел после 6-й неверной попытки (см. sms.service.ts) —
/// в отличие от просто неверного кода, повторный ввод того же кода никогда
/// не пройдёт, нужен новый код через «Отправить код ещё раз».
bool isTooManyAttemptsError(Object error) {
  if (error is! DioException) return false;
  final data = error.response?.data;
  return data is Map && data['message'] == 'Слишком много попыток, запросите новый код';
}

/// true, если вход заблокирован на 15 минут после 5 неверных паролей
/// (задача 025, та же защита, что у админа — см. auth.service.ts).
bool isLockedOutError(Object error) {
  if (error is! DioException) return false;
  final data = error.response?.data;
  return data is Map && data['message'] == 'Слишком много неверных попыток, попробуйте через 15 минут';
}

/// true, если аккаунт заблокирован админом (задача 026, п.5) — сервер
/// отвечает 403 с кодом ACCOUNT_BLOCKED на входе (SMS-код, email+пароль) и
/// на /auth/refresh, а не выдаёт токены с последующим молчаливым 401 на
/// первом же запросе.
bool isAccountBlockedError(Object error) {
  if (error is! DioException) return false;
  final data = error.response?.data;
  return data is Map && data['code'] == 'ACCOUNT_BLOCKED';
}

/// true, если email при регистрации компании уже занят (см.
/// AuthService.registerCompany, ConflictException) — предлагаем войти.
bool isEmailTakenError(Object error) {
  if (error is! DioException) return false;
  final data = error.response?.data;
  return data is Map && data['message'] == 'Email already registered';
}

/// Шторка контактов поддержки — запасной путь, если письмо с кодом
/// (регистрация/сброс пароля) не дошло (задача 025, п. 9 — qq.com/163.com
/// ненадёжны). Показывает только то, что админ заполнил в `app_settings`
/// (см. ReferenceData.supportWhatsapp/supportWechat/supportEmail).
Future<void> showSupportContactSheet(BuildContext context, WidgetRef ref) {
  final t = context.l10n;
  final refData = ref.read(referenceDataProvider).valueOrNull;
  final rows = <Widget>[
    if (refData?.supportWhatsapp != null)
      ListTile(
        leading: const Icon(LucideIcons.messageCircle),
        title: Text(t.supportContactWhatsapp),
        subtitle: Text(refData!.supportWhatsapp!),
      ),
    if (refData?.supportWechat != null)
      ListTile(
        leading: const Icon(LucideIcons.messageCircle),
        title: Text(t.supportContactWechat),
        subtitle: Text(refData!.supportWechat!),
      ),
    if (refData?.supportEmail != null)
      ListTile(leading: const Icon(LucideIcons.mail), title: Text(t.supportContactEmail), subtitle: Text(refData!.supportEmail!)),
  ];

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
            Text(t.supportContactTitle, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(t.supportContactBody, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            if (rows.isEmpty) Text(t.supportContactNone) else ...rows,
          ],
        ),
      ),
    ),
  );
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
            // Задача 032, п.13 (038) — личность: селфи и права; техпаспорта
            // живут у машин в гараже и загружаются при добавлении машины.
            _VerificationBullet(index: 1, label: t.driverVerificationSelfie),
            const SizedBox(height: AppSpacing.sm),
            _VerificationBullet(index: 2, label: t.driverVerificationLicense),
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

/// Текст системной строки чата на языке читателя (задача 038, п.11/25) —
/// общий для плашки в переписке и превью в списке чатов. Неизвестный код
/// (новый сервер + старый клиент) — русский фолбэк.
String systemMessageText(LubaoLocalizations t, String? code, Map<String, String> params, String fallback) {
  final name = params['driverName'] ?? '';
  // Старые строки без имени (до 038): без имени «Водитель  выбран» — схлопываем двойной пробел.
  String tidy(String v) => v.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  return switch (code) {
    'DRIVER_READY' => tidy(t.chatSystemDriverReady(name)),
    'DRIVER_SELECTED' => tidy(t.chatSystemDriverSelected(name)),
    'DEAL_CONFIRMED' => t.chatSystemDealConfirmed,
    'RESPONSE_WITHDRAWN' => tidy(t.chatSystemResponseWithdrawn(name)),
    'RESPONSE_REJECTED' => t.chatSystemResponseRejected,
    'CARGO_OFFERED' => t.chatSystemCargoOffered,
    'DRIVER_INVITED' => t.chatSystemDriverInvited,
    'INVITATION_DECLINED' => tidy(t.chatSystemInvitationDeclined(name)),
    'CARGO_TAKEN' => t.chatSystemCargoTaken,
    'DRIVER_SAYS_AGREED' => tidy(t.chatSystemDriverSaysAgreed(name)),
    _ => fallback,
  };
}
