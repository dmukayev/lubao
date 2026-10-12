import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/auth_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
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
      await ref.read(sessionProvider.notifier).login(_emailController.text.trim(), _passwordController.text);
    } catch (e) {
      if (!mounted) return;
      final lockSec = lockedOutSeconds(e);
      if (lockSec != null) {
        setState(() => _passwordError = t.authLockedOut('${(lockSec / 60).ceil()}'));
        _startLockCountdown(lockSec);
      } else if (authErrorCode(e) == 'INVALID_CREDENTIALS') {
        setState(() => _passwordError = t.companyLoginInvalidCredentials);
        _passwordController.clear();
        _passwordFocus.requestFocus();
      } else {
        // «Что-то пошло не так» — только для неизвестных ошибок сервера.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorText(t, e) ?? t.commonError)));
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
                const LubaoLogo(height: 48),
                const SizedBox(height: 16),
                Text(t.adminLoginTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 24),
                AppTextField(
                  label: t.adminLoginEmailLabel,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  key: const Key('adminLoginPassword'),
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
                PrimaryButton(label: t.adminLoginSubmit, loading: _loading, onPressed: _lockLeftSec > 0 ? null : _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
