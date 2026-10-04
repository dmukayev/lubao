import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/status_helpers.dart';

class DriverDealsScreen extends ConsumerWidget {
  const DriverDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final deals = ref.watch(dealsMineProvider);
    final referenceData = ref.watch(referenceDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.dealsTitle)),
      body: deals.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('DriverDealsScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(dealsMineProvider));
        },
        data: (list) {
          if (list.isEmpty) return EmptyState(message: t.dealsEmpty);
          final refData = referenceData.valueOrNull;
          final locale = Localizations.localeOf(context).languageCode;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dealsMineProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final deal = list[index];
                final (statusLabel, statusColor) = dealStatusPresentation(t, deal.status);
                final country =
                    refData != null && deal.cargo != null ? refData.countryById(deal.cargo!.destinationCountryId) : null;
                final city = refData != null && deal.cargo != null ? refData.cityById(deal.cargo!.destinationCityId) : null;
                final destinationLabel = country == null
                    ? deal.companyName
                    : [city?.name.forLanguageCode(locale), country.name.forLanguageCode(locale)]
                        .whereType<String>()
                        .join(', ');

                return CargoCard(
                  destinationLabel: destinationLabel,
                  bodyTypeLabel: deal.companyName,
                  priceLabel: deal.cargo != null ? formatMoney(deal.cargo!.price, deal.cargo!.currency) : '',
                  secondaryPriceLabel: deal.cargo == null || refData == null
                      ? null
                      : formatKztConversion(refData.convertToKzt(deal.cargo!.price, deal.cargo!.currency)),
                  readyDateLabel: formatDate(deal.createdAt),
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                  onTap: () => context.push('/deal/${deal.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
