import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/auth_provider.dart';

/// Вход логиста без пароля (задачи 006, 022): email → код, как у водителя
/// по SMS. Регистрация новой компании продолжается после кода — см.
/// CompanyOtpScreen и роутер.
class CompanyLoginScreen extends ConsumerStatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  ConsumerState<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends ConsumerState<CompanyLoginScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider.notifier).requestEmailCode(email);
      if (mounted) context.push('/login/company/otp', extra: email);
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
            AppTextField(
              label: t.companyLoginEmailLabel,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: t.companyLoginSendCode, loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
