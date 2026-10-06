import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../shared/status_helpers.dart';

final myResponsesProvider = FutureProvider.autoDispose<List<MyResponseEntry>>((ref) {
  return ref.watch(cargoRepositoryProvider).myResponses();
});

/// «Мои отклики» (задача 041, п.9): куда водитель откликался и что с этим —
/// «Ожидает», «Приглашён», «Выбран», «Отклонён», «Отозван». Тап — карточка груза.
class MyResponsesScreen extends ConsumerWidget {
  const MyResponsesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final responses = ref.watch(myResponsesProvider);
    final refData = ref.watch(referenceDataProvider).valueOrNull;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(t.myResponsesTitle)),
      body: responses.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('MyResponsesScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(myResponsesProvider));
        },
        data: (list) {
          if (list.isEmpty) return EmptyState(message: t.myResponsesEmpty);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myResponsesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final r = list[index];
                final (statusLabel, statusColor) = responseStatusPresentation(t, r.status);
                final country = refData?.countryById(r.destinationCountryId);
                final city = refData?.cityById(r.destinationCityId);
                final destination = [city?.name.forLanguageCode(locale), country?.name.forLanguageCode(locale)].whereType<String>().join(', ');
                return CargoCard(
                  key: Key('myResponseCard-${r.id}'),
                  destinationLabel: destination,
                  bodyTypeLabel: refData?.bodyTypeById(r.bodyTypeId).name.forLanguageCode(locale) ?? '',
                  priceLabel: formatMoney(r.price, r.currency),
                  secondaryPriceLabel: refData == null ? null : formatKztConversion(refData.convertToKzt(r.price, r.currency)),
                  readyDateLabel: formatDate(r.readyDate),
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                  onTap: () => context.push('/driver/cargo/${r.cargoId}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
