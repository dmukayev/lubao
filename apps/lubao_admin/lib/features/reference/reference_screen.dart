import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../shared/edit_side_panel.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Правка названия на 4 языках + включить/выключить + порядок (задача 028,
/// п.21) — общий для body-type/permit, у которых одинаковый набор полей.
class ReferenceItemEditResult {
  const ReferenceItemEditResult({required this.name, required this.isActive, required this.sortOrder, required this.reason});

  final I18nText name;
  final bool isActive;
  final int sortOrder;
  final String reason;
}

Future<ReferenceItemEditResult?> _showReferenceItemEditPanel(
  BuildContext context, {
  required String title,
  required I18nText initialName,
  required bool initialActive,
  required int initialSortOrder,
}) async {
  final kkController = TextEditingController(text: initialName.kk);
  final ruController = TextEditingController(text: initialName.ru);
  final zhController = TextEditingController(text: initialName.zh);
  final enController = TextEditingController(text: initialName.en);
  final sortOrderController = TextEditingController(text: '$initialSortOrder');
  bool isActive = initialActive;

  final reason = await showEditSidePanel(
    context: context,
    title: title,
    canSave: () => ruController.text.trim().isNotEmpty,
    fieldsBuilder: (context, setState) {
      final t = context.l10n;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: t.adminNameKk, controller: kkController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameRu, controller: ruController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameZh, controller: zhController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameEn, controller: enController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          AppTextField(label: t.adminSortOrder, controller: sortOrderController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: isActive,
            title: Text(isActive ? t.adminActive : t.adminInactive),
            onChanged: (v) => setState(() => isActive = v),
          ),
        ],
      );
    },
  );
  if (reason == null) return null;

  return ReferenceItemEditResult(
    name: I18nText(kk: kkController.text.trim(), ru: ruController.text.trim(), zh: zhController.text.trim(), en: enController.text.trim()),
    isActive: isActive,
    sortOrder: int.tryParse(sortOrderController.text.trim()) ?? initialSortOrder,
    reason: reason,
  );
}

class ReferenceScreen extends ConsumerStatefulWidget {
  const ReferenceScreen({super.key});

