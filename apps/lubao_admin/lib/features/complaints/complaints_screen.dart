import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(complaintsProvider)),
        data: (list) {
          if (list.isEmpty) return EmptyState(message: t.adminComplaintsEmpty, icon: LucideIcons.flag);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(complaintsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final complaint = list[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(complaint.reason, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('${complaint.targetType} · ${complaint.reporterName}',
                          style: Theme.of(context).textTheme.bodySmall),
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
}
