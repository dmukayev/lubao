import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 067: фото на весь экран — листание, масштаб пальцами; закрыть — ✕ в углу
/// (виден всегда) или свайп вниз.
Future<void> showFullScreenPhotos(BuildContext context, {required List<Widget> photos, int initialIndex = 0}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, _, _) => _FullScreenPhotos(photos: photos, initialIndex: initialIndex),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _FullScreenPhotos extends StatelessWidget {
  const _FullScreenPhotos({required this.photos, required this.initialIndex});

  final List<Widget> photos;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('fullScreenPhotos'),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Dismissible(
            key: const Key('fullScreenPhotosDismiss'),
            direction: DismissDirection.down,
            onDismissed: (_) => Navigator.of(context).pop(),
            child: PageView(
              controller: PageController(initialPage: initialIndex),
              children: [for (final photo in photos) InteractiveViewer(child: Center(child: photo))],
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: IconButton(
                  key: const Key('fullScreenPhotosClose'),
                  tooltip: context.l10n.driverCardClose,
                  style: IconButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white),
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
