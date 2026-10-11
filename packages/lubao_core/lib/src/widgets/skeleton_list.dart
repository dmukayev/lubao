import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 060: заготовки карточек вместо крутилки — только при самом первом
/// открытии списка; дальше прошлые данные показываются сразу.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.lines = 3});

  final int count;
  final int lines;

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: height,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(8)),
          ),
        );
    return ListView.builder(
      key: const Key('skeletonList'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      itemCount: count,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(0.7, 20),
            for (var l = 1; l < lines; l++) bar(l.isOdd ? 0.5 : 0.35, 14),
          ],
        ),
      ),
    );
  }
}
