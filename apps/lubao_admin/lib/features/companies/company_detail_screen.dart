import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../shared/cancellations_card.dart';
import '../shared/admin_dialogs.dart';
import '../shared/admin_document_image.dart';
import '../shared/admin_status_helpers.dart';
import '../shared/audit_log_tab.dart';
import '../shared/document_viewer.dart';
import '../shared/identifiers_card.dart';
import 'company_edit_panel.dart';

class CompanyDetailScreen extends ConsumerWidget {
  const CompanyDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _reload(WidgetRef ref) async => ref.invalidate(adminCompanyDetailProvider(id));

  Future<void> _block(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final reason = await showReasonDialog(context, title: t.adminBlockCompanyConfirmTitle, confirmLabel: t.adminBlock, danger: true);
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).blockCompany(id, reason: reason);
    await _reload(ref);
  }

  Future<void> _unblock(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final reason = await showReasonDialog(context, title: t.adminUnblockConfirmTitle, confirmLabel: t.adminUnblock);
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).unblockCompany(id, reason: reason);
    await _reload(ref);
  }

  Future<void> _toggleVerified(BuildContext context, WidgetRef ref, AdminCompanyDetail company) async {
    final t = context.l10n;
    final settingVerified = !company.isVerified;
    final result = await showVerifyDialog(context, settingVerified: settingVerified, offerForce: settingVerified);
    if (result == null) return;
    try {
      await ref.read(adminRepositoryProvider).setCompanyVerified(id, settingVerified, reason: result.reason, force: result.force);
      await _reload(ref);
    } on BlacklistMatchException catch (e) {
      if (!context.mounted) return;
      final override = await showBlacklistMatchDialog(context, e.blocks);
      if (!override || !context.mounted) return;
      try {
        await ref.read(adminRepositoryProvider).setCompanyVerified(id, settingVerified, reason: result.reason, force: true);
        await _reload(ref);
      } on Exception catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.adminVerifyMissingDocsError)));
      }
    } on Exception catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.adminVerifyMissingDocsError)));
    }
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.adminResetPasswordConfirmTitle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.commonDone)),
        ],
      ),
    );
    if (confirmed != true) return;
    final tempPassword = await ref.read(adminRepositoryProvider).resetCompanyPassword(id);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.adminResetPasswordDialogTitle),
        content: SelectableText(tempPassword),
        actions: [
          TextButton(
            onPressed: () {
              copyToClipboardWithToast(dialogContext, tempPassword, t.adminCopied);
            },
            child: Text(t.employeesInviteCopyLink),
          ),
          FilledButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonDone)),
        ],
      ),
    );
  }

  Future<void> _reviewDocument(BuildContext context, WidgetRef ref, AdminCardDocument doc, {required bool approve}) async {
    String? reason;
    if (!approve) {
      reason = await showRejectReasonDialog(context);
      if (reason == null) return;
    }
    await ref.read(adminRepositoryProvider).reviewDocument(doc.id, approve: approve, rejectReason: reason);
    await _reload(ref);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, AdminCompanyDetail company) async {
    final refData = await ref.read(referenceDataProvider.future);
    if (!context.mounted) return;
    final result = await showCompanyEditPanel(context, company: company, refData: refData);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).updateCompany(
          id,
          name: result.name,
          nameRu: result.nameRu,
          countryId: result.countryId,
          city: result.city,
          legalAddress: result.legalAddress,
          taxId: result.taxId,
          reason: result.reason,
        );
    await _reload(ref);
  }

  Future<void> _changeMemberRole(BuildContext context, WidgetRef ref, AdminEmployeeEntry member) async {
    final t = context.l10n;
    final newRole = member.role == 'OWNER' ? 'LOGIST' : 'OWNER';
    final title = newRole == 'OWNER' ? t.adminTransferOwnershipTitle : t.adminDemoteToLogistTitle;
    final reason = await showReasonDialog(context, title: title, confirmLabel: t.commonDone);
    if (reason == null) return;
    try {
      await ref.read(adminRepositoryProvider).setMemberRole(id, member.userId, newRole, reason: reason);
      await _reload(ref);
    } on Exception catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.adminLastOwnerError)));
    }
  }

  Future<void> _removeMember(BuildContext context, WidgetRef ref, AdminEmployeeEntry member) async {
    final t = context.l10n;
    final reason = await showReasonDialog(context, title: t.adminRemoveMemberTitle, confirmLabel: t.adminRemoveMember, danger: true);
    if (reason == null) return;
    try {
      await ref.read(adminRepositoryProvider).removeMember(id, member.userId, reason: reason);
      await _reload(ref);
    } on Exception catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.adminLastOwnerError)));
    }
  }

  Future<void> _changeMemberEmail(BuildContext context, WidgetRef ref, AdminEmployeeEntry member) async {
    final t = context.l10n;
    final emailController = TextEditingController(text: member.email ?? '');
    final reasonController = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final canConfirm = emailController.text.trim().isNotEmpty && reasonController.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text(t.adminChangeMemberEmailTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: t.companyLoginEmailLabel, controller: emailController, onChanged: (_) => setState(() {})),
                const SizedBox(height: 12),
                AppTextField(label: t.adminReasonLabel, controller: reasonController, maxLines: 2, onChanged: (_) => setState(() {})),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
              FilledButton(
                onPressed: canConfirm ? () => Navigator.pop(dialogContext, (emailController.text.trim(), reasonController.text.trim())) : null,
                child: Text(t.commonSave),
              ),
            ],
          );
        },
      ),
    );
    if (result == null) return;
    try {
      await ref.read(adminRepositoryProvider).changeMemberEmail(id, member.userId, result.$1, reason: result.$2);
      await _reload(ref);
    } on Exception catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.adminEmailTakenError)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final companyAsync = ref.watch(adminCompanyDetailProvider(id));

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/companies'))),
      body: companyAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('CompanyDetailScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => _reload(ref));
        },
        data: (company) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                company: company,
                onEdit: () => _edit(context, ref, company),
                onBlock: () => _block(context, ref),
                onUnblock: () => _unblock(context, ref),
                onResetPassword: () => _resetPassword(context, ref),
                onToggleVerified: () => _toggleVerified(context, ref, company),
              ),
              const SizedBox(height: 16),
              _StatsRow(company: company),
              CancellationsCard(stats: company.cancelStats, items: company.cancellations),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DocumentsCard(
                          documents: company.documents,
                          onApprove: (doc) => _reviewDocument(context, ref, doc, approve: true),
                          onReject: (doc) => _reviewDocument(context, ref, doc, approve: false),
                        ),
                        const SizedBox(height: 16),
                        _LegalCard(company: company, locale: locale),
                        const SizedBox(height: 16),
                        IdentifiersCard(identifiers: company.identifiers, blockHistory: company.identifierBlockHistory),
                        const SizedBox(height: 16),
                        _EmployeesCard(
                          company: company,
                          onChangeRole: (m) => _changeMemberRole(context, ref, m),
                          onRemove: (m) => _removeMember(context, ref, m),
                          onChangeEmail: (m) => _changeMemberEmail(context, ref, m),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _CompanyTabs(company: company)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.company, required this.onEdit, required this.onBlock, required this.onUnblock, required this.onResetPassword, required this.onToggleVerified});

  final AdminCompanyDetail company;
  final VoidCallback onEdit;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onResetPassword;
  final VoidCallback onToggleVerified;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    // Задача 031 (ревью белых экранов) — заголовок раньше падал с
    // «BoxConstraints forces an infinite width» (голые OutlinedButton рядом
    // с Expanded(Column) в одном Row — тот же баг, что в
    // complaints_screen.dart/driver_detail_screen.dart, задачи 030/031);
    // действия вынесены в свой Wrap под информацией, с компактным
    // minimumSize — иначе в Wrap каждая кнопка требует всю ширину строки и
    // встаёт вертикальным столбиком.
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: Text(company.name, style: Theme.of(context).textTheme.headlineSmall)),
              const SizedBox(width: 12),
              if (company.isBlocked)
                StatusBadge(label: t.adminBlockedBadge, color: StatusBadge.danger)
              else
                StatusBadge(
                  label: company.isVerified ? t.adminVerified : t.adminNotVerified,
                  color: company.isVerified ? StatusBadge.success : StatusBadge.neutral,
                ),
            ],
          ),
          if (company.nameRu != null) Text(company.nameRu!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(company.countryName.forLanguageCode(Localizations.localeOf(context).languageCode)),
          if (company.taxId != null) Text('${t.adminCode}: ${company.taxId}'),
          // 052 п.7: сколько людей привели ссылками «Поделиться» сотрудники компании.
          Text(
            t.adminShareStats(company.shareStats.links, company.shareStats.opens, company.shareStats.came),
            key: const Key('adminCompanyShareStats'),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, AppSizes.buttonHeight)),
                onPressed: onEdit,
                child: Text(t.adminEdit),
              ),
              if (company.isBlocked)
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
                  child: Text(t.adminBlockCompany),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'reset_password') onResetPassword();
                  if (value == 'toggle_verified') onToggleVerified();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'reset_password', child: Text(t.adminResetPassword)),
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
  const _StatsRow({required this.company});

  final AdminCompanyDetail company;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Row(
        children: [
          _Stat(label: t.adminStatCargosPublished, value: '${company.cargos.length}'),
          _Stat(label: t.adminStatDealsActive, value: '${company.deals.length}'),
          _Stat(label: t.adminColEmployees, value: '${company.employees.length}'),
          _Stat(label: t.adminColRating, value: '★ ${formatRating(company.ratingAvg, company.ratingCount)} (${company.ratingCount})'),
          _Stat(label: t.adminStatComplaints, value: '${company.complaintsAgainst}'),
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
            Row(
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
                      Builder(builder: (context) {
                        final (label, color) = verificationStatusPresentation(t, doc.status);
                        return StatusBadge(label: label, color: color);
                      }),
                    ],
                  ),
                ),
                if (doc.status == VerificationStatus.pending) ...[
                  IconButton(icon: const Icon(LucideIcons.check, color: StatusBadge.success), onPressed: () => onApprove(doc)),
                  IconButton(icon: const Icon(LucideIcons.x, color: StatusBadge.danger), onPressed: () => onReject(doc)),
                ],
              ],
            ),
            const Divider(),
          ],
        ],
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard({required this.company, required this.locale});

  final AdminCompanyDetail company;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminLegalDetails, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (company.city != null) Text(company.city!),
          if (company.legalAddress != null) Text(company.legalAddress!),
          if (company.taxId != null) Text(company.taxId!),
        ],
      ),
    );
  }
}

