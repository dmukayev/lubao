import 'package:flutter/material.dart';

/// Точка перелома раскладки — задача 030, п.1: < 700 px — мобильная
/// (снизу навигация, одна панель за раз), ≥ 700 — как на компьютере
/// (боковое меню, список+карточка рядом).
const double adminMobileBreakpoint = 700;

bool isMobileWidth(BuildContext context) => MediaQuery.sizeOf(context).width < adminMobileBreakpoint;

/// Общий «список слева, карточка справа» (проверка, жалобы) — на
/// компьютере обе панели видны одновременно; на телефоне — по одной:
/// список, пока ничего не выбрано, выбранная карточка во всю ширину
/// после выбора (задача 030, п.1/5/6). Назад с карточки на телефоне —
/// дело вызывающего экрана (обычно сброс id выбора в AppBar.leading).
class ResponsiveMasterDetail extends StatelessWidget {
  const ResponsiveMasterDetail({
    super.key,
    required this.master,
    required this.detail,
    required this.hasSelection,
    this.masterWidth = 380,
  });

  final Widget master;
  final Widget detail;
  final bool hasSelection;
  final double masterWidth;

  @override
  Widget build(BuildContext context) {
    if (isMobileWidth(context)) {
      return hasSelection ? detail : master;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: masterWidth, child: master),
        const VerticalDivider(width: 1),
        Expanded(child: detail),
      ],
    );
  }
}

/// Две колонки рядом на компьютере (напр. документы+машина слева,
/// вкладки справа), друг под другом на телефоне — без горизонтального
/// сжатия карточек до нечитаемой ширины (задача 030, п.1/7).
class ResponsiveTwoColumn extends StatelessWidget {
  const ResponsiveTwoColumn({super.key, required this.left, required this.right, this.leftFlex = 2, this.rightFlex = 3});

  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    if (isMobileWidth(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [left, const SizedBox(height: 16), right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: left),
        const SizedBox(width: 16),
        Expanded(flex: rightFlex, child: right),
      ],
    );
  }
}
