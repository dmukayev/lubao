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
import '../shared/document_viewer.dart';

/// Совпадает с REQUIRED_DRIVER_DOC_TYPES / REQUIRED_COMPANY_DOC_TYPES на
/// бэкенде (`backend/src/drivers/drivers.service.ts`, `admin.service.ts`) —
/// от кого требуем полный комплект, прежде чем включать «Подтвердить».
const _requiredDriverDocTypes = ['SELFIE', 'VEHICLE_PASSPORT', 'TRAILER_PASSPORT', 'DRIVER_LICENSE'];
const _requiredCompanyDocTypes = ['COMPANY_REGISTRATION'];

/// Проверка целиком — очередь по субъектам (не по документам), сверка
/// профиля с документами, один итог на человека (задача 028, этап B).
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final type = ref.watch(adminVerificationTypeProvider);
    final selectedId = ref.watch(adminVerificationSelectedIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminVerificationTitle)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 340, child: _QueuePane(type: type)),
          const VerticalDivider(width: 1),
          Expanded(
            child: selectedId == null
                ? EmptyState(message: t.adminVerificationNoSelection, icon: LucideIcons.userCheck)
                : type == 'company'
                    ? _CompanyDetailPane(key: ValueKey('company:$selectedId'), id: selectedId)
                    : _DriverDetailPane(key: ValueKey('driver:$selectedId'), id: selectedId),
          ),
        ],
      ),
    );
  }
}

