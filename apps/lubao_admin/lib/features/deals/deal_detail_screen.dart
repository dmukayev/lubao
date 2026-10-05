import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../shared/admin_dialogs.dart';
import '../shared/admin_status_helpers.dart';
import '../shared/audit_log_tab.dart';

const _progression = ['SELECTED', 'CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED'];

/// Карточка сделки (задача 028, п.17): история статусов, звонки, переписка
/// только для просмотра, «Исправить статус» (только соседний), «Отменить».
class DealDetailScreen extends ConsumerWidget {
  const DealDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _reload(WidgetRef ref) async => ref.invalidate(adminDealDetailProvider(id));

  Future<void> _fixStatus(BuildContext context, WidgetRef ref, AdminDealDetail deal) async {
    final result = await showDealStatusFixDialog(context, currentStatus: deal.status);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).advanceDealStatus(id, status: result.status, reason: result.reason);
    await _reload(ref);
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final reason = await showReasonDialog(context, title: t.adminDealCancelDialogTitle, confirmLabel: t.adminDealCancel, danger: true);
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).cancelDeal(id, reason: reason);
    await _reload(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dealAsync = ref.watch(adminDealDetailProvider(id));

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/deals'))),
      body: dealAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('DealDetailScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => _reload(ref));
        },
        data: (deal) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                deal: deal,
                locale: locale,
                onFixStatus: () => _fixStatus(context, ref, deal),
                onCancel: () => _cancel(context, ref),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _PartyCard(title: t.adminColDriver, name: deal.driverName, onTap: () => context.push('/drivers/${deal.driverId}'))),
                  const SizedBox(width: 16),
                  Expanded(child: _PartyCard(title: t.adminColCompany, name: deal.companyName, onTap: () => context.push('/companies/${deal.companyId}'))),
                ],
              ),
              const SizedBox(height: 16),
              _StatusHistoryCard(history: deal.statusHistory),
              const SizedBox(height: 16),
              _DealTabs(dealId: id, deal: deal),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.deal, required this.locale, required this.onFixStatus, required this.onCancel});

  final AdminDealDetail deal;
  final String locale;
  final VoidCallback onFixStatus;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final route = '${deal.pointName.forLanguageCode(locale)} → ${deal.destinationCountryName.forLanguageCode(locale)}';
    final (statusLabel, statusColor) = dealStatusPresentation(t, dealStatusFromJson(deal.status));
    final isTerminal = deal.status == 'DELIVERED' || deal.status == 'CANCELLED';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: Text(route, style: Theme.of(context).textTheme.headlineSmall)),
              const SizedBox(width: 12),
              StatusBadge(label: statusLabel, color: statusColor),
              if (deal.staleDays > 0) ...[
                const SizedBox(width: 8),
                StatusBadge(label: t.adminStaleDays(deal.staleDays), color: StatusBadge.danger),
              ],
            ],
          ),
          if (!isTerminal) ...[
            const SizedBox(height: 12),
            // Задача 031 (ревью белых экранов) — кнопки вынесены из строки
            // заголовка в свой Wrap: голый FilledButton/OutlinedButton рядом
            // с Expanded в одном Row падает с «BoxConstraints forces an
            // infinite width» (задачи 030/031); компактный minimumSize —
            // иначе в Wrap каждая кнопка требует всю ширину строки.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, AppSizes.buttonHeight)),
                  onPressed: onFixStatus,
                  child: Text(t.adminDealFixStatus),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: StatusBadge.danger, minimumSize: const Size(0, AppSizes.buttonHeight)),
                  onPressed: onCancel,
                  child: Text(t.adminDealCancel),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: () => context.push('/cargos/${deal.cargoId}'),
            child: Text(t.adminDealOpenCargo, style: const TextStyle(decoration: TextDecoration.underline)),
          ),
          const SizedBox(height: 4),
          Text(
            deal.priceInKzt != null
                ? '${formatMoney(deal.price, currencyFromJson(deal.currency))} (≈ ${formatMoney(deal.priceInKzt!, Currency.kzt)})'
                : formatMoney(deal.price, currencyFromJson(deal.currency)),
          ),
          if (deal.cancelReason != null) ...[
            const SizedBox(height: 8),
            Text('${t.adminDealCancelledBy(cancelledByRoleLabel(t, deal.cancelledByRole ?? ''))}: ${deal.cancelReason}', style: const TextStyle(color: StatusBadge.danger)),
          ],
        ],
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.title, required this.name, required this.onTap});

  final String title;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          InkWell(onTap: onTap, child: Text(name, style: const TextStyle(decoration: TextDecoration.underline))),
        ],
      ),
    );
  }
}

