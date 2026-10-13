import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../shared/edit_side_panel.dart';

/// 075 п.10–11: справочники «Что везёте?» в админке — товары, коды ТН ВЭД,
/// главы → категории и «Новые слова» (свои варианты логистов).
const _langs = ['ru', 'kk', 'zh', 'en'];

/// Правка товара в боковой панели; `prefill` — текст из «Новых слов».
Future<void> showGoodsEditPanel(BuildContext context, WidgetRef ref, {AdminGoods? goods, String? prefill, required ReferenceData refData}) async {
  final t = context.l10n;
  final locale = Localizations.localeOf(context).languageCode;
  final names = {for (final l in _langs) l: TextEditingController(text: goods?.name.forLanguageCode(l) ?? (l == 'ru' ? prefill ?? '' : ''))};
  final synonyms = {for (final l in _langs) l: TextEditingController(text: goods?.synonyms[l]?.join(', ') ?? '')};
  final slug = TextEditingController(text: goods?.slug ?? '');
  final hs = TextEditingController(text: goods?.hsCode ?? '');
  var categoryId = goods?.categoryId ?? refData.cargoCategories.first.id;
  String? bodyTypeId = goods?.suggestedBodyTypeId;
  var dangerous = goods?.isDangerous ?? false;
  var active = goods?.isActive ?? true;

  final reason = await showEditSidePanel(
    context: context,
    title: goods == null ? t.adminGoodsTab : goods.name.forLanguageCode(locale),
    canSave: () =>
        names['ru']!.text.trim().isNotEmpty &&
        (goods != null || RegExp(r'^[a-z0-9_]{2,60}$').hasMatch(slug.text.trim())) &&
        (hs.text.trim().isEmpty || RegExp(r'^\d{6}$').hasMatch(hs.text.trim())),
    fieldsBuilder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (goods == null) ...[
          AppTextField(key: const Key('adminGoodsSlug'), label: t.adminGoodsSlug, controller: slug, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
        ],
        for (final l in _langs) ...[
          AppTextField(key: Key('adminGoodsName-$l'), label: '${t.adminAuditFieldName} ($l)', controller: names[l]!, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminGoodsSynonyms(l), controller: synonyms[l]!),
          const SizedBox(height: 12),
        ],
        AppTextField(key: const Key('adminGoodsHs'), label: t.adminGoodsHsCode, controller: hs, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: categoryId,
          decoration: InputDecoration(labelText: t.postCargoCategory),
          items: [for (final c in refData.cargoCategories) DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale)))],
          onChanged: (v) => setState(() => categoryId = v ?? categoryId),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: bodyTypeId,
          decoration: InputDecoration(labelText: t.adminGoodsBodyHint),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('—')),
            for (final b in refData.bodyTypes) DropdownMenuItem<String?>(value: b.id, child: Text(b.name.forLanguageCode(locale))),
          ],
          onChanged: (v) => setState(() => bodyTypeId = v),
        ),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: dangerous, onChanged: (v) => setState(() => dangerous = v ?? false), title: Text(t.adminGoodsDangerous)),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: active, onChanged: (v) => setState(() => active = v ?? true), title: Text(t.adminActive)),
      ],
    ),
  );
  if (reason == null) return;
  List<String> split(String text) => text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  await ref.read(adminRepositoryProvider).saveGoods(
        id: goods?.id,
        reason: reason,
        data: {
          if (goods == null) 'slug': slug.text.trim(),
          'name': {for (final l in _langs) if (names[l]!.text.trim().isNotEmpty) l: names[l]!.text.trim()},
          'synonyms': {for (final l in _langs) l: split(synonyms[l]!.text)},
          'hsCode': hs.text.trim().isEmpty ? null : hs.text.trim(),
          'categoryId': categoryId,
          'suggestedBodyTypeId': bodyTypeId,
          'isDangerous': dangerous,
          'isActive': active,
        },
      );
}

final _goodsSearchProvider = FutureProvider.autoDispose.family<List<AdminGoods>, String>((ref, q) => ref.watch(adminRepositoryProvider).goods(q: q));

class GoodsTab extends ConsumerStatefulWidget {
  const GoodsTab({super.key, required this.refData});
  final ReferenceData refData;

  @override
  ConsumerState<GoodsTab> createState() => _GoodsTabState();
}

class _GoodsTabState extends ConsumerState<GoodsTab> {
  String _q = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final goods = ref.watch(_goodsSearchProvider(_q));
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                key: const Key('adminGoodsSearch'),
                label: t.commonSearch,
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => _q = v.trim()));
                },
              ),
            ),
            Expanded(
              child: goods.when(
                loading: () => const LoadingView(),
                error: (e, st) => ErrorView(message: apiErrorText(t, e), onRetry: () => ref.invalidate(_goodsSearchProvider(_q))),
                data: (list) => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final g = list[i];
                    return ListTile(
                      title: Text(g.name.forLanguageCode(locale)),
                      subtitle: Text([?g.hsCode, ?widget.refData.categoryById(g.categoryId)?.name.forLanguageCode(locale), if (g.isDangerous) 'ADR', if (!g.isActive) t.adminInactive].join(' · ')),
                      trailing: IconButton(
                        tooltip: '${t.adminEdit}: ${g.name.forLanguageCode(locale)}',
                        icon: const Icon(LucideIcons.pencil),
                        onPressed: () async {
                          await showGoodsEditPanel(context, ref, goods: g, refData: widget.refData);
                          ref.invalidate(_goodsSearchProvider(_q));
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            key: const Key('adminGoodsAdd'),
            onPressed: () async {
              await showGoodsEditPanel(context, ref, refData: widget.refData);
              ref.invalidate(_goodsSearchProvider(_q));
            },
            icon: const Icon(LucideIcons.plus),
            label: Text(t.adminGoodsTab),
          ),
        ),
      ],
    );
  }
}

