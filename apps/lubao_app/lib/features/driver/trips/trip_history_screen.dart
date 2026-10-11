import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/status_helpers.dart';
import 'driver_trips_screen.dart';

enum _HistoryFilter { all, delivered, failed }

/// Строка истории: доставленная сделка или закрытый отклик с причиной.
class _HistoryItem {
  const _HistoryItem({required this.key, required this.at, required this.route, required this.price, required this.delivered, this.reason, this.onTap});

  final String key;
  final DateTime at;
  final String route;
  final String price;
  final bool delivered;
  final String? reason;
  final VoidCallback? onTap;
}

String closeReasonLabel(LubaoLocalizations t, ResponseCloseReason? reason) => switch (reason) {
      ResponseCloseReason.takenByOther => t.closeReasonTakenByOther,
      ResponseCloseReason.rejectedByLogist => t.closeReasonRejectedByLogist,
      ResponseCloseReason.withdrawn => t.closeReasonWithdrawn,
      ResponseCloseReason.inviteDeclined => t.closeReasonInviteDeclined,
      ResponseCloseReason.inviteExpired => t.closeReasonInviteExpired,
      ResponseCloseReason.cargoClosed => t.closeReasonCargoClosed,
      ResponseCloseReason.cargoArchived => t.closeReasonCargoArchived,
      ResponseCloseReason.dealCancelled => t.closeReasonDealCancelled,
      ResponseCloseReason.accountDeleted => t.closeReasonAccountDeleted,
      null => t.historyFailed,
    };

/// 056 п.6: «История рейсов» в профиле водителя, новые сверху — доставленные
/// сделки и закрытые отклики с причиной (вместо безликого «Отозван»).
class TripHistoryScreen extends ConsumerStatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  String _route(ReferenceData? rd, String locale, String? pointId, String countryId, String? cityId) {
    if (rd == null || countryId.isEmpty) return '';
    final origin = pointId == null ? null : rd.pointOrNull(pointId)?.name.forLanguageCode(locale);
    final destination = rd.cityById(cityId)?.name.forLanguageCode(locale) ?? rd.countryById(countryId).name.forLanguageCode(locale);
    return origin == null ? destination : '$origin → $destination';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dealsAsync = ref.watch(dealsMineProvider);
    final responsesAsync = ref.watch(myResponsesProvider);
    final rd = ref.watch(referenceDataProvider).valueOrNull;

    Widget body;
    if ((dealsAsync.isLoading && !dealsAsync.hasValue) || (responsesAsync.isLoading && !responsesAsync.hasValue)) {
      body = const LoadingView();
    } else if (dealsAsync.hasError || responsesAsync.hasError) {
      body = ErrorView(message: t.commonError, onRetry: () {
        ref.invalidate(dealsMineProvider);
        ref.invalidate(myResponsesProvider);
      });
    } else {
      final items = <_HistoryItem>[
        for (final d in (dealsAsync.value ?? const <Deal>[]).where((d) => d.status == DealStatus.delivered))
          _HistoryItem(
            key: 'historyDeal-${d.id}',
            at: d.deliveredAt ?? d.createdAt,
            route: d.cargo == null ? d.companyName : _route(rd, locale, d.cargo!.pointId, d.cargo!.destinationCountryId, d.cargo!.destinationCityId),
            price: d.cargo == null ? '' : formatMoney(d.agreedPrice ?? d.cargo!.price, d.cargo!.currency),
            delivered: true,
            onTap: () => context.push('/deal/${d.id}'),
          ),
        for (final r in (responsesAsync.value ?? const <MyResponseEntry>[])
            .where((r) => r.status == ResponseStatus.cancelled || r.status == ResponseStatus.rejected))
          _HistoryItem(
            key: 'historyResponse-${r.id}',
            at: r.updatedAt ?? r.readyDate,
            route: _route(rd, locale, r.pointId, r.destinationCountryId, r.destinationCityId),
            price: formatMoney(r.price, r.currency),
            delivered: false,
            reason: closeReasonLabel(t, r.closeReason),
          ),
      ]..sort((a, b) => b.at.compareTo(a.at));
      final shown = items.where((i) => switch (_filter) {
            _HistoryFilter.all => true,
            _HistoryFilter.delivered => i.delivered,
            _HistoryFilter.failed => !i.delivered,
          });

      body = ListView(
        key: const Key('historyList'),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final f in _HistoryFilter.values)
                  ChoiceChip(
                    key: Key('historyFilter-${f.name}'),
                    label: Text(switch (f) {
                      _HistoryFilter.all => t.historyAll,
                      _HistoryFilter.delivered => t.historyDelivered,
                      _HistoryFilter.failed => t.historyFailed,
                    }),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
          ),
          if (shown.isEmpty)
            Padding(padding: const EdgeInsets.only(top: AppSpacing.xxl), child: EmptyState(message: t.historyEmpty))
          else
            for (final i in shown)
              ListTile(
                key: Key(i.key),
                onTap: i.onTap,
                title: Text(i.route, style: AppTextStyles.bodyStrong, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text([formatDate(i.at), if (i.price.isNotEmpty) i.price].join(' · '), style: AppTextStyles.caption),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: StatusBadge(
                    label: i.delivered ? t.historyDelivered : i.reason!,
                    color: i.delivered ? StatusBadge.success : (i.reason == t.closeReasonDealCancelled ? StatusBadge.danger : StatusBadge.neutral),
                  ),
                ),
              ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.historyTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dealsMineProvider);
          ref.invalidate(myResponsesProvider);
        },
        child: body,
      ),
    );
  }
}
