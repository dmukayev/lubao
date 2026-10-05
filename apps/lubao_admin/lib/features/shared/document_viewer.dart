import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'admin_document_image.dart';

/// Полноэкранный просмотр фото документа — зум (InteractiveViewer, без
/// новой зависимости), колесо мыши/трекпад и поворот на 90° (задача 026,
/// п.13; колесо мыши и «рядом с селфи» — задача 028, п.9).
Future<void> openDocumentViewer(BuildContext context, String url, {String? compareUrl, String? compareLabel}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => _DocumentViewerScreen(url: url, compareUrl: compareUrl, compareLabel: compareLabel),
    ),
  );
}

class _DocumentViewerScreen extends StatefulWidget {
  const _DocumentViewerScreen({required this.url, this.compareUrl, this.compareLabel});

  final String url;
  final String? compareUrl;
  final String? compareLabel;

  @override
  State<_DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<_DocumentViewerScreen> {
  int _quarterTurns = 0;
  bool _compareOpen = false;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final canCompare = widget.compareUrl != null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (canCompare)
            IconButton(
              icon: Icon(_compareOpen ? LucideIcons.rows : LucideIcons.columns),
              tooltip: widget.compareLabel,
              onPressed: () => setState(() => _compareOpen = !_compareOpen),
            ),
          IconButton(
            icon: const Icon(LucideIcons.rotateCw),
            tooltip: t.adminRotate,
            onPressed: () => setState(() => _quarterTurns = (_quarterTurns + 1) % 4),
          ),
        ],
      ),
      body: _compareOpen && canCompare
          ? Row(
              children: [
                Expanded(child: _zoomable(widget.url)),
                const VerticalDivider(color: Colors.white24, width: 1),
                Expanded(child: _zoomable(widget.compareUrl!)),
              ],
            )
          : Center(child: _zoomable(widget.url)),
    );
  }

  Widget _zoomable(String url) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5,
      trackpadScrollCausesScale: true,
      child: RotatedBox(
        quarterTurns: _quarterTurns,
        child: AdminDocumentImage(url: url, fit: BoxFit.contain),
      ),
    );
  }
}
