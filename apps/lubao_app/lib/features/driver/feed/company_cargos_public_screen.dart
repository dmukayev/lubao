import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../shared/status_helpers.dart';

final _companyCargosProvider = FutureProvider.autoDispose.family<List<Cargo>, String>((ref, companyId) {
  return ref.watch(cargoRepositoryProvider).byCompany(companyId);
});

/// 052: водитель открыл ссылку «Все грузы компании» (/co/…) — её активные грузы.
class CompanyCargosPublicScreen extends ConsumerWidget {
  const CompanyCargosPublicScreen({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final cargos = ref.watch(_companyCargosProvider(companyId));
    final refData = ref.watch(referenceDataProvider).valueOrNull;
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(cargos.valueOrNull?.firstOrNull?.companyName ?? t.shareCompanyCargosTitle)),
      body: cargos.when(
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(_companyCargosProvider(companyId))),
        data: (list) {
          if (list.isEmpty) return EmptyState(message: t.cargosEmptyActive);
          return ListView(
            key: const Key('companyCargosPublicList'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            children: [
              for (final c in list)
                CargoCard(
                  key: Key('companyCargoPublic-${c.id}'),
                  originLabel: refData?.pointOrNull(c.pointId)?.name.forLanguageCode(locale),
                  destinationLabel: refData == null
                      ? ''
                      : (refData.cityById(c.destinationCityId)?.name.forLanguageCode(locale) ?? refData.countryById(c.destinationCountryId).name.forLanguageCode(locale)),
                  bodyTypeLabel: refData?.bodyTypeById(c.bodyTypeId).name.forLanguageCode(locale) ?? '',
                  priceLabel: formatMoney(c.price, c.currency),
                  readyDateLabel: formatDate(c.readyDate),
                  onTap: () => context.push('/driver/cargo/${c.id}'),
                ),
            ],
          );
        },
      ),
    );
  }
}
