import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final session = ref.watch(sessionProvider);
    final driver = session?.driver;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profileTitle),
        actions: [IconButton(icon: const Icon(LucideIcons.pencil), onPressed: () => context.push('/driver/setup'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(driver?.fullName ?? '', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.star, size: 16, color: Colors.amber),
              Text(' ${driver?.ratingAvg.toStringAsFixed(1) ?? '-'} (${driver?.ratingCount ?? 0})'),
              const SizedBox(width: 12),
              StatusBadge(
                label: (driver?.isVerified ?? false) ? t.profileVerified : t.profileNotVerified,
                color: (driver?.isVerified ?? false) ? StatusBadge.success : StatusBadge.neutral,
              ),
            ],
          ),
          if (!(driver?.isVerified ?? false)) ...[
            const SizedBox(height: AppSpacing.lg),
            _CompletenessBanner(driver: driver),
          ],
          const Divider(height: 32),
          ListTile(
            leading: const Icon(LucideIcons.phone),
            title: Text(t.profilePhone),
            subtitle: Text(session?.user.phone ?? '-'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.languages),
            title: Text(t.profileLanguage),
            trailing: DropdownButton<Locale>(
              value: locale,
              items: const [
                DropdownMenuItem(value: Locale('ru'), child: Text('Русский')),
                DropdownMenuItem(value: Locale('kk'), child: Text('Қазақша')),
                DropdownMenuItem(value: Locale('zh'), child: Text('中文')),
              ],
              onChanged: (value) {
                if (value != null) ref.read(localeProvider.notifier).state = value;
              },
            ),
          ),
          ListTile(
            leading: const Icon(LucideIcons.smartphone),
            title: Text(t.profileMyDevices),
            onTap: () => context.push('/devices'),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
            child: Text(t.profileLogout),
          ),
        ],
      ),
    );
  }
}

class _CompletenessBanner extends StatelessWidget {
  const _CompletenessBanner({required this.driver});

  final Driver? driver;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final pending = driver?.verificationStatus == DriverVerificationStatus.pending;
    final percent = pending ? 80 : 60;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(t.profileCompleteness(percent), style: AppTextStyles.body),
          if (!pending) ...[
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: t.driverVerificationRequiredAction,
              onPressed: () => context.push('/driver/verification'),
            ),
          ],
        ],
      ),
    );
  }
}
