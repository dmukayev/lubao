import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Значок WhatsApp: облачко с хвостиком внизу слева и трубка внутри — чтобы
/// кнопка не путалась с чатом приложения (раньше обе были «облачками»
/// Lucide). Рисуется сам, без svg-пакетов и сетевых шрифтов.
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 22, this.color = whatsappGreen});

  static const whatsappGreen = Color(0xFF25D366);
  /// Фон кнопки под значком — светлый зелёный, в пару к `primarySoft`.
  static const whatsappSoft = Color(0xFFE3F8EB);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(dimension: size, child: CustomPaint(painter: _WhatsAppPainter(color)));
  }
}

class _WhatsAppPainter extends CustomPainter {
  _WhatsAppPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Координаты в сетке 24×24, как у иконок Lucide.
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Облачко: окружность, разомкнутая внизу слева, и хвостик к углу.
    const center = Offset(12.4, 11.6);
    const r = 9.0;
    final bubble = Path()
      ..moveTo(4.6, 16.2)
      ..arcTo(Rect.fromCircle(center: center, radius: r), math.pi * 0.83, math.pi * 1.74, false)
      ..lineTo(3, 21)
      ..close();
    canvas.drawPath(bubble, stroke);

    // Трубка: залитая, наклонённая, как в оригинальном знаке.
    final fill = Paint()..color = color;
    final handset = Path()
      ..moveTo(9.3, 7.4)
      ..cubicTo(8.7, 7.4, 8.1, 8.0, 8.1, 9.0)
      ..cubicTo(8.1, 11.4, 10.6, 14.6, 13.6, 15.6)
      ..cubicTo(14.7, 16.0, 15.6, 15.5, 15.9, 14.8)
      ..lineTo(16.1, 14.1)
      ..cubicTo(16.2, 13.8, 16.0, 13.6, 15.8, 13.5)
      ..lineTo(14.2, 12.7)
      ..cubicTo(14.0, 12.6, 13.8, 12.7, 13.6, 12.9)
      ..lineTo(13.1, 13.5)
      ..cubicTo(12.0, 13.0, 11.0, 12.0, 10.5, 11.0)
      ..lineTo(11.0, 10.4)
      ..cubicTo(11.2, 10.2, 11.2, 10.0, 11.1, 9.8)
      ..lineTo(10.4, 8.0)
      ..cubicTo(10.2, 7.6, 9.9, 7.4, 9.3, 7.4)
      ..close();
    canvas.drawPath(handset, fill);
  }

  @override
  bool shouldRepaint(_WhatsAppPainter old) => old.color != color;
}
