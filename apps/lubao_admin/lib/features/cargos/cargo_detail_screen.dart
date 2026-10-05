import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../shared/admin_dialogs.dart';
import '../shared/admin_status_helpers.dart';
import '../shared/audit_log_tab.dart';
import 'cargo_edit_dialog.dart';

/// Карточка груза (задача 028, п.15): все поля, отклики, сделка, журнал;
/// действия «Снять с публикации» и «Исправить».
class CargoDetailScreen extends ConsumerWidget {
  const CargoDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _reload(WidgetRef ref) async => ref.invalidate(adminCargoDetailProvider(id));

  Future<void> _unpublish(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final reason = await showReasonDialog(context, title: t.adminCargoUnpublishDialogTitle, confirmLabel: t.adminCargoUnpublish, danger: true);
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).unpublishCargo(id, reason: reason);
    await _reload(ref);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, AdminCargoDetail cargo) async {
    final refData = await ref.read(referenceDataProvider.future);
    if (!context.mounted) return;
    final result = await showCargoEditDialog(context, cargo: cargo, refData: refData);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).updateCargo(
          id,
          destinationCountryId: result.destinationCountryId,
          bodyTypeId: result.bodyTypeId,
          weightKg: result.weightKg,
          volumeM3: result.volumeM3,
          price: result.price,
          currency: result.currency,
          readyDate: result.readyDate,
          description: result.description,
          reason: result.reason,
        );
    await _reload(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final cargoAsync = ref.watch(adminCargoDetailProvider(id));

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/cargos'))),
      body: cargoAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('CargoDetailScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => _reload(ref));
        },
        data: (cargo) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                cargo: cargo,
                locale: locale,
                onUnpublish: () => _unpublish(context, ref),
                onEdit: () => _edit(context, ref, cargo),
              ),
              const SizedBox(height: 16),
              _DetailsCard(cargo: cargo, locale: locale),
              const SizedBox(height: 16),
              if (cargo.photoUrls.isNotEmpty) ...[
                _PhotosCard(photoUrls: cargo.photoUrls),
                const SizedBox(height: 16),
              ],
              _CargoTabs(cargo: cargo),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cargo, required this.locale, required this.onUnpublish, required this.onEdit});

  final AdminCargoDetail cargo;
  final String locale;
  final VoidCallback onUnpublish;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final route = '${cargo.pointName.forLanguageCode(locale)} → ${cargo.destinationCityName?.forLanguageCode(locale) ?? cargo.destinationCountryName.forLanguageCode(locale)}';
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(route, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(width: 12),
                    StatusBadge(label: cargoStatusLabel(t, cargo.status), color: _statusColor(cargo.status)),
                  ],
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => context.push('/companies/${cargo.companyId}'),
                  child: Text(cargo.companyName, style: const TextStyle(decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
          OutlinedButton(onPressed: onEdit, child: Text(t.adminCargoEdit)),
          const SizedBox(width: 8),
          if (cargo.status == 'PUBLISHED') FilledButton(onPressed: onUnpublish, child: Text(t.adminCargoUnpublish)),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'PUBLISHED' => StatusBadge.success,
        'ARCHIVED' => StatusBadge.neutral,
        'CANCELLED' => StatusBadge.danger,
        _ => StatusBadge.warning,
      };
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.cargo, required this.locale});

  final AdminCargoDetail cargo;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final rows = <(String, String)>[
      (t.cargoBodyType, cargo.bodyTypeName.forLanguageCode(locale)),
      if (cargo.weightKg != null) (t.cargoWeight, '${cargo.weightKg} ${t.unitKg}'),
      if (cargo.volumeM3 != null) (t.cargoVolume, '${cargo.volumeM3} ${t.unitM3}'),
      (
        t.cargoPrice,
        cargo.priceInKzt != null
            ? '${formatMoney(cargo.price, currencyFromJson(cargo.currency))} (≈ ${formatMoney(cargo.priceInKzt!, Currency.kzt)})'
            : formatMoney(cargo.price, currencyFromJson(cargo.currency)),
      ),
      (t.cargoReadyDate, formatAdminDate(cargo.readyDate)),
      (t.adminCargoPublishedAt, formatAdminDate(cargo.publishedAt)),
      (t.adminCargoExpiresAt, formatAdminDate(cargo.expiresAt)),
      if (cargo.archivedAt != null) (t.adminCargoArchivedAt, formatAdminDate(cargo.archivedAt!)),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [SizedBox(width: 180, child: Text(row.$1)), Expanded(child: Text(row.$2))]),
            ),
          if (cargo.description != null) ...[
            const SizedBox(height: 8),
            Text(cargo.description!),
          ],
        ],
      ),
    );
  }
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard({required this.photoUrls});

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(photoUrls[i], width: 120, height: 120, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _CargoTabs extends StatefulWidget {
  const _CargoTabs({required this.cargo});

  final AdminCargoDetail cargo;

  @override
  State<_CargoTabs> createState() => _CargoTabsState();
}

class _CargoTabsState extends State<_CargoTabs> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cargo = widget.cargo;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(controller: _controller, isScrollable: true, tabs: [Tab(text: t.adminCargoTabResponses), Tab(text: t.adminTabLog)]),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _controller,
              children: [
                _ResponsesTab(responses: cargo.responses, deal: cargo.deal),
                AuditLogTab(entries: cargo.auditLog),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsesTab extends StatelessWidget {
  const _ResponsesTab({required this.responses, required this.deal});

  final List<AdminCargoResponseEntry> responses;
  final AdminCargoDealRef? deal;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (responses.isEmpty) return Center(child: Text(t.adminNoResponses));
    return ListView.separated(
      itemCount: responses.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, i) {
        final r = responses[i];
        final isDeal = deal != null && deal!.driverName == r.driverName;
        return ListTile(
          title: InkWell(onTap: () => context.push('/drivers/${r.driverId}'), child: Text(r.driverName, style: const TextStyle(decoration: TextDecoration.underline))),
          subtitle: r.message != null ? Text(r.message!) : null,
          trailing: Text(isDeal ? dealStatusLabel(t, deal!.status) : responseStatusLabel(t, r.status)),
        );
      },
    );
  }
}

