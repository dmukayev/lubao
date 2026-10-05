import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_admin/features/shared/audit_log_tab.dart';
import 'package:lubao_admin/providers/locale_provider.dart';
import 'package:lubao_core/lubao_core.dart';

/// Задача 029, п.19 — журнал показывал сырой код действия без разбора
/// `metadata`. Проверяем: перевод кода действия, «Поле: было → стало» по
/// `changes`, вложенные изменения (смена машины), и {from,to} у
/// DEAL_STATUS_FIXED.
void main() {
  Future<void> pump(WidgetTester tester, AdminAuditLogEntry entry) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: supportedLocales,
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        home: Scaffold(body: AuditLogEntryTile(entry: entry)),
      ),
    );
  }

  testWidgets('translates the action code instead of showing the raw string', (tester) async {
    await pump(
      tester,
      AdminAuditLogEntry(id: '1', action: 'DRIVER_VERIFIED', actorName: 'admin@lubao.kz', createdAt: DateTime(2026, 1, 1)),
    );

    expect(find.text('Водитель подтверждён'), findsOneWidget);
    expect(find.text('DRIVER_VERIFIED'), findsNothing);
  });

  testWidgets('renders old → new for every changed field', (tester) async {
    await pump(
      tester,
      AdminAuditLogEntry(
        id: '2',
        action: 'COMPANY_UPDATED',
        actorName: 'admin@lubao.kz',
        createdAt: DateTime(2026, 1, 1),
        metadata: {
          'reason': 'Опечатка в адресе',
          'changes': {
            'legalAddress': {'old': 'ул. Старая, 1', 'new': 'ул. Новая, 2'},
          },
        },
      ),
    );

    expect(find.textContaining('Юридический адрес: ул. Старая, 1 → ул. Новая, 2'), findsOneWidget);
  });

  testWidgets('flattens nested vehicle changes with a combined label', (tester) async {
    await pump(
      tester,
      AdminAuditLogEntry(
        id: '3',
        action: 'DRIVER_UPDATED',
        createdAt: DateTime(2026, 1, 1),
        metadata: {
          'changes': {
            'vehicle': {
              'old': null,
              'new': {
                'plateNumber': {'old': '123ABC01', 'new': '456DEF02'},
              },
            },
          },
        },
      ),
    );

    expect(find.textContaining('Транспорт · Госномер: 123ABC01 → 456DEF02'), findsOneWidget);
  });

  testWidgets('DEAL_STATUS_FIXED renders {from,to} as a status change row', (tester) async {
    await pump(
      tester,
      AdminAuditLogEntry(
        id: '4',
        action: 'DEAL_STATUS_FIXED',
        createdAt: DateTime(2026, 1, 1),
        metadata: {'from': 'SELECTED', 'to': 'LOADED'},
      ),
    );

    expect(find.textContaining('Статус: Выбран → Загружен'), findsOneWidget);
  });

  testWidgets('an unmapped action code falls back to the raw string, not a crash', (tester) async {
    await pump(tester, AdminAuditLogEntry(id: '5', action: 'SOME_FUTURE_ACTION', createdAt: DateTime(2026, 1, 1)));

    expect(find.text('SOME_FUTURE_ACTION'), findsOneWidget);
  });
}