  @override
  ConsumerState<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends ConsumerState<ReferenceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, String>?> _showNameDialog(
    BuildContext context, {
    required String title,
    bool withCode = true,
    String? initialRu,
  }) {
    final t = context.l10n;
    final codeController = TextEditingController();
    final kkController = TextEditingController();
    final ruController = TextEditingController(text: initialRu ?? '');
    final zhController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (withCode) ...[
                AppTextField(label: t.adminCode, controller: codeController),
                const SizedBox(height: 8),
              ],
              AppTextField(label: t.adminNameKk, controller: kkController),
              const SizedBox(height: 8),
              AppTextField(label: t.adminNameRu, controller: ruController),
              const SizedBox(height: 8),
              AppTextField(label: t.adminNameZh, controller: zhController),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'code': codeController.text.trim(),
              'kk': kkController.text.trim(),
              'ru': ruController.text.trim(),
              'zh': zhController.text.trim(),
            }),
            child: Text(t.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _addBodyType() async {
    final t = context.l10n;
    final result = await _showNameDialog(context, title: t.adminAddBodyType);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).createBodyType(
          result['code']!,
          I18nText(kk: result['kk']!, ru: result['ru']!, zh: result['zh']!),
        );
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _addPermit() async {
    final t = context.l10n;
    final result = await _showNameDialog(context, title: t.adminAddPermit);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).createPermit(
          result['code']!,
          I18nText(kk: result['kk']!, ru: result['ru']!, zh: result['zh']!),
        );
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _addPoint(List<City> cities) async {
    final t = context.l10n;
    String? cityId = cities.isNotEmpty ? cities.first.id : null;
    final kkController = TextEditingController();
    final ruController = TextEditingController();
    final zhController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final radiusController = TextEditingController(text: '3000');
    var kind = PointKind.city;
    final locale = Localizations.localeOf(context).languageCode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.adminAddPoint),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: cityId,
                  decoration: InputDecoration(labelText: t.adminPointCity, border: const OutlineInputBorder()),
                  items: cities
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale))))
                      .toList(),
                  onChanged: (value) => setDialogState(() => cityId = value),
                ),
                const SizedBox(height: 8),
                AppTextField(label: t.adminNameKk, controller: kkController),
                const SizedBox(height: 8),
                AppTextField(label: t.adminNameRu, controller: ruController),
                const SizedBox(height: 8),
                AppTextField(label: t.adminNameZh, controller: zhController),
                const SizedBox(height: 8),
                DropdownButtonFormField<PointKind>(
                  key: const Key('adminPointKind'),
                  initialValue: kind,
                  decoration: InputDecoration(labelText: t.adminPointKind, border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: PointKind.city, child: Text(t.adminPointKindCity)),
                    DropdownMenuItem(value: PointKind.terminal, child: Text(t.adminPointKindTerminal)),
                  ],
                  onChanged: (value) => setDialogState(() => kind = value ?? kind),
                ),
                if (kind == PointKind.terminal) ...[
                  const SizedBox(height: 8),
                  AppTextField(label: t.adminLat, controller: latController, keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  AppTextField(label: t.adminLng, controller: lngController, keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  AppTextField(label: t.adminPointRadius, controller: radiusController, keyboardType: TextInputType.number),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.commonSave)),
          ],
        ),
      ),
    );

    if (confirmed != true || cityId == null) return;
    final lat = double.tryParse(latController.text.trim());
    final lng = double.tryParse(lngController.text.trim());
    final radiusM = int.tryParse(radiusController.text.trim());
    if (kind == PointKind.terminal && (lat == null || lng == null || radiusM == null)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.adminPointTerminalNeedsGeofence)));
      return;
    }
    await ref.read(adminRepositoryProvider).createPoint(
          cityId!,
          I18nText(kk: kkController.text.trim(), ru: ruController.text.trim(), zh: zhController.text.trim()),
          kind: kind,
          lat: kind == PointKind.terminal ? lat : null,
          lng: kind == PointKind.terminal ? lng : null,
          radiusM: kind == PointKind.terminal ? radiusM : null,
        );
    ref.invalidate(referenceDataProvider);
  }

  /// Тип кузова: название/порядок или профиль и поля (048 п.1).
  Future<void> _bodyTypeActions(BodyType item) async {
    final t = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(LucideIcons.pencil), title: Text(t.adminBodyTypeNameEdit), onTap: () => Navigator.pop(sheetContext, 'name')),
            ListTile(
              key: const Key('adminBodyTypeProfileEdit'),
              leading: const Icon(LucideIcons.listChecks),
              title: Text(t.adminBodyTypeProfileEdit),
              onTap: () => Navigator.pop(sheetContext, 'profile'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'name') await _editBodyType(item);
    if (choice == 'profile') await _editBodyTypeProfile(item);
  }

  Future<void> _editBodyTypeProfile(BodyType item) async {
    final t = context.l10n;
    var profile = item.profile;
    final fieldsController = TextEditingController(text: const JsonEncoder.withIndent('  ').convert(item.rawFields));
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('${t.adminBodyTypeProfileEdit}: ${item.name.forLanguageCode(Localizations.localeOf(dialogContext).languageCode)}'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: profile,
                    decoration: InputDecoration(labelText: t.adminBodyTypeProfile),
                    items: [for (final p in const ['VOLUME', 'PLATFORM', 'CONTAINER', 'BULK', 'TANK', 'CAR_CARRIER']) DropdownMenuItem(value: p, child: Text(p))],
                    onChanged: (v) => setState(() => profile = v ?? profile),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('adminBodyTypeFields'),
                    controller: fieldsController,
                    maxLines: 18,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: InputDecoration(labelText: t.adminBodyTypeFieldsJson, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: t.adminReasonLabel, controller: reasonController),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.commonSave)),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    List<dynamic> fields;
    try {
      fields = jsonDecode(fieldsController.text) as List<dynamic>;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.adminBodyTypeFieldsInvalid('JSON'))));
      return;
    }
    // 049 п.10: границы числового поля — числа и min ≤ max (сервер проверит тоже).
    final badBounds = <String>[];
    for (final (i, f) in fields.indexed) {
      if (f is! Map) continue;
      final min = f['min'], max = f['max'];
      if ((min != null && min is! num) || (max != null && max is! num)) {
        badBounds.add('#$i: min/max');
      } else if (min is num && max is num && min > max) {
        badBounds.add('#$i: min > max');
      }
    }
    if (badBounds.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(t.adminBodyTypeFieldsInvalid(badBounds.join(', ')))));
      return;
    }
    try {
      await ref.read(adminRepositoryProvider).updateBodyTypeProfile(item.id, profile: profile, fields: fields, reason: reasonController.text.trim().isEmpty ? '—' : reasonController.text.trim());
      ref.invalidate(referenceDataProvider);
    } on DioException catch (e) {
      final data = e.response?.data;
      final errors = data is Map && data['errors'] is List ? (data['errors'] as List).join(', ') : e.message ?? '';
      messenger.showSnackBar(SnackBar(content: Text(t.adminBodyTypeFieldsInvalid(errors))));
    }
  }

  Future<void> _editBodyType(BodyType item) async {
    final result = await _showReferenceItemEditPanel(context, title: item.name.forLanguageCode(Localizations.localeOf(context).languageCode), initialName: item.name, initialActive: item.isActive, initialSortOrder: item.sortOrder);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).updateBodyType(item.id, name: result.name, isActive: result.isActive, sortOrder: result.sortOrder, reason: result.reason);
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _addCategory() async {
    final t = context.l10n;
    final result = await _showNameDialog(context, title: t.adminCargoCategoriesTitle);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).createCargoCategory(
          result['code']!,
          I18nText(kk: result['kk']!, ru: result['ru']!, zh: result['zh']!),
        );
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _editCategory(CargoCategory item) async {
    final result = await _showReferenceItemEditPanel(context, title: item.name.forLanguageCode(Localizations.localeOf(context).languageCode), initialName: item.name, initialActive: item.isActive, initialSortOrder: item.sortOrder);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).updateCargoCategory(item.id, name: result.name, isActive: result.isActive, sortOrder: result.sortOrder, reason: result.reason);
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _editPermit(Permit item) async {
    final result = await _showReferenceItemEditPanel(context, title: item.name.forLanguageCode(Localizations.localeOf(context).languageCode), initialName: item.name, initialActive: item.isActive, initialSortOrder: item.sortOrder);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).updatePermit(item.id, name: result.name, isActive: result.isActive, sortOrder: result.sortOrder, reason: result.reason);
    ref.invalidate(referenceDataProvider);
  }

  /// Шаблоны размеров кузова (задача 033, п.11) — значения ориентировочные,
  /// правятся здесь без релиза; машинам, выбравшим шаблон раньше, правка
  /// задним числом ничего не меняет (значения копируются при выборе).
  Future<void> _addBodySizePreset() async {
    final t = context.l10n;
    final result = await _showNameDialog(context, title: t.adminAddBodySizePreset);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).createBodySizePreset(
          code: result['code']!,
          name: I18nText(kk: result['kk']!, ru: result['ru']!, zh: result['zh']!),
        );
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _editBodySizePreset(BodySizePreset preset, String locale) async {
    final t = context.l10n;
    final kkController = TextEditingController(text: preset.name.kk);
    final ruController = TextEditingController(text: preset.name.ru);
    final zhController = TextEditingController(text: preset.name.zh);
    final enController = TextEditingController(text: preset.name.en);
    final lengthController = TextEditingController(text: preset.innerLengthM?.toString() ?? '');
    final widthController = TextEditingController(text: preset.innerWidthM?.toString() ?? '');
    final heightController = TextEditingController(text: preset.innerHeightM?.toString() ?? '');
    final volumeController = TextEditingController(text: preset.volumeM3?.toString() ?? '');
    final palletsController = TextEditingController(text: preset.palletsEuro?.toString() ?? '');
    bool isActive = preset.isActive;

    final reason = await showEditSidePanel(
      context: context,
      title: preset.name.forLanguageCode(locale),
      canSave: () => ruController.text.trim().isNotEmpty,
      fieldsBuilder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: t.adminNameKk, controller: kkController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameRu, controller: ruController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameZh, controller: zhController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameEn, controller: enController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          AppTextField(label: t.garageSizeLength, controller: lengthController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.garageSizeWidth, controller: widthController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.garageSizeHeight, controller: heightController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: '${t.postCargoVolume} (${t.unitM3})', controller: volumeController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.postCargoPallets, controller: palletsController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: isActive,
            title: Text(isActive ? t.adminActive : t.adminInactive),
            onChanged: (v) => setState(() => isActive = v),
          ),
        ],
      ),
    );
    if (reason == null) return;

    await ref.read(adminRepositoryProvider).updateBodySizePreset(
          preset.id,
          name: I18nText(kk: kkController.text.trim(), ru: ruController.text.trim(), zh: zhController.text.trim(), en: enController.text.trim()),
          innerLengthM: double.tryParse(lengthController.text.trim()),
          innerWidthM: double.tryParse(widthController.text.trim()),
          innerHeightM: double.tryParse(heightController.text.trim()),
          volumeM3: double.tryParse(volumeController.text.trim()),
          palletsEuro: int.tryParse(palletsController.text.trim()),
          isActive: isActive,
          reason: reason,
        );
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _editPoint(LoadingPoint point, List<City> cities, String locale) async {
    final kkController = TextEditingController(text: point.name.kk);
    final ruController = TextEditingController(text: point.name.ru);
    final zhController = TextEditingController(text: point.name.zh);
    final enController = TextEditingController(text: point.name.en);
    final latController = TextEditingController(text: point.lat?.toString() ?? '');
    final lngController = TextEditingController(text: point.lng?.toString() ?? '');
    final radiusController = TextEditingController(text: point.radiusM?.toString() ?? '');
    String cityId = point.cityId;
    bool isActive = point.isActive;
    var kind = point.kind;
    final t = context.l10n;

    final reason = await showEditSidePanel(
      context: context,
      title: point.name.forLanguageCode(locale),
      canSave: () => ruController.text.trim().isNotEmpty,
      fieldsBuilder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: cityId,
            decoration: InputDecoration(labelText: t.adminPointCity),
            items: cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale)))).toList(),
            onChanged: (v) => setState(() => cityId = v!),
          ),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameKk, controller: kkController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameRu, controller: ruController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameZh, controller: zhController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameEn, controller: enController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          AppTextField(label: t.adminLat, controller: latController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminLng, controller: lngController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          DropdownButtonFormField<PointKind>(
            key: const Key('adminPointKind'),
            initialValue: kind,
            decoration: InputDecoration(labelText: t.adminPointKind),
            items: [
              DropdownMenuItem(value: PointKind.city, child: Text(t.adminPointKindCity)),
              DropdownMenuItem(value: PointKind.terminal, child: Text(t.adminPointKindTerminal)),
            ],
            onChanged: (v) => setState(() => kind = v ?? kind),
          ),
          if (kind == PointKind.terminal) ...[
            const SizedBox(height: 8),
            AppTextField(label: t.adminPointRadius, controller: radiusController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: isActive,
            title: Text(isActive ? t.adminActive : t.adminInactive),
            onChanged: (v) => setState(() => isActive = v),
          ),
        ],
      ),
    );
    if (reason == null) return;
    final lat = double.tryParse(latController.text.trim());
    final lng = double.tryParse(lngController.text.trim());
    final radiusM = int.tryParse(radiusController.text.trim());
    if (kind == PointKind.terminal && ((lat ?? point.lat) == null || (lng ?? point.lng) == null || (radiusM ?? point.radiusM) == null)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.adminPointTerminalNeedsGeofence)));
      return;
    }

    await ref.read(adminRepositoryProvider).updatePoint(
          point.id,
          name: I18nText(kk: kkController.text.trim(), ru: ruController.text.trim(), zh: zhController.text.trim(), en: enController.text.trim()),
          cityId: cityId,
          lat: lat,
          lng: lng,
          kind: kind,
          radiusM: kind == PointKind.terminal ? radiusM : null,
          isActive: isActive,
          reason: reason,
        );
    ref.invalidate(referenceDataProvider);
  }

  /// Правка уже APPROVED города — область и координаты (нужны «Близко к
  /// дому», задача 016); отдельно от очереди PENDING-городов выше.
  Future<void> _editCity(City city, List<Region> regions, String locale) async {
    final kkController = TextEditingController(text: city.name.kk);
    final ruController = TextEditingController(text: city.name.ru);
    final zhController = TextEditingController(text: city.name.zh);
    final enController = TextEditingController(text: city.name.en);
    final latController = TextEditingController(text: city.lat?.toString() ?? '');
    final lngController = TextEditingController(text: city.lng?.toString() ?? '');
    String? regionId = city.regionId;
    final t = context.l10n;
    final countryRegions = regions.where((r) => r.countryId == city.countryId).toList();

    final reason = await showEditSidePanel(
      context: context,
      title: city.name.forLanguageCode(locale),
      canSave: () => ruController.text.trim().isNotEmpty,
      fieldsBuilder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: regionId,
            decoration: InputDecoration(labelText: t.adminCityRegion),
            items: countryRegions.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name.forLanguageCode(locale)))).toList(),
            onChanged: (v) => setState(() => regionId = v),
          ),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameKk, controller: kkController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameRu, controller: ruController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameZh, controller: zhController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminNameEn, controller: enController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          AppTextField(label: t.adminLat, controller: latController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          AppTextField(label: t.adminLng, controller: lngController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
        ],
      ),
    );
    if (reason == null) return;

    await ref.read(adminRepositoryProvider).updateCity(
          city.id,
          name: I18nText(kk: kkController.text.trim(), ru: ruController.text.trim(), zh: zhController.text.trim(), en: enController.text.trim()),
          regionId: regionId,
          lat: double.tryParse(latController.text.trim()),
          lng: double.tryParse(lngController.text.trim()),
          reason: reason,
        );
    ref.invalidate(referenceDataProvider);
  }

  /// Подтвердить город, предложенный пользователем (задача 021): диалог
  /// переводов предзаполнен его `ru`-названием как отправная точка.
  Future<void> _approvePendingCity(AdminPendingCity pending) async {
    final t = context.l10n;
    final result = await _showNameDialog(context, title: t.adminApprove, withCode: false, initialRu: pending.name);
    if (result == null) return;
    await ref.read(adminRepositoryProvider).approveCity(
          pending.id,
          I18nText(kk: result['kk']!, ru: result['ru']!, zh: result['zh']!),
        );
    ref.invalidate(pendingCitiesProvider);
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _mergePendingCity(AdminPendingCity pending, List<City> cities, String locale) async {
    final t = context.l10n;
    String? targetId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.adminMergeCity),
          content: DropdownButtonFormField<String>(
            initialValue: targetId,
            decoration: InputDecoration(labelText: t.adminMergeCityTarget, border: const OutlineInputBorder()),
            items: cities
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale))))
                .toList(),
            onChanged: (value) => setDialogState(() => targetId = value),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.adminMergeCity)),
          ],
        ),
      ),
    );
    if (confirmed != true || targetId == null) return;
    await ref.read(adminRepositoryProvider).mergeCity(pending.id, targetId!);
    ref.invalidate(pendingCitiesProvider);
    ref.invalidate(referenceDataProvider);
  }

  Future<void> _rejectPendingCity(AdminPendingCity pending) async {
    final t = context.l10n;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.adminReject),
        content: AppTextField(label: t.adminRejectReasonLabel, controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(t.commonDone)),
        ],
      ),
    );
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).rejectCity(pending.id, rejectReason: reason.trim());
    ref.invalidate(pendingCitiesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final referenceData = ref.watch(referenceDataProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminReferenceTitle),
        bottom: TabBar(controller: _tabController, isScrollable: true, tabs: [
          Tab(text: t.driverSetupVehicleBodyType),
          Tab(text: t.adminBodySizePresetsTab),
          Tab(text: t.driverSetupPermits),
          Tab(text: t.adminCargoCategoriesTitle),
          Tab(text: t.navFeed),
          Tab(text: t.adminCitiesTab),
          Tab(text: t.adminPendingCitiesTab),
        ]),
      ),
      body: referenceData.when(
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(referenceDataProvider)),
        data: (refData) => TabBarView(
          controller: _tabController,
          children: [
            _SimpleList(
              items: refData.bodyTypes.map((b) => (b.id, '${b.name.forLanguageCode(locale)} · ${b.profile}', b.isActive, () => _bodyTypeActions(b))).toList(),
              onAdd: _addBodyType,
              addLabel: t.adminAddBodyType,
            ),
            _SimpleList(
              items: refData.bodySizePresets
                  .map((p) => (
                        p.id,
                        [
                          p.name.forLanguageCode(locale),
                          if (p.volumeM3 != null) '${p.volumeM3!.toStringAsFixed(0)} ${t.unitM3}',
                          if (p.palletsEuro != null) '${p.palletsEuro} ${t.unitPallets}',
                        ].join(' · '),
                        p.isActive,
                        () => _editBodySizePreset(p, locale)
                      ))
                  .toList(),
              onAdd: _addBodySizePreset,
              addLabel: t.adminAddBodySizePreset,
            ),
            _SimpleList(
              items: refData.permits.map((p) => (p.id, p.name.forLanguageCode(locale), p.isActive, () => _editPermit(p))).toList(),
              onAdd: _addPermit,
              addLabel: t.adminAddPermit,
            ),
            // 047 п.1: категории груза.
            _SimpleList(
              items: refData.cargoCategories.map((c) => (c.id, c.name.forLanguageCode(locale), c.isActive, () => _editCategory(c))).toList(),
              onAdd: _addCategory,
              addLabel: t.adminCargoCategoriesTitle,
            ),
            _PointsList(
              points: refData.points,
              locale: locale,
              onAdd: () => _addPoint(refData.cities),
              onEdit: (p) => _editPoint(p, refData.cities, locale),
              addLabel: t.adminAddPoint,
            ),
            _CitiesList(
              cities: refData.cities.where((c) => c.cityStatus == CityStatus.approved).toList(),
              locale: locale,
              onEdit: (c) => _editCity(c, refData.regions, locale),
            ),
            _PendingCitiesList(
              onApprove: _approvePendingCity,
              onMerge: (pending) => _mergePendingCity(pending, refData.cities, locale),
              onReject: _rejectPendingCity,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCitiesList extends ConsumerWidget {
  const _PendingCitiesList({required this.onApprove, required this.onMerge, required this.onReject});

  final void Function(AdminPendingCity) onApprove;
  final void Function(AdminPendingCity) onMerge;
  final void Function(AdminPendingCity) onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final pending = ref.watch(pendingCitiesProvider);

    return pending.when(
      loading: () => const LoadingView(),
      error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(pendingCitiesProvider)),
      data: (list) {
        if (list.isEmpty) return EmptyState(message: t.adminPendingCitiesEmpty, icon: LucideIcons.mapPin);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingCitiesProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final city = list[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city.name, style: Theme.of(context).textTheme.titleMedium),
                    if (city.regionName != null) Text('${t.adminCityRegion}: ${city.regionName}'),
                    if (city.submittedByLabel != null) Text('${t.adminCitySubmittedBy}: ${city.submittedByLabel}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(onPressed: () => onApprove(city), child: Text(t.adminApprove)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(onPressed: () => onMerge(city), child: Text(t.adminMergeCity)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(onPressed: () => onReject(city), child: Text(t.adminReject)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SimpleList extends StatelessWidget {
  const _SimpleList({required this.items, required this.onAdd, required this.addLabel});

  final List<(String, String, bool, VoidCallback)> items;
  final VoidCallback onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final (id, name, isActive, onEdit) = items[index];
            return ListTile(
              title: Text(name),
              subtitle: Text(isActive ? t.adminActive : t.adminInactive),
              trailing: IconButton(icon: const Icon(LucideIcons.pencil), onPressed: onEdit),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(onPressed: onAdd, icon: const Icon(LucideIcons.plus), label: Text(addLabel)),
        ),
      ],
    );
  }
}

class _PointsList extends StatelessWidget {
  const _PointsList({required this.points, required this.locale, required this.onAdd, required this.onEdit, required this.addLabel});

  final List<LoadingPoint> points;
  final String locale;
  final VoidCallback onAdd;
  final void Function(LoadingPoint) onEdit;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: points.length,
          itemBuilder: (context, index) {
            final point = points[index];
            return ListTile(
              title: Text(point.name.forLanguageCode(locale)),
              subtitle: Text([
                point.kind == PointKind.terminal ? t.adminPointKindTerminal : t.adminPointKindCity,
                point.isActive ? t.adminActive : t.adminInactive,
              ].join(' · ')),
              trailing: IconButton(icon: const Icon(LucideIcons.pencil), onPressed: () => onEdit(point)),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(onPressed: onAdd, icon: const Icon(LucideIcons.plus), label: Text(addLabel)),
        ),
      ],
    );
  }
}

class _CitiesList extends StatelessWidget {
  const _CitiesList({required this.cities, required this.locale, required this.onEdit});

  final List<City> cities;
  final String locale;
  final void Function(City) onEdit;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        return ListTile(
          title: Text(city.name.forLanguageCode(locale)),
          trailing: IconButton(icon: const Icon(LucideIcons.pencil), onPressed: () => onEdit(city)),
        );
      },
    );
  }
}
