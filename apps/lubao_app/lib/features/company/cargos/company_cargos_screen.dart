import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/status_helpers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CompanyCargosScreen extends ConsumerWidget {
  const CompanyCargosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final cargos = ref.watch(myCargosProvider);
    final referenceData = ref.watch(referenceDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.myCargosTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('companyPostCargoFab'),
        onPressed: () => context.push('/company/cargos/new'),
        icon: const Icon(LucideIcons.plus),
        label: Text(t.postCargoTitle),
      ),
      body: cargos.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('CompanyCargosScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(myCargosProvider));
        },
        data: (list) {
          if (list.isEmpty) return EmptyState(message: t.myCargosEmpty);
          final refData = referenceData.valueOrNull;
          final locale = Localizations.localeOf(context).languageCode;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myCargosProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final cargo = list[index];
                final country = refData?.countryById(cargo.destinationCountryId);
                final city = refData?.cityById(cargo.destinationCityId);
                final destinationLabel = country == null
                    ? ''
                    : [city?.name.forLanguageCode(locale), country.name.forLanguageCode(locale)]
                        .whereType<String>()
                        .join(', ');
                final bodyType = refData?.bodyTypeById(cargo.bodyTypeId);
                final (statusLabel, statusColor) = cargoStatusPresentation(t, cargo.status);

                return CargoCard(
                  key: Key('companyCargoCard-${cargo.id}'),
                  originLabel: refData?.pointOrNull(cargo.pointId)?.name.forLanguageCode(locale),
                  partialLabel: cargo.allowPartial ? t.feedBadgePartial : null,
                  destinationLabel: destinationLabel,
                  bodyTypeLabel: bodyType?.name.forLanguageCode(locale) ?? '',
                  priceLabel: formatMoney(cargo.price, cargo.currency),
                  secondaryPriceLabel:
                      refData == null ? null : formatKztConversion(refData.convertToKzt(cargo.price, cargo.currency)),
                  readyDateLabel: formatDate(cargo.readyDate),
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                  onTap: () => context.push('/company/cargos/${cargo.id}/responses'),
                  trailing: cargo.activeDeal == null ? null : _DealDriverRow(deal: cargo.activeDeal!),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// «Водитель: <имя> · подтвердил» + «Документы» / «· ждём подтверждения» (044 п.3).
class _DealDriverRow extends StatelessWidget {
  const _DealDriverRow({required this.deal});
  final CargoActiveDeal deal;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final confirmed = deal.status != DealStatus.selected;
    return Row(
      key: Key('cargoDealDriver-${deal.id}'),
      children: [
        Icon(confirmed ? LucideIcons.checkCircle2 : LucideIcons.clock, size: 16, color: confirmed ? AppColors.success : AppColors.accentText),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            confirmed ? t.cargoDealDriverConfirmed(deal.driverName) : t.cargoDealDriverWaiting(deal.driverName),
            style: AppTextStyles.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (confirmed)
          TextButton(
            key: Key('cargoDealDocs-${deal.id}'),
            onPressed: () => context.push('/deal/${deal.id}'),
            child: Text(t.driverDocsOpen),
          ),
      ],
    );
  }
}

