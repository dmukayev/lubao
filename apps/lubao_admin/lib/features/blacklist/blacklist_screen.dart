import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../shared/admin_dialogs.dart';
import '../shared/admin_status_helpers.dart';

final _showLiftedProvider = StateProvider.autoDispose<bool>((ref) => false);

final _blacklistProvider = FutureProvider.autoDispose<List<AdminBlockedIdentifier>>((ref) {
  final showLifted = ref.watch(_showLiftedProvider);
  return ref.watch(adminRepositoryProvider).blacklist(activeOnly: !showLifted);
});

const _types = ['IIN', 'PHONE', 'PLATE', 'VIN', 'DRIVER_LICENSE_NO', 'BIN', 'USCC'];

String identifierTypeLabel(LubaoLocalizations t, String type) => switch (type) {
      'IIN' => t.adminIdentifierTypeIin,
      'PHONE' => t.adminIdentifierTypePhone,
      'PLATE' => t.adminIdentifierTypePlate,
      'VIN' => t.adminIdentifierTypeVin,
      'DRIVER_LICENSE_NO' => t.adminIdentifierTypeLicense,
      'BIN' => t.adminIdentifierTypeBin,
      'USCC' => t.adminIdentifierTypeUscc,
      _ => type,
    };

/// Чёрный список (043 п.4): ручная блокировка ИИН / телефона / госномера /
/// VIN / прав / БИН / USCC с причиной и снятие. Значения — только маской;
/// каждое действие — в журнал действий.
class BlacklistScreen extends ConsumerWidget {
  const BlacklistScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final valueController = TextEditingController();
    final reasonController = TextEditingController();
    var type = _types.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final canSave = valueController.text.trim().isNotEmpty && reasonController.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text(t.adminBlacklistAdd),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    key: const Key('blacklistType'),
                    initialValue: type,
                    decoration: InputDecoration(labelText: t.adminBlacklistType),
                    items: [for (final ty in _types) DropdownMenuItem(value: ty, child: Text(identifierTypeLabel(t, ty)))],
                    onChanged: (v) => setState(() => type = v ?? type),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(key: const Key('blacklistValue'), label: t.adminBlacklistValue, controller: valueController, onChanged: (_) => setState(() {})),
                  const SizedBox(height: 12),
                  AppTextField(key: const Key('blacklistReason'), label: t.adminReasonLabel, controller: reasonController, maxLines: 2, onChanged: (_) => setState(() {})),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.commonCancel)),
              FilledButton(onPressed: canSave ? () => Navigator.pop(dialogContext, true) : null, child: Text(t.commonSave)),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).addToBlacklist(type: type, value: valueController.text.trim(), reason: reasonController.text.trim());
    } catch (e) {
      debugPrint('BlacklistScreen: $e');
      messenger.showSnackBar(SnackBar(content: Text(t.adminBlacklistInvalid)));
    }
    ref.invalidate(_blacklistProvider);
  }

  Future<void> _lift(BuildContext context, WidgetRef ref, AdminBlockedIdentifier row) async {
    final t = context.l10n;
    final reason = await showReasonDialog(context, title: t.adminBlacklistLift, confirmLabel: t.adminBlacklistLift);
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).liftBlacklist(row.id, reason: reason);
    ref.invalidate(_blacklistProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final rows = ref.watch(_blacklistProvider);
    final showLifted = ref.watch(_showLiftedProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminNavBlacklist),
        actions: [
          IconButton(
            key: const Key('blacklistAddButton'),
            tooltip: t.adminBlacklistAdd,
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _add(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: Text(t.adminBlacklistShowLifted),
            value: showLifted,
            onChanged: (v) => ref.read(_showLiftedProvider.notifier).state = v,
          ),
          Expanded(
            child: rows.when(
              loading: () => const LoadingView(),
              error: (e, st) {
                debugPrint('BlacklistScreen: $e');
                return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(_blacklistProvider));
              },
              data: (list) => list.isEmpty
                  ? EmptyState(message: t.adminBlacklistEmpty, icon: LucideIcons.shieldCheck)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final row = list[i];
                        return AppCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${identifierTypeLabel(t, row.type)} · ${row.valueMasked}', style: AppTextStyles.bodyStrong),
                                    const SizedBox(height: 4),
                                    Text(row.reason),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${formatAdminDateTime(row.createdAt)}${row.blockedByName != null ? ' · ${row.blockedByName}' : ''}',
                                      style: AppTextStyles.caption,
                                    ),
                                    if (row.liftedAt != null)
                                      Text(
                                        '${t.adminBlacklistLifted}: ${formatAdminDateTime(row.liftedAt!)}${row.liftReason != null ? ' — ${row.liftReason}' : ''}',
                                        style: AppTextStyles.caption,
                                      ),
                                  ],
                                ),
                              ),
                              if (row.liftedAt == null)
                                TextButton(onPressed: () => _lift(context, ref, row), child: Text(t.adminBlacklistLift)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