class _QueuePane extends ConsumerWidget {
  const _QueuePane({required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final queue = ref.watch(adminVerificationQueueProvider(type));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'driver', label: Text(t.adminVerificationTabDrivers)),
              ButtonSegment(value: 'company', label: Text(t.adminVerificationTabCompanies)),
            ],
            selected: {type},
            onSelectionChanged: (s) {
              ref.read(adminVerificationTypeProvider.notifier).state = s.first;
              ref.read(adminVerificationSelectedIdProvider.notifier).state = null;
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: queue.when(
            loading: () => const LoadingView(),
            error: (e, st) => ErrorView(
              message: t.commonError,
              retryLabel: t.commonRetry,
              onRetry: () => ref.invalidate(adminVerificationQueueProvider(type)),
            ),
            data: (items) {
              if (items.isEmpty) return EmptyState(message: t.adminVerificationEmpty, icon: LucideIcons.badgeCheck);
              final selectedId = ref.watch(adminVerificationSelectedIdProvider);
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final ageHours = DateTime.now().difference(item.oldestPendingAt).inHours;
                  return ListTile(
                    selected: item.subjectId == selectedId,
                    title: Text(item.subjectName),
                    subtitle: Text(_reasonLabel(t, item)),
                    trailing: ageHours >= 24
                        ? const Icon(LucideIcons.alertCircle, color: StatusBadge.danger, size: 18)
                        : null,
                    onTap: () => ref.read(adminVerificationSelectedIdProvider.notifier).state = item.subjectId,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _reasonLabel(LubaoLocalizations t, AdminVerificationQueueItem item) {
    switch (item.reason) {
      case AdminVerificationQueueReason.resubmitted:
        return t.adminVerificationReasonResubmitted(verificationDocTypeLabel(t, item.resubmittedType ?? ''));
      case AdminVerificationQueueReason.vehicleChanged:
        return t.adminVerificationReasonVehicleChanged;
      case AdminVerificationQueueReason.newSubmission:
        return t.adminVerificationReasonNew(item.pendingCount);
    }
  }
}

/// `true` — документ в порядке, `false` — есть проблема, `null` — ещё не
/// решили в этой сессии (наследуем текущий статус с сервера).
typedef _DocDecisions = Map<String, bool>;

bool? _effectiveOk(_DocDecisions local, AdminCardDocument doc) {
  if (local.containsKey(doc.id)) return local[doc.id];
  if (doc.status == VerificationStatus.approved) return true;
  if (doc.status == VerificationStatus.rejected) return false;
  return null;
}

class _DriverDetailPane extends ConsumerStatefulWidget {
  const _DriverDetailPane({super.key, required this.id});

  final String id;

  @override
  ConsumerState<_DriverDetailPane> createState() => _DriverDetailPaneState();
}

class _DriverDetailPaneState extends ConsumerState<_DriverDetailPane> {
  final _DocDecisions _decisions = {};
  final Map<String, String> _reasons = {};
  final Map<String, bool?> _crossChecks = {};
  String? _selectedDocId;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final profile = ref.watch(adminVerificationDriverProfileProvider(widget.id));

    return profile.when(
      loading: () => const LoadingView(),
      error: (e, st) => ErrorView(
        message: t.commonError,
        retryLabel: t.commonRetry,
        onRetry: () => ref.invalidate(adminVerificationDriverProfileProvider(widget.id)),
      ),
      data: (driver) {
        final selfie = driver.documents.where((d) => d.type == 'SELFIE').firstOrNull;
        final selectedDoc = driver.documents.where((d) => d.id == _selectedDocId).firstOrNull ?? driver.documents.firstOrNull;
        final allRequiredOk = _requiredDriverDocTypes.every(
          (type) => driver.documents.any((d) => d.type == type && _effectiveOk(_decisions, d) == true),
        );
        final anyProblem = driver.documents.any((d) => _effectiveOk(_decisions, d) == false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _Header(
                    title: driver.fullName,
                    isVerified: driver.isVerified,
                    onOpenCard: () => context.push('/drivers/${driver.id}'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _CrossCheckCard(
                    rows: [
                      (key: 'name', label: t.adminCrossCheckName),
                      (key: 'photo', label: t.adminCrossCheckPhoto),
                      (key: 'plate', label: t.adminCrossCheckPlate),
                      (key: 'trailerPlate', label: t.adminCrossCheckTrailerPlate),
                    ],
                    values: _crossChecks,
                    onChanged: (key, value) => setState(() => _crossChecks[key] = value),
                    extra: driver.vehicles.isEmpty
                        ? null
                        : driver.vehicles
                            .map((v) => '${v.bodyTypeName.forLanguageCode(Localizations.localeOf(context).languageCode)}'
                                '${v.plateNumber != null ? ' · ${v.plateNumber}' : ''}')
                            .join(', '),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (selectedDoc != null)
                    _BigViewer(
                      doc: selectedDoc,
                      compareUrl: selfie != null && selfie.id != selectedDoc.id ? selfie.fileUrl : null,
                      ok: _effectiveOk(_decisions, selectedDoc),
                      onOk: () => setState(() => _decisions[selectedDoc.id] = true),
                      onProblem: () async {
                        final reason = await showRejectReasonDialog(context);
                        if (reason == null) return;
                        setState(() {
                          _decisions[selectedDoc.id] = false;
                          _reasons[selectedDoc.id] = reason;
                        });
                      },
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _ThumbnailStrip(
                    documents: driver.documents,
                    selectedId: selectedDoc?.id,
                    decisions: _decisions,
                    onSelect: (id) => setState(() => _selectedDocId = id),
                  ),
                ],
              ),
            ),
            _ActionBar(
              submitting: _submitting,
              confirmLabel: t.adminConfirmDriverButton,
              confirmEnabled: allRequiredOk,
              returnEnabled: anyProblem,
              hint: allRequiredOk ? null : t.adminVerificationMissingDocsHint,
              onConfirm: () => _confirm(driver),
              onReturn: () => _returnForRework(driver),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirm(AdminVerificationDriverProfile driver) async {
    final reason = await showReasonDialog(context, title: context.l10n.adminVerifyDialogTitle, confirmLabel: context.l10n.commonDone);
    if (reason == null || !mounted) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final toApprove = driver.documents.where((d) => _decisions[d.id] == true && d.status != VerificationStatus.approved);
      await Future.wait(toApprove.map((d) => repo.reviewDocument(d.id, approve: true)));
      await repo.setDriverVerified(driver.id, true, reason: reason, crossChecks: _crossChecks);
      ref.invalidate(adminVerificationQueueProvider('driver'));
      ref.invalidate(adminVerificationDriverProfileProvider(driver.id));
      ref.read(adminVerificationSelectedIdProvider.notifier).state = null;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _returnForRework(AdminVerificationDriverProfile driver) async {
    final note = await showReasonDialog(
      context,
      title: context.l10n.adminReturnForReworkDialogTitle,
      confirmLabel: context.l10n.adminReturnForReworkButton,
    );
    if (note == null || !mounted) return;
    final decisions = driver.documents
        .where((d) => _effectiveOk(_decisions, d) == false)
        .map((d) => VerificationReworkDecision(documentId: d.id, rejectReason: _reasons[d.id] ?? d.rejectReason ?? note))
        .toList();
    if (decisions.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(adminRepositoryProvider).returnDriverForRework(driver.id, decisions: decisions, note: note, crossChecks: _crossChecks);
      ref.invalidate(adminVerificationQueueProvider('driver'));
      ref.invalidate(adminVerificationDriverProfileProvider(driver.id));
      ref.read(adminVerificationSelectedIdProvider.notifier).state = null;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _CompanyDetailPane extends ConsumerStatefulWidget {
  const _CompanyDetailPane({super.key, required this.id});

  final String id;

  @override
  ConsumerState<_CompanyDetailPane> createState() => _CompanyDetailPaneState();
}

class _CompanyDetailPaneState extends ConsumerState<_CompanyDetailPane> {
  final _DocDecisions _decisions = {};
  final Map<String, String> _reasons = {};
  final Map<String, bool?> _crossChecks = {};
  String? _selectedDocId;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final profile = ref.watch(adminVerificationCompanyProfileProvider(widget.id));

    return profile.when(
      loading: () => const LoadingView(),
      error: (e, st) => ErrorView(
        message: t.commonError,
        retryLabel: t.commonRetry,
        onRetry: () => ref.invalidate(adminVerificationCompanyProfileProvider(widget.id)),
      ),
      data: (company) {
        final selectedDoc = company.documents.where((d) => d.id == _selectedDocId).firstOrNull ?? company.documents.firstOrNull;
        final allRequiredOk = _requiredCompanyDocTypes.every(
          (type) => company.documents.any((d) => d.type == type && _effectiveOk(_decisions, d) == true),
        );
        final anyProblem = company.documents.any((d) => _effectiveOk(_decisions, d) == false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _Header(
                    title: company.name,
                    isVerified: company.isVerified,
                    onOpenCard: () => context.push('/companies/${company.id}'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _CrossCheckCard(
                    rows: [
                      (key: 'name', label: t.adminCrossCheckCompanyName),
                      (key: 'taxId', label: t.adminCrossCheckCompanyTaxId),
                    ],
                    values: _crossChecks,
                    onChanged: (key, value) => setState(() => _crossChecks[key] = value),
                    extra: company.taxId,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (selectedDoc != null)
                    _BigViewer(
                      doc: selectedDoc,
                      compareUrl: null,
                      ok: _effectiveOk(_decisions, selectedDoc),
                      onOk: () => setState(() => _decisions[selectedDoc.id] = true),
                      onProblem: () async {
                        final reason = await showRejectReasonDialog(context);
                        if (reason == null) return;
                        setState(() {
                          _decisions[selectedDoc.id] = false;
                          _reasons[selectedDoc.id] = reason;
                        });
                      },
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _ThumbnailStrip(
                    documents: company.documents,
                    selectedId: selectedDoc?.id,
                    decisions: _decisions,
                    onSelect: (id) => setState(() => _selectedDocId = id),
                  ),
                ],
              ),
            ),
            _ActionBar(
              submitting: _submitting,
              confirmLabel: t.adminConfirmCompanyButton,
              confirmEnabled: allRequiredOk,
              returnEnabled: anyProblem,
              hint: allRequiredOk ? null : t.adminVerificationMissingDocsHint,
              onConfirm: () => _confirm(company),
              onReturn: () => _returnForRework(company),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirm(AdminVerificationCompanyProfile company) async {
    final reason = await showReasonDialog(context, title: context.l10n.adminVerifyDialogTitle, confirmLabel: context.l10n.commonDone);
    if (reason == null || !mounted) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final toApprove = company.documents.where((d) => _decisions[d.id] == true && d.status != VerificationStatus.approved);
      await Future.wait(toApprove.map((d) => repo.reviewDocument(d.id, approve: true)));
      await repo.setCompanyVerified(company.id, true, reason: reason, crossChecks: _crossChecks);
      ref.invalidate(adminVerificationQueueProvider('company'));
      ref.invalidate(adminVerificationCompanyProfileProvider(company.id));
      ref.read(adminVerificationSelectedIdProvider.notifier).state = null;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _returnForRework(AdminVerificationCompanyProfile company) async {
    final note = await showReasonDialog(
      context,
      title: context.l10n.adminReturnForReworkDialogTitle,
      confirmLabel: context.l10n.adminReturnForReworkButton,
    );
    if (note == null || !mounted) return;
    final decisions = company.documents
        .where((d) => _effectiveOk(_decisions, d) == false)
        .map((d) => VerificationReworkDecision(documentId: d.id, rejectReason: _reasons[d.id] ?? d.rejectReason ?? note))
        .toList();
    if (decisions.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(adminRepositoryProvider).returnCompanyForRework(company.id, decisions: decisions, note: note, crossChecks: _crossChecks);
      ref.invalidate(adminVerificationQueueProvider('company'));
      ref.invalidate(adminVerificationCompanyProfileProvider(company.id));
      ref.read(adminVerificationSelectedIdProvider.notifier).state = null;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.isVerified, required this.onOpenCard});

  final String title;
  final bool isVerified;
  final VoidCallback onOpenCard;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 12),
              if (isVerified) StatusBadge(label: t.adminVerified, color: StatusBadge.success),
            ],
          ),
        ),
        TextButton(onPressed: onOpenCard, child: Text(t.adminVerificationOpenCard)),
      ],
    );
  }
}

class _CrossCheckCard extends StatelessWidget {
  const _CrossCheckCard({required this.rows, required this.values, required this.onChanged, this.extra});

  final List<({String key, String label})> rows;
  final Map<String, bool?> values;
  final void Function(String key, bool value) onChanged;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminVerificationCrossCheckTitle, style: Theme.of(context).textTheme.titleMedium),
          if (extra != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(extra!, style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(row.label)),
                  ChoiceChip(
                    label: Text(t.adminCrossCheckMatch),
                    selected: values[row.key] == true,
                    onSelected: (_) => onChanged(row.key, true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(t.adminCrossCheckMismatch),
                    selected: values[row.key] == false,
                    onSelected: (_) => onChanged(row.key, false),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BigViewer extends StatelessWidget {
  const _BigViewer({required this.doc, required this.compareUrl, required this.ok, required this.onOk, required this.onProblem});

  final AdminCardDocument doc;
  final String? compareUrl;
  final bool? ok;
  final VoidCallback onOk;
  final VoidCallback onProblem;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final (statusLabel, statusColor) = verificationStatusPresentation(t, doc.status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(verificationDocTypeLabel(t, doc.type), style: Theme.of(context).textTheme.titleMedium)),
              StatusBadge(label: statusLabel, color: statusColor),
              IconButton(
                icon: const Icon(LucideIcons.maximize2),
                tooltip: t.adminVerificationCompareWithSelfie,
                onPressed: () => openDocumentViewer(context, doc.fileUrl, compareUrl: compareUrl, compareLabel: t.adminVerificationCompareWithSelfie),
              ),
            ],
          ),
          if (doc.rejectReason != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(doc.rejectReason!, style: const TextStyle(color: StatusBadge.danger))),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 380,
              width: double.infinity,
              child: ColoredBox(
                color: Colors.black,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  trackpadScrollCausesScale: true,
                  child: AdminDocumentImage(url: doc.fileUrl, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: ok == true ? FilledButton.styleFrom(backgroundColor: StatusBadge.success) : null,
                  onPressed: onOk,
                  child: Text(t.adminApprove),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: ok == false ? OutlinedButton.styleFrom(foregroundColor: StatusBadge.danger, side: const BorderSide(color: StatusBadge.danger)) : null,
                  onPressed: onProblem,
                  child: Text(t.adminReject),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({required this.documents, required this.selectedId, required this.decisions, required this.onSelect});

  final List<AdminCardDocument> documents;
  final String? selectedId;
  final _DocDecisions decisions;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: documents.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final doc = documents[index];
          final ok = _effectiveOk(decisions, doc);
          final dotColor = ok == true ? StatusBadge.success : ok == false ? StatusBadge.danger : StatusBadge.warning;
          return GestureDetector(
            onTap: () => onSelect(doc.id),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: doc.id == selectedId ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(width: 72, height: 72, child: AdminDocumentImage(url: doc.fileUrl)),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.submitting,
    required this.confirmLabel,
    required this.confirmEnabled,
    required this.returnEnabled,
    required this.hint,
    required this.onConfirm,
    required this.onReturn,
  });

  final bool submitting;
  final String confirmLabel;
  final bool confirmEnabled;
  final bool returnEnabled;
  final String? hint;
  final VoidCallback onConfirm;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hint != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(hint!, style: Theme.of(context).textTheme.bodySmall)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: submitting || !returnEnabled ? null : onReturn,
                    child: Text(t.adminReturnForReworkButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: submitting || !confirmEnabled ? null : onConfirm,
                    child: submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
