import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../shared/error_feedback.dart';

/// «Нет моего города» (задача 021): свободный текст + обязательная область.
/// Регионы в справочнике сегодня есть только для Казахстана — ровно тот
/// случай, который описан в задаче (Жаркент, Талгар, Сарыагаш и т.п.).
Future<City?> showAddCitySheet(BuildContext context, WidgetRef ref, ReferenceData refData) {
  return showModalBottomSheet<City>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge))),
    builder: (sheetContext) => _AddCitySheet(refData: refData),
  );
}

class _AddCitySheet extends ConsumerStatefulWidget {
  const _AddCitySheet({required this.refData});

  final ReferenceData refData;

  @override
  ConsumerState<_AddCitySheet> createState() => _AddCitySheetState();
}

class _AddCitySheetState extends ConsumerState<_AddCitySheet> {
  final _settlementController = TextEditingController();
  String? _regionId;
  String? _settlementError;
  String? _regionError;
  bool _saving = false;

  @override
  void dispose() {
    _settlementController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final settlement = _settlementController.text.trim();
    setState(() {
      _settlementError = settlement.isEmpty ? t.addCitySettlementError : null;
      _regionError = _regionId == null ? t.addCityRegionError : null;
    });
    if (_settlementError != null || _regionError != null) return;

    setState(() => _saving = true);
    try {
      final city = await ref
          .read(referenceDataRepositoryProvider)
          .submitCity(settlementName: settlement, regionId: _regionId!);
      if (mounted) Navigator.of(context).pop(city);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final kazakhstan = widget.refData.countries.where((c) => c.code == 'KZ').firstOrNull;
    final regions = kazakhstan == null ? const <Region>[] : widget.refData.regionsOf(kazakhstan.id);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.cityNotListed, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: t.addCitySettlementLabel,
            controller: _settlementController,
            errorText: _settlementError,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _regionId,
            decoration: InputDecoration(
              labelText: t.addCityRegionLabel,
              errorText: _regionError,
              border: const OutlineInputBorder(),
            ),
            items: regions
                .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name.forLanguageCode(locale))))
                .toList(),
            onChanged: (value) => setState(() => _regionId = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: t.addCitySubmit, loading: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
