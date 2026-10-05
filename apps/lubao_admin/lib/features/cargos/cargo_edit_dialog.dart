import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import '../shared/admin_status_helpers.dart';

/// Результат диалога редактирования груза (задача 028, п.15) — те же поля,
/// что при публикации (без фото — админ не управляет фотографиями груза),
/// плюс обязательная причина.
class CargoEditResult {
  const CargoEditResult({
    required this.destinationCountryId,
    required this.bodyTypeId,
    this.weightKg,
    this.volumeM3,
    required this.price,
    required this.currency,
    required this.readyDate,
    this.description,
    required this.reason,
  });

  final String destinationCountryId;
  final String bodyTypeId;
  final double? weightKg;
  final double? volumeM3;
  final double price;
  final String currency;
  final DateTime readyDate;
  final String? description;
  final String reason;
}

Future<CargoEditResult?> showCargoEditDialog(
  BuildContext context, {
  required AdminCargoDetail cargo,
  required ReferenceData refData,
}) {
  return showDialog<CargoEditResult>(
    context: context,
    builder: (dialogContext) => _CargoEditDialog(cargo: cargo, refData: refData),
  );
}

class _CargoEditDialog extends StatefulWidget {
  const _CargoEditDialog({required this.cargo, required this.refData});

  final AdminCargoDetail cargo;
  final ReferenceData refData;

  @override
  State<_CargoEditDialog> createState() => _CargoEditDialogState();
}

class _CargoEditDialogState extends State<_CargoEditDialog> {
  late String _destinationCountryId = widget.cargo.destinationCountryId;
  late String _bodyTypeId = widget.cargo.bodyTypeId;
  late Currency _currency = currencyFromJson(widget.cargo.currency);
  late DateTime _readyDate = widget.cargo.readyDate;
  late final _weightController = TextEditingController(text: widget.cargo.weightKg?.toString() ?? '');
  late final _volumeController = TextEditingController(text: widget.cargo.volumeM3?.toString() ?? '');
  late final _priceController = TextEditingController(text: widget.cargo.price.toString());
  late final _descriptionController = TextEditingController(text: widget.cargo.description ?? '');
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _volumeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final canConfirm = _priceController.text.trim().isNotEmpty && _reasonController.text.trim().isNotEmpty;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(t.adminCargoEditDialogTitle),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _destinationCountryId,
                    decoration: InputDecoration(labelText: t.postCargoDestinationCountry),
                    items: widget.refData.countries.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale)))).toList(),
                    onChanged: (v) => setState(() => _destinationCountryId = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _bodyTypeId,
                    decoration: InputDecoration(labelText: t.postCargoBodyType),
                    items: widget.refData.bodyTypes.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name.forLanguageCode(locale)))).toList(),
                    onChanged: (v) => setState(() => _bodyTypeId = v!),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: t.postCargoWeight, controller: _weightController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
                  const SizedBox(height: 12),
                  AppTextField(label: t.postCargoVolume, controller: _volumeController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: AppTextField(label: t.postCargoPrice, controller: _priceController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                      const SizedBox(width: 12),
                      DropdownButton<Currency>(
                        value: _currency,
                        items: Currency.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()))).toList(),
                        onChanged: (v) => setState(() => _currency = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.postCargoReadyDate),
                    subtitle: Text(formatAdminDate(_readyDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _readyDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) setState(() => _readyDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: t.postCargoDescription, controller: _descriptionController, maxLines: 3, onChanged: (_) => setState(() {})),
                  const SizedBox(height: 16),
                  AppTextField(label: t.adminReasonLabel, controller: _reasonController, maxLines: 2, onChanged: (_) => setState(() {})),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.commonCancel)),
            FilledButton(
              onPressed: canConfirm
                  ? () => Navigator.pop(
                        context,
                        CargoEditResult(
                          destinationCountryId: _destinationCountryId,
                          bodyTypeId: _bodyTypeId,
                          weightKg: double.tryParse(_weightController.text.trim()),
                          volumeM3: double.tryParse(_volumeController.text.trim()),
                          price: double.parse(_priceController.text.trim()),
                          currency: _currency.name.toUpperCase(),
                          readyDate: _readyDate,
                          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                          reason: _reasonController.text.trim(),
                        ),
                      )
                  : null,
              child: Text(t.commonSave),
            ),
          ],
        );
      },
    );
  }
}
