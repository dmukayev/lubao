import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/auth_provider.dart';

/// true, если бэкенд отклонил вход из-за 15-минутной блокировки после
/// 5 неверных попыток (см. auth.service.ts#loginAdmin) — отличаем от
/// обычного "неверный email/пароль", чтобы объяснить пользователю причину.
bool _isLockedOutError(Object error) {
  if (error is! DioException) return false;
  final data = error.response?.data;
  return data is Map && data['message'] == 'Слишком много неверных попыток, попробуйте через 15 минут';
}

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
      await ref.read(sessionProvider.notifier).login(_emailController.text.trim(), _passwordController.text);
    } catch (e) {
      if (mounted) {
        final message = _isLockedOutError(e) ? t.adminLoginLockedOut : t.commonError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.appName, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(t.adminLoginTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 24),
                AppTextField(
                  label: t.adminLoginEmailLabel,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                AppTextField(label: t.adminLoginPasswordLabel, controller: _passwordController, obscureText: true),
                const SizedBox(height: 16),
                PrimaryButton(label: t.adminLoginSubmit, loading: _loading, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
