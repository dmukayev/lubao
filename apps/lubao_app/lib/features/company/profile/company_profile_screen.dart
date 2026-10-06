import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/locale_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../shared/photo_picker.dart';
import '../../shared/error_feedback.dart';

/// Плашка-напоминание о неподтверждённом email (задача 025, п. 7) — не
/// блокирует ничего, просто предлагает подтвердить. «Отправить код» зовёт
/// тот же resend-эндпоинт, который использует и регистрация.
class _EmailVerifyBanner extends ConsumerStatefulWidget {
  const _EmailVerifyBanner();

  @override
  ConsumerState<_EmailVerifyBanner> createState() => _EmailVerifyBannerState();
}

class _EmailVerifyBannerState extends ConsumerState<_EmailVerifyBanner> {
  bool _sending = false;

  Future<void> _resendAndOpenDialog() async {
    final t = context.l10n;
    setState(() => _sending = true);
    try {
      await ref.read(authRepositoryProvider).resendEmailVerification();
    } catch (e) {
      // лимит писем — код мог уже быть отправлен раньше, диалог всё равно полезен
      debugPrint('CompanyProfile: resend email verification failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    if (!mounted) return;
    final codeController = TextEditingController();
    String? error;
    bool verifying = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(t.emailVerifyDialogTitle),
          content: AppTextField(
            label: t.emailVerifyDialogCodeLabel,
            controller: codeController,
            keyboardType: TextInputType.number,
            errorText: error,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t.commonCancel)),
            FilledButton(
              onPressed: verifying
                  ? null
                  : () async {
                      setDialogState(() => verifying = true);
                      try {
                        await ref.read(sessionProvider.notifier).verifyEmail(codeController.text.trim());
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      } catch (e) {
                        debugPrint('CompanyProfile: verifyEmail failed: $e');
                        setDialogState(() {
                          verifying = false;
                          error = t.forgotPasswordInvalidCode;
                        });
                      }
                    },
              child: Text(t.emailVerifyDialogSubmit),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Card(
      color: AppColors.primarySoft,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: const Icon(LucideIcons.mail),
        title: Text(t.emailVerifyBannerText),
        trailing: TextButton(
          onPressed: _sending ? null : _resendAndOpenDialog,
          child: Text(t.emailVerifyBannerAction),
        ),
      ),
    );
  }
}

Future<void> _showInviteDialog(BuildContext context, WidgetRef ref) async {
  final t = context.l10n;
  final emailController = TextEditingController();
  CompanyMemberRole role = CompanyMemberRole.logist;
  String? error;
  String? resultLink;
  bool saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(t.employeesInviteButton),
        content: resultLink != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.employeesInviteLinkReady),
                  const SizedBox(height: AppSpacing.sm),
                  SelectableText(resultLink!),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: t.employeesInviteEmailLabel,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    errorText: error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<CompanyMemberRole>(
                    segments: [
                      ButtonSegment(value: CompanyMemberRole.logist, label: Text(t.employeesInviteRoleLogist)),
                      ButtonSegment(value: CompanyMemberRole.owner, label: Text(t.employeesInviteRoleOwner)),
                    ],
                    selected: {role},
                    onSelectionChanged: (s) => setState(() => role = s.first),
                  ),
                ],
              ),
        actions: resultLink != null
            ? [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: resultLink!));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.employeesInviteCopied)));
                  },
                  child: Text(t.employeesInviteCopyLink),
                ),
                FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t.commonDone)),
              ]
            : [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t.commonCancel)),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          if (!email.contains('@')) {
                            setState(() => error = t.companyRegisterEmailError);
                            return;
                          }
                          setState(() => saving = true);
                          try {
                            final token =
                                await ref.read(companyRepositoryProvider).createInvite(email: email, role: role);
                            setState(() {
                              saving = false;
                              resultLink = '${appPublicUrl.replaceAll(RegExp(r'/+$'), '')}/invite/$token';
                            });
                          } catch (e) {
                            setState(() {
                              saving = false;
                              error = errorMessage(t, e);
                            });
                          }
                        },
                  child: Text(t.employeesInviteSubmit),
                ),
              ],
      ),
    ),
  );
}

