import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/disk_bytes_cache.dart';

final _dio = Dio(BaseOptions(responseType: ResponseType.bytes, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 30)));

/// Публичное фото (груз) — с диска, иначе из сети и на диск (060 п.4).
final cachedPhotoProvider = FutureProvider.family<Uint8List, String>((ref, url) {
  return DiskBytesCache.instance.getOrFetch('photo:$url', () async {
    final res = await _dio.get<List<int>>(url);
    return Uint8List.fromList(res.data ?? const []);
  });
});

/// Фото по адресу: миниатюра декодируется в размере показа ([size]), а не
/// оригиналом — списки не тормозят; без [size] — как есть (просмотр крупно).
class CachedPhoto extends ConsumerWidget {
  const CachedPhoto(this.url, {super.key, this.size, this.fit = BoxFit.cover});

  final String url;
  final double? size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = SizedBox(width: size, height: size, child: const Center(child: Icon(LucideIcons.image, color: Colors.black26)));
    return ref.watch(cachedPhotoProvider(url)).maybeWhen(
          data: (bytes) {
            final px = size == null ? null : (size! * MediaQuery.devicePixelRatioOf(context)).round();
            return Image.memory(bytes, width: size, height: size, fit: fit, cacheWidth: px, gaplessPlayback: true, errorBuilder: (_, _, _) => placeholder);
          },
          orElse: () => placeholder,
        );
  }
}
