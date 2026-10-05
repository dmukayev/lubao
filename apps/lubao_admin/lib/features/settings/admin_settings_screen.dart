import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../shared/admin_dialogs.dart';

/// Настройки (задача 028, п.22): точка по умолчанию, радиус «Близко к
/// дому», срок архива груза. Каждое изменение — с причиной, в audit_log.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  Future<void> _saveDefaultCity(BuildContext context, WidgetRef ref, String cityId) async {
    final t = context.l10n;
    final reason = await showReasonDialog(context, title: t.adminSettingDefaultCity, confirmLabel: t.commonSave);
    if (reason == null) return;
    await ref.read(adminRepositoryProvider).setSetting('defaultPointCityId', cityId, reason: reason);
    ref.invalidate(adminSettingsProvider);
  }

  Future<void> _saveNumberSetting(BuildContext context, WidgetRef ref, {required String key, required String title, required String currentValue}) async {
    final t = context.l10n;
    final controller = TextEditingController(text: currentValue);
    final reasonController = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final canConfirm = controller.text.trim().isNotEmpty && reasonController.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: title, controller: controller, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
                const SizedBox(height: 12),
                AppTextField(label: t.adminReasonLabel, controller: reasonController, maxLines: 2, onChanged: (_) => setState(() {})),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
              FilledButton(
                onPressed: canConfirm ? () => Navigator.pop(dialogContext, (controller.text.trim(), reasonController.text.trim())) : null,
                child: Text(t.commonSave),
              ),
            ],
          );
        },
      ),
    );
    if (result == null) return;
    await ref.read(adminRepositoryProvider).setSetting(key, result.$1, reason: result.$2);
    ref.invalidate(adminSettingsProvider);
  }

  Future<void> _pickDefaultCity(BuildContext context, WidgetRef ref, List<City> cities, String locale, String? currentCityId) async {
    final t = context.l10n;
    String? selection = currentCityId;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(t.adminSettingDefaultCity),
          content: DropdownButtonFormField<String>(
            initialValue: selection,
            items: cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale)))).toList(),
            onChanged: (v) => setState(() => selection = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, selection), child: Text(t.commonSave)),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await _saveDefaultCity(context, ref, selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final settings = ref.watch(adminSettingsProvider);
    final refDataAsync = ref.watch(referenceDataProvider);
    final cities = refDataAsync.valueOrNull?.cities ?? const <City>[];
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(t.adminNavSettings)),
      body: settings.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('AdminSettingsScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminSettingsProvider));
        },
        data: (values) {
          final defaultCityId = values['defaultPointCityId'];
          final homeRadiusKm = values['homeRadiusKm'] ?? '200';
          final cargoArchiveDays = values['cargoArchiveDays'] ?? '3';
          final defaultCity = cities.where((c) => c.id == defaultCityId).firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.adminSettingDefaultCity, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Text(defaultCity?.name.forLanguageCode(locale) ?? t.adminSettingNotSet),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: cities.isEmpty ? null : () => _pickDefaultCity(context, ref, cities, locale, defaultCityId),
                      child: Text(t.adminEdit),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _NumberSettingCard(
                title: t.adminSettingHomeRadius,
                value: '$homeRadiusKm ${t.adminUnitKm}',
                onEdit: () => _saveNumberSetting(context, ref, key: 'homeRadiusKm', title: t.adminSettingHomeRadius, currentValue: homeRadiusKm),
              ),
              const SizedBox(height: 12),
              _NumberSettingCard(
                title: t.adminSettingCargoArchiveDays,
                value: t.adminStaleDays(int.tryParse(cargoArchiveDays) ?? 3),
                onEdit: () => _saveNumberSetting(context, ref, key: 'cargoArchiveDays', title: t.adminSettingCargoArchiveDays, currentValue: cargoArchiveDays),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NumberSettingCard extends StatelessWidget {
  const _NumberSettingCard({required this.title, required this.value, required this.onEdit});

  final String title;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(value),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(onPressed: onEdit, child: Text(t.adminEdit)),
        ],
      ),
    );
  }
}
