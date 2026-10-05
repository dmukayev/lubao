import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';

class CargoCloseResult {
  const CargoCloseResult({required this.outcome, this.driverId});

  final String outcome;
  final String? driverId;
}

/// Груз нельзя закрыть без выбора исхода (задача 017, п.6) — заменяет
/// старое «удалить» без причины.
Future<CargoCloseResult?> showCargoCloseDialog(BuildContext context, WidgetRef ref, String cargoId) {
  return showDialog<CargoCloseResult>(
    context: context,
    builder: (dialogContext) => _CargoCloseDialog(ref: ref, cargoId: cargoId),
  );
}

class _CargoCloseDialog extends StatefulWidget {
  const _CargoCloseDialog({required this.ref, required this.cargoId});

  final WidgetRef ref;
  final String cargoId;

  @override
  State<_CargoCloseDialog> createState() => _CargoCloseDialogState();
}

class _CargoCloseDialogState extends State<_CargoCloseDialog> {
  String? _outcome;
  String? _driverId;
  List<CargoCloseCandidate>? _candidates;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final canConfirm = _outcome != null && (_outcome != 'FOUND_IN_APP' || _driverId != null);

    return AlertDialog(
      title: Text(t.cargoCloseDialogTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioListTile<String>(
              value: 'FOUND_IN_APP',
              groupValue: _outcome,
              title: Text(t.cargoCloseFoundInApp),
              onChanged: (v) async {
                setState(() => _outcome = v);
                _candidates ??= await widget.ref.read(cargoRepositoryProvider).closeCandidates(widget.cargoId);
                if (mounted) setState(() {});
              },
            ),
            if (_outcome == 'FOUND_IN_APP')
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 8),
                child: _candidates == null
                    ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())
                    : _candidates!.isEmpty
                        ? Text(t.cargoCloseNoCandidates, style: AppTextStyles.caption)
                        : DropdownButtonFormField<String>(
                            initialValue: _driverId,
                            decoration: InputDecoration(labelText: t.cargoCloseDriverLabel),
                            items: _candidates!.map((c) => DropdownMenuItem(value: c.driverId, child: Text(c.driverName))).toList(),
                            onChanged: (v) => setState(() => _driverId = v),
                          ),
              ),
            RadioListTile<String>(
              value: 'FOUND_OUTSIDE',
              groupValue: _outcome,
              title: Text(t.cargoCloseFoundOutside),
              onChanged: (v) => setState(() => _outcome = v),
            ),
            RadioListTile<String>(
              value: 'CARGO_CANCELLED',
              groupValue: _outcome,
              title: Text(t.cargoCloseCancelled),
              onChanged: (v) => setState(() => _outcome = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.commonCancel)),
        FilledButton(
          onPressed: canConfirm ? () => Navigator.of(context).pop(CargoCloseResult(outcome: _outcome!, driverId: _driverId)) : null,
          child: Text(t.cargoCloseConfirm),
        ),
      ],
    );
  }
}
