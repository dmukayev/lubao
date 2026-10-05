import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import 'admin_status_helpers.dart';

/// Журнал действий админа — общий виджет для карточек водителя, компании,
/// груза и сделки (задача 029, п.19: раньше каждая карточка дублировала
/// один и тот же `_LogTab`, который показывал сырой код действия без
/// разбора `metadata`). Каждая запись рендерится через [AuditLogEntryTile]
/// — тот же виджет, что и в общем журнале [AdminAuditScreen].
class AuditLogTab extends StatelessWidget {
  const AuditLogTab({super.key, required this.entries});

  final List<AdminAuditLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (entries.isEmpty) return Center(child: Text(t.adminNoLog));
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, i) => AuditLogEntryTile(entry: entries[i]),
    );
  }
}

/// Одна запись журнала — код действия через ARB, причина, и если в
/// `metadata.changes` (или `{from, to}` у DEAL_STATUS_FIXED) есть
/// старое/новое значение по полю — «Поле: было → стало» под причиной.
class AuditLogEntryTile extends StatelessWidget {
  const AuditLogEntryTile({super.key, required this.entry, this.showEntityType = false});

  final AdminAuditLogEntry entry;
  final bool showEntityType;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final e = entry;
    final reason = e.metadata?['reason'] as String?;
    final changes = e.metadata?['changes'];
    final from = e.metadata?['from'] as String?;
    final to = e.metadata?['to'] as String?;
    final subtitleParts = [
      if (showEntityType && e.entityType != null) e.entityType!,
      if (e.actorName != null) e.actorName!,
      if (reason != null) reason,
    ];
    final rows = <Widget>[
      ListTile(
        title: Text(auditActionLabel(t, e.action)),
        subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
        trailing: Text(formatAdminDateTime(e.createdAt)),
      ),
    ];
    // DEAL_STATUS_FIXED пишет {from, to} вместо дженерик changes-карты —
    // показываем как тот же «было → стало», ярлык статуса через
    // dealStatusLabel.
    if (from != null && to != null) {
      rows.add(_ChangeRow(label: t.adminAuditFieldStatus, oldValue: dealStatusLabel(t, from), newValue: dealStatusLabel(t, to)));
    }
    if (changes is Map) {
      rows.addAll(_changeRows(t, Map<String, dynamic>.from(changes)));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  List<Widget> _changeRows(LubaoLocalizations t, Map<String, dynamic> changes, {String? parentLabel}) {
    final rows = <Widget>[];
    for (final changeEntry in changes.entries) {
      final value = changeEntry.value;
      if (value is! Map || !value.containsKey('old') || !value.containsKey('new')) continue;
      final label = parentLabel != null ? '$parentLabel · ${auditFieldLabel(t, changeEntry.key)}' : auditFieldLabel(t, changeEntry.key);
      final newValue = value['new'];
      if (newValue is Map) {
        // Вложенные изменения, напр. смена машины внутри правки водителя
        // (changes.vehicle = {old: null, new: {plateNumber: {old,new}, …}}).
        rows.addAll(_changeRows(t, Map<String, dynamic>.from(newValue), parentLabel: label));
      } else {
        rows.add(_ChangeRow(label: label, oldValue: formatAuditValue(t, value['old']), newValue: formatAuditValue(t, newValue)));
      }
    }
    return rows;
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.label, required this.oldValue, required this.newValue});

  final String label;
  final String oldValue;
  final String newValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Text(
        '$label: $oldValue → $newValue',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
