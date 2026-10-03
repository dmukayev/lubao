import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/auth_provider.dart';

class CompanyLoginScreen extends ConsumerStatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  ConsumerState<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends ConsumerState<CompanyLoginScreen> {
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
      await ref
          .read(sessionProvider.notifier)
          .loginCompany(_emailController.text.trim(), _passwordController.text);
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
            const SizedBox(height: 12),
            AppTextField(
              label: t.companyLoginPasswordLabel,
              controller: _passwordController,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: t.companyLoginSubmit, loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
