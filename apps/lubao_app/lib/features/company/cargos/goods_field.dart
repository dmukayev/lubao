import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';

/// 075/077 (decisions.md «„Что везёте?“ — один вопрос»): одно поле с
/// подсказками — товары простыми словами («Название · Категория», без кодов);
/// цифры ищут по коду HS, буквы — по названиям и синонимам на 4 языках; до ввода — частые товары компании. Последняя строка
/// всегда «Добавить: „…“» — свой текст логиста.
class GoodsField extends ConsumerStatefulWidget {
  const GoodsField({
    super.key,
    required this.initialText,
    required this.onSelected,
    required this.onOwnText,
    required this.onCleared,
    this.errorText,
    this.focusNode,
  });

  final String initialText;
  final String? errorText;
  final FocusNode? focusNode;
  final void Function(GoodsHit hit, String label) onSelected;
  final void Function(String text) onOwnText;

  /// Текст изменили после выбора — товар больше не выбран.
  final VoidCallback onCleared;

  @override
  ConsumerState<GoodsField> createState() => _GoodsFieldState();
}

class _GoodsFieldState extends ConsumerState<GoodsField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialText);
  Timer? _debounce;
  List<GoodsHit> _hits = const [];
  bool _open = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocus);
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (widget.focusNode?.hasFocus ?? false) {
      if (_controller.text.trim().isEmpty) _search('');
    }
  }

  void _onChanged(String value) {
    widget.onCleared();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    final id = ++_request;
    try {
      final repo = ref.read(cargoRepositoryProvider);
      final hits = query.isEmpty ? await repo.recentGoods() : await repo.searchGoods(query);
      if (!mounted || id != _request) return;
      setState(() {
        _hits = hits.take(8).toList();
        _open = true;
      });
    } catch (e) {
      debugPrint('GoodsField: search failed: $e');
      if (mounted && id == _request) setState(() => _open = query.isNotEmpty);
    }
  }

  void _pick(GoodsHit hit, String label) {
    _controller.text = label;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _open = false);
    widget.onSelected(hit, label);
  }

  void _addOwn(String text) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _open = false);
    widget.onOwnText(text);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final refData = ref.watch(referenceDataProvider).valueOrNull;
    final query = _controller.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('postCargoWhat'),
          focusNode: widget.focusNode,
          label: t.postCargoWhatTitle,
          hintText: t.postCargoWhatHint,
          controller: _controller,
          errorText: widget.errorText,
          onChanged: _onChanged,
        ),
        if (_open && (_hits.isNotEmpty || query.isNotEmpty))
          Card(
            key: const Key('postCargoWhatSuggestions'),
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, hit) in _hits.indexed)
                  InkWell(
                    key: Key('goodsHit-$i'),
                    onTap: () => _pick(hit, hit.name.forLanguageCode(locale)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hit.name.forLanguageCode(locale), style: AppTextStyles.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(
                            // 077: в подсказке — «Название · Категория», без кода ТН ВЭД.
                            [
                              if (refData != null && hit.categoryId != null) ?refData.categoryById(hit.categoryId)?.name.forLanguageCode(locale),
                              if (hit.isDangerous) t.cargoDangerousGoods,
                            ].join(' · '),
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (query.isNotEmpty)
                  InkWell(
                    key: const Key('postCargoWhatAdd'),
                    onTap: () => _addOwn(query),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.plus, size: 16, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(child: Text(t.postCargoWhatAdd(query), style: AppTextStyles.body.copyWith(color: AppColors.primary))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
