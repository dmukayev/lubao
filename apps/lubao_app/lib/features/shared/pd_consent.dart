import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';

/// Юридические страницы (043 п.2): `/legal/terms`, `/legal/privacy` на сайте
/// приложения, раздел — по языку интерфейса.
Uri legalUrl(String page, String locale) => Uri.parse('$appPublicUrl/legal/$page#$locale');

Future<void> openLegalPage(BuildContext context, String page) async {
  final locale = Localizations.localeOf(context).languageCode;
  await launchUrl(legalUrl(page, locale), mode: LaunchMode.externalApplication);
}

/// Перед первой загрузкой документа (043 п.2): если согласие ещё не дано —
/// лист с текстом, галочкой и ссылкой на политику. `true` — можно загружать.
Future<bool> ensurePdConsent(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  if (session == null || !session.user.pdConsentRequired) return true;
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _PdConsentSheet(),
  );
  return accepted == true;
}

class _PdConsentSheet extends ConsumerStatefulWidget {
  const _PdConsentSheet();

  @override
  ConsumerState<_PdConsentSheet> createState() => _PdConsentSheetState();
}

class _PdConsentSheetState extends ConsumerState<_PdConsentSheet> {
  bool _checked = false;
  bool _saving = false;

  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      await ref.read(sessionProvider.notifier).acceptPdConsent();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('PdConsentSheet: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commonError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return SingleChildScrollView(
      key: const Key('pdConsentSheet'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.pdConsentTitle, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          Text(t.pdConsentBody),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('pdConsentPolicyLink'),
              onPressed: () => openLegalPage(context, 'privacy'),
              child: Text(t.legalPrivacy),
            ),
          ),
          CheckboxListTile(
            key: const Key('pdConsentCheckbox'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _checked,
            onChanged: _saving ? null : (v) => setState(() => _checked = v ?? false),
            title: Text(t.pdConsentCheckbox),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            key: const Key('pdConsentContinueButton'),
            label: t.pdConsentContinue,
            loading: _saving,
            onPressed: _checked && !_saving ? _continue : null,
          ),
        ],
      ),
    );
  }
}

/// Ссылки «Условия» · «Политика» — экран входа и профиль (043 п.2).
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        TextButton(key: const Key('legalTermsLink'), onPressed: () => openLegalPage(context, 'terms'), child: Text(t.legalTerms)),
        TextButton(key: const Key('legalPrivacyLink'), onPressed: () => openLegalPage(context, 'privacy'), child: Text(t.legalPrivacy)),
      ],
    );
  }
}
