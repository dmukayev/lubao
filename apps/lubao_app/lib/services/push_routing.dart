import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

/// Чистые правила push (042 п.1) — без Firebase, покрыты тестами.

/// Ссылка из push — путь go_router. Общие псевдонимы сервер не знает, как
/// раскрыть (у водителя и логиста разные экраны), — раскрываем здесь.
String resolvePushRoute(String link, UserRole? role) {
  final isDriver = role == UserRole.driver;
  switch (link) {
    case '/verification':
      return isDriver ? '/driver/verification' : '/company/profile';
    case '/arrival':
      // Анонс и вопросы «Доехали?/Ещё ищете?» — наверху ленты водителя.
      return '/driver/feed';
    case '/profile':
      return isDriver ? '/driver/profile' : '/company/profile';
  }
  // Ссылки из старых сборок сервера (lubao://chat/…) — тот же путь.
  if (link.startsWith('lubao://')) return '/${link.substring('lubao://'.length)}';
  return link.startsWith('/') ? link : '/$link';
}

/// Корни вкладок (и их псевдонимы-редиректы) водителя и логиста.
const _tabRoutes = {
  '/driver/feed', '/driver/trips', '/driver/deals', '/driver/responses', '/driver/chats', '/driver/profile',
  '/company/cargos', '/company/deals', '/company/drivers', '/company/chats', '/company/profile',
};

/// 061 п.2: адрес вкладки — сам корень оболочки; `push` поверх чата или сделки
/// дал бы вторую копию оболочки («Duplicate GlobalKey») или ленту в чужой вкладке.
bool isTabRoute(String route) => _tabRoutes.contains(Uri.parse(route).path);

/// Открыть ссылку из push: вкладка — `go` (вложенные экраны закрываются),
/// вложенный экран (чат, сделка, груз, отклики, история) — `push` поверх.
void openPushLink(GoRouter router, String link, UserRole? role) {
  final route = resolvePushRoute(link, role);
  if (isTabRoute(route)) {
    router.go(route);
  } else {
    router.push(route);
  }
}

/// Кнопки в push: «Ещё ищете груз?» — Да / Уехал, «Договорились?» — Да / Нет.
enum PushAction { stillLookingYes, stillLookingLeft, agreedYes, agreedNo }

const pushCategoryStillLooking = 'STILL_LOOKING';
const pushCategoryAgreed = 'AGREED_CHECK';

const _actionIds = {
  PushAction.stillLookingYes: 'STILL_LOOKING_YES',
  PushAction.stillLookingLeft: 'STILL_LOOKING_LEFT',
  PushAction.agreedYes: 'AGREED_YES',
  PushAction.agreedNo: 'AGREED_NO',
};

String pushActionId(PushAction action) => _actionIds[action]!;

PushAction? pushActionFromId(String? id) {
  for (final entry in _actionIds.entries) {
    if (entry.value == id) return entry.key;
  }
  return null;
}

/// Кнопки категории с подписями на языке устройства.
List<(PushAction, String)> pushActionsFor(String? category, LubaoLocalizations t) => switch (category) {
      pushCategoryStillLooking => [(PushAction.stillLookingYes, t.arrivalStillYes), (PushAction.stillLookingLeft, t.arrivalStillLeft)],
      pushCategoryAgreed => [(PushAction.agreedYes, t.commonYes), (PushAction.agreedNo, t.commonNo)],
      _ => const [],
    };
