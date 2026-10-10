import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/error_feedback.dart';

/// 058 п.8: ☆ груза — в ленте и на карточке груза. Состояние — из списка
/// «Избранное» (один запрос на экран), нажатие — сразу на сервер.
class FavoriteCargoButton extends ConsumerStatefulWidget {
  const FavoriteCargoButton({super.key, required this.cargoId, this.compact = false});

  final String cargoId;
  final bool compact;

  @override
  ConsumerState<FavoriteCargoButton> createState() => _FavoriteCargoButtonState();
}

class _FavoriteCargoButtonState extends ConsumerState<FavoriteCargoButton> {
  bool? _optimistic;

  Future<void> _toggle(bool current) async {
    setState(() => _optimistic = !current);
    try {
      await ref.read(cargoRepositoryProvider).setFavorite(widget.cargoId, !current);
    } catch (e) {
      if (mounted) {
        setState(() => _optimistic = null);
        showApiError(context, e);
      }
    }
    ref.invalidate(favoriteCargosProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final fromServer = ref.watch(favoriteCargosProvider).valueOrNull?.any((c) => c.id == widget.cargoId) ?? false;
    final on = _optimistic ?? fromServer;
    if (_optimistic != null && _optimistic == fromServer) _optimistic = null;
    return IconButton(
      key: Key('favoriteCargo-${widget.cargoId}'),
      tooltip: on ? t.favoriteRemove : t.favoriteAdd,
      visualDensity: widget.compact ? VisualDensity.compact : null,
      // Lucide — только контур: включённая ☆ — залитая звезда Material.
      icon: Icon(on ? Icons.star_rounded : LucideIcons.star, size: widget.compact ? 22 : 26, color: on ? AppColors.accent : AppColors.textSecondary),
      onPressed: () => _toggle(on),
    );
  }
}
