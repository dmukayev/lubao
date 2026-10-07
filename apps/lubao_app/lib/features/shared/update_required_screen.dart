import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/api_providers.dart';

/// «Обновите приложение» (043 п.8) — кнопка ведёт на страницу загрузки
/// `/app` (APK / Google Play / TestFlight, `infra/site/app.html`).
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.download, size: 48, color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(t.appUpdateTitle, key: const Key('appUpdateTitle'), style: AppTextStyles.headline, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                Text(t.appUpdateBody, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  key: const Key('appUpdateButton'),
                  label: t.appUpdateButton,
                  onPressed: () => launchUrl(Uri.parse('$appPublicUrl/app'), mode: LaunchMode.externalApplication),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
