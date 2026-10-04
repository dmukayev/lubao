import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/auth_provider.dart';
import '../shared/status_helpers.dart';

class CompanyOtpScreen extends ConsumerStatefulWidget {
  const CompanyOtpScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<CompanyOtpScreen> createState() => _CompanyOtpScreenState();
}

class _CompanyOtpScreenState extends ConsumerState<CompanyOtpScreen> {
  final _codeController = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  int _resendCooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
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

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final t = context.l10n;
    if (_codeController.text.trim().isEmpty) return;
    setState(() => _verifying = true);
    try {
      await ref.read(sessionProvider.notifier).verifyEmailCode(widget.email, _codeController.text.trim());
      // Дальше решает редирект роутера: нет компании — на регистрацию
      // компании, иначе сразу в кабинет (см. app_router.dart).
    } catch (e) {
      if (mounted) {
        final message = isTooManyAttemptsError(e) ? t.driverOtpTooManyAttempts : t.driverOtpInvalidCode;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(sessionProvider.notifier).requestEmailCode(widget.email);
      _startCooldown();
    } catch (_) {
      // лимит/сеть — просто не перезапускаем отсчёт
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(t.companyLoginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.companyOtpSubtitle(widget.email), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: t.companyOtpCodeLabel,
              controller: _codeController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: t.companyLoginVerify, loading: _verifying, onPressed: _verify),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: _resendCooldown > 0 || _resending ? null : _resend,
                child: Text(
                  _resendCooldown > 0 ? '${t.driverOtpResend} ($_resendCooldown s)' : t.driverOtpResend,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
