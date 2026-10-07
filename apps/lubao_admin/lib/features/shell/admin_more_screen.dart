import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/auth_provider.dart';

/// «Ещё» — задача 030, п.2: на телефоне внизу только 5 самых частых
/// разделов (Сводка/Проверка/Жалобы/Поиск), остальные — здесь одним
/// списком. На компьютере этот экран не используется (боковое меню
/// показывает все разделы сразу).
class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final items = [
      (LucideIcons.user, t.adminNavDrivers, '/drivers'),
      (LucideIcons.building2, t.adminNavCompanies, '/companies'),
      (LucideIcons.truck, t.adminNavCargos, '/cargos'),
      (LucideIcons.fileCheck2, t.adminNavDeals, '/deals'),
      (LucideIcons.clipboardList, t.adminNavReference, '/reference'),
      (LucideIcons.ban, t.adminNavBlacklist, '/blacklist'),
      (LucideIcons.settings, t.adminNavSettings, '/settings'),
      (LucideIcons.listTree, t.adminAuditLogLink, '/audit'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.adminNavMore)),
      body: ListView(
        children: [
          for (final (icon, label, route) in items)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push(route),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.logOut),
            title: Text(t.profileLogout),
            onTap: () => ref.read(sessionProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
