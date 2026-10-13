import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/error_feedback.dart';
import '../../shared/offer_sheet.dart';
import '../../shared/status_helpers.dart';
import '../haul_hint.dart';
import 'cargo_close_dialog.dart';
import '../../shared/driver_avatar.dart';
import '../drivers/driver_card_screen.dart' show showDriverInfoSheet;
import '../../shared/share_action.dart';
import '../../shared/cargo_info.dart';
import '../../../providers/auth_provider.dart';
import '../../shared/chat_opener.dart';

class CargoResponsesScreen extends ConsumerWidget {
  const CargoResponsesScreen({super.key, required this.cargoId});

  final String cargoId;

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String responseId, String status, {double? expectedPrice}) async {
    try {
      await ref.read(cargoRepositoryProvider).updateResponseStatus(responseId, status, expectedPrice: expectedPrice);
    } catch (e) {
      if (context.mounted) {
        final t = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseConflictText(t, e) ?? errorMessage(t, e))));
      }
    }
    ref.invalidate(cargoResponsesProvider(cargoId));
  }

  Future<void> _edit(BuildContext context, Cargo cargo) async {
    await context.push('/company/cargos/new', extra: cargo);
  }

  /// Груз нельзя закрыть без выбора исхода (задача 017, п.6) — заменяет
  /// старое «удалить» без причины.
  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final result = await showCargoCloseDialog(context, ref, cargoId);
    if (result == null) return;

    await ref.read(cargoRepositoryProvider).close(cargoId, outcome: result.outcome, driverId: result.driverId);
    ref.invalidate(myCargosProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cargoClosed)));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final responses = ref.watch(cargoResponsesProvider(cargoId));
    final cargoAsync = ref.watch(cargoByIdProvider(cargoId));
    final referenceData = ref.watch(referenceDataProvider);
    final cargo = cargoAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        // 071: на экране — груз целиком и отклики.
        title: Text(t.cargoDetailTitle),
        actions: cargo == null
            ? null
            : [
                // 052 п.4: поделиться своим грузом — со своего экрана груза.
                IconButton(
                  key: const Key('cargoShareDetail'),
                  tooltip: t.shareButton,
                  icon: const Icon(LucideIcons.share),
                  onPressed: () {
                    final rd = referenceData.valueOrNull;
                    if (rd == null) return;
                    shareContent(context, ref,
                        kind: ShareKind.cargo,
                        targetId: cargo.id,
                        dialogTitle: t.shareDialogCargo,
                        buildText: (url) => cargoShareText(t, rd, cargo, url, Localizations.localeOf(context).languageCode));
                  },
                ),
              ],
      ),
      body: responses.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('CargoResponsesScreen: $e');
          return ErrorView(message: errorMessage(t, e), onRetry: () => ref.invalidate(cargoResponsesProvider(cargoId)));
        },
        data: (list) {
          // 071 п.4: приглашения — своим блоком: ждём ответа, отказался, истекло.
          bool inviteClosed(CargoResponse r) =>
              r.status == ResponseStatus.cancelled && (r.closeReason == ResponseCloseReason.inviteDeclined || r.closeReason == ResponseCloseReason.inviteExpired);
          final invited = [...list.where((r) => r.status == ResponseStatus.invited), ...list.where(inviteClosed)];
          final active = list.where((r) => r.status == ResponseStatus.selected || r.status == ResponseStatus.pending).toList();
          final inactive = list.where((r) => (r.status == ResponseStatus.rejected || r.status == ResponseStatus.cancelled) && !inviteClosed(r)).toList();
          final newCount = active.where((r) => r.isNew).length;
          Widget card(CargoResponse response) => _ResponseCard(
                response: response,
                cargoWeightKg: cargo?.weightKg,
                cargo: cargo,
                refData: referenceData.valueOrNull,
                onUpdateStatus: (status, {expectedPrice}) => _updateStatus(context, ref, response.id, status, expectedPrice: expectedPrice),
              );
          final refData = referenceData.valueOrNull;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(cargoResponsesProvider(cargoId));
              ref.invalidate(cargoByIdProvider(cargoId));
            },
            child: ListView(
              key: const Key('companyCargoDetail'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.screen),
              children: [
                // 071 п.1: груз целиком — те же блоки, что у водителя.
                if (cargo != null && refData != null) ...[
                  if (cargo.photoUrls.isNotEmpty) ...[CargoPhotosStrip(photoUrls: cargo.photoUrls), const SizedBox(height: AppSpacing.md)],
                  CargoMainCard(cargo: cargo, refData: refData, showMarket: false),
                  const SizedBox(height: AppSpacing.sm),
                  _CargoMeta(cargo: cargo),
                  const SizedBox(height: AppSpacing.md),
                  CargoParamsBlock(cargo: cargo, refData: refData),
                  if (cargo.allowPartial)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
                      child: Text(t.feedBadgePartial, style: AppTextStyles.body.copyWith(color: AppColors.primary)),
                    ),
                  if (cargo.description != null && cargo.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.cargoDescriptionTitle, style: AppTextStyles.caption),
                          const SizedBox(height: AppSpacing.xs),
                          Text(cargo.description!, key: const Key('companyCargoDescription'), style: AppTextStyles.body),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _CargoActions(
                    cargo: cargo,
                    onEdit: () => _edit(context, cargo),
                    onRepeat: () => context.push('/company/cargos/repeat', extra: cargo),
                    onUnpublish: () => _close(context, ref),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // 076: «Приглашены» — над «Откликами» (071 п.4).
                if (invited.isNotEmpty) ...[
                  _InvitedBlock(responses: invited, cargoId: cargoId),
                  const SizedBox(height: AppSpacing.md),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: Text(
                    [
                      active.isEmpty ? t.cargoNoResponses : t.cargoResponsesCount(active.length),
                      if (newCount > 0) t.cargoResponsesNew(newCount),
                    ].join(' · '),
                    key: const Key('companyCargoResponsesTitle'),
                    style: AppTextStyles.title,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (active.isEmpty && invited.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: EmptyState(message: t.responsesEmpty),
                  ),
                // 056 п.5: сверху — ждут решения (порядок задаёт сервер), неактивные свёрнуты.
                for (final response in active) ...[
                  card(response),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (inactive.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    child: ExpansionTile(
                      key: const Key('responsesInactive'),
                      tilePadding: EdgeInsets.zero,
                      title: Text(t.responsesInactive(inactive.length), style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textSecondary)),
                      children: [
                        for (final response in inactive) ...[
                          card(response),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 071 п.1: номер — в карточке выше; здесь когда опубликован, статус и кто
/// опубликовал (если не я).
class _CargoMeta extends ConsumerWidget {
  const _CargoMeta({required this.cargo});

  final Cargo cargo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final (statusLabel, statusColor) = cargoStatusPresentation(t, cargo.status);
    final me = ref.watch(sessionProvider)?.user.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // «Опубликован» и так в дате — плашка только у других статусов.
          if (cargo.status != CargoStatus.published) StatusBadge(label: statusLabel, color: statusColor),
          Text(t.cargoPublishedAtFull(formatDateTime(cargo.publishedAt)), key: const Key('companyCargoPublishedAt'), style: AppTextStyles.caption),
          if (cargo.contactUserId != null && cargo.contactUserId != me && (cargo.contactName ?? '').isNotEmpty)
            Text(t.cargoPublishedBy(cargo.contactName!), key: const Key('companyCargoPublishedBy'), style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// 071 п.2: действия маленькими серыми кнопками; в архиве — только «Повторить».
class _CargoActions extends StatelessWidget {
  const _CargoActions({required this.cargo, required this.onEdit, required this.onRepeat, required this.onUnpublish});

  final Cargo cargo;
  final VoidCallback onEdit;
  final VoidCallback onRepeat;
  final VoidCallback onUnpublish;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final archived = cargo.status == CargoStatus.archived || cargo.status == CargoStatus.expired || cargo.status == CargoStatus.cancelled;
    final style = TextButton.styleFrom(foregroundColor: AppColors.textSecondary, visualDensity: VisualDensity.compact, textStyle: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Wrap(
        children: [
          if (!archived) TextButton.icon(key: const Key('companyCargoEdit'), style: style, onPressed: onEdit, icon: const Icon(LucideIcons.pencil, size: 16), label: Text(t.cargoEdit)),
          TextButton.icon(key: const Key('companyCargoRepeat'), style: style, onPressed: onRepeat, icon: const Icon(LucideIcons.copy, size: 16), label: Text(t.cargoRepeat)),
          if (cargo.status == CargoStatus.published)
            TextButton.icon(key: const Key('companyCargoUnpublish'), style: style, onPressed: onUnpublish, icon: const Icon(LucideIcons.xCircle, size: 16), label: Text(t.cargoUnpublish)),
        ],
      ),
    );
  }
}

/// 071 п.4: «Приглашены (N)» — над откликами: ждём ответа · осталось 18 ч /
/// отказался / истекло. Принял — уходит в отклики. Нажатие — карточка водителя.
class _InvitedBlock extends StatelessWidget {
  const _InvitedBlock({required this.responses, required this.cargoId});

  final List<CargoResponse> responses;
  final String cargoId;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    String statusOf(CargoResponse r) {
      if (r.status == ResponseStatus.invited) {
        final left = r.inviteExpiresAt?.difference(DateTime.now()).inHours;
        return left == null ? t.responsesWaitingDriver : t.cargoInviteWaitingLeft(left < 1 ? 1 : left);
      }
      return r.closeReason == ResponseCloseReason.inviteDeclined ? t.cargoInviteDeclined : t.cargoInviteExpired;
    }

    return AppCard(
      key: const Key('companyCargoInvited'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.cargoInvitedBlockTitle(responses.length), style: AppTextStyles.bodyStrong),
          for (final r in responses)
            InkWell(
              key: Key('companyCargoInvited-${r.driverId}'),
              onTap: () => showDriverInfoSheet(context, driverId: r.driverId, cargoId: cargoId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    // 076: аватар 40 px, как в откликах; статус — второй строкой.
                    DriverAvatar(driverId: r.driverId, name: r.driverName, version: r.avatarVersion, radius: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.driverName, style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            statusOf(r),
                            style: AppTextStyles.caption.copyWith(color: r.status == ResponseStatus.invited ? AppColors.accentText : AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResponseCard extends ConsumerStatefulWidget {
  const _ResponseCard({
    required this.response,
    required this.cargoWeightKg,
    required this.refData,
    required this.onUpdateStatus,
    this.cargo,
  });

  final CargoResponse response;

  /// 058 п.5: цена груза — «вы просили $10 300», валюта встречной цены.
  final Cargo? cargo;

  final double? cargoWeightKg;
  final ReferenceData? refData;
  final void Function(String status, {double? expectedPrice}) onUpdateStatus;

  @override
  ConsumerState<_ResponseCard> createState() => _ResponseCardState();
}

class _ResponseCardState extends ConsumerState<_ResponseCard> {

  /// Задача 038, п.9 — мягкое предупреждение перед «Выбрать», если по
  /// сводке «Уже везёт…» груз не помещается (водитель не сможет
  /// подтвердить, пока не освободит машину).
  Future<void> _select(String? haulHint) async {
    final response = widget.response;
    if (haulHint != null &&
        haulLooksFull(
          activeDealsCount: response.activeDealsCount,
          committedWeightKg: response.committedWeightKg,
          hasUnknownWeight: response.committedHasUnknownWeight,
          capacityTons: response.capacityTons,
          newCargoWeightKg: widget.cargoWeightKg,
        )) {
      final proceed = await confirmSelectBusyDriver(context, haulHint);
      if (!proceed || !mounted) return;
    }
    // 061 п.3: цена на кнопке — она же уходит на сверку.
    widget.onUpdateStatus('SELECTED', expectedPrice: response.offer.proposedPrice ?? widget.cargo?.price);
  }

  /// 058 п.5: встречная цена — один раз.
  Future<void> _counter() async {
    final t = context.l10n;
    final cargo = widget.cargo;
    if (cargo == null) return;
    final offer = await showOfferSheet(context,
        currency: cargo.currency, title: t.offerCounterButton, initialPrice: widget.response.offer.proposedPrice, withComment: false, hint: t.offerCounterHint);
    if (offer == null || !mounted) return;
    try {
      await ref.read(cargoRepositoryProvider).counterOffer(widget.response.id, offer.price);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
    ref.invalidate(cargoResponsesProvider(widget.response.cargoId));
  }

  /// 078: чат открывается сразу, тред — в фоне.
  Future<void> _chat() async {
    openChat(context, ChatTarget(driverId: widget.response.driverId, cargoId: widget.response.cargoId, title: widget.response.driverName));
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.response.offer;
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final response = widget.response;
    // Выбранный отклик — уже сделка: показываем её текущий статус
    // («Загружен», «В пути»…) и открываем её по нажатию.
    final (statusLabel, statusColor) = response.dealStatus != null
        ? dealStatusPresentation(t, response.dealStatus!)
        : responseStatusPresentation(t, response.status);
    // Задача 038, п.8 — занятость водителя видна прямо в отклике (у выбранного
    // она включает этот же груз — «уже везёт» здесь только путает).
    final bodyCode = widget.refData?.bodyTypes.where((b) => b.id == response.bodyTypeId).firstOrNull?.code;
    final haulHint = widget.refData == null || response.dealId != null
        ? null
        : haulHintText(
            t,
            widget.refData!,
            locale,
            activeDealsCount: response.activeDealsCount,
            committedWeightKg: response.committedWeightKg,
            hasUnknownWeight: response.committedHasUnknownWeight,
            capacityTons: response.capacityTons,
            destinationCountryId: response.committedDestinationCountryId,
            destinationCityId: response.committedDestinationCityId,
            readyDate: response.committedReadyDate,
          );

    // 067: нажатие на строку — полная карточка водителя (в ожидающем отклике —
    // с «Выбрать»); сделка открывается нажатием на её статус.
    void openDriverCard() => showDriverInfoSheet(
          context,
          driverId: response.driverId,
          cargoId: response.cargoId,
          selectLabel: offer.hasDriverPrice && widget.cargo != null ? t.offerSelectFor(formatMoney(offer.proposedPrice!, widget.cargo!.currency)) : null,
          onSelect: response.status == ResponseStatus.pending ? () => _select(haulHint) : null,
        );
    return AppCard(
      key: Key('responseCard-${response.id}'),
      onTap: openDriverCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DriverAvatar(driverId: response.driverId, name: response.driverName, version: response.avatarVersion, radius: 20, openCard: true),
              const SizedBox(width: AppSpacing.sm),
              // 056 п.5: точка у отклика, который сотрудник ещё не открывал.
              if (response.isNew) ...[
                Semantics(
                  label: context.l10n.responsesNewDot,
                  child: Container(key: Key('responseNewDot-${response.id}'), width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(key: Key('driverNameTap-${response.driverId}'), onTap: openDriverCard, child: Text(response.driverName, style: AppTextStyles.bodyStrong)),
                    // 058 п.7: «в сети» / «был сегодня в 20:15».
                    if (formatLastSeen(t, response.lastSeenAt) case final seen?)
                      Text(seen, key: Key('responseLastSeen-${response.id}'), style: AppTextStyles.caption.copyWith(color: seen == t.lastSeenOnline ? AppColors.success : AppColors.textSecondary)),
                  ],
                ),
              ),
              if (response.dealId != null)
                GestureDetector(
                  key: Key('responseDealStatus-${response.id}'),
                  onTap: () => context.push('/deal/${response.dealId}'),
                  child: StatusBadge(label: statusLabel, color: statusColor),
                )
              else
                StatusBadge(label: statusLabel, color: statusColor),
              const SizedBox(width: AppSpacing.sm),
              IconSquareButton(icon: LucideIcons.messageSquare, onPressed: _chat),
            ],
          ),
          // 033 п.9 / 038 п.14 — вместимость связки водителя в отклике:
          // «20 т · 90 м³ · 33 пал.».
          if (response.bodyTypeId != null || response.capacityTons != null || response.volumeM3 != null || response.palletsEuro != null) ...[
            const SizedBox(height: AppSpacing.xs),
            // Фото машины — в карточке водителя (067).
            Row(
                children: [
                // 045 п.4: миниатюра кузова водителя.
                if (response.bodyTypeId != null) ...[
                  BodyTypeIcon(bodyTypeCode: bodyCode, width: 40),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    // 048 п.6: необъёмный кузов — строка по профилю.
                    (response.bodyTypeId != null && widget.refData != null && !widget.refData!.bodyTypeById(response.bodyTypeId!).isVolume && response.specs != null)
                        ? specsSummary(t, Localizations.localeOf(context).languageCode, widget.refData!.bodyTypeById(response.bodyTypeId!), response.specs)
                        : [
                      if (response.bodyTypeId != null && widget.refData != null)
                        widget.refData!.bodyTypeById(response.bodyTypeId!).name.forLanguageCode(Localizations.localeOf(context).languageCode),
                      if (response.capacityTons != null) '${response.capacityTons!.toStringAsFixed(0)} ${t.unitTon}',
                      if (response.volumeM3 != null && isVolumeBodyType(bodyCode)) '${response.volumeM3!.toStringAsFixed(0)} ${t.unitM3}',
                      if (response.palletsEuro != null && isVolumeBodyType(bodyCode) && response.bodyTypeId != null && (widget.refData?.bodyTypeById(response.bodyTypeId!).showPallets ?? false)) '${response.palletsEuro} ${t.unitPallets}',
                    ].join(' · '),
                    style: AppTextStyles.caption,
                  ),
                ),
                ],
            ),
          ],
          if (haulHint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(haulHint, style: AppTextStyles.caption.copyWith(color: AppColors.accentText)),
          ],
          // 046 п.3: «отменил 1 из 15 · после загрузки 1».
          if (cancelStatsText(t, response.cancelStats) case final stats?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(stats, key: const Key('responseCancelStats'), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
          if (response.message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(response.message!, style: AppTextStyles.body),
          ],
          // 058 п.5: торг — своя цена водителя и встречная логиста.
          if (widget.cargo case final cargo? when offer.hasDriverPrice) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.offerLogistProposes(formatMoney(offer.proposedPrice!, cargo.currency), formatMoney(cargo.price, cargo.currency)),
              key: Key('responseOffer-${response.id}'),
              style: AppTextStyles.bodyStrong,
            ),
            if (offer.proposedComment != null) Text(offer.proposedComment!, style: AppTextStyles.body),
            if (offer.counterPending)
              Text(t.offerCounterSent(formatMoney(offer.counterPrice!, cargo.currency)), key: Key('responseCounterSent-${response.id}'), style: AppTextStyles.caption.copyWith(color: AppColors.accentText)),
            if (offer.counterStatus == CounterStatus.declined)
              Text(t.offerCounterDeclined(formatMoney(offer.counterPrice!, cargo.currency)), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
          if (response.status == ResponseStatus.pending) ...[
            const SizedBox(height: AppSpacing.md),
            // Друг под другом: «Выбрать водителя» в половине узкого экрана не
            // помещалось (переполнение, найдено сценарием 9 на iPhone 16e/17).
            PrimaryButton(
              key: const Key('responseSelectButton'),
              label: offer.hasDriverPrice && widget.cargo != null ? t.offerSelectFor(formatMoney(offer.proposedPrice!, widget.cargo!.currency)) : t.responseSelect,
              onPressed: () => _select(haulHint),
            ),
            if (offer.canCounter && widget.cargo != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(key: Key('responseCounterButton-${response.id}'), onPressed: _counter, child: Text(t.offerCounterButton)),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => widget.onUpdateStatus('REJECTED'), child: Text(t.responseReject)),
            ),
          ],
        ],
      ),
    );
  }
}
