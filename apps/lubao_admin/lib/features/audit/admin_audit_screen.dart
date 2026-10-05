import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/data_providers.dart';
import '../shared/audit_log_tab.dart';

/// Полный журнал (задача 028, п.5, «Журнал →» со сводки) — в отличие от
/// «Последних событий» это сырые записи audit_log без смешивания с
/// регистрациями/грузами.
class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final entries = ref.watch(adminAuditLogProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminAuditLogTitle)),
      body: entries.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('AdminAuditScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminAuditLogProvider));
        },
        data: (list) {
          if (list.isEmpty) return EmptyState(message: t.adminNoLog, icon: LucideIcons.listTree);
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) => AuditLogEntryTile(entry: list[i], showEntityType: true),
          );
        },
      ),
    );
  }
}