Future<void> _showSetPasswordDialog(BuildContext context, WidgetRef ref) async {
  final t = context.l10n;
  final controller = TextEditingController();
  String? error;
  bool saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(t.companySetPasswordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.companySetPasswordHint, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: t.adminLoginPasswordLabel,
              controller: controller,
              obscureText: true,
              errorText: error,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t.commonCancel)),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (controller.text.length < 8) {
                      setState(() => error = t.companySetPasswordTooShort);
                      return;
                    }
                    setState(() => saving = true);
                    try {
                      await ref.read(companyRepositoryProvider).setPassword(controller.text);
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    } catch (e) {
                      setState(() {
                        saving = false;
                        error = errorMessage(t, e);
                      });
                    }
                  },
            child: Text(t.commonSave),
          ),
        ],
      ),
    ),
  );
}

/// Вебхук группового бота WeCom (задача 011, п.2) — владелец вставляет
/// адрес в профиле, «Проверить» шлёт туда тестовое сообщение сразу же,
/// без отдельного сохранения — одной кнопкой одновременно и сохраняем,
/// и проверяем, что бот действительно настроен.
Future<void> _showWeComDialog(BuildContext context, WidgetRef ref, String? currentUrl) async {
  final t = context.l10n;
  final controller = TextEditingController(text: currentUrl ?? '');
  String? error;
  String? info;
  bool saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(t.companyWecomTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.companyWecomHint, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: t.companyWecomUrlLabel, controller: controller, errorText: error),
            if (info != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(info!, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t.commonCancel)),
          TextButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() {
                      saving = true;
                      error = null;
                      info = null;
                    });
                    try {
                      await ref.read(companyRepositoryProvider).updateWeComWebhook(
                            controller.text.trim().isEmpty ? null : controller.text.trim(),
                          );
                      await ref.read(companyRepositoryProvider).testWeComWebhook();
                      setState(() {
                        saving = false;
                        info = t.companyWecomTestSuccess;
                      });
                    } catch (e) {
                      debugPrint('CompanyProfile: wecom test failed: $e');
                      setState(() {
                        saving = false;
                        error = t.companyWecomTestError;
                      });
                    }
                  },
            child: Text(t.companyWecomTestButton),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    try {
                      await ref.read(companyRepositoryProvider).updateWeComWebhook(
                            controller.text.trim().isEmpty ? null : controller.text.trim(),
                          );
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    } catch (e) {
                      setState(() {
                        saving = false;
                        error = errorMessage(t, e);
                      });
                    }
                  },
            child: Text(t.commonSave),
          ),
        ],
      ),
    ),
  );
}

/// Данные компании, которые правит владелец (задача 012, п.8) — город,
/// юр. адрес, рег. номер. Формат рег. номера проверяет бэкенд по стране.
Future<void> _showCompanyEditDialog(BuildContext context, WidgetRef ref, Company company) async {
  final t = context.l10n;
  final cityController = TextEditingController(text: company.city ?? '');
  final addressController = TextEditingController(text: company.legalAddress ?? '');
  final taxIdController = TextEditingController(text: company.taxId ?? '');
  String? error;
  bool saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(t.companyEditTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: t.companyEditCityLabel, controller: cityController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: t.companyEditLegalAddressLabel, controller: addressController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: t.companyEditTaxIdLabel, controller: taxIdController, errorText: error),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t.commonCancel)),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    try {
                      final updated = await ref.read(companyRepositoryProvider).updateProfile(
                            city: cityController.text.trim(),
                            legalAddress: addressController.text.trim(),
                            taxId: taxIdController.text.trim(),
                          );
                      final session = ref.read(sessionProvider);
                      if (session?.companyMember != null) {
                        ref.read(sessionProvider.notifier).updateCompany(updated, session!.companyMember!);
                      }
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    } catch (e) {
                      debugPrint('CompanyProfile: tax id update failed: $e');
                      setState(() {
                        saving = false;
                        error = t.companyEditTaxIdError;
                      });
                    }
                  },
            child: Text(t.commonSave),
          ),
        ],
      ),
    ),
  );
}

