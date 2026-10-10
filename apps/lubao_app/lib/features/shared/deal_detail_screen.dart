import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import 'status_helpers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'error_feedback.dart';
import 'tracking_consent_sheet.dart';
import 'map_links.dart';
import '../driver/feed/driver_status.dart';
import 'driver_documents_block.dart';
import '../driver/profile/vehicle_photos.dart';
import 'driver_avatar.dart';

class DealDetailScreen extends ConsumerStatefulWidget {
  const DealDetailScreen({super.key, required this.dealId});

  final String dealId;

  @override
  ConsumerState<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends ConsumerState<DealDetailScreen> {
  bool _busy = false;
  bool _openingChat = false;

  /// Чат теперь по `chatId`, не по `dealId` (задача 017, п.1) — находим
  /// существующий чат пары водитель+компания по грузу этой сделки (он уже
  /// привязан к сделке на бэкенде) и переходим в него.
  Future<void> _openChat(Deal deal) async {
    setState(() => _openingChat = true);
    try {
      final session = ref.read(sessionProvider);
      final thread = await ref.read(chatRepositoryProvider).findOrCreate(
            driverId: session?.driver != null ? null : deal.driverId,
            cargoId: deal.cargoId,
          );
      if (mounted) context.push('/chat/${thread.id}');
    } catch (e) {
      debugPrint('DealDetailScreen: failed to open chat: $e');
      if (mounted) {
        final t = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.chatOpenFailed),
          action: SnackBarAction(label: t.commonRetry, onPressed: () => _openChat(deal)),
        ));
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  Future<void> _advance(DealStatus next) async {
    // «Загружен» — начало рейса: отдельное согласие на передачу местоположения
    // (041, п.11). Закрыли шторку — сделка всё равно двигается, координаты не уйдут.
    if (next == DealStatus.loaded) await ensureTripTrackingConsent(context, ref);
    if (!mounted) return;
    // Город назначения — до перезагрузки сделки (для «Ищете груз отсюда?»).
    final dealBefore = ref.read(dealByIdProvider(widget.dealId)).valueOrNull;
    setState(() => _busy = true);
    try {
      await ref.read(dealRepositoryProvider).advanceStatus(widget.dealId, next);
      ref.invalidate(dealByIdProvider(widget.dealId));
      ref.invalidate(dealsMineProvider);
      // Подтверждение сделки гасит анонс водителя на сервере (040, п.4).
      ref.invalidate(myArrivalsProvider);
      ref.invalidate(cargoFeedProvider);
      // 045 п.11: после «Доставлено» — «Вы в <город>. Ищете груз отсюда?».
      if (next == DealStatus.delivered && mounted) {
        final refData = ref.read(referenceDataProvider).valueOrNull;
        if (refData != null) {
          await askLookingFromDestination(context, ref, refData: refData, destinationCityId: dealBefore?.cargo?.destinationCityId);
        }
      }
    } on DioException catch (e) {
      final full = asVehicleFullError(e);
      if (isDriverNotVerifiedError(e)) {
        if (mounted) await showVerificationRequiredSheet(context);
      } else if (full != null) {
        // Задача 037, п.4 — не «Ошибка», а понятное объяснение с переходом
        // к сделке, которая занимает машину.
        if (mounted) await _showVehicleFullSheet(full);
      } else if (isVehicleNotVerifiedError(e)) {
        // Задача 032, п.12 (038) — понятный текст и переход в гараж.
        if (mounted) {
          final t = context.l10n;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            // Нет прицепа/тягача — так и говорим; «на проверке» — только когда машина не проверена.
            content: Text(isVehicleRequiredError(e) ? t.dealVehicleRequired : t.dealVehicleNotVerified),
            action: SnackBarAction(label: t.garageGoToGarage, onPressed: () => context.push('/driver/garage')),
          ));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commonError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Шторка «Машина заполнена» общая с чатом (задача 038, п.10) —
  // см. showVehicleFullSheet в status_helpers.dart.
  Future<void> _showVehicleFullSheet(VehicleFullError full) => showVehicleFullSheet(context, full);

  /// Отмена (046 п.1, 5–6): причина — чипом из списка, текст только для
  /// «Другое». После «В пути» — это запрос второй стороне. Отменили после
  /// загрузки — сразу предлагаем «Пожаловаться».
  Future<void> _cancel(Deal deal, {required bool isDriver}) async {
    final t = context.l10n;
    final controller = TextEditingController();
    final codes = cancelReasonCodes.where((c) => isDriver || c != 'TOOK_OTHER_CARGO').toList();
    String? code;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final canSubmit = code != null && (code != 'OTHER' || controller.text.trim().isNotEmpty);
          return AlertDialog(
            title: Text(t.dealCancel),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (deal.cancelNeedsConsent) ...[
                    Text(t.dealCancelRequestNotice, key: const Key('dealCancelRequestNotice'), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Text(t.dealCancelReasonPick, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final c in codes)
                        ChoiceChip(
                          key: Key('cancelReason_$c'),
                          label: Text(cancelReasonLabel(t, c)),
                          selected: code == c,
                          onSelected: (_) => setDialogState(() => code = c),
                        ),
                    ],
                  ),
                  if (code == 'OTHER') ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      key: const Key('cancelOtherText'),
                      label: t.dealCancelOtherHint,
                      controller: controller,
                      maxLines: 3,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.commonCancel)),
              FilledButton(
                key: const Key('cancelSubmit'),
                onPressed: canSubmit ? () => Navigator.pop(dialogContext, true) : null,
                child: Text(deal.cancelNeedsConsent ? t.dealCancelRequestSend : t.dealCancel),
              ),
            ],
          );
        },
      ),
    );
    if (submitted != true || code == null) return;

    setState(() => _busy = true);
    Deal? result;
    try {
      result = await ref.read(dealRepositoryProvider).cancel(widget.dealId, reasonCode: code!, reason: code == 'OTHER' ? controller.text : null);
      ref.invalidate(dealByIdProvider(widget.dealId));
      ref.invalidate(dealsMineProvider);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (result != null && result.status == DealStatus.cancelled && result.cancelledAfterLoad && mounted) {
      await _offerComplaint();
    }
  }

  /// Ответ на запрос отмены: подтвердить или оспорить (046 п.5).
  Future<void> _answerCancelRequest({required bool confirm}) async {
    final t = context.l10n;
    String? reason;
    if (!confirm) {
      final controller = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.dealCancelDispute),
          content: AppTextField(key: const Key('disputeReasonField'), label: t.dealDisputeReasonLabel, controller: controller, maxLines: 3),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
            FilledButton(key: const Key('disputeSubmit'), onPressed: () => Navigator.pop(dialogContext, controller.text), child: Text(t.dealCancelDispute)),
          ],
        ),
      );
      if (reason == null || reason.trim().isEmpty) return;
    }
    setState(() => _busy = true);
    Deal? result;
    try {
      final repo = ref.read(dealRepositoryProvider);
      result = confirm ? await repo.confirmCancel(widget.dealId) : await repo.disputeCancel(widget.dealId, reason: reason!.trim());
      ref.invalidate(dealByIdProvider(widget.dealId));
      ref.invalidate(dealsMineProvider);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (result != null && result.status == DealStatus.cancelled && mounted) await _offerComplaint();
  }

  /// «Пожаловаться» с предзаполненной сделкой (046 п.6) — в очередь жалоб админки.
  Future<void> _offerComplaint() async {
    final t = context.l10n;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('complaintOffer'),
        title: Text(t.complaintOfferTitle),
        // Узкий экран + крупный шрифт + клавиатура (iPhone SE): прокрутка, а не переполнение.
        content: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.complaintOfferBody, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(key: const Key('complaintText'), label: t.complaintReasonLabel, controller: controller, maxLines: 3),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
          FilledButton(key: const Key('complaintSubmit'), onPressed: () => Navigator.pop(dialogContext, controller.text), child: Text(t.complaintSend)),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    try {
      await ref.read(dealRepositoryProvider).complain(widget.dealId, reason: text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.complaintSent)));
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _leaveReview() async {
    final t = context.l10n;
    int rating = 5;
    final commentController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.reviewTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  return IconButton(
                    icon: Icon(starIndex <= rating ? Icons.star : Icons.star_border, color: Colors.amber),
                    onPressed: () => setDialogState(() => rating = starIndex),
                  );
                }),
              ),
              AppTextField(label: t.reviewCommentLabel, controller: commentController, maxLines: 3),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.reviewSubmit)),
          ],
        ),
      ),
    );

    if (submitted != true) return;
    try {
      await ref.read(reviewRepositoryProvider).submit(widget.dealId, rating: rating, comment: commentController.text);
      ref.invalidate(reviewsForDealProvider(widget.dealId));
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final dealAsync = ref.watch(dealByIdProvider(widget.dealId));
    final session = ref.watch(sessionProvider);
    final isDriver = session?.user.role == UserRole.driver;

    final deal = dealAsync.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.dealDetailTitle),
        actions: [
          if (deal != null)
            IconButton(
              icon: _openingChat
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.messageCircle),
              onPressed: _openingChat ? null : () => _openChat(deal),
            ),
        ],
      ),
      body: dealAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('DealDetailScreen: $e');
          return ErrorView(message: t.commonError);
        },
        data: (deal) {
          final (statusLabel, statusColor) = dealStatusPresentation(t, deal.status);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isDriver) ...[
                      DriverAvatar(driverId: deal.driverId, name: deal.driverName, version: deal.driverAvatarVersion, radius: 22),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(child: Text(isDriver ? deal.companyName : deal.driverName, style: Theme.of(context).textTheme.titleLarge)),
                    StatusBadge(label: statusLabel, color: statusColor),
                  ],
                ),
                // 046 п.3: отмены второй стороны — «отменил 1 из 15 · после загрузки 1».
                if (cancelStatsText(t, isDriver ? deal.companyCancelStats : deal.driverCancelStats) case final stats?) ...[
                  const SizedBox(height: 4),
                  Text(stats, key: const Key('dealCancelStats'), style: AppTextStyles.caption.copyWith(color: StatusBadge.warning)),
                ],
                if (deal.cancelRequest != null && (deal.status == DealStatus.cancelRequested || deal.status == DealStatus.disputed)) ...[
                  const SizedBox(height: 12),
                  _cancelRequestBanner(context, deal, isDriver: isDriver),
                ],
                if (deal.cargo != null) ...[
                  const SizedBox(height: 8),
                  Text(formatMoney(deal.cargo!.price, deal.cargo!.currency), style: Theme.of(context).textTheme.headlineSmall),
                ],
                const Divider(height: 32),
                Text(t.dealTimelineTitle, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _timeline(context, deal),
                if (deal.status == DealStatus.cancelled && (deal.cancelReason != null || deal.cancelReasonCode != null)) ...[
                  const SizedBox(height: 16),
                  Text(
                    [
                      '${t.dealCancelReasonLabel}: ${cancelReasonLabel(t, deal.cancelReasonCode, text: deal.cancelReason)}',
                      if (cancelStageLabel(t, deal.cancelStage) case final stage?) stage,
                    ].join(' · '),
                    key: const Key('dealCancelReason'),
                  ),
                  if (deal.cancelledAfterLoad) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('dealComplain'),
                      onPressed: _offerComplaint,
                      icon: const Icon(LucideIcons.flag, size: 18),
                      label: Text(t.complaintSend),
                    ),
                  ],
                ],
                // 044 п.5: машина рейса ещё на проверке — видно обоим.
                if (!deal.vehiclesVerified && deal.status != DealStatus.cancelled) ...[
                  const SizedBox(height: 12),
                  StatusBadge(key: const Key('dealVehiclePending'), label: t.driverDocsVehiclePending, color: StatusBadge.warning),
                ],
                if (!isDriver && deal.status != DealStatus.cancelled) ...[
                  const Divider(height: 32),
                  DriverDocumentsBlock(deal: deal),
                ],
                if (isDriver) DriverDocsOpenedRow(deal: deal),
                // 053 п.4: машина рейса у водителя — фото спереди вместо иконки.
                if (isDriver) _TripVehicles(deal: deal),
                if (!isDriver) ...[
                  const Divider(height: 32),
                  Text(t.dealDriverLocationTitle, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (deal.driverLocation != null)
                    // Нажатие — открыть точку в установленной карте или
                    // скопировать координаты (живая проверка 2026-10-07).
                    InkWell(
                      key: const Key('dealDriverLocation'),
                      onTap: () => showOpenInMaps(
                        context,
                        lat: deal.driverLocation!.lat,
                        lng: deal.driverLocation!.lng,
                        label: deal.driverName,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${deal.driverLocation!.lat.toStringAsFixed(5)}, ${deal.driverLocation!.lng.toStringAsFixed(5)}\n'
                                '${t.dealLocationUpdatedAt}: ${formatDateTime(deal.driverLocation!.updatedAt)}',
                              ),
                            ),
                            Text(t.mapsOpen, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(t.dealLocationNoData, style: TextStyle(color: Theme.of(context).disabledColor)),
                ],
                const SizedBox(height: 24),
                if (isDriver && (deal.status == DealStatus.loaded || deal.status == DealStatus.inTransit)) ...[
                  const TripTrackingSwitch(),
                  const SizedBox(height: 8),
                ],
                // 044 п.4: что и кому открывается при подтверждении.
                if (isDriver && deal.nextStatus == DealStatus.confirmedByDriver) ...[
                  Text(t.dealConfirmDocsNotice(deal.companyName), key: const Key('dealConfirmDocsNotice'), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                ],
                if (isDriver && deal.nextStatus != null) ...[
                  PrimaryButton(
                    key: const Key('dealNextStatusButton'),
                    label: switch (deal.nextStatus!) {
                      DealStatus.confirmedByDriver => t.dealConfirm,
                      DealStatus.loaded => t.dealMarkLoaded,
                      DealStatus.inTransit => t.dealMarkInTransit,
                      DealStatus.delivered => t.dealMarkDelivered,
                      _ => t.commonNext,
                    },
                    loading: _busy,
                    onPressed: () => _advance(deal.nextStatus!),
                  ),
                  const SizedBox(height: 8),
                ],
                if (deal.isCancellable)
                  OutlinedButton(
                    key: const Key('dealCancelButton'),
                    onPressed: _busy ? null : () => _cancel(deal, isDriver: isDriver),
                    child: Text(t.dealCancel),
                  ),
                if (deal.status == DealStatus.delivered) ...[
                  const SizedBox(height: 24),
                  Text(t.reviewsReceivedTitle, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _ReviewsSection(dealId: widget.dealId, onAddReview: _leaveReview),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Запрос отмены после «В пути»: инициатор ждёт, вторая сторона отвечает; спор — у админа.
  Widget _cancelRequestBanner(BuildContext context, Deal deal, {required bool isDriver}) {
    final t = context.l10n;
    final req = deal.cancelRequest!;
    final mine = req.byRole == (isDriver ? UserRole.driver : UserRole.company);
    final until = req.expiresAt == null ? '' : formatDateTime(req.expiresAt!);
    final reason = cancelReasonLabel(t, req.reasonCode, text: req.reason);
    return AppCard(
      key: const Key('dealCancelRequestBanner'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (deal.status == DealStatus.disputed)
            Text(t.dealDisputedNotice, style: AppTextStyles.bodyStrong)
          else if (mine)
            Text(t.dealCancelRequestedByMe(until), style: AppTextStyles.body)
          else ...[
            Text(t.dealCancelRequestedByOther(isDriver ? deal.companyName : deal.driverName, reason, until), style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              key: const Key('dealCancelConfirm'),
              label: t.dealCancelConfirm,
              loading: _busy,
              onPressed: () => _answerCancelRequest(confirm: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              key: const Key('dealCancelDispute'),
              onPressed: _busy ? null : () => _answerCancelRequest(confirm: false),
              child: Text(t.dealCancelDispute),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeline(BuildContext context, Deal deal) {
    final t = context.l10n;
    final steps = <(String, DateTime?)>[
      (t.dealStatusSelected, deal.createdAt),
      (t.dealStatusConfirmed, deal.confirmedAt),
      (t.dealStatusLoaded, deal.loadedAt),
      (t.dealStatusInTransit, deal.inTransitAt),
      (t.dealStatusDelivered, deal.deliveredAt),
    ];
    return Column(
      children: steps.map((step) {
        final (label, at) = step;
        final done = at != null;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(done ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  size: 18, color: done ? StatusBadge.success : Theme.of(context).disabledColor),
              const SizedBox(width: 8),
              Expanded(child: Text(label)),
              if (at != null) Text(formatDate(at), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.dealId, required this.onAddReview});

  final String dealId;
  final VoidCallback onAddReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final session = ref.watch(sessionProvider);
    final reviewsAsync = ref.watch(reviewsForDealProvider(dealId));

    return reviewsAsync.when(
      loading: () => const LoadingView(),
      error: (e, st) {
        debugPrint('DealDetailScreen (reviews): $e');
        return Text(t.commonError);
      },
      data: (reviews) {
        final myRole = session?.user.role == UserRole.driver ? UserRole.driver : UserRole.company;
        final alreadyReviewed = reviews.any((r) => r.authorRole == myRole);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final review in reviews)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, size: 16, color: Colors.amber),
                    ),
                    const SizedBox(width: 8),
                    if (review.comment != null) Expanded(child: Text(review.comment!)),
                  ],
                ),
              ),
            if (!alreadyReviewed) ...[
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onAddReview, child: Text(t.reviewTitle)),
            ],
          ],
        );
      },
    );
  }
}


/// Машины рейса у водителя (053 п.4): фото спереди (или иконка кузова) и номер.
class _TripVehicles extends ConsumerWidget {
  const _TripVehicles({required this.deal});
  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = [deal.tractorId, deal.trailerId].whereType<String>().toSet();
    if (ids.isEmpty) return const SizedBox.shrink();
    final vehicles = (ref.watch(garageVehiclesProvider).valueOrNull ?? const <GarageVehicle>[]).where((v) => ids.contains(v.id)).toList();
    if (vehicles.isEmpty) return const SizedBox.shrink();
    final refData = ref.watch(referenceDataProvider).valueOrNull;
    return Padding(
      key: const Key('dealTripVehicles'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          for (final v in vehicles)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VehicleFrontThumb(
                  vehicle: v,
                  bodyTypeCode: v.bodyTypeId == null ? null : refData?.bodyTypes.where((b) => b.id == v.bodyTypeId).firstOrNull?.code,
                  width: 56,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(v.plateNumber ?? context.l10n.garageNoPlate, style: AppTextStyles.bodyStrong),
              ],
            ),
        ],
      ),
    );
  }
}