class _StatusHistoryCard extends StatelessWidget {
  const _StatusHistoryCard({required this.history});

  final List<AdminDealStatusHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminDealStatusHistoryTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final e in history)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [Expanded(child: Text(dealStatusLabel(t, e.status))), Text(formatAdminDateTime(e.at))]),
            ),
        ],
      ),
    );
  }
}

class _DealTabs extends StatefulWidget {
  const _DealTabs({required this.dealId, required this.deal});

  final String dealId;
  final AdminDealDetail deal;

  @override
  State<_DealTabs> createState() => _DealTabsState();
}

class _DealTabsState extends State<_DealTabs> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(controller: _controller, isScrollable: true, tabs: [Tab(text: t.adminDealTabChat), Tab(text: t.adminDealTabCalls), Tab(text: t.adminTabLog)]),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _controller,
              children: [
                _ChatTab(dealId: widget.dealId),
                _CallsTab(calls: widget.deal.calls),
                AuditLogTab(entries: widget.deal.auditLog),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Переписка подгружается только по явному нажатию (п.17 — каждое открытие
/// пишется в audit_log на бэкенде именно в момент запроса).
class _ChatTab extends ConsumerStatefulWidget {
  const _ChatTab({required this.dealId});

  final String dealId;

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (!_opened) {
      return Center(child: FilledButton(onPressed: () => setState(() => _opened = true), child: Text(t.adminDealShowChat)));
    }
    final messagesAsync = ref.watch(adminDealChatProvider(widget.dealId));
    return messagesAsync.when(
      loading: () => const LoadingView(),
      error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminDealChatProvider(widget.dealId))),
      data: (messages) {
        if (messages.isEmpty) return Center(child: Text(t.adminNoChat));
        return ListView.separated(
          itemCount: messages.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final m = messages[i];
            final translation = m.translations?.values.whereType<String>().firstOrNull;
            return ListTile(
              title: Text(m.originalText),
              subtitle: translation != null ? Text(translation, style: Theme.of(context).textTheme.bodySmall) : null,
              trailing: Text(formatAdminDateTime(m.createdAt)),
            );
          },
        );
      },
    );
  }
}

class _CallsTab extends StatelessWidget {
  const _CallsTab({required this.calls});

  final List<AdminDealCallEntry> calls;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (calls.isEmpty) return Center(child: Text(t.adminNoCalls));
    return ListView.separated(
      itemCount: calls.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, i) {
        final c = calls[i];
        return ListTile(title: Text(contactEventTypeLabel(t, c.type)), trailing: Text(formatAdminDateTime(c.createdAt)));
      },
    );
  }
}

class DealStatusFixResult {
  const DealStatusFixResult({required this.status, required this.reason});

  final String status;
  final String reason;
}

Future<DealStatusFixResult?> showDealStatusFixDialog(BuildContext context, {required String currentStatus}) {
  final currentIndex = _progression.indexOf(currentStatus);
  final options = [
    if (currentIndex > 0) _progression[currentIndex - 1],
    if (currentIndex < _progression.length - 1) _progression[currentIndex + 1],
  ];
  return showDialog<DealStatusFixResult>(
    context: context,
    builder: (dialogContext) => _DealStatusFixDialog(options: options),
  );
}

class _DealStatusFixDialog extends StatefulWidget {
  const _DealStatusFixDialog({required this.options});

  final List<String> options;

  @override
  State<_DealStatusFixDialog> createState() => _DealStatusFixDialogState();
}

class _DealStatusFixDialogState extends State<_DealStatusFixDialog> {
  late String _status = widget.options.first;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return StatefulBuilder(
      builder: (context, setState) {
        final canConfirm = _reasonController.text.trim().isNotEmpty;
        return AlertDialog(
          title: Text(t.adminDealFixStatusDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in widget.options)
                RadioListTile<String>(
                  value: s,
                  groupValue: _status,
                  title: Text(dealStatusLabel(t, s)),
                  onChanged: (v) => setState(() => _status = v!),
                ),
              const SizedBox(height: 8),
              AppTextField(label: t.adminReasonLabel, controller: _reasonController, maxLines: 2, onChanged: (_) => setState(() {})),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.commonCancel)),
            FilledButton(
              onPressed: canConfirm ? () => Navigator.pop(context, DealStatusFixResult(status: _status, reason: _reasonController.text.trim())) : null,
              child: Text(t.commonSave),
            ),
          ],
        );
      },
    );
  }
}
