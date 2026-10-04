import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/locale_provider.dart';

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          LanguagePickerButton(
            languageCode: locale.languageCode,
            onChanged: (code) => ref.read(localeProvider.notifier).state = Locale(code),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.appName, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(t.roleSelectTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(t.roleSelectSubtitle, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              PrimaryButton(
                label: t.roleDriver,
                icon: LucideIcons.truck,
                onPressed: () => context.push('/login/driver'),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: t.roleCompany,
                icon: LucideIcons.building2,
                onPressed: () => context.push('/login/company'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
