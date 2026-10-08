import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../shared/driver_avatar.dart';
import '../../shared/error_feedback.dart';
import '../../shared/pd_consent.dart';
import '../../shared/photo_picker.dart';

/// 054: действия с фото профиля водителя. После каждого — свежий профиль
/// (версия фото и признак предложения приходят с сервера).
Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
  try {
    await action();
    final fresh = await ref.read(driverRepositoryProvider).me();
    ref.read(sessionProvider.notifier).updateDriver(fresh);
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
}

/// «Сделать другое» / «Сменить фото»: камера → загрузка → миниатюра на сервере.
Future<void> _takeNew(BuildContext context, WidgetRef ref) async {
  if (!await ensurePdConsent(context, ref) || !context.mounted) return;
  final picked = await pickPhoto(ImageSource.camera);
  if (picked == null || !context.mounted) return;
  await _run(context, ref, () async {
    final bytes = await picked.readAsBytes();
    final key = await ref.read(uploadsRepositoryProvider).uploadDocument(bytes, filename: picked.name);
    await ref.read(driverRepositoryProvider).setAvatar(key);
  });
}

/// Фото рядом с именем; нажатие — «Сменить фото» / «Убрать» (нет фото — «Добавить фото»).
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, required this.driver});

  final Driver driver;

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final hasPhoto = driver.avatarVersion != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.sm),
              child: Text(t.avatarHint, style: AppTextStyles.caption),
            ),
            ListTile(
              key: const Key('avatarMenuTake'),
              leading: const Icon(LucideIcons.camera),
              title: Text(hasPhoto ? t.avatarChange : t.avatarAdd),
              onTap: () => Navigator.pop(sheetContext, 'take'),
            ),
            if (hasPhoto)
              ListTile(
                key: const Key('avatarMenuRemove'),
                leading: const Icon(LucideIcons.trash2, color: AppColors.error),
                title: Text(t.avatarRemove, style: const TextStyle(color: AppColors.error)),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'take') await _takeNew(context, ref);
    if (choice == 'remove') await _run(context, ref, () => ref.read(driverRepositoryProvider).removeAvatar());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: driver.avatarVersion != null ? context.l10n.avatarChange : context.l10n.avatarAdd,
      child: InkWell(
        key: const Key('profileAvatar'),
        customBorder: const CircleBorder(),
        onTap: () => _menu(context, ref),
        child: DriverAvatar(driverId: driver.id, name: driver.fullName, version: driver.avatarVersion, radius: 32),
      ),
    );
  }
}

/// 054 п.2: один раз после принятого селфи — «Поставить это фото в профиль?».
class AvatarOfferCard extends ConsumerWidget {
  const AvatarOfferCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final repo = ref.read(driverRepositoryProvider);
    return AppCard(
      key: const Key('avatarOfferCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userCircle2, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(t.avatarOfferTitle, style: AppTextStyles.bodyStrong)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(t.avatarOfferBody, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(key: const Key('avatarOfferYes'), label: t.avatarOfferYes, onPressed: () => _run(context, ref, repo.setAvatarFromSelfie)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton(key: const Key('avatarOfferOther'), onPressed: () => _takeNew(context, ref), child: Text(t.avatarOfferOther)),
              TextButton(key: const Key('avatarOfferLater'), onPressed: () => _run(context, ref, repo.dismissAvatarOffer), child: Text(t.avatarOfferLater)),
            ],
          ),
        ],
      ),
    );
  }
}