class _EmployeesCard extends StatelessWidget {
  const _EmployeesCard({required this.company, required this.onChangeRole, required this.onRemove, required this.onChangeEmail});

  final AdminCompanyDetail company;
  final void Function(AdminEmployeeEntry) onChangeRole;
  final void Function(AdminEmployeeEntry) onRemove;
  final void Function(AdminEmployeeEntry) onChangeEmail;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.profileMembers, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final e in company.employees)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.name ?? e.email ?? e.userId),
              subtitle: Text(e.role),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (e.isBlocked) StatusBadge(label: t.adminBlockedBadge, color: StatusBadge.danger),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'role') onChangeRole(e);
                      if (value == 'remove') onRemove(e);
                      if (value == 'email') onChangeEmail(e);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'role', child: Text(e.role == 'OWNER' ? t.adminDemoteToLogistTitle : t.adminTransferOwnershipTitle)),
                      PopupMenuItem(value: 'email', child: Text(t.adminChangeMemberEmailTitle)),
                      PopupMenuItem(value: 'remove', child: Text(t.adminRemoveMember)),
                    ],
                  ),
                ],
              ),
            ),
          if (company.invites.isNotEmpty) ...[
            const Divider(),
            Text(t.adminInvites, style: Theme.of(context).textTheme.titleSmall),
            for (final i in company.invites)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(i.email),
                subtitle: Text('${i.role} · ${i.usedAt != null ? t.adminInviteUsed : formatAdminDate(i.expiresAt)}'),
              ),
          ],
        ],
      ),
    );
  }
}

