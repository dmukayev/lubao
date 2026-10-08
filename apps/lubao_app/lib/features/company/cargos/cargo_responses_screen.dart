import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/status_helpers.dart';
import '../haul_hint.dart';
import 'cargo_close_dialog.dart';

class CargoResponsesScreen extends ConsumerWidget {
  const CargoResponsesScreen({super.key, required this.cargoId});

  final String cargoId;

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String responseId, String status) async {
    try {
      await ref.read(cargoRepositoryProvider).updateResponseStatus(responseId, status);
    } catch (e) {
      if (context.mounted) {
        final t = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseConflictText(t, e) ?? t.commonError)));
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
    final locale = Localizations.localeOf(context).languageCode;
    final responses = ref.watch(cargoResponsesProvider(cargoId));
    final cargoAsync = ref.watch(cargoByIdProvider(cargoId));
    final referenceData = ref.watch(referenceDataProvider);
    final cargo = cargoAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.responsesTitle),
        actions: cargo == null
            ? null
            : [
                IconButton(
                  tooltip: t.cargoEdit,
                  icon: const Icon(LucideIcons.pencil),
                  onPressed: () => _edit(context, cargo),
                ),
                IconButton(
                  tooltip: t.cargoClose,
                  icon: const Icon(LucideIcons.xCircle),
                  onPressed: () => _close(context, ref),
                ),
              ],
      ),
      body: responses.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('CargoResponsesScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(cargoResponsesProvider(cargoId)));
        },
        data: (list) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(cargoResponsesProvider(cargoId)),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.screen),
              children: [
                if (cargo != null && referenceData.valueOrNull != null)
                  _CargoSummaryCard(cargo: cargo, refData: referenceData.valueOrNull!, locale: locale),
                const SizedBox(height: AppSpacing.lg),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: EmptyState(message: t.responsesEmpty),
                  )
                else
                  for (final response in list) ...[
                    _ResponseCard(
                      response: response,
                      cargoWeightKg: cargo?.weightKg,
                      refData: referenceData.valueOrNull,
                      onUpdateStatus: (status) => _updateStatus(context, ref, response.id, status),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CargoSummaryCard extends StatelessWidget {
  const _CargoSummaryCard({required this.cargo, required this.refData, required this.locale});

  final Cargo cargo;
  final ReferenceData refData;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final country = refData.countryById(cargo.destinationCountryId);
    final city = refData.cityById(cargo.destinationCityId);
    final destinationLabel =
        [city?.name.forLanguageCode(locale), country.name.forLanguageCode(locale)].whereType<String>().join(', ');
    final (statusLabel, statusColor) = cargoStatusPresentation(t, cargo.status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(destinationLabel, style: AppTextStyles.route)),
              StatusBadge(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(formatDate(cargo.readyDate), style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(formatMoney(cargo.price, cargo.currency), style: AppTextStyles.priceCard),
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
  });

  final CargoResponse response;
  final double? cargoWeightKg;
  final ReferenceData? refData;
  final ValueChanged<String> onUpdateStatus;

  @override
  ConsumerState<_ResponseCard> createState() => _ResponseCardState();
}

class _ResponseCardState extends ConsumerState<_ResponseCard> {
  bool _openingChat = false;

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
    widget.onUpdateStatus('SELECTED');
  }

  Future<void> _chat() async {
    setState(() => _openingChat = true);
    try {
      final thread = await ref
          .read(chatRepositoryProvider)
          .findOrCreate(driverId: widget.response.driverId, cargoId: widget.response.cargoId);
      if (mounted) context.push('/chat/${thread.id}');
    } catch (e) {
      debugPrint('CargoResponsesScreen: failed to open chat: $e');
      if (mounted) {
        final t = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.chatOpenFailed),
          action: SnackBarAction(label: t.commonRetry, onPressed: _chat),
        ));
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return AppCard(
      key: Key('responseCard-${response.id}'),
      onTap: response.dealId == null ? null : () => context.push('/deal/${response.dealId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(response.driverName, style: AppTextStyles.bodyStrong)),
              StatusBadge(label: statusLabel, color: statusColor),
              const SizedBox(width: AppSpacing.sm),
              IconSquareButton(icon: LucideIcons.messageSquare, loading: _openingChat, onPressed: _chat),
            ],
          ),
          // 033 п.9 / 038 п.14 — вместимость связки водителя в отклике:
          // «20 т · 90 м³ · 33 пал.».
          if (response.bodyTypeId != null || response.capacityTons != null || response.volumeM3 != null || response.palletsEuro != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                // 045 п.4: миниатюра кузова водителя.
                if (response.bodyTypeId != null) ...[
                  BodyTypeIcon(bodyTypeCode: widget.refData?.bodyTypes.where((b) => b.id == response.bodyTypeId).firstOrNull?.code, width: 40),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    [
                      if (response.bodyTypeId != null && widget.refData != null)
                        widget.refData!.bodyTypeById(response.bodyTypeId!).name.forLanguageCode(Localizations.localeOf(context).languageCode),
                      if (response.capacityTons != null) '${response.capacityTons!.toStringAsFixed(0)} ${t.unitTon}',
                      if (response.volumeM3 != null) '${response.volumeM3!.toStringAsFixed(0)} ${t.unitM3}',
                      if (response.palletsEuro != null) '${response.palletsEuro} ${t.unitPallets}',
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
          if (response.message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(response.message!, style: AppTextStyles.body),
          ],
          if (response.status == ResponseStatus.pending) ...[
            const SizedBox(height: AppSpacing.md),
            // Друг под другом: «Выбрать водителя» в половине узкого экрана не
            // помещалось (переполнение, найдено сценарием 9 на iPhone 16e/17).
            PrimaryButton(key: const Key('responseSelectButton'), label: t.responseSelect, onPressed: () => _select(haulHint)),
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
