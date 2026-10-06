import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../l10n/context_extension.dart';
import '../models/reference_data.dart';
import '../theme/app_theme.dart';
import '../utils/city_search.dart';

/// Общий выбор города (задача 040, п.2): поиск по всем четырём языкам,
/// недавние, «рядом со мной». Используется в анонсе водителя, в грузе, в
/// «Кто свободен». Плагины (геолокация, хранилище недавних) сюда не тянем —
/// приложение передаёт их колбэками.
///
/// [onFindNearby] — вернуть ближайший город по геолокации (или `null`);
/// не задан — кнопки «Рядом со мной» нет. [recentIds] — id точек, от
/// свежих к старым.
Future<LoadingPoint?> showCityPicker(
  BuildContext context, {
  required List<LoadingPoint> points,
  String? selectedId,
  List<String> recentIds = const [],
  Future<LoadingPoint?> Function()? onFindNearby,
  String? title,
}) {
  return showModalBottomSheet<LoadingPoint>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge))),
    builder: (context) => _CityPickerSheet(
      points: points.where((p) => p.isActive).toList(),
      selectedId: selectedId,
      recentIds: recentIds,
      onFindNearby: onFindNearby,
      title: title,
    ),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({
    required this.points,
    required this.selectedId,
    required this.recentIds,
    required this.onFindNearby,
    required this.title,
  });

  final List<LoadingPoint> points;
  final String? selectedId;
  final List<String> recentIds;
  final Future<LoadingPoint?> Function()? onFindNearby;
  final String? title;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _controller = TextEditingController();
  bool _findingNearby = false;
  bool _nearbyNotFound = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _nearby() async {
    setState(() {
      _findingNearby = true;
      _nearbyNotFound = false;
    });
    LoadingPoint? found;
    try {
      found = await widget.onFindNearby!();
    } catch (e) {
      debugPrint('CityPicker: nearby failed: $e');
    }
    if (!mounted) return;
    if (found != null) {
      Navigator.of(context).pop(found);
    } else {
      setState(() {
        _findingNearby = false;
        _nearbyNotFound = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final query = _controller.text.trim();

    final byId = {for (final p in widget.points) p.id: p};
    final recent = [for (final id in widget.recentIds) if (byId[id] != null) byId[id]!];
    final sortedAll = [...widget.points]..sort((a, b) => a.name.forLanguageCode(locale).compareTo(b.name.forLanguageCode(locale)));
    final results = query.isEmpty ? null : searchPoints(widget.points, query);

    Widget row(LoadingPoint p) => ListTile(
          key: Key('cityPickerRow-${p.id}'),
          contentPadding: EdgeInsets.zero,
          minVerticalPadding: AppSpacing.md,
          title: Text(p.name.forLanguageCode(locale), style: AppTextStyles.body),
          trailing: p.id == widget.selectedId ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
          onTap: () => Navigator.of(context).pop(p),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(widget.title ?? t.cityPickerTitle, style: AppTextStyles.title)),
                  IconButton(icon: const Icon(LucideIcons.x), tooltip: t.commonBack, onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('cityPickerSearch'),
                controller: _controller,
                autofocus: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: t.cityPickerSearchHint,
                  prefixIcon: const Icon(LucideIcons.search),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (widget.onFindNearby != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('cityPickerNearby'),
                    onPressed: _findingNearby ? null : _nearby,
                    icon: _findingNearby
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.locateFixed, size: 18),
                    label: Text(t.cityPickerNearby),
                  ),
                ),
                if (_nearbyNotFound)
                  Text(t.cityPickerNearbyNotFound, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: results != null
                    ? (results.isEmpty
                        ? Center(child: Text(t.cityPickerNothingFound, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)))
                        : ListView(children: [for (final p in results) row(p)]))
                    : ListView(
                        children: [
                          if (recent.isNotEmpty) ...[
                            Text(t.cityPickerRecent, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                            for (final p in recent) row(p),
                            const SizedBox(height: AppSpacing.md),
                            Text(t.cityPickerAll, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                          for (final p in sortedAll) row(p),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Поле-кнопка «Город» с выбором через [showCityPicker] — одинаковое в анонсе,
/// грузе и «Кто свободен».
class CityField extends StatelessWidget {
  const CityField({super.key, required this.label, required this.value, required this.onTap, this.errorText});

  final String label;
  final String? value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.field),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(LucideIcons.chevronDown),
        ),
        child: Text(
          value ?? t.cityFieldPlaceholder,
          style: AppTextStyles.body.copyWith(color: value == null ? AppColors.textSecondary : AppColors.text),
        ),
      ),
    );
  }
}
