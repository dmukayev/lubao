import 'package:flutter/widgets.dart';

/// 060: у каждой вкладки нижнего меню — свой контроллер прокрутки
/// (PrimaryScrollController): списки вкладки берут его сами, а повторное
/// нажатие на активную вкладку прокручивает наверх.
final _controllers = <String, ScrollController>{};

ScrollController tabScrollController(String id) => _controllers.putIfAbsent(id, ScrollController.new);

/// Корень вкладки: экран со своим PrimaryScrollController.
Widget tabRoot(String id, Widget child) => PrimaryScrollController(controller: tabScrollController(id), child: child);

/// 061 п.11: списки со своим контроллером (подгрузка по `position`, несколько
/// списков во вкладке) — тоже наверх по повторному нажатию.
final _attached = <String, Set<ScrollController>>{};

void attachTabScroll(String id, ScrollController controller) => _attached.putIfAbsent(id, () => {}).add(controller);

void detachTabScroll(String id, ScrollController controller) => _attached[id]?.remove(controller);

/// Повторное нажатие на активную вкладку — наверх (все прикреплённые списки).
void scrollTabToTop(String id) {
  for (final controller in [?_controllers[id], ...?_attached[id]]) {
    for (final position in List.of(controller.positions)) {
      position.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }
}
