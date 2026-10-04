import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ComplaintsScreen extends ConsumerWidget {
  const ComplaintsScreen({super.key});

  Future<void> _update(WidgetRef ref, String id, ComplaintStatus status) async {
    await ref.read(adminRepositoryProvider).resolveComplaint(id, status);
    ref.invalidate(complaintsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final complaints = ref.watch(complaintsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminComplaintsTitle)),
      body: complaints.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('ComplaintsScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(complaintsProvider));
        },
        data: (list) {
          if (list.isEmpty) return EmptyState(message: t.adminComplaintsEmpty, icon: LucideIcons.flag);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(complaintsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final complaint = list[index];
                final target = complaint.target;
                final reporter = complaint.reporter;
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(complaint.reason, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text('${t.adminComplaintReporter}:'),
                          if (reporter != null && (reporter.driverId != null || reporter.companyId != null))
                            InkWell(
                              onTap: () => _openCard(context, driverId: reporter.driverId, companyId: reporter.companyId),
                              child: Text(complaint.reporterName, style: const TextStyle(decoration: TextDecoration.underline)),
                            )
                          else
                            Text(complaint.reporterName),
                          const Text('·'),
                          Text('${t.adminComplaintTarget}:'),
                          if (target != null && (target.driverId != null || target.companyId != null))
                            InkWell(
                              onTap: () => _openCard(context, driverId: target.driverId, companyId: target.companyId),
                              child: Text(target.title, style: const TextStyle(decoration: TextDecoration.underline)),
                            )
                          else
                            Text(target?.title ?? complaint.targetType),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _update(ref, complaint.id, ComplaintStatus.inReview),
                              child: Text(t.adminMarkInReview),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _update(ref, complaint.id, ComplaintStatus.resolved),
                              child: Text(t.adminResolve),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Переход на карточку нарушителя/заявителя (задача 026, п.14) — оба
  /// резолвятся на бэкенде через один и тот же complaintTarget('USER', ...).
  void _openCard(BuildContext context, {String? driverId, String? companyId}) {
    if (driverId != null) {
      context.push('/drivers/$driverId');
    } else if (companyId != null) {
      context.push('/companies/$companyId');
    }
  }
}
