import 'package:flutter/material.dart';

import '../l10n/context_extension.dart';
import '../l10n/generated/lubao_localizations.dart';
import '../models/reference_data.dart';
import '../theme/app_theme.dart';
import 'app_text_field.dart';
import 'selectable_tile.dart';

/// Единица поля профиля кузова (048) — на языке интерфейса.
String bodyUnitLabel(LubaoLocalizations t, String? unit) => switch (unit) {
      't' => t.unitTon,
      'm3' => t.unitM3,
      'pallets' => t.unitPallets,
      'm' => t.unitM,
      'l' => t.unitLiters,
      'c' => t.unitCelsius,
      'cars' => t.unitCars,
      'slots' => t.unitSlots,
      'sections' => t.unitSections,
      _ => '',
    };

String _num(num v) {
  if (v == v.roundToDouble()) {
    final s = v.toInt().toString();
    // 30000 → «30 000» — крупные литры читаются глазами.
    return s.length > 4 ? s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ') : s;
  }
  return v.toString();
}

/// Строка машины/груза по профилю (048 п.3, 6): «Цистерна · 30 000 л · Пищевое · 3 секц.».
String specsSummary(LubaoLocalizations t, String locale, BodyType bodyType, Map<String, dynamic>? specs, {bool cargo = false}) {
  final values = specs ?? const {};
  final parts = <String>[bodyType.name.forLanguageCode(locale)];
  for (final f in cargo ? bodyType.cargoFields : bodyType.vehicleFields) {
    final v = values[f.key];
    if (v == null) continue;
    switch (f.kind) {
      case 'number':
        if (v is num) parts.add('${_num(v)} ${bodyUnitLabel(t, f.unit)}'.trim());
      case 'enum':
        final o = f.options.where((o) => o.code == v).firstOrNull;
        if (o != null) parts.add(o.label.forLanguageCode(locale));
      case 'multi':
        if (v is List) parts.add(f.options.where((o) => v.contains(o.code)).map((o) => o.label.forLanguageCode(locale)).join('/'));
      case 'bool':
        if (v == true) parts.add(f.label.forLanguageCode(locale).toLowerCase());
    }
  }
  return parts.join(' · ');
}

/// Форма параметров по полям профиля кузова (048 п.3–4, 7): числа с единицами,
/// выбор одного / нескольких вариантов, переключатель. Значения — как в `specs`.
class SpecsForm extends StatefulWidget {
  const SpecsForm({super.key, required this.fields, required this.values, required this.onChanged});

  final List<BodyField> fields;
  final Map<String, dynamic> values;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<SpecsForm> createState() => _SpecsFormState();
}

class _SpecsFormState extends State<SpecsForm> {
  final _controllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _set(String key, dynamic value) {
    final next = {...widget.values};
    if (value == null) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final children = <Widget>[];
    for (final f in widget.fields) {
      final label = f.label.forLanguageCode(locale) + (f.required ? ' *' : '');
      switch (f.kind) {
        case 'number':
          final controller = _controllers.putIfAbsent(f.key, () {
            final v = widget.values[f.key];
            return TextEditingController(text: v is num ? _num(v).replaceAll(' ', '') : '');
          });
          final unit = bodyUnitLabel(t, f.unit);
          children.add(AppTextField(
            key: Key('spec-${f.key}'),
            label: unit.isEmpty ? label : '$label, $unit',
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            onChanged: (text) => _set(f.key, double.tryParse(text.replaceAll(',', '.').replaceAll(' ', ''))),
          ));
        case 'enum':
        case 'multi':
          final current = widget.values[f.key];
          children.add(Text(label, style: AppTextStyles.bodyStrong));
          children.add(const SizedBox(height: AppSpacing.xs));
          children.add(Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final o in f.options)
                SelectableTile(
                  key: Key('spec-${f.key}-${o.code}'),
                  label: o.label.forLanguageCode(locale),
                  selected: f.kind == 'enum' ? current == o.code : (current is List && current.contains(o.code)),
                  onTap: () {
                    if (f.kind == 'enum') {
                      _set(f.key, current == o.code ? null : o.code);
                    } else {
                      final list = current is List ? [...current.cast<String>()] : <String>[];
                      list.contains(o.code) ? list.remove(o.code) : list.add(o.code);
                      _set(f.key, list.isEmpty ? null : list);
                    }
                  },
                ),
            ],
          ));
        case 'bool':
          children.add(SwitchListTile(
            key: Key('spec-${f.key}'),
            contentPadding: EdgeInsets.zero,
            title: Text(f.label.forLanguageCode(locale)),
            value: widget.values[f.key] == true,
            onChanged: (v) => _set(f.key, v),
          ));
      }
      children.add(const SizedBox(height: AppSpacing.md));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
