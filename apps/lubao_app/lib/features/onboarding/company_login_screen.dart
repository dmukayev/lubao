import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/auth_provider.dart';

/// Вход логиста: код на email по умолчанию (задачи 006, 022), пароль —
/// альтернатива для тех, кто его себе задал (решение 2026-10-04, «Вход
/// логиста — код ИЛИ пароль»; настройка пароля — в профиле компании).
/// Регистрация новой компании продолжается после кода — см.
/// CompanyOtpScreen и роутер.
class CompanyLoginScreen extends ConsumerStatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  ConsumerState<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends ConsumerState<CompanyLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _usePassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    try {
      if (_usePassword) {
        await ref.read(sessionProvider.notifier).loginCompanyPassword(email, _passwordController.text);
        // Дальше решает редирект роутера.
      } else {
        await ref.read(sessionProvider.notifier).requestEmailCode(email);
        if (mounted) context.push('/login/company/otp', extra: email);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.commonError)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.companyLoginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(t.companyLoginByCode)),
                ButtonSegment(value: true, label: Text(t.companyLoginByPassword)),
              ],
              selected: {_usePassword},
              onSelectionChanged: (value) => setState(() => _usePassword = value.first),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: t.companyLoginEmailLabel,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            if (_usePassword) ...[
              const SizedBox(height: 12),
              AppTextField(
                label: t.adminLoginPasswordLabel,
                controller: _passwordController,
                obscureText: true,
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: _usePassword ? t.companyLoginVerify : t.companyLoginSendCode,
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