/// «Мой профиль» (задача 012, п.1/8) — имя, телефон для водителей, WeChat
/// у конкретного сотрудника (не у компании). И владелец, и логист правят
/// у себя — то, что увидит водитель по грузу, который они опубликовали.
Future<void> _showMyContactDialog(BuildContext context, WidgetRef ref, CompanyMember? member) async {
  final t = context.l10n;
  final nameController = TextEditingController(text: member?.fullName ?? '');
  final phoneController = TextEditingController(text: member?.contactPhone ?? '');
  final wechatController = TextEditingController(text: member?.wechatId ?? '');
  String? error;
  bool saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(t.myProfileTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: t.myProfileNameLabel, controller: nameController, errorText: error),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: t.myProfilePhoneLabel, controller: phoneController, keyboardType: TextInputType.phone),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: t.myProfileWechatLabel, controller: wechatController),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t.commonCancel)),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    final name = nameController.text.trim();
                    if (name.length < 2) {
                      setState(() => error = t.myProfileNameError);
                      return;
                    }
                    setState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      final updated = await ref.read(companyRepositoryProvider).updateMyContact(
                            fullName: name,
                            contactPhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                            wechatId: wechatController.text.trim().isEmpty ? null : wechatController.text.trim(),
                          );
                      final session = ref.read(sessionProvider);
                      if (session?.company != null) {
                        ref.read(sessionProvider.notifier).updateCompany(session!.company!, updated);
                      }
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    } catch (e) {
                      setState(() {
                        saving = false;
                        error = errorMessage(t, e);
                      });
                    }
                  },
            child: Text(t.commonSave),
          ),
        ],
      ),
    ),
  );
}

/// Подтверждение компании (задача 012, п.5) — ровно один документ
/// (свидетельство о регистрации), по тому же паттерну, что у водителя
/// (DriverVerificationScreen): фото → MinIO → POST verification-documents.
class _CompanyVerificationCard extends ConsumerStatefulWidget {
  const _CompanyVerificationCard({required this.company});

  final Company company;

  @override
  ConsumerState<_CompanyVerificationCard> createState() => _CompanyVerificationCardState();
}

class _CompanyVerificationCardState extends ConsumerState<_CompanyVerificationCard> {
  bool _uploading = false;

