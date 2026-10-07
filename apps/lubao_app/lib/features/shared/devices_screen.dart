import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import 'status_helpers.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  Future<void> _revoke(BuildContext context, WidgetRef ref, String id) async {
    await ref.read(authRepositoryProvider).revokeSession(id);
    ref.invalidate(devicesProvider);
  }

  Future<void> _revokeAllOthers(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(t.devicesLogoutAllOthersConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.devicesLogoutAllOthers)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).revokeAllOthers();
    ref.invalidate(devicesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final devicesAsync = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.devicesTitle)),
      body: devicesAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('DevicesScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(devicesProvider));
        },
        data: (devices) {
          if (devices.isEmpty) {
            return EmptyState(message: t.devicesEmpty, icon: LucideIcons.smartphone);
          }
          final hasOthers = devices.any((d) => !d.isCurrent);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              if (hasOthers) ...[
                PrimaryButton(
                  label: t.devicesLogoutAllOthers,
                  onPressed: () => _revokeAllOthers(context, ref),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              for (final device in devices) ...[
                _DeviceTile(device: device, onLogout: () => _revoke(context, ref, device.id)),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onLogout});

  final DeviceSession device;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Row(
        children: [
          const Icon(LucideIcons.smartphone, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название + «это устройство» — с переносом: на узком экране с
                // крупным шрифтом ряд вылезал вправо (iPhone SE в e2e, +8 px).
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(device.deviceName ?? device.platform ?? '—', style: AppTextStyles.bodyStrong),
                    if (device.isCurrent) StatusBadge(label: t.devicesCurrentBadge, color: StatusBadge.success),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(formatDateTime(device.lastUsedAt), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (!device.isCurrent)
            IconButton(
              icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.error),
              tooltip: t.devicesLogoutThis,
              onPressed: onLogout,
            ),
        ],
      ),
    );
  }
}
