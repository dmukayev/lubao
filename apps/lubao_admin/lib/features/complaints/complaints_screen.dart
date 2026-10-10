import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../shared/admin_status_helpers.dart';
import '../shared/responsive.dart';
import 'complaint_resolve_dialog.dart';

/// Жалобы (задача 028, этап E): вкладки Новые/В работе/Закрытые (раньше
/// список спрашивал только `status=OPEN`, и жалоба пропадала из вида после
/// «В работе»), слева очередь, справа — карточка с контекстом и решением.
class ComplaintsScreen extends ConsumerWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final selectedId = ref.watch(adminComplaintSelectedIdProvider);

    final isMobile = isMobileWidth(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminComplaintsTitle),
        leading: isMobile && selectedId != null
            ? BackButton(onPressed: () => ref.read(adminComplaintSelectedIdProvider.notifier).state = null)
            : null,
      ),
      body: ResponsiveMasterDetail(
        hasSelection: selectedId != null,
        master: _Queue(),
        detail: selectedId == null
            ? EmptyState(message: t.adminComplaintSelectHint, icon: LucideIcons.flag)
            : _Detail(key: ValueKey(selectedId), id: selectedId),
      ),
    );
  }
}

class _Queue extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final tab = ref.watch(adminComplaintsTabProvider);
    final mine = ref.watch(adminComplaintsMineProvider);
    final counts = ref.watch(adminComplaintCountsProvider);
    final complaints = ref.watch(complaintsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: counts.when(
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
            data: (c) => SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'NEW', label: Text('${t.adminComplaintTabNew} · ${c.newCount}')),
                ButtonSegment(value: 'IN_REVIEW', label: Text('${t.adminComplaintTabInReview} · ${c.inReviewCount}')),
                ButtonSegment(value: 'CLOSED', label: Text('${t.adminComplaintTabClosed} · ${c.closedCount}')),
              ],
              selected: {tab},
              onSelectionChanged: (s) {
                ref.read(adminComplaintsTabProvider.notifier).state = s.first;
                ref.read(adminComplaintSelectedIdProvider.notifier).state = null;
              },
            ),
          ),
        ),
        CheckboxListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          value: mine,
          title: Text(t.adminComplaintMineFilter),
          onChanged: (v) => ref.read(adminComplaintsMineProvider.notifier).state = v ?? false,
        ),
        const Divider(height: 1),
        Expanded(
          child: complaints.when(
            loading: () => const LoadingView(),
            error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(complaintsProvider)),
            data: (list) {
              if (list.isEmpty) return EmptyState(message: t.adminComplaintsEmpty, icon: LucideIcons.flag);
              final selectedId = ref.watch(adminComplaintSelectedIdProvider);
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final c = list[index];
                  return ListTile(
                    selected: c.id == selectedId,
                    title: Text(c.reason, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(c.target?.title ?? c.targetType),
                    trailing: Text(formatAdminDate(c.createdAt)),
                    onTap: () => ref.read(adminComplaintSelectedIdProvider.notifier).state = c.id,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({super.key, required this.id});

  final String id;

  Future<void> _reload(WidgetRef ref) async {
    ref.invalidate(adminComplaintDetailProvider(id));
    ref.invalidate(complaintsProvider);
    ref.invalidate(adminComplaintCountsProvider);
  }

  Future<void> _assign(WidgetRef ref) async {
    await ref.read(adminRepositoryProvider).assignComplaint(id);
    await _reload(ref);
  }

  Future<void> _unassign(WidgetRef ref) async {
    await ref.read(adminRepositoryProvider).unassignComplaint(id);
    await _reload(ref);
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref, String targetType) async {
    final result = await showComplaintResolveDialog(context, targetType: targetType);
    if (result == null) return;
    try {
      await ref.read(adminRepositoryProvider).resolveComplaint(id, resolution: result.resolution, resolutionNote: result.resolutionNote);
    } catch (e) {
      // Сервер отказал (например, «нечего снимать / некого блокировать») —
      // причина на экране, а не тишина.
      debugPrint('ComplaintDetail: resolve failed: $e');
      if (context.mounted) {
        final data = e is DioException ? e.response?.data : null;
        final reason = data is Map ? data['message']?.toString() : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text([context.l10n.commonError, ?reason].join(': '))));
      }
      return;
    }
    await _reload(ref);
    ref.read(adminComplaintSelectedIdProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final detailAsync = ref.watch(adminComplaintDetailProvider(id));

    return detailAsync.when(
      loading: () => const LoadingView(),
      error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminComplaintDetailProvider(id))),
      data: (detail) {
        final c = detail.complaint;
        final isClosed = c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.reason, style: Theme.of(context).textTheme.headlineSmall),
              if (c.description != null) ...[
                const SizedBox(height: 8),
                Text(c.description!),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _PartyCard(title: t.adminComplaintReporter, target: c.reporter, name: c.reporterName)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PartyCard(
                      title: t.adminComplaintTarget,
                      target: c.target,
                      name: c.target?.title ?? c.targetType,
                      extra: detail.violatorComplaintsLastMonth > 0 ? t.adminComplaintMoreThisMonth(detail.violatorComplaintsLastMonth) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (detail.cargo != null) _CargoContextCard(cargo: detail.cargo!),
              if (detail.deal != null) _DealContextCard(deal: detail.deal!),
              if (detail.message != null) _MessageContextCard(message: detail.message!),
              const SizedBox(height: 16),
              if (!isClosed)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (c.assignedToUserId != null) ...[
                        Row(
                          children: [
                            Expanded(child: Text(t.adminComplaintAssignedTo(c.assignedToName ?? ''))),
                            const SizedBox(width: 12),
                            OutlinedButton(onPressed: () => _unassign(ref), child: Text(t.adminComplaintReturnToNew)),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Задача 030 — Row(..., Spacer(), ...) с обычным
                      // (не-Expanded) FilledButton падал с «BoxConstraints
                      // forces an infinite width» при открытии карточки
                      // жалобы (поймано живой проверкой в браузере, баг
                      // из задачи 028, не зависел от ширины экрана). У
                      // FilledButton/OutlinedButton в теме minimumSize на
                      // всю ширину (Size.fromHeight) — тот же паттерн
                      // Expanded-кнопок 50/50, что в _ActionBar проверки,
                      // безопасен и для Row с неопределённой шириной.
                      Row(
                        children: [
                          if (c.assignedToUserId == null) ...[
                            Expanded(child: FilledButton(onPressed: () => _assign(ref), child: Text(t.adminComplaintTakeOver))),
                            const SizedBox(width: 12),
                          ],
                          Expanded(child: FilledButton(onPressed: () => _resolve(context, ref, c.targetType), child: Text(t.adminComplaintResolveButton))),
                        ],
                      ),
                    ],
                  ),
                )
              else
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.adminComplaintResolutionTitle, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(complaintResolutionLabel(t, c.resolution ?? '')),
                      if (c.resolutionNote != null) ...[
                        const SizedBox(height: 4),
                        Text(c.resolutionNote!),
                      ],
                      if (c.resolvedByName != null && c.resolvedAt != null) ...[
                        const SizedBox(height: 8),
                        Text('${c.resolvedByName} · ${formatAdminDateTime(c.resolvedAt!)}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.title, required this.target, required this.name, this.extra});

  final String title;
  final AdminComplaintTarget? target;
  final String name;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          if (target != null && (target!.driverId != null || target!.companyId != null))
            InkWell(
              onTap: () => target!.driverId != null ? context.push('/drivers/${target!.driverId}') : context.push('/companies/${target!.companyId}'),
              child: Text(name, style: const TextStyle(decoration: TextDecoration.underline)),
            )
          else
            Text(name),
          if (extra != null) ...[
            const SizedBox(height: 4),
            Text(extra!, style: const TextStyle(color: StatusBadge.danger)),
          ],
        ],
      ),
    );
  }
}

class _CargoContextCard extends StatelessWidget {
  const _CargoContextCard({required this.cargo});

  final AdminComplaintContextCargo cargo;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: InkWell(
          onTap: () => context.push('/cargos/${cargo.id}'),
          child: Row(
            children: [
              Expanded(child: Text('${t.adminColRoute}: ${cargo.pointName.forLanguageCode(locale)} · ${cargo.companyName}')),
              Text(formatMoney(cargo.price, currencyFromJson(cargo.currency))),
            ],
          ),
        ),
      ),
    );
  }
}

class _DealContextCard extends StatelessWidget {
  const _DealContextCard({required this.deal});

  final AdminComplaintContextDeal deal;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: InkWell(
          onTap: () => context.push('/deals/${deal.id}'),
          child: Row(
            children: [
              Expanded(child: Text('${deal.driverName} · ${deal.companyName}')),
              Text(dealStatusLabel(t, deal.status)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageContextCard extends StatelessWidget {
  const _MessageContextCard({required this.message});

  final AdminComplaintContextMessage message;

  @override
  Widget build(BuildContext context) {
    final translation = message.translations?.values.whereType<String>().firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.originalText),
            if (translation != null) Text(translation, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
