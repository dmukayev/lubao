import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_app/services/push_routing.dart';
import 'package:lubao_core/lubao_core.dart';

void main() {
  group('resolvePushRoute (042 п.1)', () {
    test('маршруты приложения — как есть', () {
      expect(resolvePushRoute('/chat/c1', UserRole.driver), '/chat/c1');
      expect(resolvePushRoute('/driver/cargo/x', UserRole.driver), '/driver/cargo/x');
      expect(resolvePushRoute('/company/cargos/x/responses', UserRole.company), '/company/cargos/x/responses');
    });

    test('псевдонимы раскрываются по роли', () {
      expect(resolvePushRoute('/verification', UserRole.driver), '/driver/verification');
      expect(resolvePushRoute('/verification', UserRole.company), '/company/profile');
      expect(resolvePushRoute('/profile', UserRole.company), '/company/profile');
      expect(resolvePushRoute('/arrival', UserRole.driver), '/driver/feed');
    });

    test('ссылки старого сервера lubao://… не теряются', () {
      expect(resolvePushRoute('lubao://chat/c1', UserRole.driver), '/chat/c1');
    });
  });

  group('кнопки push', () {
    final t = lookupLubaoLocalizations(const Locale('ru'));

    test('«Ещё ищете груз?» — Да / Уехал, «Договорились?» — Да / Нет', () {
      expect(pushActionsFor('STILL_LOOKING', t).map((a) => a.$1), [PushAction.stillLookingYes, PushAction.stillLookingLeft]);
      expect(pushActionsFor('AGREED_CHECK', t).map((a) => a.$2), [t.commonYes, t.commonNo]);
      expect(pushActionsFor(null, t), isEmpty);
    });

    test('идентификаторы кнопок совпадают с AppDelegate и обратимы', () {
      for (final action in PushAction.values) {
        expect(pushActionFromId(pushActionId(action)), action);
      }
      expect(pushActionId(PushAction.stillLookingLeft), 'STILL_LOOKING_LEFT');
      expect(pushActionFromId('UNKNOWN'), isNull);
    });
  });
}
