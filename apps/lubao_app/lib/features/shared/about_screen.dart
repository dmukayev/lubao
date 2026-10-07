import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/auth_provider.dart';
import 'delete_account.dart';
import 'pd_consent.dart';

final _appVersionProvider = FutureProvider<String>((ref) async => (await PackageInfo.fromPlatform()).version);

/// Профиль → «О приложении» (043 п.2): Условия, Политика, Оферта (у логиста),
/// версия, «Удалить аккаунт».
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final isCompany = ref.watch(sessionProvider)?.user.role == UserRole.company;
    final version = ref.watch(_appVersionProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(t.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          ListTile(
            key: const Key('aboutTerms'),
            leading: const Icon(LucideIcons.fileText),
            title: Text(t.legalTerms),
            trailing: const Icon(LucideIcons.externalLink, size: 18),
            onTap: () => openLegalPage(context, 'terms'),
          ),
          ListTile(
            key: const Key('aboutPrivacy'),
            leading: const Icon(LucideIcons.shieldCheck),
            title: Text(t.legalPrivacy),
            trailing: const Icon(LucideIcons.externalLink, size: 18),
            onTap: () => openLegalPage(context, 'privacy'),
          ),
          if (isCompany)
            ListTile(
              key: const Key('aboutOffer'),
              leading: const Icon(LucideIcons.fileSignature),
              title: Text(t.legalOffer),
              trailing: const Icon(LucideIcons.externalLink, size: 18),
              onTap: () => openLegalPage(context, 'offer'),
            ),
          if (version != null)
            ListTile(
              key: const Key('aboutVersion'),
              leading: const Icon(LucideIcons.info),
              title: Text(t.aboutVersion(version)),
            ),
          const SizedBox(height: AppSpacing.xl),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: DeleteAccountButton(),
          ),
        ],
      ),
    );
  }
}
