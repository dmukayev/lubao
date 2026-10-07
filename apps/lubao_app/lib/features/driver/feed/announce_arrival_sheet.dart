import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/city_picking.dart';
import '../../shared/status_helpers.dart';
import '../../shared/error_feedback.dart';
import '../../../services/push_service.dart';

const _waitDaysOptions = [1, 2, 3];

/// «Свободен в <город> с <даты>» (задачи 015, 040): где, когда, куда готов.
/// [editing] — правка существующего анонса (их может быть несколько).
/// Возвращает true, если анонс сохранён — вызывающий код сам инвалидирует
/// `myArrivalsProvider`. `_AnnounceArrivalSheet` сам читает провайдеры через
/// `ConsumerStatefulWidget`, поэтому отдельный `WidgetRef` сюда передавать
/// не нужно.
Future<bool?> showAnnounceArrivalSheet(
  BuildContext context, {
  required ReferenceData refData,
  Arrival? editing,
  bool driverAnyCountry = false,
  List<String> driverDirectionCountryIds = const [],
  String? driverHomeCityId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge))),
    builder: (context) => _AnnounceArrivalSheet(
      refData: refData,
      editing: editing,
      driverAnyCountry: driverAnyCountry,
      driverDirectionCountryIds: driverDirectionCountryIds,
      driverHomeCityId: driverHomeCityId,
    ),
  );
}

class _AnnounceArrivalSheet extends ConsumerStatefulWidget {
  const _AnnounceArrivalSheet({
    required this.refData,
    this.editing,
    required this.driverAnyCountry,
    required this.driverDirectionCountryIds,
    this.driverHomeCityId,
  });

  final ReferenceData refData;
  final Arrival? editing;
  final bool driverAnyCountry;
  final List<String> driverDirectionCountryIds;
  final String? driverHomeCityId;

  @override
  ConsumerState<_AnnounceArrivalSheet> createState() => _AnnounceArrivalSheetState();
}

enum _DayChoice { today, tomorrow, dayAfter, custom }

