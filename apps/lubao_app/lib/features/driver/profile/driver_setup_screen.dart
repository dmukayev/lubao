import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import 'add_city_sheet.dart';
import '../../shared/error_feedback.dart';

const _capacityPresets = [10.0, 15.0, 20.0, 25.0];

class DriverSetupScreen extends ConsumerStatefulWidget {
  const DriverSetupScreen({super.key, this.isRegistration = false});

  /// true — это первый шаг после SMS (анкеты ещё нет): без гос.номера и
  /// допусков, занимает около минуты. Документы для подтверждения личности
  /// запрашиваются отдельно, при первом отклике или подтверждении сделки.
  final bool isRegistration;

  @override
  ConsumerState<DriverSetupScreen> createState() => _DriverSetupScreenState();
}

class _DriverSetupScreenState extends ConsumerState<DriverSetupScreen> {
  final _fullNameController = TextEditingController();
  final _plateController = TextEditingController();
  String? _homeCityId;
  String? _bodyTypeId;
  double? _capacityTons;
  bool _anyCountry = false;
  final _selectedCountries = <String>{};
  final _selectedPermits = <String>{};
  /// Области внутри выбранных стран (045 п.7); у страны без своих областей — вся страна.
  final _selectedRegions = <String>{};
  /// 048 п.7: «основа» кузова по профилю (литры и продукт, места, контейнеры).
  Map<String, dynamic> _preferredSpecs = {};

  BodyType? _selectedBodyType(ReferenceData refData) =>
      _bodyTypeId == null ? null : refData.bodyTypes.where((b) => b.id == _bodyTypeId).firstOrNull;
  bool _initialized = false;
  bool _saving = false;
  TextEditingController? _cityFieldController;

  String? _fullNameError;
  String? _homeCityError;
  String? _bodyTypeError;

  /// Регистрация — 3 шага с индикатором (задача 021): 0 — имя+город,
  /// 1 — машина, 2 — страны. Редактирование профиля (isRegistration==false)
  /// остаётся одной формой, как раньше — это не регистрация.
  int _step = 0;
  static const _stepCount = 3;

  void _initFromDriver(Driver driver) {
    if (_initialized) return;
    _initialized = true;
    _fullNameController.text = driver.fullName;
    _plateController.text = driver.vehicle?.plateNumber ?? '';
    _homeCityId = driver.homeCityId;
    _bodyTypeId = driver.vehicle?.bodyTypeId ?? driver.preferredBodyTypeId;
    _capacityTons = driver.vehicle?.capacityTons ?? driver.preferredCapacityTons;
    _anyCountry = driver.anyCountry;
    _selectedCountries.addAll(driver.directionCountryIds);
    _selectedPermits.addAll(driver.permitIds);
    _selectedRegions.addAll(driver.directionRegionIds);
  }

