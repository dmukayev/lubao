import 'package:flutter/material.dart';

/// Фирменный знак Lubao (design/brand/README.md). Картинки — из ассетов
/// lubao_core, поэтому одинаковы в приложении и админке.
abstract final class LubaoBrand {
  static const orange = Color(0xFFE8742E);
  static const cream = Color(0xFFFFF3DC);
  static const dark = Color(0xFF1A1D26);

  static const _base = 'packages/lubao_core/assets/brand';
  static const iconAsset = '$_base/icon.png';
  static const markAsset = '$_base/mark.png';
  static const logoAsset = '$_base/logo-horizontal.png';
  static const logoLightAsset = '$_base/logo-horizontal-light.png';
}

/// Иконка приложения (кремовая плитка) — стартовый экран, «О приложении».
class LubaoAppIcon extends StatelessWidget {
  const LubaoAppIcon({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(LubaoBrand.iconAsset, width: size, height: size, filterQuality: FilterQuality.medium, semanticLabel: 'Lubao');
  }
}

/// Знак + «Lubao» в строку — шапки экранов входа и админки.
class LubaoLogo extends StatelessWidget {
  const LubaoLogo({super.key, this.height = 32, this.onDark = false});

  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      onDark ? LubaoBrand.logoLightAsset : LubaoBrand.logoAsset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Lubao',
    );
  }
}
