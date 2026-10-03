import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
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
