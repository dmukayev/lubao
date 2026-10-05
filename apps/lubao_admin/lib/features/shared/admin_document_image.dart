import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';

/// Новый `fileUrl` документов верификации — относительный путь на
/// бэкенд-прокси `/admin/documents/:id/file` (задача 028, п.12: чинили зум,
/// который не открывался из-за CORS на presigned-ссылке MinIO). Прокси
/// требует Authorization-заголовок, который `Image.network` не умеет
/// надёжно обновлять при истечении токена — поэтому тянем байты тем же
/// Dio, что и остальные запросы (токен и refresh уже в его интерсепторе).
final adminDocumentBytesProvider = FutureProvider.autoDispose.family<Uint8List, String>((ref, path) async {
  final dio = ref.watch(apiClientProvider).dio;
  final res = await dio.get<List<int>>(path, options: Options(responseType: ResponseType.bytes));
  return Uint8List.fromList(res.data!);
});

class AdminDocumentImage extends ConsumerWidget {
  const AdminDocumentImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Легаси-документы (сид/старые загрузки) хранят готовый http(s)-URL —
    // presigned-ссылка публично читаема, авторизация не нужна.
    if (url.startsWith('http')) {
      return Image.network(url, fit: fit, errorBuilder: (ctx, err, st) => const Icon(LucideIcons.fileWarning, size: 32));
    }

    final bytes = ref.watch(adminDocumentBytesProvider(url));
    return bytes.when(
      data: (data) => Image.memory(data, fit: fit, errorBuilder: (ctx, err, st) => const Icon(LucideIcons.fileWarning, size: 32)),
      loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      error: (err, st) => const Icon(LucideIcons.fileWarning, size: 32),
    );
  }
}
