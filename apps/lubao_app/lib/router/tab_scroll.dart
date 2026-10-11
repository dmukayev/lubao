import 'package:flutter/widgets.dart';

/// 060: у каждой вкладки нижнего меню — свой контроллер прокрутки
/// (PrimaryScrollController): списки вкладки берут его сами, а повторное
/// нажатие на активную вкладку прокручивает наверх.
final _controllers = <String, ScrollController>{};

ScrollController tabScrollController(String id) => _controllers.putIfAbsent(id, ScrollController.new);

/// Корень вкладки: экран со своим PrimaryScrollController.
Widget tabRoot(String id, Widget child) => PrimaryScrollController(controller: tabScrollController(id), child: child);

/// Повторное нажатие на активную вкладку — наверх (все прикреплённые списки).
void scrollTabToTop(String id) {
  final controller = _controllers[id];
  if (controller == null) return;
  for (final position in List.of(controller.positions)) {
    position.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }
}
