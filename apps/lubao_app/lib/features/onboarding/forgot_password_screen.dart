import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../shared/status_helpers.dart';
import '../shared/error_feedback.dart';

/// «Забыли пароль» (задача 025, п. 9): email → код на почту → новый
/// пароль. Успешная смена пароля разлогинивает все остальные устройства
/// (см. AuthService.resetPassword) — пользователь уже на новом пароле
/// увидит это сам при следующем входе там.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _codeRequested = false;
  bool _sendingCode = false;
  bool _resending = false;
  bool _submitting = false;
  int _resendCooldown = 60;
  Timer? _timer;
  String? _codeError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _requestCode() async {
    final t = context.l10n;
    final email = _emailController.text.trim();
    if (!email.contains('@')) return;
    setState(() => _sendingCode = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email: email);
      setState(() => _codeRequested = true);
      _startCooldown();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.commonError)));
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email: _emailController.text.trim());
      _startCooldown();
    } catch (e) {
      // лимит/сеть — отсчёт не перезапускаем, но причину показываем
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final code = _codeController.text.trim();
    final password = _newPasswordController.text;
    setState(() {
      _codeError = code.isEmpty ? t.forgotPasswordInvalidCode : null;
      _passwordError = password.length >= 8 ? null : t.companyRegisterPasswordError;
    });
    if (_codeError != null || _passwordError != null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _emailController.text.trim(),
            code: code,
            newPassword: password,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.forgotPasswordSuccess)));
        context.go('/login/company', extra: _emailController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _codeError = t.forgotPasswordInvalidCode);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.forgotPasswordTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          AppTextField(
            label: t.companyLoginEmailLabel,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_codeRequested,
          ),
          if (!_codeRequested) ...[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: t.forgotPasswordSendCode, loading: _sendingCode, onPressed: _requestCode),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: t.forgotPasswordCodeLabel,
              controller: _codeController,
              keyboardType: TextInputType.number,
              errorText: _codeError,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: t.forgotPasswordNewPasswordLabel,
              controller: _newPasswordController,
              obscureText: _obscurePassword,
              errorText: _passwordError,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Text(_obscurePassword ? t.companyLoginShowPassword : t.companyLoginHidePassword),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(label: t.forgotPasswordSubmit, loading: _submitting, onPressed: _submit),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: _resendCooldown > 0 || _resending ? null : _resend,
                child: Text(_resendCooldown > 0 ? '${t.forgotPasswordResend} ($_resendCooldown s)' : t.forgotPasswordResend),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: () => showSupportContactSheet(context, ref),
              child: Text(t.forgotPasswordNoEmailLink),
            ),
          ),
        ],
      ),
    );
  }
}
