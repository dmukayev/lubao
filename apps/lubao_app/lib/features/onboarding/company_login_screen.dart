import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../shared/error_feedback.dart';
import '../shared/pd_consent.dart';

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
  bool _loading = false;
  // 073: ошибка входа — под полем пароля; блокировка — с обратным отсчётом.
  final _passwordFocus = FocusNode();
  String? _passwordError;
  Timer? _lockTimer;
  int _lockLeftSec = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  void _startLockCountdown(int seconds) {
    _lockTimer?.cancel();
    setState(() => _lockLeftSec = seconds);
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        _lockLeftSec--;
        if (_lockLeftSec <= 0) {
          timer.cancel();
          _passwordError = null;
        } else {
          _passwordError = context.l10n.authLockedOut('${(_lockLeftSec / 60).ceil()}');
        }
      });
    });
  }

  Future<void> _submit() async {
    final t = context.l10n;
    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider.notifier).loginCompany(_emailController.text.trim(), _passwordController.text);
      // Дальше решает редирект роутера.
    } catch (e) {
      if (!mounted) return;
      // 073: по коду сервера — понятный текст; «Что-то пошло не так» — только для неизвестных 5xx.
      final lockSec = lockedOutSeconds(e);
      final code = authErrorCode(e);
      if (lockSec != null) {
        setState(() => _passwordError = t.authLockedOut('${(lockSec / 60).ceil()}'));
        _startLockCountdown(lockSec);
      } else if (code == 'INVALID_CREDENTIALS') {
        // Неверный пароль — под полем, поле очищается, курсор в нём.
        setState(() => _passwordError = t.companyLoginInvalidCredentials);
        _passwordController.clear();
        _passwordFocus.requestFocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorText(t, e) ?? errorMessage(t, e))));
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
      // Прокрутка: на узком экране с крупным шрифтом (Huawei Y7 ×1,3, iPhone SE)
      // колонка не помещалась по высоте — «bottom overflowed».
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const LubaoLogo(height: 36),
            const SizedBox(height: 24),
            AppTextField(
              key: const Key('companyLoginEmailField'),
              label: t.companyLoginEmailLabel,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            // «Глаз» показать / скрыть — в самом поле (AppTextField).
            AppTextField(
              key: const Key('companyLoginPasswordField'),
              label: t.adminLoginPasswordLabel,
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: true,
              errorText: _passwordError,
              onChanged: (_) {
                if (_passwordError != null && _lockLeftSec <= 0) setState(() => _passwordError = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            PrimaryButton(key: const Key('companyLoginSubmitButton'), label: t.companyLoginVerify, loading: _loading, onPressed: _lockLeftSec > 0 ? null : _submit),
            const SizedBox(height: 16),
            // Две ссылки — в строку, а не влезают — переносом (не вылезают вправо).
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
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
            const SizedBox(height: 8),
            const LegalNotice(),
          ],
        ),
      ),
    );
  }
}