  Future<void> _pick(ImageSource source) async {
    final t = context.l10n;
    final picked = await pickPhoto(source);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final key = await ref.read(uploadsRepositoryProvider).uploadDocument(bytes, filename: picked.name);
      await ref.read(companyRepositoryProvider).submitVerificationDocument(fileUrl: key);
      ref.invalidate(companyVerificationDocumentsProvider);
    } catch (e) {
      if (mounted) showApiError(context, e, fallback: t.driverVerificationUploadFailed);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (widget.company.isVerified) return const SizedBox.shrink();
    final docsAsync = ref.watch(companyVerificationDocumentsProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: docsAsync.when(
          loading: () => const LoadingView(),
          error: (e, st) => Text(t.commonError),
          data: (docs) {
            final doc = docs.isEmpty ? null : docs.first;
            final (statusLabel, statusColor) = switch (doc?.status) {
              // Документ одобрен, но admin ещё не поставил isVerified — тот
              // же текст «на проверке», узкое переходное окно между двумя
              // независимыми действиями админа (см. AdminService).
              VerificationDocStatus.pending || VerificationDocStatus.approved => (t.companyVerificationStatusPending, AppColors.accentText),
              VerificationDocStatus.rejected => (t.companyVerificationStatusRejected, AppColors.error),
              null => (t.companyVerificationStatusNone, AppColors.textSecondary),
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(t.companyVerificationTitle, style: Theme.of(context).textTheme.titleSmall)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(t.companyVerificationHint, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(statusLabel, key: const Key('companyVerificationStatus'), style: AppTextStyles.caption.copyWith(color: statusColor)),
                    if (doc?.status == VerificationDocStatus.rejected && doc?.rejectReason != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(doc!.rejectReason!, style: AppTextStyles.caption.copyWith(color: AppColors.error))),
                    ],
                  ],
                ),
                if (doc?.status != VerificationDocStatus.pending) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _uploading ? null : () => _pick(ImageSource.camera),
                          icon: const Icon(LucideIcons.camera),
                          label: Text(t.postCargoAddPhotoCamera),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('companyVerificationGallery'),
                          onPressed: _uploading ? null : () => _pick(ImageSource.gallery),
                          icon: const Icon(LucideIcons.image),
                          label: Text(t.postCargoAddPhotoGallery),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final session = ref.watch(sessionProvider);
    final company = session?.company;
    final isOwner = session?.companyMember?.role == CompanyMemberRole.owner;
    final members = ref.watch(companyMembersProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (session != null && session.user.emailVerifiedAt == null) const _EmailVerifyBanner(),
          // Задача 012, п.4 — компания видит прямо в профиле, почему не
          // может опубликовать груз, а не только натыкается на 403.
          if (company != null && !company.isVerified)
            Card(
              key: const Key('companyNotVerifiedBanner'),
              color: AppColors.primarySoft,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ListTile(
                leading: const Icon(LucideIcons.shieldAlert),
                title: Text(t.companyNotVerifiedBannerText),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company?.name ?? '', style: Theme.of(context).textTheme.headlineSmall),
                    if (company?.nameRu != null && company!.nameRu!.isNotEmpty && company.nameRu != company.name)
                      Text(company.nameRu!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(LucideIcons.pencil),
                  onPressed: company == null ? null : () => _showCompanyEditDialog(context, ref, company),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.star, size: 16, color: Colors.amber),
              Text(' ${company?.ratingAvg.toStringAsFixed(1) ?? '-'} (${company?.ratingCount ?? 0})'),
              const SizedBox(width: 12),
              StatusBadge(
                label: (company?.isVerified ?? false) ? t.profileVerified : t.profileNotVerified,
                color: (company?.isVerified ?? false) ? StatusBadge.success : StatusBadge.neutral,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (company != null) _CompanyVerificationCard(company: company),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(LucideIcons.mail),
            title: Text(t.profileEmail),
            subtitle: Text(session?.user.email ?? '-'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.languages),
            title: Text(t.profileLanguage),
            trailing: DropdownButton<Locale>(
              value: locale,
              items: const [
                DropdownMenuItem(value: Locale('kk'), child: Text('Қазақша')),
                DropdownMenuItem(value: Locale('ru'), child: Text('Русский')),
                DropdownMenuItem(value: Locale('zh'), child: Text('中文')),
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) ref.read(sessionProvider.notifier).setLocale(value.languageCode);
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(t.profileMembers, style: Theme.of(context).textTheme.titleSmall),
          members.when(
            loading: () => const LoadingView(),
            error: (e, st) {
              debugPrint('CompanyProfileScreen (members): $e');
              return Text(t.commonError);
            },
            data: (list) => Column(
              children: list
                  .map((m) => ListTile(
                        leading: const Icon(LucideIcons.user),
                        title: Text(m.fullName ?? m.role.name.toUpperCase()),
                        subtitle: m.fullName == null ? null : Text(m.role.name.toUpperCase()),
                      ))
                  .toList(),
            ),
          ),
          if (isOwner)
            ListTile(
              leading: const Icon(LucideIcons.userPlus),
              title: Text(t.employeesInviteButton),
              onTap: () => _showInviteDialog(context, ref),
            ),
          const SizedBox(height: 16),
          Text(t.myProfileTitle, style: Theme.of(context).textTheme.titleSmall),
          ListTile(
            leading: const Icon(LucideIcons.contact),
            title: Text(session?.companyMember?.fullName ?? t.myProfileNotSetYet),
            subtitle: Text([
              if (session?.companyMember?.contactPhone != null) session!.companyMember!.contactPhone!,
              if (session?.companyMember?.wechatId != null) 'WeChat: ${session!.companyMember!.wechatId}',
            ].join(' · ')),
            onTap: () => _showMyContactDialog(context, ref, session?.companyMember),
          ),
          ListTile(
            leading: const Icon(LucideIcons.smartphone),
            title: Text(t.profileMyDevices),
            onTap: () => context.push('/devices'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.bell),
            title: Text(t.profileNotificationSettings),
            onTap: () => context.push('/notifications/settings'),
          ),
          if (isOwner)
            ListTile(
              leading: const Icon(LucideIcons.messageSquare),
              title: Text(t.companyWecomTitle),
              subtitle: Text(company?.wecomWebhookUrl ?? t.companyWecomHint, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => _showWeComDialog(context, ref, company?.wecomWebhookUrl),
            ),
          ListTile(
            leading: const Icon(LucideIcons.keyRound),
            title: Text(t.companySetPasswordTitle),
            subtitle: Text(t.companySetPasswordHint),
            onTap: () => _showSetPasswordDialog(context, ref),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            key: const Key('companyProfileLogoutButton'),
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
            child: Text(t.profileLogout),
          ),
        ],
      ),
    );
  }
}
