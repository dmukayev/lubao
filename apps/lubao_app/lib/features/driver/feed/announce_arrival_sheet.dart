import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../shared/status_helpers.dart';

const _waitDaysOptions = [1, 2, 3];

/// «Буду на точке» в 3 нажатия (задача 015): когда, где, куда готов.
/// Возвращает true, если анонс опубликован — вызывающий код сам
/// инвалидирует `myArrivalProvider`. `_AnnounceArrivalSheet` сам читает
/// провайдеры через `ConsumerStatefulWidget`, поэтому отдельный `WidgetRef`
/// сюда передавать не нужно.
Future<bool?> showAnnounceArrivalSheet(
  BuildContext context, {
  required ReferenceData refData,
  ArrivalTemplate? template,
  bool driverAnyCountry = false,
  List<String> driverDirectionCountryIds = const [],
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge))),
    builder: (context) => _AnnounceArrivalSheet(
      refData: refData,
      template: template,
      driverAnyCountry: driverAnyCountry,
      driverDirectionCountryIds: driverDirectionCountryIds,
    ),
  );
}

class _AnnounceArrivalSheet extends ConsumerStatefulWidget {
  const _AnnounceArrivalSheet({
    required this.refData,
    this.template,
    required this.driverAnyCountry,
    required this.driverDirectionCountryIds,
  });

  final ReferenceData refData;
  final ArrivalTemplate? template;
  final bool driverAnyCountry;
  final List<String> driverDirectionCountryIds;

  @override
  ConsumerState<_AnnounceArrivalSheet> createState() => _AnnounceArrivalSheetState();
}

enum _DayChoice { today, tomorrow, dayAfter, custom }

class _AnnounceArrivalSheetState extends ConsumerState<_AnnounceArrivalSheet> {
  _DayChoice _dayChoice = _DayChoice.today;
  DateTime? _customDate;
  late String _pointId;
  late bool _anyCountry;
  late final Set<String> _countryIds;
  int _waitDays = 2;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pointId = widget.template?.pointId ?? (widget.refData.points.isEmpty ? '' : widget.refData.points.first.id);
    _anyCountry = widget.template?.anyCountry ?? widget.driverAnyCountry;
    _countryIds = {...(widget.template?.countryIds ?? widget.driverDirectionCountryIds)};
  }

  DateTime get _plannedDate {
    final now = DateTime.now();
    switch (_dayChoice) {
      case _DayChoice.today:
        return DateTime(now.year, now.month, now.day, 12);
      case _DayChoice.tomorrow:
        final d = now.add(const Duration(days: 1));
        return DateTime(d.year, d.month, d.day, 12);
      case _DayChoice.dayAfter:
        final d = now.add(const Duration(days: 2));
        return DateTime(d.year, d.month, d.day, 12);
      case _DayChoice.custom:
        return _customDate ?? now;
    }
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
    );
    if (picked != null) {
      setState(() {
        _customDate = DateTime(picked.year, picked.month, picked.day, 12);
        _dayChoice = _DayChoice.custom;
      });
    }
  }

  Future<void> _submit() async {
    if (_pointId.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(arrivalRepositoryProvider).announce(
            pointId: _pointId,
            plannedAt: _plannedDate,
            anyCountry: _anyCountry,
            countryIds: _anyCountry ? const [] : _countryIds.toList(),
            waitDays: _waitDays,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screen,
          right: AppSpacing.screen,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.announceArrivalTitle, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.lg),

              Text(t.announceArrivalWhen, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SelectableTile(
                    label: t.announceArrivalToday,
                    selected: _dayChoice == _DayChoice.today,
                    onTap: () => setState(() => _dayChoice = _DayChoice.today),
                  ),
                  SelectableTile(
                    label: t.announceArrivalTomorrow,
                    selected: _dayChoice == _DayChoice.tomorrow,
                    onTap: () => setState(() => _dayChoice = _DayChoice.tomorrow),
                  ),
                  SelectableTile(
                    label: t.announceArrivalDayAfter,
                    selected: _dayChoice == _DayChoice.dayAfter,
                    onTap: () => setState(() => _dayChoice = _DayChoice.dayAfter),
                  ),
                  SelectableTile(
                    label: _dayChoice == _DayChoice.custom && _customDate != null
                        ? formatDate(_customDate!)
                        : t.announceArrivalPickDate,
                    selected: _dayChoice == _DayChoice.custom,
                    onTap: _pickCustomDate,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(t.announceArrivalWhere, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              InputDecorator(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _pointId.isEmpty ? null : _pointId,
                    isExpanded: true,
                    items: widget.refData.points
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name.forLanguageCode(locale))))
                        .toList(),
                    onChanged: (value) => setState(() => _pointId = value ?? _pointId),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(t.announceArrivalCountries, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SelectableTile(
                    label: t.driverSetupAnyCountry,
                    selected: _anyCountry,
                    onTap: () => setState(() => _anyCountry = !_anyCountry),
                  ),
                  if (!_anyCountry)
                    for (final country in widget.refData.countries)
                      SelectableTile(
                        label: country.name.forLanguageCode(locale),
                        selected: _countryIds.contains(country.id),
                        onTap: () => setState(() {
                          if (_countryIds.contains(country.id)) {
                            _countryIds.remove(country.id);
                          } else {
                            _countryIds.add(country.id);
                          }
                        }),
                      ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(t.announceArrivalWaitDays, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final days in _waitDaysOptions)
                    SelectableTile(
                      label: t.announceArrivalWaitDaysValue(days),
                      selected: _waitDays == days,
                      onTap: () => setState(() => _waitDays = days),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              PrimaryButton(label: t.announceArrivalSubmit, loading: _saving, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
