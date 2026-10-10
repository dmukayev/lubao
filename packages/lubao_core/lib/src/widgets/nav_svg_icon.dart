import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Иконки нижнего меню (эталон 33, design/brand/nav): свои цветные SVG —
/// одинаковы на iOS, Android и в вебе.
enum NavIconAsset { cargo, trips, boxes, drivers, chats, profile }

/// Цветная иконка вкладки: выбранная — как в файле (подложку `primarySoft`
/// рисует NavigationBar), невыбранная — прозрачность 0,8. Бейдж-цифра —
/// красный кружок справа сверху; [badgeKey] — на бейдже всегда (для тестов).
class NavSvgIcon extends StatelessWidget {
  const NavSvgIcon(this.asset, {super.key, this.selected = false, this.count = 0, this.badgeKey});

  final NavIconAsset asset;
  final bool selected;
  final int count;
  final Key? badgeKey;

  static const double size = 30;

  @override
  Widget build(BuildContext context) {
    final icon = Opacity(
      opacity: selected ? 1 : 0.8,
      child: SvgPicture.asset('assets/nav/${asset.name}.svg', package: 'lubao_core', width: size, height: size),
    );
    if (badgeKey == null && count <= 0) return icon;
    return Badge.count(
      key: badgeKey,
      count: count,
      isLabelVisible: count > 0,
      backgroundColor: AppColors.error,
      child: icon,
    );
  }
}

/// Вкладка нижнего меню с цветной иконкой (обычная и выбранная).
NavigationDestination navDestination(NavIconAsset asset, String label, {int count = 0, Key? badgeKey}) => NavigationDestination(
      icon: NavSvgIcon(asset, count: count, badgeKey: badgeKey),
      selectedIcon: NavSvgIcon(asset, selected: true, count: count, badgeKey: badgeKey),
      label: label,
    );
