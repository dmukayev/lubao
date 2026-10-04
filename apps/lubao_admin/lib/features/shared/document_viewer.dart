import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Полноэкранный просмотр фото документа — зум (InteractiveViewer, без
/// новой зависимости) и поворот на 90° (задача 026, п.13).
Future<void> openDocumentViewer(BuildContext context, String url) {
  return Navigator.of(context).push(
    MaterialPageRoute(fullscreenDialog: true, builder: (context) => _DocumentViewerScreen(url: url)),
  );
}

class _DocumentViewerScreen extends StatefulWidget {
  const _DocumentViewerScreen({required this.url});

  final String url;

  @override
  State<_DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<_DocumentViewerScreen> {
  int _quarterTurns = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCw),
            tooltip: t.adminRotate,
            onPressed: () => setState(() => _quarterTurns = (_quarterTurns + 1) % 4),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: RotatedBox(
            quarterTurns: _quarterTurns,
            child: Image.network(
              widget.url,
              errorBuilder: (context, error, stackTrace) => Icon(LucideIcons.fileWarning, color: Colors.white, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