class _AnnounceArrivalSheetState extends ConsumerState<_AnnounceArrivalSheet> {
  _DayChoice _dayChoice = _DayChoice.today;
  DateTime? _customDate;
  String? _pointId;
  bool _pointError = false;
  late bool _anyCountry;
  late final Set<String> _countryIds;
  int _waitDays = 2;
  bool _saving = false;
  String? _tractorId;
  String? _trailerId;
  bool _comboTouched = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    // Город по умолчанию — домашний город водителя, если он есть среди
    // городов погрузки; иначе выбирает сам (первую попавшуюся не подставляем).
    _pointId = editing?.pointId ??
        widget.refData.points.where((p) => p.cityId == widget.driverHomeCityId).map((p) => p.id).firstOrNull;
    _anyCountry = editing?.anyCountry ?? widget.driverAnyCountry;
    _countryIds = {...(editing?.countryIds ?? widget.driverDirectionCountryIds)};
    if (editing != null) {
      _waitDays = editing.waitDays;
      _tractorId = editing.tractorId;
      _trailerId = editing.trailerId;
      _comboTouched = true;
      _dayChoice = _dayChoiceFor(editing.plannedDay);
      if (_dayChoice == _DayChoice.custom) _customDate = DateTime(editing.plannedDay.year, editing.plannedDay.month, editing.plannedDay.day, 12);
    }
  }

  static _DayChoice _dayChoiceFor(DateTime plannedDay) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(plannedDay.year, plannedDay.month, plannedDay.day);
    final diff = day.difference(today).inDays;
    return switch (diff) {
      0 => _DayChoice.today,
      1 => _DayChoice.tomorrow,
      2 => _DayChoice.dayAfter,
      _ => _DayChoice.custom,
    };
  }

  Future<void> _pickCity() async {
    final picked = await pickCity(context, ref, refData: widget.refData, selectedId: _pointId);
    if (picked != null && mounted) {
      setState(() {
        _pointId = picked.id;
        _pointError = false;
      });
    }
  }

  /// Задача 031, этап B, п.9 — по умолчанию связка из прошлого анонса; пока
  /// гараж не загрузился (или водитель ничего не выбрал) используем первую
  /// непроверенную-или-проверенную машину каждого вида, как и сервер.
  void _defaultCombo(List<GarageVehicle> vehicles) {
    if (_comboTouched) return;
    final tractor = vehicles.where((v) => v.kind == VehicleKind.tractor || v.kind == VehicleKind.rigid).firstOrNull;
    final trailer = vehicles.where((v) => v.kind == VehicleKind.trailer).firstOrNull;
    _tractorId = tractor?.id;
    _trailerId = trailer?.id;
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
    final pointId = _pointId;
    if (pointId == null) {
      setState(() => _pointError = true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(arrivalRepositoryProvider).announce(
            arrivalId: widget.editing?.id,
            pointId: pointId,
            plannedAt: _plannedDate,
            anyCountry: _anyCountry,
            countryIds: _anyCountry ? const [] : _countryIds.toList(),
            waitDays: _waitDays,
            tractorId: _tractorId,
            trailerId: _trailerId,
          );
      // Первое осмысленное действие — спрашиваем разрешение на push (042 п.1).
      unawaited(ref.read(pushServiceProvider).requestPermissionAndRegister());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showApiError(context, e);
      }
    }
  }

  String _comboLabel(String details, String fallback, bool verified, String pendingBadge) {
    final base = details.isEmpty ? fallback : details;
    return verified ? base : '$base · $pendingBadge';
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
              Row(
                children: [
                  Expanded(child: Text(t.announceArrivalTitle, style: AppTextStyles.title)),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: t.commonBack,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(t.announceArrivalWhere, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              CityField(
                key: const Key('announceCityField'),
                label: t.cityPickerTitle,
                value: _pointId == null ? null : widget.refData.pointOrNull(_pointId!)?.name.forLanguageCode(locale),
                errorText: _pointError ? t.announceArrivalCityError : null,
                onTap: _pickCity,
              ),
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
              const SizedBox(height: AppSpacing.lg),

              Text(t.garageComboTitle, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Consumer(
                builder: (context, ref, _) {
                  final vehiclesAsync = ref.watch(garageVehiclesProvider);
                  return vehiclesAsync.when(
                    loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (e, st) => const SizedBox.shrink(),
                    data: (vehicles) {
                      _defaultCombo(vehicles);
                      final tractors = vehicles.where((v) => v.kind == VehicleKind.tractor || v.kind == VehicleKind.rigid).toList();
                      final trailers = vehicles.where((v) => v.kind == VehicleKind.trailer).toList();
                      if (tractors.isEmpty && trailers.isEmpty) {
                        return Text(t.garageComboEmpty, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tractors.isNotEmpty) ...[
                            Text(t.garageComboTractorLabel, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final v in tractors)
                                  SelectableTile(
                                    label: _comboLabel(
                                      [v.brand, v.plateNumber].whereType<String>().join(' · '),
                                      t.garageKindTractor,
                                      v.isVerified,
                                      t.garageComboPendingBadge,
                                    ),
                                    selected: _tractorId == v.id,
                                    onTap: () => setState(() {
                                      _comboTouched = true;
                                      _tractorId = _tractorId == v.id ? null : v.id;
                                    }),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          if (trailers.isNotEmpty) ...[
                            Text(t.garageComboTrailerLabel, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final v in trailers)
                                  SelectableTile(
                                    label: _comboLabel(
                                      [
                                        if (v.capacityTons != null) '${v.capacityTons!.toStringAsFixed(0)} ${t.unitTon}',
                                        v.plateNumber,
                                      ].whereType<String>().join(' · '),
                                      t.garageKindTrailer,
                                      v.isVerified,
                                      t.garageComboPendingBadge,
                                    ),
                                    selected: _trailerId == v.id,
                                    onTap: () => setState(() {
                                      _comboTouched = true;
                                      _trailerId = _trailerId == v.id ? null : v.id;
                                    }),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              PrimaryButton(
                key: const Key('announceArrivalSubmitButton'),
                label: t.announceArrivalSubmit,
                loading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
