import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import '../shared/edit_side_panel.dart';

class DriverEditResult {
  const DriverEditResult({
    required this.fullName,
    required this.phone,
    required this.homeCityId,
    required this.anyCountry,
    required this.countryIds,
    required this.permitIds,
    this.vehicleBodyTypeId,
    this.vehicleCapacityTons,
    this.vehicleLengthM,
    this.vehiclePlateNumber,
    this.vehicleBrand,
    required this.reason,
  });

  final String fullName;
  final String phone;
  final String homeCityId;
  final bool anyCountry;
  final List<String> countryIds;
  final List<String> permitIds;
  final String? vehicleBodyTypeId;
  final double? vehicleCapacityTons;
  final double? vehicleLengthM;
  final String? vehiclePlateNumber;
  final String? vehicleBrand;
  final String reason;
}

/// Общая панель редактирования водителя (задача 028, п.18/19): имя,
/// телефон (предупреждение — сессии будут отозваны), домашний город (поиск
/// как в задаче 021), машина, страны/«любая», допуски.
Future<DriverEditResult?> showDriverEditPanel(
  BuildContext context, {
  required AdminDriverDetail driver,
  required ReferenceData refData,
}) async {
  final locale = Localizations.localeOf(context).languageCode;
  final fullNameController = TextEditingController(text: driver.fullName);
  final phoneController = TextEditingController(text: driver.phone ?? '');
  final cityController = TextEditingController(text: driver.homeCityName.forLanguageCode(locale));
  final plateController = TextEditingController(text: driver.vehicles.isNotEmpty ? driver.vehicles.first.plateNumber ?? '' : '');
  final brandController = TextEditingController(text: driver.vehicles.isNotEmpty ? driver.vehicles.first.brand ?? '' : '');
  final capacityController = TextEditingController(text: driver.vehicles.isNotEmpty ? driver.vehicles.first.capacityTons?.toString() ?? '' : '');
  final lengthController = TextEditingController(text: driver.vehicles.isNotEmpty ? driver.vehicles.first.lengthM?.toString() ?? '' : '');

  String homeCityId = driver.homeCityId;
  bool anyCountry = driver.anyCountry;
  final selectedCountryIds = {...driver.directionCountryIds};
  final selectedPermitIds = {...driver.permitIds};
  String? bodyTypeId = refData.bodyTypes.where((b) => driver.vehicles.isNotEmpty && b.id == driver.vehicles.first.bodyTypeId).firstOrNull?.id;

  final hasVehicle = driver.vehicles.isNotEmpty;
  final originalPhone = driver.phone ?? '';

  final reason = await showEditSidePanel(
    context: context,
    title: driver.fullName,
    canSave: () => fullNameController.text.trim().isNotEmpty && phoneController.text.trim().isNotEmpty && homeCityId.isNotEmpty,
    fieldsBuilder: (context, setState) {
      final t = context.l10n;
      final cityMatches = cityController.text.trim().isEmpty
          ? <City>[]
          : searchCities(refData.cities, refData.countries, cityController.text.trim());

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: t.driverSetupFullName, controller: fullNameController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          AppTextField(label: t.driverLoginPhoneLabel, controller: phoneController, onChanged: (_) => setState(() {})),
          if (phoneController.text.trim() != originalPhone) ...[
            const SizedBox(height: 4),
            Text(t.adminPhoneChangeWarning, style: const TextStyle(color: StatusBadge.danger, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          AppTextField(label: t.driverSetupHomeCity, controller: cityController, onChanged: (_) => setState(() {})),
          for (final city in cityMatches.take(5))
            ListTile(
              dense: true,
              title: Text(city.name.forLanguageCode(locale)),
              onTap: () => setState(() {
                homeCityId = city.id;
                cityController.text = city.name.forLanguageCode(locale);
              }),
            ),
          const SizedBox(height: 16),
          Text(t.driverSetupVehicleTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (hasVehicle) ...[
            DropdownButtonFormField<String>(
              initialValue: bodyTypeId,
              decoration: InputDecoration(labelText: t.postCargoBodyType),
              items: refData.bodyTypes.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name.forLanguageCode(locale)))).toList(),
              onChanged: (v) => setState(() => bodyTypeId = v),
            ),
            const SizedBox(height: 12),
            AppTextField(label: t.driverSetupVehiclePlate, controller: plateController, onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            AppTextField(label: t.adminVehicleBrand, controller: brandController, onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            AppTextField(label: t.postCargoWeight, controller: capacityController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            AppTextField(label: t.adminVehicleLengthM, controller: lengthController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
          ],
          const SizedBox(height: 16),
          Text(t.driverSetupDirectionsTitle, style: Theme.of(context).textTheme.titleMedium),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: anyCountry,
            title: Text(t.driverSetupAnyCountry),
            onChanged: (v) => setState(() => anyCountry = v ?? false),
          ),
          if (!anyCountry)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: refData.countries
                  .map((c) => FilterChip(
                        label: Text(c.name.forLanguageCode(locale)),
                        selected: selectedCountryIds.contains(c.id),
                        onSelected: (v) => setState(() => v ? selectedCountryIds.add(c.id) : selectedCountryIds.remove(c.id)),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 16),
          Text(t.driverSetupPermits, style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: refData.permits
                .map((p) => FilterChip(
                      label: Text(p.name.forLanguageCode(locale)),
                      selected: selectedPermitIds.contains(p.id),
                      onSelected: (v) => setState(() => v ? selectedPermitIds.add(p.id) : selectedPermitIds.remove(p.id)),
                    ))
                .toList(),
          ),
        ],
      );
    },
  );

  if (reason == null) return null;

  return DriverEditResult(
    fullName: fullNameController.text.trim(),
    phone: phoneController.text.trim(),
    homeCityId: homeCityId,
    anyCountry: anyCountry,
    countryIds: selectedCountryIds.toList(),
    permitIds: selectedPermitIds.toList(),
    vehicleBodyTypeId: bodyTypeId,
    vehicleCapacityTons: double.tryParse(capacityController.text.trim()),
    vehicleLengthM: double.tryParse(lengthController.text.trim()),
    vehiclePlateNumber: hasVehicle ? plateController.text.trim() : null,
    vehicleBrand: hasVehicle ? brandController.text.trim() : null,
    reason: reason,
  );
}
