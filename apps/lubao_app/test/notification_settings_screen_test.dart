import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/shared/notification_settings_screen.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/providers/locale_provider.dart';

class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository() : super(ApiClient(baseUrl: 'http://localhost'));

  List<NotificationEventSetting> settings = const [
    NotificationEventSetting(eventGroup: NotificationEventGroup.chatMessage, enabled: true),
    NotificationEventSetting(eventGroup: NotificationEventGroup.dealStatus, enabled: false),
  ];

  NotificationEventGroup? lastToggledGroup;
  bool? lastToggledValue;

  @override
  Future<List<NotificationEventSetting>> eventSettings() async => settings;

  @override
  Future<void> setEventSetting(NotificationEventGroup group, bool enabled) async {
    lastToggledGroup = group;
    lastToggledValue = enabled;
  }
}

void main() {
  testWidgets('renders a toggle per event group, reflecting enabled/disabled state, and calls the repository on tap', (tester) async {
    final repo = _FakeNotificationsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repo),
          localeProvider.overrideWith((ref) => const Locale('ru')),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: supportedLocales,
          localizationsDelegates: LubaoLocalizations.localizationsDelegates,
          home: const NotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwitchListTile), findsNWidgets(2));

    final switches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
    expect(switches[0].value, isTrue);
    expect(switches[1].value, isFalse);

    await tester.tap(find.byType(SwitchListTile).last);
    await tester.pumpAndSettle();

    expect(repo.lastToggledGroup, NotificationEventGroup.dealStatus);
    expect(repo.lastToggledValue, isTrue);
  });
}
