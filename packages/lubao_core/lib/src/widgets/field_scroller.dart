import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 072 (decisions.md «Незаполненное поле — прокрутка к нему»): форма
/// регистрирует поля по порядку; после «Опубликовать / Сохранить / Готово»
/// экран плавно прокручивается к первому неверному полю. Текстовое поле
/// получает фокус (клавиатура открыта), выбор (чипы, город, кузов, дата, фото)
/// коротко мигает красной рамкой. Текст ошибки — под полем, у самой формы.
///
/// Списки формы — с большим `cacheExtent`, чтобы поле за краем экрана уже было
/// построено (иначе прокрутить к нему нечем).
class FieldScroller {
  final _keys = <String, GlobalKey>{};
  final _focus = <String, FocusNode>{};

  /// Поле, которое сейчас мигает рамкой.
  final flashing = ValueNotifier<String?>(null);

  /// Ключ обёртки поля (`FieldAnchor`) — по нему ищем, куда прокрутить.
  GlobalKey keyOf(String name) => _keys.putIfAbsent(name, () => GlobalKey(debugLabel: 'field-$name'));

  /// Фокус текстового поля: после прокрутки — в него (клавиатура открыта).
  FocusNode focusOf(String name) => _focus.putIfAbsent(name, FocusNode.new);

  /// Первое по порядку поле из [invalid] — прокрутить к нему, затем фокус или
  /// мигание. `order` — порядок полей в форме сверху вниз.
  Future<void> showFirstInvalid(List<String> order, Set<String> invalid) async {
    for (final name in order) {
      if (invalid.contains(name)) return reveal(name);
    }
  }

  Future<void> reveal(String name) async {
    final context = _keys[name]?.currentContext;
    if (context == null || !context.mounted) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      // Ближе к верху: поле не под шапкой и не под клавиатурой.
      alignment: 0.15,
    );
    final focus = _focus[name];
    if (focus != null && focus.context != null) {
      focus.requestFocus();
      return;
    }
    flashing.value = name;
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (flashing.value == name) flashing.value = null;
  }

  void dispose() {
    for (final f in _focus.values) {
      f.dispose();
    }
    flashing.dispose();
  }
}

/// Обёртка поля формы: ключ для прокрутки и короткая красная рамка, когда
/// поле — выбор (чипы, город, кузов, дата) и его забыли заполнить.
class FieldAnchor extends StatelessWidget {
  const FieldAnchor({super.key, required this.scroller, required this.name, required this.child});

  final FieldScroller scroller;
  final String name;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: scroller.keyOf(name),
      child: ValueListenableBuilder<String?>(
        valueListenable: scroller.flashing,
        builder: (context, flashing, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: flashing == name ? AppColors.error : Colors.transparent, width: 2),
          ),
          child: child,
        ),
        child: child,
      ),
    );
  }
}