final _hsSearchProvider = FutureProvider.autoDispose.family<AdminSearchPage<AdminHsCode>, String>((ref, q) => ref.watch(adminRepositoryProvider).hsCodes(q: q));

class HsCodesTab extends ConsumerStatefulWidget {
  const HsCodesTab({super.key});

  @override
  ConsumerState<HsCodesTab> createState() => _HsCodesTabState();
}

class _HsCodesTabState extends ConsumerState<HsCodesTab> {
  String _q = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _rename(AdminHsCode hs) async {
    final names = {for (final l in _langs) l: TextEditingController(text: hs.name.forLanguageCode(l))};
    final t = context.l10n;
    final reason = await showEditSidePanel(
      context: context,
      title: hs.code,
      fieldsBuilder: (context, setState) => Column(
        children: [for (final l in _langs) ...[AppTextField(label: '${t.adminAuditFieldName} ($l)', controller: names[l]!, maxLines: 3), const SizedBox(height: 12)]],
      ),
    );
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).renameHsCode(hs.code, reason: reason, name: {for (final l in _langs) if (names[l]!.text.trim().isNotEmpty) l: names[l]!.text.trim()});
    ref.invalidate(_hsSearchProvider(_q));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final page = ref.watch(_hsSearchProvider(_q));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppTextField(
            key: const Key('adminHsSearch'),
            label: t.commonSearch,
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => _q = v.trim()));
            },
          ),
        ),
        Expanded(
          child: page.when(
            loading: () => const LoadingView(),
            error: (e, st) => ErrorView(message: apiErrorText(t, e), onRetry: () => ref.invalidate(_hsSearchProvider(_q))),
            data: (p) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: p.items.length,
              itemBuilder: (context, i) {
                final hs = p.items[i];
                return ListTile(
                  title: Text(hs.code),
                  subtitle: Text(hs.name.forLanguageCode(locale), maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(tooltip: '${t.adminEdit}: ${hs.code}', icon: const Icon(LucideIcons.pencil), onPressed: () => _rename(hs)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

final _chaptersProvider = FutureProvider.autoDispose<List<AdminHsChapter>>((ref) => ref.watch(adminRepositoryProvider).hsChapters());

class HsChaptersTab extends ConsumerWidget {
  const HsChaptersTab({super.key, required this.refData});
  final ReferenceData refData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    return ref.watch(_chaptersProvider).when(
          loading: () => const LoadingView(),
          error: (e, st) => ErrorView(message: apiErrorText(t, e), onRetry: () => ref.invalidate(_chaptersProvider)),
          data: (chapters) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.length,
            itemBuilder: (context, i) {
              final ch = chapters[i];
              return ListTile(
                title: Text(ch.chapter),
                trailing: DropdownButton<String>(
                  value: ch.categoryId,
                  items: [for (final c in refData.cargoCategories) DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale)))],
                  onChanged: (v) async {
                    if (v == null || v == ch.categoryId) return;
                    await ref.read(adminRepositoryProvider).setHsChapterCategory(ch.chapter, categoryId: v, reason: 'admin');
                    ref.invalidate(_chaptersProvider);
                  },
                ),
              );
            },
          ),
        );
  }
}

final _newWordsProvider = FutureProvider.autoDispose<List<AdminNewWord>>((ref) => ref.watch(adminRepositoryProvider).goodsNewWords());

class GoodsNewWordsTab extends ConsumerWidget {
  const GoodsNewWordsTab({super.key, required this.refData});
  final ReferenceData refData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    return ref.watch(_newWordsProvider).when(
          loading: () => const LoadingView(),
          error: (e, st) => ErrorView(message: apiErrorText(t, e), onRetry: () => ref.invalidate(_newWordsProvider)),
          data: (words) => words.isEmpty
              ? EmptyState(message: t.adminNewWordsTab)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: words.length,
                  itemBuilder: (context, i) {
                    final w = words[i];
                    return ListTile(
                      title: Text(w.text),
                      subtitle: Text(t.adminNewWordsCount(w.count)),
                      trailing: TextButton(
                        onPressed: () async {
                          await showGoodsEditPanel(context, ref, prefill: w.text, refData: refData);
                          ref.invalidate(_newWordsProvider);
                        },
                        child: Text(t.adminGoodsAddFromWord),
                      ),
                    );
                  },
                ),
        );
  }
}
