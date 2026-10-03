import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  Future<void> _approve(BuildContext context, WidgetRef ref, String id) async {
    await ref.read(adminRepositoryProvider).reviewDocument(id, approve: true);
    ref.invalidate(verificationDocumentsProvider);
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String id) async {
    final t = context.l10n;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.adminReject),
        content: AppTextField(label: t.adminRejectReasonLabel, controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(t.commonDone)),
        ],
      ),
    );
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).reviewDocument(id, approve: false, rejectReason: reason.trim());
    ref.invalidate(verificationDocumentsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final docs = ref.watch(verificationDocumentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminVerificationTitle)),
      body: docs.when(
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(verificationDocumentsProvider)),
        data: (list) {
          if (list.isEmpty) return EmptyState(message: t.adminVerificationEmpty, icon: LucideIcons.badgeCheck);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(verificationDocumentsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final doc = list[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.subjectName, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(doc.type),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _approve(context, ref, doc.id),
                              child: Text(t.adminApprove),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _reject(context, ref, doc.id),
                              child: Text(t.adminReject),
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
