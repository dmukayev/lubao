import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import '../shared/edit_side_panel.dart';

class CompanyEditResult {
  const CompanyEditResult({
    required this.name,
    required this.nameRu,
    required this.countryId,
    required this.city,
    required this.legalAddress,
    required this.taxId,
    required this.reason,
  });

  final String name;
  final String? nameRu;
  final String countryId;
  final String? city;
  final String? legalAddress;
  final String? taxId;
  final String reason;
}

/// Общая панель редактирования компании (задача 028, п.18/20).
Future<CompanyEditResult?> showCompanyEditPanel(
  BuildContext context, {
  required AdminCompanyDetail company,
  required ReferenceData refData,
}) async {
  final locale = Localizations.localeOf(context).languageCode;
  final nameController = TextEditingController(text: company.name);
  final nameRuController = TextEditingController(text: company.nameRu ?? '');
  final cityController = TextEditingController(text: company.city ?? '');
  final legalAddressController = TextEditingController(text: company.legalAddress ?? '');
  final taxIdController = TextEditingController(text: company.taxId ?? '');
  String countryId = company.countryId;

  final reason = await showEditSidePanel(
    context: context,
    title: company.name,
    canSave: () => nameController.text.trim().isNotEmpty,
    fieldsBuilder: (context, setState) {
      final t = context.l10n;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: t.companyRegisterCompanyName, controller: nameController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          AppTextField(label: t.companyRegisterCompanyNameRu, controller: nameRuController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: countryId,
            decoration: InputDecoration(labelText: t.postCargoDestinationCountry),
            items: refData.countries.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale)))).toList(),
            onChanged: (v) => setState(() => countryId = v!),
          ),
          const SizedBox(height: 12),
          AppTextField(label: t.adminCompanyCity, controller: cityController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          AppTextField(label: t.adminLegalAddress, controller: legalAddressController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          AppTextField(label: t.adminTaxId, controller: taxIdController, onChanged: (_) => setState(() {})),
        ],
      );
    },
  );

  if (reason == null) return null;

  return CompanyEditResult(
    name: nameController.text.trim(),
    nameRu: nameRuController.text.trim().isEmpty ? null : nameRuController.text.trim(),
    countryId: countryId,
    city: cityController.text.trim().isEmpty ? null : cityController.text.trim(),
    legalAddress: legalAddressController.text.trim().isEmpty ? null : legalAddressController.text.trim(),
    taxId: taxIdController.text.trim().isEmpty ? null : taxIdController.text.trim(),
    reason: reason,
  );
}
