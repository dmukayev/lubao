import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';

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
  bool _initialized = false;
  bool _saving = false;

  void _initFromDriver(Driver driver) {
    if (_initialized) return;
    _initialized = true;
    _fullNameController.text = driver.fullName;
    _plateController.text = driver.vehicle?.plateNumber ?? '';
    _homeCityId = driver.homeCityId;
    _bodyTypeId = driver.vehicle?.bodyTypeId;
    _capacityTons = driver.vehicle?.capacityTons;
    _anyCountry = driver.anyCountry;
    _selectedCountries.addAll(driver.directionCountryIds);
    _selectedPermits.addAll(driver.permitIds);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_homeCityId == null || _bodyTypeId == null) return;
    setState(() => _saving = true);
    try {
      final updated = await ref.read(driverRepositoryProvider).updateProfile(DriverSetupInput(
            fullName: _fullNameController.text.trim(),
            homeCityId: _homeCityId!,
            anyCountry: _anyCountry,
            directionCountryIds: _anyCountry ? [] : _selectedCountries.toList(),
            permitIds: _selectedPermits.toList(),
            bodyTypeId: _bodyTypeId!,
            plateNumber: widget.isRegistration ? null : _plateController.text.trim(),
            capacityTons: _capacityTons,
          ));
      ref.read(sessionProvider.notifier).updateDriver(updated);
      if (mounted) {
        if (widget.isRegistration) {
          context.go('/driver/feed');
        } else {
          Navigator.of(context).pop();
        }
      }
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
      appBar: AppBar(title: Text(widget.isRegistration ? t.driverRegisterTitle : t.driverSetupTitle)),
      body: referenceData.when(
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(message: t.commonError),
        data: (refData) {
          if (driver != null) _initFromDriver(driver);

          final homeCityOptions = refData.countryCityOptions(locale, includeCountryOnly: false);
          final initialCity = refData.cityById(_homeCityId);
          final initialCityLabel = initialCity == null
              ? ''
              : homeCityOptions.firstWhere((o) => o.cityId == initialCity.id, orElse: () => homeCityOptions.first).label;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              AppTextField(label: t.driverSetupFullName, controller: _fullNameController),
              const SizedBox(height: AppSpacing.md),
              Autocomplete<CountryCityOption>(
                initialValue: TextEditingValue(text: initialCityLabel),
                displayStringForOption: (o) => o.label,
                optionsBuilder: (value) {
                  if (value.text.isEmpty) return homeCityOptions;
                  final query = value.text.toLowerCase();
                  return homeCityOptions.where((o) => o.label.toLowerCase().contains(query));
                },
                onSelected: (option) => setState(() => _homeCityId = option.cityId),
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) => AppTextField(
                  label: t.driverSetupHomeCity,
                  hintText: t.searchCityCountryHint,
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (_) => onSubmitted(),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Text(t.driverSetupVehicleTitle, style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.xs),
              Text(t.driverSetupVehicleSubtitle, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              for (var i = 0; i < refData.bodyTypes.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _VehicleTile(
                          label: refData.bodyTypes[i].name.forLanguageCode(locale),
                          selected: _bodyTypeId == refData.bodyTypes[i].id,
                          onTap: () => setState(() => _bodyTypeId = refData.bodyTypes[i].id),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (i + 1 < refData.bodyTypes.length)
                        Expanded(
                          child: _VehicleTile(
                            label: refData.bodyTypes[i + 1].name.forLanguageCode(locale),
                            selected: _bodyTypeId == refData.bodyTypes[i + 1].id,
                            onTap: () => setState(() => _bodyTypeId = refData.bodyTypes[i + 1].id),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(t.driverSetupCapacity, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final capacity in _capacityPresets)
                    SelectableTile(
                      label: '${capacity.toStringAsFixed(0)} ${t.unitTon}',
                      selected: _capacityTons == capacity,
                      onTap: () => setState(() => _capacityTons = capacity),
                    ),
                ],
              ),
              if (!widget.isRegistration) ...[
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: t.driverSetupVehiclePlate, controller: _plateController),
                const SizedBox(height: AppSpacing.md),
                Text(t.driverSetupDocuments, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
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
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),

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
                      for (final country in refData.countries)
                        _CountryRow(
                          code: country.code,
                          label: country.name.forLanguageCode(locale),
                          selected: _selectedCountries.contains(country.id),
                          showDivider: country != refData.countries.last,
                          onTap: () => setState(() {
                            if (_selectedCountries.contains(country.id)) {
                              _selectedCountries.remove(country.id);
                            } else {
                              _selectedCountries.add(country.id);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ],
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
        },
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.label, required this.selected, required this.onTap});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.truck, size: 32, color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: showDivider ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))) : null,
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
