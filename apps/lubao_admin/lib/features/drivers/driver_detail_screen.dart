import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../shared/admin_dialogs.dart';
import '../shared/admin_document_image.dart';
import '../shared/admin_status_helpers.dart';
import '../shared/audit_log_tab.dart';
import '../shared/document_viewer.dart';
import '../shared/identifiers_card.dart';
import '../shared/responsive.dart';
import 'driver_edit_panel.dart';

class DriverDetailScreen extends ConsumerWidget {
  const DriverDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _reload(WidgetRef ref) async => ref.invalidate(adminDriverDetailProvider(id));

  Future<void> _block(BuildContext context, WidgetRef ref, AdminDriverDetail driver) async {
    final t = context.l10n;
    final reason = await showReasonDialog(context, title: t.adminBlockConfirmTitle, confirmLabel: t.adminBlock, danger: true);
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).blockUser(driver.userId, reason: reason);
    await _reload(ref);
  }

  Future<void> _unblock(BuildContext context, WidgetRef ref, AdminDriverDetail driver) async {
    final t = context.l10n;
    final reason = await showReasonDialog(context, title: t.adminUnblockConfirmTitle, confirmLabel: t.adminUnblock);
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).unblockUser(driver.userId, reason: reason);
    await _reload(ref);
  }

  Future<void> _endSessions(BuildContext context, WidgetRef ref, AdminDriverDetail driver) async {
    final t = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.adminEndSessionsConfirmTitle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.commonDone)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(adminRepositoryProvider).revokeSessions(driver.userId);
    await _reload(ref);
  }

  Future<void> _toggleVerified(BuildContext context, WidgetRef ref, AdminDriverDetail driver) async {
    final t = context.l10n;
    final settingVerified = !driver.isVerified;
    final result = await showVerifyDialog(context, settingVerified: settingVerified, offerForce: settingVerified);
    if (result == null) return;
    try {
      await ref.read(adminRepositoryProvider).setDriverVerified(id, settingVerified, reason: result.reason, force: result.force);
      await _reload(ref);
    } on Exception catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.adminVerifyMissingDocsError)));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, AdminDriverDetail driver) async {
    final refData = await ref.read(referenceDataProvider.future);
    if (!context.mounted) return;
    final result = await showDriverEditPanel(context, driver: driver, refData: refData);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).updateDriver(
          id,
          fullName: result.fullName,
          phone: result.phone,
          homeCityId: result.homeCityId,
          anyCountry: result.anyCountry,
          countryIds: result.countryIds,
          permitIds: result.permitIds,
          vehicleBodyTypeId: result.vehicleBodyTypeId,
          vehicleCapacityTons: result.vehicleCapacityTons,
          vehicleLengthM: result.vehicleLengthM,
          vehiclePlateNumber: result.vehiclePlateNumber,
          vehicleBrand: result.vehicleBrand,
          reason: result.reason,
        );
    await _reload(ref);
  }

  Future<void> _reviewDocument(BuildContext context, WidgetRef ref, AdminCardDocument doc, {required bool approve}) async {
    final t = context.l10n;
    String? reason;
    if (!approve) {
      reason = await showRejectReasonDialog(context);
      if (reason == null) return;
    }
    await ref.read(adminRepositoryProvider).reviewDocument(doc.id, approve: approve, rejectReason: reason);
    await _reload(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? t.adminApprove : t.adminReject)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final driverAsync = ref.watch(adminDriverDetailProvider(id));

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/drivers'))),
      body: driverAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('DriverDetailScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => _reload(ref));
        },
        data: (driver) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                driver: driver,
                onEdit: () => _edit(context, ref, driver),
                onBlock: () => _block(context, ref, driver),
                onUnblock: () => _unblock(context, ref, driver),
                onEndSessions: () => _endSessions(context, ref, driver),
                onToggleVerified: () => _toggleVerified(context, ref, driver),
              ),
              const SizedBox(height: 16),
              _StatsRow(driver: driver),
              const SizedBox(height: 16),
              ResponsiveTwoColumn(
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DocumentsCard(
                      documents: driver.documents,
                      onApprove: (doc) => _reviewDocument(context, ref, doc, approve: true),
                      onReject: (doc) => _reviewDocument(context, ref, doc, approve: false),
                    ),
                    const SizedBox(height: 16),
                    _VehicleCard(vehicles: driver.vehicles, locale: locale),
                    const SizedBox(height: 16),
                    IdentifiersCard(
                      identifiers: [...driver.identifiers, ...driver.vehicles.expand((v) => v.identifiers)],
                      blockHistory: [...driver.identifierBlockHistory, ...driver.vehicles.expand((v) => v.identifierBlockHistory)],
                    ),
                    const SizedBox(height: 16),
                    _DirectionsCard(driver: driver, locale: locale),
                  ],
                ),
                right: _DriverTabs(driver: driver),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.driver,
    required this.onEdit,
    required this.onBlock,
    required this.onUnblock,
    required this.onEndSessions,
    required this.onToggleVerified,
  });

  final AdminDriverDetail driver;
  final VoidCallback onEdit;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onEndSessions;
  final VoidCallback onToggleVerified;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final initials = driver.fullName.trim().isEmpty
        ? '?'
        : driver.fullName.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();

    // Задача 031 (ревью белых экранов) — заголовок раньше падал с
    // «BoxConstraints forces an infinite width» (голые OutlinedButton рядом
    // с Expanded(Column) в одном Row — тот же баг, что в
    // complaints_screen.dart, задача 030); компактный minimumSize это чинит,
    // но на узком экране/коротком имени кнопки+меню всё равно не влезали в
    // одну строку с именем+бейджем — поэтому действия вынесены в свой Wrap
    // под информационным блоком, а не в одну строку с ним.
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 28, child: Text(initials)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(driver.fullName, style: Theme.of(context).textTheme.headlineSmall)),
                        const SizedBox(width: 12),
                        if (driver.isBlocked)
                          StatusBadge(label: t.adminBlockedBadge, color: StatusBadge.danger)
                        else
                          StatusBadge(
                            label: driver.isVerified ? t.adminVerified : t.adminNotVerified,
                            color: driver.isVerified ? StatusBadge.success : StatusBadge.neutral,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (driver.phone != null)
                          InkWell(
                            onTap: () => copyToClipboardWithToast(context, driver.phone!, t.adminCopied),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [Text(driver.phone!), const SizedBox(width: 4), const Icon(LucideIcons.copy, size: 14)]),
                          ),
                        Text(driver.homeCityName.forLanguageCode(Localizations.localeOf(context).languageCode)),
                        Text(t.adminWithUsSince(formatAdminDate(driver.registeredAt))),
                        Text(t.adminLastLogin(formatAdminDateTime(driver.lastLoginAt))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // minimumSize компактный, а не Size.fromHeight темы — иначе каждая
          // кнопка в Wrap требует всю ширину строки и встаёт вертикальным
          // столбиком вместо ряда (эту ловушку уже проходили в
          // complaints_screen.dart, задача 030).
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, AppSizes.buttonHeight)),
                onPressed: onEdit,
                child: Text(t.adminEdit),
              ),
              if (driver.isBlocked)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, AppSizes.buttonHeight)),
                  onPressed: onUnblock,
                  child: Text(t.adminUnblock),
                )
              else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: StatusBadge.danger,
                    side: const BorderSide(color: StatusBadge.danger),
                    minimumSize: const Size(0, AppSizes.buttonHeight),
                  ),
                  onPressed: onBlock,
                  child: Text(t.adminBlock),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'end_sessions') onEndSessions();
                  if (value == 'toggle_verified') onToggleVerified();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'end_sessions', child: Text(t.adminEndSessions)),
                  PopupMenuItem(value: 'toggle_verified', child: Text(t.adminToggleVerification)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.driver});

  final AdminDriverDetail driver;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final totalDeals = driver.stats.dealsByStatus.values.fold<int>(0, (a, b) => a + b);
    return AppCard(
      child: Row(
        children: [
          _Stat(label: t.adminStatDealsActive, value: '$totalDeals'),
          _Stat(label: t.adminColRating, value: '★ ${driver.stats.ratingAvg.toStringAsFixed(1)} (${driver.stats.ratingCount})'),
          _Stat(label: t.adminStatCancellations, value: '${driver.stats.cancellations}'),
          _Stat(label: t.adminStatCalls, value: '${driver.stats.calls + driver.stats.whatsapp}'),
          _Stat(label: t.adminStatComplaints, value: '${driver.stats.complaintsAgainst}'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard({required this.documents, required this.onApprove, required this.onReject});

  final List<AdminCardDocument> documents;
  final ValueChanged<AdminCardDocument> onApprove;
  final ValueChanged<AdminCardDocument> onReject;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminDocuments, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (documents.isEmpty) Text(t.adminNoDocuments),
          for (final doc in documents) ...[
            _DocumentRow(doc: doc, onApprove: () => onApprove(doc), onReject: () => onReject(doc)),
            const Divider(),
          ],
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.doc, required this.onApprove, required this.onReject});

  final AdminCardDocument doc;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final (statusLabel, statusColor) = verificationStatusPresentation(t, doc.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => openDocumentViewer(context, doc.fileUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 56, height: 56, child: AdminDocumentImage(url: doc.fileUrl)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verificationDocTypeLabel(t, doc.type)),
                StatusBadge(label: statusLabel, color: statusColor),
                if (doc.status == VerificationStatus.rejected && doc.rejectReason != null)
                  Text(doc.rejectReason!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: StatusBadge.danger)),
              ],
            ),
          ),
          if (doc.status == VerificationStatus.pending) ...[
            IconButton(icon: const Icon(LucideIcons.check, color: StatusBadge.success), onPressed: onApprove, tooltip: t.adminApprove),
            IconButton(icon: const Icon(LucideIcons.x, color: StatusBadge.danger), onPressed: onReject, tooltip: t.adminReject),
          ],
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicles, required this.locale});

  final List<AdminDriverVehicle> vehicles;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.driverSetupVehicleTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final v in vehicles)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${v.bodyTypeName.forLanguageCode(locale)}'
                '${v.capacityTons != null ? ' · ${v.capacityTons} ${t.unitTon}' : ''}'
                '${v.plateNumber != null ? ' · ${v.plateNumber}' : ''}',
              ),
            ),
        ],
      ),
    );
  }
}

