import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Круглый аватар: фото, если есть байты, иначе буквы имени (054: без фото —
/// как раньше). Байты грузит вызывающий (у приложения и админки свои клиенты).
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.name, this.bytes, this.radius = 24});

  final String name;
  final Uint8List? bytes;
  final double radius;

  static String initials(String full) {
    final parts = full.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts[1].characters.first : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final letters = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      child: Text(
        initials(name),
        style: (radius >= 24 ? AppTextStyles.title : AppTextStyles.bodyStrong).copyWith(color: AppColors.primary),
      ),
    );
    final b = bytes;
    if (b == null || b.isEmpty) return letters;
    return ClipOval(
      child: Image.memory(
        b,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => letters,
      ),
    );
  }
}
