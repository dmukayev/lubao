import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/locale_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

Future<void> _showSetPasswordDialog(BuildContext context, WidgetRef ref) async {
  final t = context.l10n;
  final controller = TextEditingController();
  String? error;
  bool saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(t.companySetPasswordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.companySetPasswordHint, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: t.adminLoginPasswordLabel,
              controller: controller,
              obscureText: true,
              errorText: error,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t.commonCancel)),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (controller.text.length < 8) {
                      setState(() => error = t.companySetPasswordTooShort);
                      return;
                    }
                    setState(() => saving = true);
                    try {
                      await ref.read(companyRepositoryProvider).setPassword(controller.text);
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    } catch (_) {
                      setState(() {
                        saving = false;
                        error = t.commonError;
                      });
                    }
                  },
            child: Text(t.commonSave),
          ),
        ],
      ),
    ),
  );
}

class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final session = ref.watch(sessionProvider);
    final company = session?.company;
    final members = ref.watch(companyMembersProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(company?.name ?? '', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.star, size: 16, color: Colors.amber),
              Text(' ${company?.ratingAvg.toStringAsFixed(1) ?? '-'} (${company?.ratingCount ?? 0})'),
              const SizedBox(width: 12),
              StatusBadge(
                label: (company?.isVerified ?? false) ? t.profileVerified : t.profileNotVerified,
                color: (company?.isVerified ?? false) ? StatusBadge.success : StatusBadge.neutral,
              ),
            ],
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(LucideIcons.mail),
            title: Text(t.profileEmail),
            subtitle: Text(session?.user.email ?? '-'),
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
          const SizedBox(height: 16),
          Text(t.profileMembers, style: Theme.of(context).textTheme.titleSmall),
          members.when(
            loading: () => const LoadingView(),
            error: (e, st) => Text(t.commonError),
            data: (list) => Column(
              children: list
                  .map((m) => ListTile(
                        leading: const Icon(LucideIcons.user),
                        title: Text(m.role.name.toUpperCase()),
                      ))
                  .toList(),
            ),
          ),
          ListTile(
            leading: const Icon(LucideIcons.smartphone),
            title: Text(t.profileMyDevices),
            onTap: () => context.push('/devices'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.keyRound),
            title: Text(t.companySetPasswordTitle),
            subtitle: Text(t.companySetPasswordHint),
            onTap: () => _showSetPasswordDialog(context, ref),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
            child: Text(t.profileLogout),
          ),
        ],
      ),
    );
  }
}