class _DirectionsCard extends StatelessWidget {
  const _DirectionsCard({required this.driver, required this.locale});

  final AdminDriverDetail driver;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.driverSetupDirectionsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(driver.anyCountry ? t.driverSetupAnyCountry : driver.directionNames.map((n) => n.forLanguageCode(locale)).join(', ')),
          const SizedBox(height: 12),
          Text(t.driverSetupPermits, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(driver.permitNames.isEmpty ? '—' : driver.permitNames.map((n) => n.forLanguageCode(locale)).join(', ')),
        ],
      ),
    );
  }
}

class _DriverTabs extends StatefulWidget {
  const _DriverTabs({required this.driver});

  final AdminDriverDetail driver;

  @override
  State<_DriverTabs> createState() => _DriverTabsState();
}

class _DriverTabsState extends State<_DriverTabs> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final driver = widget.driver;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _controller,
            isScrollable: true,
            tabs: [Tab(text: t.adminTabDeals), Tab(text: t.adminTabReviews), Tab(text: t.adminTabLog)],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _controller,
              children: [
                _DealsTab(deals: driver.deals),
                _ReviewsTab(reviews: driver.stats.reviews),
                AuditLogTab(entries: driver.auditLog),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DealsTab extends StatelessWidget {
  const _DealsTab({required this.deals});

  final List<AdminDriverDealEntry> deals;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (deals.isEmpty) return Center(child: Text(t.adminNoDeals));
    return ListView.separated(
      itemCount: deals.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, i) {
        final deal = deals[i];
        final (label, color) = dealStatusPresentation(t, deal.status);
        return ListTile(
          title: InkWell(onTap: () => context.push('/companies/${deal.companyId}'), child: Text(deal.companyName, style: const TextStyle(decoration: TextDecoration.underline))),
          trailing: StatusBadge(label: label, color: color),
          subtitle: Text(formatAdminDate(deal.createdAt)),
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.reviews});

  final List<AdminReviewEntry> reviews;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (reviews.isEmpty) return Center(child: Text(t.adminNoReviews));
    return ListView.separated(
      itemCount: reviews.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, i) {
        final r = reviews[i];
        return ListTile(
          title: Text('★ ${r.rating}'),
          subtitle: r.comment != null ? Text(r.comment!) : null,
          trailing: Text(formatAdminDate(r.createdAt)),
        );
      },
    );
  }
}

