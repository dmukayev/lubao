import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/status_helpers.dart';

class CargoResponsesScreen extends ConsumerWidget {
  const CargoResponsesScreen({super.key, required this.cargoId});

  final String cargoId;

  Future<void> _updateStatus(WidgetRef ref, String responseId, String status) async {
    await ref.read(cargoRepositoryProvider).updateResponseStatus(responseId, status);
    ref.invalidate(cargoResponsesProvider(cargoId));
  }

  Future<void> _edit(BuildContext context, Cargo cargo) async {
    await context.push('/company/cargos/new', extra: cargo);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.cargoDeleteConfirmTitle),
        content: Text(t.cargoDeleteConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.cargoDelete)),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(cargoRepositoryProvider).delete(cargoId);
    ref.invalidate(myCargosProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cargoDeleted)));
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
                  tooltip: t.cargoDelete,
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: () => _delete(context, ref),
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
              padding: const EdgeInsets.all(AppSpacing.screen),
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
                    _ResponseCard(response: response, onUpdateStatus: (status) => _updateStatus(ref, response.id, status)),
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

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({required this.response, required this.onUpdateStatus});

  final CargoResponse response;
  final ValueChanged<String> onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final (statusLabel, statusColor) = responseStatusPresentation(t, response.status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(response.driverName, style: AppTextStyles.bodyStrong),
              StatusBadge(label: statusLabel, color: statusColor),
            ],
          ),
          if (response.message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(response.message!, style: AppTextStyles.body),
          ],
          if (response.status == ResponseStatus.pending) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(label: t.responseSelect, onPressed: () => onUpdateStatus('SELECTED')),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(onPressed: () => onUpdateStatus('REJECTED'), child: Text(t.responseReject)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
