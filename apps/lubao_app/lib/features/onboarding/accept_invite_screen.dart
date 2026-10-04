import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';

/// Принять приглашение сотрудника по ссылке (задача 025, «Путь Б» из 022):
/// email уже известен из приглашения (только показываем, не редактируем),
/// дальше — пароль, имя, телефон для водителей (можно позже), WeChat
/// (необязательно). Принятие ссылки автоматически подтверждает email —
/// переход по ней уже доказывает, что почта принадлежит пользователю.
class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _wechatController = TextEditingController();
  bool _obscurePassword = true;
  bool _saving = false;
  String? _passwordError;
  String? _nameError;

  late final Future<CompanyInviteInfo> _inviteFuture =
      ref.read(authRepositoryProvider).getInvite(widget.token);

  @override
  void dispose() {
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _wechatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    setState(() {
      _passwordError = password.length >= 8 ? null : t.companyRegisterPasswordError;
      _nameError = isValidPersonName(name) ? null : t.driverSetupFullNameError;
    });
    if (_passwordError != null || _nameError != null) return;

    setState(() => _saving = true);
    try {
      await ref.read(sessionProvider.notifier).acceptInvite(
            widget.token,
            password: password,
            name: name,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            wechat: _wechatController.text.trim().isEmpty ? null : _wechatController.text.trim(),
          );
      // Дальше решает редирект роутера — сессия с привязанной компанией
      // уводит прямо в кабинет (см. app_router.dart).
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.acceptInviteInvalidToken)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.acceptInviteTitle)),
      body: FutureBuilder<CompanyInviteInfo>(
        future: _inviteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          if (snapshot.hasError || snapshot.data == null) {
            return ErrorView(message: t.acceptInviteInvalidToken);
          }
          final invite = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text(
                t.acceptInviteSubtitle(
                  invite.companyName,
                  invite.role == CompanyMemberRole.owner ? t.employeesInviteRoleOwner : t.employeesInviteRoleLogist,
                ),
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: t.companyLoginEmailLabel, controller: TextEditingController(text: invite.email), enabled: false),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: t.adminLoginPasswordLabel,
                controller: _passwordController,
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
              AppTextField(label: t.acceptInviteNameLabel, controller: _nameController, errorText: _nameError),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: t.acceptInvitePhoneLabel, controller: _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: t.acceptInviteWechatLabel, controller: _wechatController),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: t.acceptInviteSubmit, loading: _saving, onPressed: _submit),
            ],
          );
        },
      ),
    );
  }
}
