import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/auth_provider.dart';

/// «Удалить аккаунт» (043 п.1) — в профиле водителя и логиста. Подтверждение
/// с объяснением, что останется (сделки и отзывы без имени), затем
/// `DELETE /auth/me`; 409 — понятный текст (активная сделка / сотрудники).
class DeleteAccountButton extends ConsumerWidget {
  const DeleteAccountButton({super.key});

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.profileDeleteAccountTitle),
        content: SingleChildScrollView(child: Text(t.profileDeleteAccountBody)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.commonCancel)),
          TextButton(
            key: const Key('deleteAccountConfirmButton'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.profileDeleteAccountConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(sessionProvider.notifier).deleteAccount();
    } catch (e) {
      debugPrint('DeleteAccountButton: $e');
      messenger.showSnackBar(SnackBar(content: Text(_errorText(t, e))));
    }
  }

  String _errorText(LubaoLocalizations t, Object error) {
    final data = error is DioException ? error.response?.data : null;
    final code = data is Map ? data['code'] : null;
    return switch (code) {
      'ACTIVE_DEALS' => t.profileDeleteAccountActiveDeals,
      'OWNER_HAS_MEMBERS' => t.profileDeleteAccountOwnerHasMembers,
      _ => t.commonError,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      key: const Key('profileDeleteAccountButton'),
      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
      onPressed: () => _confirmAndDelete(context, ref),
      child: Text(context.l10n.profileDeleteAccount, textAlign: TextAlign.center),
    );
  }
}
