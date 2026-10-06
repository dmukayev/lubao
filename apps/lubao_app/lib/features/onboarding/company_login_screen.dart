import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../shared/status_helpers.dart';

/// Вход логиста — email и пароль по умолчанию (задача 025, заменяет вход
/// по коду из 006/022). Внизу — «Регистрация» и «Забыли пароль?» в одну
/// строку, без отдельной кнопки «У меня приглашение» (ссылка-приглашение
/// сама открывает нужный экран).
class CompanyLoginScreen extends ConsumerStatefulWidget {
  const CompanyLoginScreen({super.key, this.prefillEmail});

  final String? prefillEmail;

  @override
  ConsumerState<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends ConsumerState<CompanyLoginScreen> {
  late final _emailController = TextEditingController(text: widget.prefillEmail);
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider.notifier).loginCompany(_emailController.text.trim(), _passwordController.text);
      // Дальше решает редирект роутера.
    } catch (e) {
      if (mounted) {
        final message = isAccountBlockedError(e)
            ? t.accountBlockedMessage
            : isLockedOutError(e)
                ? t.companyLoginLockedOut
                : t.commonError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final appLocale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.companyLoginTitle),
        actions: [
          LanguagePickerButton(
            languageCode: appLocale.languageCode,
            onChanged: (code) => ref.read(localeProvider.notifier).state = Locale(code),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(
              key: const Key('companyLoginEmailField'),
              label: t.companyLoginEmailLabel,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            AppTextField(
              key: const Key('companyLoginPasswordField'),
              label: t.adminLoginPasswordLabel,
              controller: _passwordController,
              obscureText: _obscurePassword,
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Text(_obscurePassword ? t.companyLoginShowPassword : t.companyLoginHidePassword),
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(key: const Key('companyLoginSubmitButton'), label: t.companyLoginVerify, loading: _loading, onPressed: _submit),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  key: const Key('companyLoginRegisterLink'),
                  onPressed: () => context.push('/login/company/register'),
                  child: Text(t.companyLoginRegisterLink),
                ),
                TextButton(
                  onPressed: () => context.push('/login/company/forgot-password'),
                  child: Text(t.companyLoginForgotPasswordLink),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
