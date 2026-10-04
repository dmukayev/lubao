import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../shared/admin_dialogs.dart';
import '../shared/admin_status_helpers.dart';
import '../shared/document_viewer.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  Future<void> _approve(WidgetRef ref, String id) async {
    await ref.read(adminRepositoryProvider).reviewDocument(id, approve: true);
    ref.invalidate(verificationDocumentsProvider);
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String id) async {
    final reason = await showRejectReasonDialog(context);
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).reviewDocument(id, approve: false, rejectReason: reason);
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
        error: (e, st) {
          debugPrint('VerificationScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(verificationDocumentsProvider));
        },
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => openDocumentViewer(context, doc.fileUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            doc.fileUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.fileWarning, size: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => context.push(doc.driverId != null ? '/drivers/${doc.driverId}' : '/companies/${doc.companyId}'),
                              child: Text(
                                doc.subjectName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(decoration: TextDecoration.underline),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(verificationDocTypeLabel(t, doc.type)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _approve(ref, doc.id),
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