class _CompanyTabs extends StatefulWidget {
  const _CompanyTabs({required this.company});

  final AdminCompanyDetail company;

  @override
  State<_CompanyTabs> createState() => _CompanyTabsState();
}

class _CompanyTabsState extends State<_CompanyTabs> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final company = widget.company;
    final locale = Localizations.localeOf(context).languageCode;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _controller,
            isScrollable: true,
            tabs: [Tab(text: t.adminTabCargos), Tab(text: t.adminTabDeals), Tab(text: t.adminTabReviews), Tab(text: t.adminTabLog)],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _controller,
              children: [
                _CargosTab(cargos: company.cargos, locale: locale),
                _DealsTab(deals: company.deals),
                _ReviewsTab(reviews: company.reviews),
                AuditLogTab(entries: company.auditLog),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CargosTab extends StatelessWidget {
  const _CargosTab({required this.cargos, required this.locale});

  final List<AdminCargoEntry> cargos;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (cargos.isEmpty) return Center(child: Text(t.adminNoCargos));
    return ListView.separated(
      itemCount: cargos.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, i) {
        final c = cargos[i];
        return ListTile(
          title: Text('${c.pointName.forLanguageCode(locale)} → ${c.destinationCountryName.forLanguageCode(locale)}'),
          subtitle: Text(formatMoney(c.price, currencyFromJson(c.currency))),
          trailing: Text('${c.responseCount}'),
        );
      },
    );
  }
}

class _DealsTab extends StatelessWidget {
  const _DealsTab({required this.deals});

  final List<AdminCompanyDealEntry> deals;

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
          title: InkWell(onTap: () => context.push('/drivers/${deal.driverId}'), child: Text(deal.driverName, style: const TextStyle(decoration: TextDecoration.underline))),
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
        return ListTile(title: Text('★ ${r.rating}'), subtitle: r.comment != null ? Text(r.comment!) : null, trailing: Text(formatAdminDate(r.createdAt)));
      },
    );
  }
}

