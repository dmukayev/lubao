import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';

/// Карточка «Идентификаторы» (задача 031, п.24) — подтверждённые значения
/// (маски, с кнопкой «Показать» на полное значение) и история блокировок.
/// Общая для карточек водителя и компании — машины водителя передаются
/// объединённо с самим водителем вызывающей стороной.
class IdentifiersCard extends ConsumerStatefulWidget {
  const IdentifiersCard({super.key, required this.identifiers, required this.blockHistory});

  final List<AdminIdentifierEntry> identifiers;
  final List<AdminIdentifierBlockEntry> blockHistory;

  @override
  ConsumerState<IdentifiersCard> createState() => _IdentifiersCardState();
}

class _IdentifiersCardState extends ConsumerState<IdentifiersCard> {
  final Map<String, String> _revealed = {};

  Future<void> _reveal(String identifierId) async {
    final value = await ref.read(adminRepositoryProvider).revealIdentifier(identifierId);
    if (value != null && mounted) setState(() => _revealed[identifierId] = value);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (widget.identifiers.isEmpty && widget.blockHistory.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminIdentifiersCardTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final identifier in widget.identifiers)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 140, child: Text(identifier.type, style: Theme.of(context).textTheme.bodySmall)),
                  Expanded(child: Text(_revealed[identifier.id] ?? identifier.valueMasked)),
                  if (_revealed[identifier.id] == null)
                    TextButton(onPressed: () => _reveal(identifier.id), child: Text(t.adminIdentifierReveal)),
                ],
              ),
            ),
          if (widget.blockHistory.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 4),
            Text(t.adminIdentifierBlockHistoryTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final block in widget.blockHistory)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${block.type} ${block.valueMasked} · ${block.reason}'
                        '${block.liftedAt != null && block.liftReason != null ? ' → ${block.liftReason}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: block.liftedAt == null ? t.adminIdentifierActive : t.adminIdentifierLifted,
                      color: block.liftedAt == null ? StatusBadge.danger : StatusBadge.neutral,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
