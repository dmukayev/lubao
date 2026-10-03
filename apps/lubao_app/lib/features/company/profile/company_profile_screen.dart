import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/locale_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
