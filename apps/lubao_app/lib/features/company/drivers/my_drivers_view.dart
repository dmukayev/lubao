import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../shared/driver_avatar.dart';
import '../../shared/error_feedback.dart';
import '../../shared/status_helpers.dart';
import 'invite_cargo_picker.dart';

/// 058 п.6: «Мои» в «Водителях» — общий список компании: с кем были сделки,
/// сохранённые ☆ и заведённые компанией. «Ищет груз» и на месте — сверху;
/// пригласить на груз — одним нажатием; «Создать водителя».
class MyDriversView extends ConsumerWidget {
  const MyDriversView({super.key});

  Future<void> _invite(BuildContext context, WidgetRef ref, CompanyDriverEntry driver) async {
    final t = context.l10n;
    final cargos = (await ref.read(myCargosProvider.future)).where((c) => c.status == CargoStatus.published).toList();
    if (!context.mounted) return;
    if (cargos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.driversAtPointNoCargos)));
      return;
    }
    final cargo = await showInviteCargoPicker(context, driverName: driver.name, cargos: cargos, refData: ref.read(referenceDataProvider).valueOrNull);
    if (cargo == null || !context.mounted) return;
    try {
      await ref.read(cargoRepositoryProvider).inviteDriver(cargo.id, driver.driverId!);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.driversAtPointInviteSent)));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseConflictText(t, e) ?? errorMessage(t, e))));
    }
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final input = await showModalBottomSheet<({String name, String phone})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _CreateDriverSheet(),
    );
    if (input == null || !context.mounted) return;
    try {
      final res = await ref.read(companyDriversRepositoryProvider).create(name: input.name, phone: input.phone);
      ref.invalidate(myDriversProvider);
      if (!context.mounted) return;
      switch (res.result) {
        case CreateDriverResult.alreadyInList:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.myDriversAlready)));
        case CreateDriverResult.invitedExisting:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.myDriversInvitedExisting)));
        case CreateDriverResult.created:
          // Ссылку логист отправляет сам — системное меню (WhatsApp и т. п.).
          final company = ref.read(sessionProvider)?.company?.name ?? '';
          await SharePlus.instance.share(ShareParams(text: t.myDriversShareText(company, res.url)));
      }
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final async = ref.watch(myDriversProvider);
    final create = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
      child: OutlinedButton.icon(
        key: const Key('myDriversCreate'),
        icon: const Icon(LucideIcons.userPlus, size: 18),
        label: Text(t.myDriversCreate),
        onPressed: () => _create(context, ref),
      ),
    );
    return async.when(
      loading: () => const SkeletonList(lines: 2),
      error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(myDriversProvider)),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(myDriversProvider),
        child: ListView(
          key: const Key('myDriversList'),
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            create,
            if (list.isEmpty)
              Padding(padding: const EdgeInsets.all(AppSpacing.screen), child: EmptyState(message: t.myDriversEmpty)),
            for (final d in list) _MyDriverCard(driver: d, onInvite: d.driverId == null || d.pending ? null : () => _invite(context, ref, d)),
          ],
        ),
      ),
    );
  }
}

class _MyDriverCard extends ConsumerWidget {
  const _MyDriverCard({required this.driver, this.onInvite});

  final CompanyDriverEntry driver;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final seen = formatLastSeen(t, driver.lastSeenAt);
    final status = [
      if (driver.pending) t.myDriversWaiting,
      if (driver.onSite) t.myDriversOnSite else if (driver.searching) t.myDriversSearching,
      ?seen,
    ].join(' · ');
    return AppCard(
      key: Key('myDriverCard-${driver.driverId ?? driver.rowId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (driver.driverId != null) ...[
                DriverAvatar(driverId: driver.driverId!, name: driver.name, version: driver.avatarVersion, radius: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(driver.name, style: AppTextStyles.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (driver.isVerified) ...[const SizedBox(width: AppSpacing.xs), const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.primary)],
                        if (driver.ratingCount > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(LucideIcons.star, size: 13, color: AppColors.accent),
                          Text(' ${driver.ratingAvg.toStringAsFixed(1)}', style: AppTextStyles.caption),
                        ],
                      ],
                    ),
                    if (status.isNotEmpty)
                      Text(status, style: AppTextStyles.caption.copyWith(color: driver.searching || driver.onSite || seen == t.lastSeenOnline ? AppColors.success : AppColors.textSecondary)),
                  ],
                ),
              ),
              if (driver.saved && driver.driverId != null)
                IconButton(
                  key: Key('myDriverUnsave-${driver.driverId}'),
                  tooltip: t.driverUnsave,
                  icon: const Icon(Icons.star_rounded, color: AppColors.accent),
                  onPressed: () async {
                    try {
                      await ref.read(companyDriversRepositoryProvider).setSaved(driver.driverId!, false);
                    } catch (e) {
                      if (context.mounted) showApiError(context, e);
                    }
                    ref.invalidate(myDriversProvider);
                  },
                ),
            ],
          ),
          if (onInvite != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(key: Key('myDriverInvite-${driver.driverId}'), onPressed: onInvite, child: Text(t.myDriversInvite)),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateDriverSheet extends StatefulWidget {
  const _CreateDriverSheet();

  @override
  State<_CreateDriverSheet> createState() => _CreateDriverSheetState();
}

class _CreateDriverSheetState extends State<_CreateDriverSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController(text: '+7');
  bool _tried = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _phoneOk => RegExp(r'^\+\d{10,15}$').hasMatch(_phone.text.replaceAll(RegExp(r'[^\d+]'), ''));

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.myDriversCreate, style: AppTextStyles.headline),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const Key('myDriversCreateName'),
              label: t.myDriversName,
              controller: _name,
              errorText: _tried && _name.text.trim().length < 2 ? t.fieldRequired : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const Key('myDriversCreatePhone'),
              label: t.myDriversPhone,
              hintText: t.myDriversPhoneHint,
              controller: _phone,
              keyboardType: TextInputType.phone,
              errorText: _tried && !_phoneOk ? t.myDriversPhoneError : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              key: const Key('myDriversCreateSubmit'),
              label: t.myDriversCreate,
              onPressed: () {
                if (_name.text.trim().length < 2 || !_phoneOk) return setState(() => _tried = true);
                Navigator.pop(context, (name: _name.text.trim(), phone: _phone.text.trim()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
