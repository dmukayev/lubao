import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import 'admin_status_helpers.dart';

/// «Отмены» в карточке водителя/компании (046 п.3): те же цифры, что видит
/// вторая сторона, и последние отмены — кто, почему, на каком этапе, чья вина.
class CancellationsCard extends StatelessWidget {
  const CancellationsCard({super.key, required this.stats, required this.items});

  final CancelStats? stats;
  final List<AdminCancellation> items;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (items.isEmpty && (stats?.cancelled ?? 0) == 0) return const SizedBox.shrink();
    final summary = cancelStatsText(t, stats);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AppCard(
        key: const Key('adminCancellations'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.adminCancellationsTitle, style: Theme.of(context).textTheme.titleMedium),
            if (summary != null) ...[
              const SizedBox(height: 4),
              Text(
                [summary, if ((stats?.selfFault ?? 0) > 0) '${t.cancelAtFault} ${stats!.selfFault}'].join(' · '),
                key: const Key('adminCancelStats'),
              ),
            ],
            for (final c in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(Icons.cancel_outlined, color: c.atFault ? StatusBadge.danger : StatusBadge.neutral),
                title: Text(cancelReasonLabel(t, c.reasonCode, text: c.reason)),
                subtitle: Text([
                  cancelledByRoleLabel(t, c.cancelledByRole ?? ''),
                  if (cancelStageLabel(t, c.stage) case final stage?) stage,
                  if (c.atFault) t.cancelAtFault,
                  formatAdminDateTime(c.at),
                ].join(' · ')),
                onTap: () => context.go('/deals/${c.dealId}'),
              ),
          ],
        ),
      ),
    );
  }
}
