import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/error_feedback.dart';

Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
  ref.invalidate(driverCompaniesProvider);
}

/// 058 п.6: при входе — «Компания X добавила вас в свои водители» →
/// «Принять» / «Отказаться». Без «Принять» компания видит только имя.
class CompanyInviteCards extends ConsumerWidget {
  const CompanyInviteCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final pending = (ref.watch(driverCompaniesProvider).valueOrNull ?? const <DriverCompanyEntry>[]).where((c) => c.pending).toList();
    if (pending.isEmpty) return const SizedBox.shrink();
    final repo = ref.read(companyDriversRepositoryProvider);
    return Column(
      children: [
        for (final c in pending)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
            child: AppCard(
              key: Key('companyInviteCard-${c.companyId}'),
              borderColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.driverCompanyInviteTitle(c.companyName), style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.xs),
                  Text(t.driverCompanyInviteBody, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: Key('companyInviteDecline-${c.companyId}'),
                          onPressed: () => _run(context, ref, () => repo.decline(c.companyId)),
                          child: Text(t.driverCompanyDecline),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          key: Key('companyInviteAccept-${c.companyId}'),
                          onPressed: () => _run(context, ref, () => repo.accept(c.companyId)),
                          child: Text(t.driverCompanyAccept),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 058 п.6: «Компании, где я в списке» в профиле — выйти из любой.
class DriverCompaniesSection extends ConsumerWidget {
  const DriverCompaniesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final list = ref.watch(driverCompaniesProvider).valueOrNull ?? const <DriverCompanyEntry>[];
    if (list.isEmpty) return const SizedBox.shrink();
    final repo = ref.read(companyDriversRepositoryProvider);
    return Column(
      key: const Key('driverCompaniesSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(t.driverCompaniesTitle, style: AppTextStyles.bodyStrong),
        for (final c in list)
          ListTile(
            key: Key('driverCompany-${c.companyId}'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.building2),
            title: Text(c.companyName),
            subtitle: c.pending ? Text(t.driverCompanyPending) : null,
            trailing: c.pending
                ? TextButton(onPressed: () => _run(context, ref, () => repo.accept(c.companyId)), child: Text(t.driverCompanyAccept))
                : TextButton(
                    key: Key('driverCompanyLeave-${c.companyId}'),
                    onPressed: () => _run(context, ref, () => repo.leave(c.companyId)),
                    child: Text(t.driverCompaniesLeave),
                  ),
          ),
      ],
    );
  }
}