  /// Области страны (045 п.7): ничего не отмечено — вся страна.
  Future<void> _pickRegions(BuildContext context, ReferenceData refData, Country country, String locale) async {
    final t = context.l10n;
    final regions = refData.regionsOf(country.id);
    final picked = {..._selectedRegions.where((id) => regions.any((r) => r.id == id))};
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(top: false, child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Text(t.directionRegionsTitle(country.name.forLanguageCode(locale)), style: AppTextStyles.title),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  CheckboxListTile(
                    key: const Key('directionRegionsAll'),
                    value: picked.isEmpty,
                    title: Text(t.directionRegionsAll),
                    onChanged: (_) => setSheet(picked.clear),
                  ),
                  for (final region in regions)
                    CheckboxListTile(
                      key: Key('directionRegion-${region.id}'),
                      value: picked.contains(region.id),
                      title: Text(region.name.forLanguageCode(locale)),
                      onChanged: (v) => setSheet(() => v == true ? picked.add(region.id) : picked.remove(region.id)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: PrimaryButton(key: const Key('directionRegionsDone'), label: t.commonDone, onPressed: () => Navigator.pop(sheetContext, picked)),
            ),
          ],
        )),
      ),
    );
    if (result == null) return;
    setState(() {
      _selectedRegions.removeAll(regions.map((r) => r.id));
      _selectedRegions.addAll(result);
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  bool _validateStep0() {
    final t = context.l10n;
    final fullName = _fullNameController.text.trim();
    setState(() {
      _fullNameError = isValidPersonName(fullName) ? null : t.driverSetupFullNameError;
      _homeCityError = _homeCityId == null ? t.driverSetupHomeCityError : null;
    });
    return _fullNameError == null && _homeCityError == null;
  }

  bool _validateStep1() {
    final t = context.l10n;
    setState(() => _bodyTypeError = _bodyTypeId == null ? t.driverSetupBodyTypeError : null);
    return _bodyTypeError == null;
  }

  void _goNext() {
    final valid = _step == 0 ? _validateStep0() : _validateStep1();
    if (!valid) return;
    setState(() => _step += 1);
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step -= 1);
    }
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final fullName = _fullNameController.text.trim();
    setState(() {
      _fullNameError = isValidPersonName(fullName) ? null : t.driverSetupFullNameError;
      _homeCityError = _homeCityId == null ? t.driverSetupHomeCityError : null;
      // Кузов — только в регистрации; при правке профиля машины не меняются (041, п.6).
      _bodyTypeError = widget.isRegistration && _bodyTypeId == null ? t.driverSetupBodyTypeError : null;
    });
    if (_fullNameError != null || _homeCityError != null || _bodyTypeError != null) return;

    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(driverRepositoryProvider)
          .updateProfile(
            DriverSetupInput(
              fullName: fullName,
              homeCityId: _homeCityId!,
              anyCountry: _anyCountry,
              directionCountryIds: _anyCountry ? [] : _selectedCountries.toList(),
              permitIds: _selectedPermits.toList(),
              directionRegionIds: _anyCountry ? const [] : _selectedRegions.toList(),
              preferredSpecs: widget.isRegistration && _preferredSpecs.isNotEmpty ? _preferredSpecs : null,
              bodyTypeId: widget.isRegistration ? _bodyTypeId : null,
              plateNumber: null,
              capacityTons: _capacityTons,
            ),
          );
      ref.read(sessionProvider.notifier).updateDriver(updated);
      if (mounted) {
        if (widget.isRegistration) {
          // 045 п.9/11: сразу на главную, там — «Где вы сейчас?».
          context.go('/driver/feed?where=1');
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Регистрация/сохранение не должны молча «ничего не делать» (041, п.7).
      if (mounted) showApiError(context, e, onRetry: _submit);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final referenceData = ref.watch(referenceDataProvider);
    final driver = ref.watch(sessionProvider)?.driver;

    return Scaffold(
      appBar: AppBar(
        leading: widget.isRegistration ? IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: _goBack) : null,
        title: Text(widget.isRegistration ? t.driverRegisterTitle : t.driverSetupTitle),
      ),
      body: referenceData.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('DriverSetupScreen: $e');
          return ErrorView(message: t.commonError);
        },
        data: (refData) {
          if (driver != null) _initFromDriver(driver);

          final homeCityOptions = refData.countryCityOptions(locale, includeCountryOnly: false);
          final initialCity = refData.cityById(_homeCityId);
          final initialCityLabel = initialCity == null
              ? ''
              : homeCityOptions
                    .firstWhere((o) => o.cityId == initialCity.id, orElse: () => homeCityOptions.first)
                    .label;

          final step0Fields = [
            AppTextField(
              key: const Key('driverSetupFullName'),
              // 045 п.10: при регистрации — только имя; полное ФИО придёт из прав.
              label: widget.isRegistration ? t.driverSetupFirstName : t.driverSetupFullName,
              controller: _fullNameController,
              errorText: _fullNameError,
            ),
            const SizedBox(height: AppSpacing.md),
            Autocomplete<CountryCityOption>(
              initialValue: TextEditingValue(text: initialCityLabel),
              displayStringForOption: (o) => o.label,
              optionsBuilder: (value) {
                final addCityOption = CountryCityOption(label: t.cityNotListed, countryId: '', isAddCityAction: true);
                if (value.text.trim().isEmpty) return [...homeCityOptions, addCityOption];
                final matches = searchCities(refData.cities, refData.countries, value.text);
                final matchedOptions = <CountryCityOption>[];
                for (final city in matches) {
                  for (final option in homeCityOptions) {
                    if (option.cityId == city.id) {
                      matchedOptions.add(option);
                      break;
                    }
                  }
                }
                return [...matchedOptions, addCityOption];
              },
              onSelected: (option) async {
                if (option.isAddCityAction) {
                  final city = await showAddCitySheet(context, ref, refData);
                  if (city != null) {
                    final countryName = refData.countryById(city.countryId).name.forLanguageCode(locale);
                    _cityFieldController?.text = '${city.name.forLanguageCode(locale)}, $countryName';
                    setState(() {
                      _homeCityId = city.id;
                      _homeCityError = null;
                    });
                  } else {
                    _cityFieldController?.text = '';
                  }
                  return;
                }
                setState(() {
                  _homeCityId = option.cityId;
                  _homeCityError = null;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                _cityFieldController = controller;
                return AppTextField(
                  key: const Key('driverSetupHomeCity'),
                  label: t.driverSetupHomeCity,
                  hintText: t.searchCityCountryHint,
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (_) => onSubmitted(),
                  errorText: _homeCityError,
                );
              },
            ),
          ];

          final Widget permitChips = Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: refData.permits.map((permit) {
                  final selected = _selectedPermits.contains(permit.id);
                  return SelectableTile(
                    label: permit.name.forLanguageCode(locale),
                    selected: selected,
                    leading: selected ? const Icon(LucideIcons.check, size: 16, color: AppColors.primary) : null,
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedPermits.remove(permit.id);
                      } else {
                        _selectedPermits.add(permit.id);
                      }
                    }),
                  );
                }).toList(),
              );

          final step1Fields = [
            if (widget.isRegistration) ...[
              Text(t.driverSetupVehicleTitle, style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.xs),
              Text(t.driverSetupVehicleSubtitle, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              for (var i = 0; i < refData.bodyTypes.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  // IntrinsicHeight — иначе Row(crossAxisAlignment: stretch) внутри
                  // ListView (где высота родителя не ограничена) пытается растянуть
                  // детей на "бесконечную" высоту и падает с BoxConstraints forces
                  // an infinite height.
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _VehicleTile(
                            key: Key('driverSetupBody-${refData.bodyTypes[i].code}'),
                            bodyTypeCode: refData.bodyTypes[i].code,
                            label: refData.bodyTypes[i].name.forLanguageCode(locale),
                            selected: _bodyTypeId == refData.bodyTypes[i].id,
                            onTap: () => setState(() {
                              _bodyTypeId = refData.bodyTypes[i].id;
                              _preferredSpecs = {};
                            }),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (i + 1 < refData.bodyTypes.length)
                          Expanded(
                            child: _VehicleTile(
                              bodyTypeCode: refData.bodyTypes[i + 1].code,
                              label: refData.bodyTypes[i + 1].name.forLanguageCode(locale),
                              selected: _bodyTypeId == refData.bodyTypes[i + 1].id,
                              onTap: () => setState(() {
                                _bodyTypeId = refData.bodyTypes[i + 1].id;
                                _preferredSpecs = {};
                              }),
                            ),
                          )
                        else
                          const Expanded(child: SizedBox()),
                      ],
                    ),
                  ),
                ),
              if (_bodyTypeError != null) ...[
                Text(_bodyTypeError!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                const SizedBox(height: AppSpacing.sm),
              ],
              // 048 п.7: «основа» типа кузова — тоннаж только там, где он поле
              // профиля (у автовоза и контейнеровоза его нет), остальное — по профилю.
              if (_selectedBodyType(refData)?.hasCapacity ?? true) ...[
                const SizedBox(height: AppSpacing.md),
                Text(t.driverSetupCapacity, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final capacity in _capacityPresets)
                      SelectableTile(
                        key: Key('driverSetupCapacity-${capacity.toStringAsFixed(0)}'),
                        label: '${capacity.toStringAsFixed(0)} ${t.unitTon}',
                        selected: _capacityTons == capacity,
                        onTap: () => setState(() => _capacityTons = capacity),
                      ),
                  ],
                ),
              ],
              if (_selectedBodyType(refData) != null &&
                  _selectedBodyType(refData)!.primaryFields.any((f) => f.key != 'capacityTons')) ...[
                const SizedBox(height: AppSpacing.md),
                SpecsForm(
                  key: ValueKey('preferredSpecs-$_bodyTypeId'),
                  fields: _selectedBodyType(refData)!.primaryFields.where((f) => f.key != 'capacityTons').toList(),
                  values: _preferredSpecs,
                  onChanged: (v) => setState(() => _preferredSpecs = v),
                ),
              ],
            ],
            if (!widget.isRegistration) ...[
              // Машины правятся в гараже (041, п.6) — здесь только допуски.
              ListTile(
                key: const Key('driverSetupGarageLink'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.truck),
                title: Text(t.garageGoToGarage),
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () => context.push('/driver/garage'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(t.driverSetupDocuments, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              permitChips,
            ],
          ];

          final step2Fields = [
            Text(t.driverSetupDirectionsTitle, style: AppTextStyles.headline),
            const SizedBox(height: AppSpacing.xs),
            Text(t.driverSetupDirectionsSubtitle, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Row(
                children: [
                  const Icon(LucideIcons.globe, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(t.driverSetupAnyCountry, style: AppTextStyles.bodyStrong)),
                  Switch(
                    value: _anyCountry,
                    onChanged: (value) => setState(() => _anyCountry = value),
                    activeTrackColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            if (!_anyCountry) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final country in refData.countries) ...[
                      _CountryRow(
                        code: country.code,
                        label: country.name.forLanguageCode(locale),
                        selected: _selectedCountries.contains(country.id),
                        showDivider: country != refData.countries.last && !_selectedCountries.contains(country.id),
                        onTap: () => setState(() {
                          if (_selectedCountries.contains(country.id)) {
                            _selectedCountries.remove(country.id);
                            _selectedRegions.removeAll(refData.regionsOf(country.id).map((r) => r.id));
                          } else {
                            _selectedCountries.add(country.id);
                          }
                        }),
                      ),
                      // 045 п.7: уточнить области — по тапу; по умолчанию «вся страна».
                      if (_selectedCountries.contains(country.id) && refData.regionsOf(country.id).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl + AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              key: Key('directionRegions-${country.code}'),
                              onPressed: () => _pickRegions(context, refData, country, locale),
                              icon: const Icon(LucideIcons.mapPin, size: 16),
                              label: Text(() {
                                final count = refData.regionsOf(country.id).where((r) => _selectedRegions.contains(r.id)).length;
                                return count == 0 ? t.directionRegionsAll : t.directionRegionsCount(count);
                              }()),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
            // 045 п.8: допуски — на этом же шаге, необязательными чипами.
            if (widget.isRegistration) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(t.driverSetupPermitsOptional, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              permitChips,
            ],
          ];

          if (!widget.isRegistration) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                ...step0Fields,
                const SizedBox(height: AppSpacing.xxl),
                ...step1Fields,
                const SizedBox(height: AppSpacing.xxl),
                ...step2Fields,
                const SizedBox(height: AppSpacing.xxl),
                PrimaryButton(
                  label: _anyCountry || _selectedCountries.isEmpty
                      ? t.driverSetupSubmit
                      : t.driverSetupCountriesSelected(_selectedCountries.length),
                  loading: _saving,
                  onPressed: _submit,
                ),
              ],
            );
          }

          final stepFields = [step0Fields, step1Fields, step2Fields][_step];
          final isLastStep = _step == _stepCount - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StepProgress(currentStep: _step + 1, totalSteps: _stepCount),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.driverSetupStepOf(_step + 1, _stepCount),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  children: stepFields,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: PrimaryButton(
                  key: const Key('driverSetupNext'),
                  label: isLastStep
                      ? (_anyCountry || _selectedCountries.isEmpty
                            ? t.driverSetupSubmit
                            : t.driverSetupCountriesSelected(_selectedCountries.length))
                      : t.commonNext,
                  loading: _saving,
                  onPressed: isLastStep ? _submit : _goNext,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// У `BodyType` нет поля под картинку/иконку (только `code`/`name`) — вместо
/// добавления ассета на бэкенд сопоставляем по коду справочника локально;
/// коду без пары — обычный грузовик, чтобы новый тип не остался без иконки.

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({super.key, required this.bodyTypeCode, required this.label, required this.selected, required this.onTap});

  /// Миниатюра кузова по коду справочника (045 п.4, эталон 29).
  final String bodyTypeCode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              BodyTypeIcon(bodyTypeCode: bodyTypeCode, width: 120),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(color: selected ? AppColors.primary : AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.code,
    required this.label,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('driverSetupCountry-$code'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              )
            : null,
        child: Row(
          children: [
            CountryCode(code: code),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTextStyles.bodyStrong)),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 2),
              ),
              child: selected ? const Icon(LucideIcons.check, size: 16, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}
