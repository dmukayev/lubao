import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/common.dart';
import '../theme/app_theme.dart';
import 'body_type_icon.dart';

enum VehiclePhotoAngle { front, side }

/// Подсказка к фото машины (053 п.2, эталон 31): рамка видоискателя.
/// Спереди — кабина анфас с выделенным номером (`photo-front.svg`); сбоку —
/// вся машина: иконка кузова этой машины (не всегда тент) в той же рамке.
class VehiclePhotoHint extends StatelessWidget {
  const VehiclePhotoHint({super.key, required this.angle, this.bodyTypeCode, this.vehicleKind});

  final VehiclePhotoAngle angle;
  final String? bodyTypeCode;
  final VehicleKind? vehicleKind;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.field)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: angle == VehiclePhotoAngle.front
              ? SvgPicture.asset('packages/lubao_core/assets/vehicles/photo-front.svg', fit: BoxFit.contain)
              : CustomPaint(
                  painter: _ViewfinderPainter(),
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: BodyTypeIcon(bodyTypeCode: bodyTypeCode, vehicleKind: vehicleKind, width: 200),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Уголки рамки видоискателя — как в `photo-front.svg`.
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final l = size.shortestSide * 0.15;
    final w = size.width, h = size.height;
    for (final p in [
      [Offset(0, l), Offset.zero, Offset(l, 0)],
      [Offset(w - l, 0), Offset(w, 0), Offset(w, l)],
      [Offset(w, h - l), Offset(w, h), Offset(w - l, h)],
      [Offset(l, h), Offset(0, h), Offset(0, h - l)],
    ]) {
      canvas.drawPath(Path()..moveTo(p[0].dx, p[0].dy)..lineTo(p[1].dx, p[1].dy)..lineTo(p[2].dx, p[2].dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
