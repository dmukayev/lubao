import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../shared/photo_picker.dart';
import '../../shared/pd_consent.dart';
import '../../../providers/auth_provider.dart';

/// Добавление машины в гараж (задача 031, этап B, п.8) — без распознавания
/// (этап D) поля заполняются вручную, ничего не блокируется. Возвращает
/// добавленную машину (null — закрыли). Дальше — шаг «Сфотографируйте машину»
/// (044 п.7), его можно пропустить.
Future<GarageVehicle?> showAddVehicleSheet(BuildContext context, WidgetRef ref) async {
  final result = await showModalBottomSheet<GarageVehicle>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge))),
    builder: (context) => const _AddVehicleSheet(),
  );
  if (result != null && context.mounted) await showVehiclePhotosSheet(context, ref, result);
  return result;
}

/// «Сфотографируйте машину» (044 п.7): спереди с госномером и сбоку, по одному
/// касанию; можно пропустить. Фото — в приватный бакет, на проверку не идут.
Future<void> showVehiclePhotosSheet(BuildContext context, WidgetRef ref, GarageVehicle vehicle) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    builder: (context) => SafeArea(top: false, child: _VehiclePhotosSheet(vehicle: vehicle)),
  );
}

class _VehiclePhotosSheet extends ConsumerStatefulWidget {
  const _VehiclePhotosSheet({required this.vehicle});
  final GarageVehicle vehicle;

  @override
  ConsumerState<_VehiclePhotosSheet> createState() => _VehiclePhotosSheetState();
}

class _VehiclePhotosSheetState extends ConsumerState<_VehiclePhotosSheet> {
  late bool _front = widget.vehicle.hasPhotoFront;
  late bool _side = widget.vehicle.hasPhotoSide;
  VerificationDocType? _uploading;

  Future<void> _take(VerificationDocType type) async {
    if (!await ensurePdConsent(context, ref) || !mounted) return;
    final picked = await pickPhoto(ImageSource.camera);
    if (picked == null) return;
    setState(() => _uploading = type);
    try {
      final bytes = await picked.readAsBytes();
      final key = await ref.read(uploadsRepositoryProvider).uploadDocument(bytes, filename: picked.name);
      await ref.read(driverRepositoryProvider).submitVerificationDocument(type: type, fileUrl: key, vehicleId: widget.vehicle.id);
      if (mounted) setState(() => type == VerificationDocType.vehiclePhotoFront ? _front = true : _side = true);
    } catch (e) {
      debugPrint('VehiclePhotosSheet: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commonError)));
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final refData = ref.watch(referenceDataProvider).valueOrNull;
    final code = widget.vehicle.bodyTypeId == null ? null : refData?.bodyTypes.where((b) => b.id == widget.vehicle.bodyTypeId).firstOrNull?.code;
    Widget slot(VerificationDocType type, String label, bool done) => Expanded(
          child: OutlinedButton(
            key: Key('vehiclePhoto-${type.name}'),
            onPressed: _uploading != null ? null : () => _take(type),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(AppSpacing.md)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Подсказка-силуэт — миниатюра этого кузова.
                Opacity(opacity: done ? 1 : 0.35, child: BodyTypeIcon(bodyTypeCode: code, vehicleKind: widget.vehicle.kind, width: 96)),
                const SizedBox(height: AppSpacing.sm),
                if (_uploading == type)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Icon(done ? LucideIcons.checkCircle2 : LucideIcons.camera, color: done ? AppColors.success : AppColors.primary),
                const SizedBox(height: AppSpacing.xs),
                Text(label, textAlign: TextAlign.center, style: AppTextStyles.caption),
              ],
            ),
          ),
        );
    return SingleChildScrollView(
      key: const Key('vehiclePhotosSheet'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.vehiclePhotoStepTitle, style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.sm),
          Text(t.vehiclePhotoStepHint, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              slot(VerificationDocType.vehiclePhotoFront, t.vehiclePhotoFront, _front),
              const SizedBox(width: AppSpacing.sm),
              slot(VerificationDocType.vehiclePhotoSide, t.vehiclePhotoSide, _side),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            key: const Key('vehiclePhotosDone'),
            label: _front && _side ? t.commonDone : t.commonSkip,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _AddVehicleSheet extends ConsumerStatefulWidget {
  const _AddVehicleSheet();

  @override
  ConsumerState<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends ConsumerState<_AddVehicleSheet> {
  VehicleKind _kind = VehicleKind.tractor;
  String? _bodyTypeId;
  final _plateController = TextEditingController();
  final _vinController = TextEditingController();
  final _brandController = TextEditingController();
  final _capacityController = TextEditingController();
  final _lengthController = TextEditingController();
  // Размер кузова (задача 033, п.6) — шаблон одним касанием или «свой
  // размер» с ручным вводом Д/Ш/В (объём и паллеты считает сервер).
  String? _sizePresetId;
  bool _customSize = false;
  final _innerLengthController = TextEditingController();
  final _innerWidthController = TextEditingController();
  final _innerHeightController = TextEditingController();
  XFile? _photo;
  /// 048: параметры по профилю кузова (не объёмные — литры, места, контейнеры…).
  Map<String, dynamic> _specs = {};
  bool _submitting = false;
  String? _photoError;

  BodyType? _selectedBodyType(ReferenceData? refData) =>
      _bodyTypeId == null ? null : refData?.bodyTypes.where((b) => b.id == _bodyTypeId).firstOrNull;

  bool get _isVolume {
    final refData = ref.read(referenceDataProvider).valueOrNull;
    final code = _bodyTypeId == null || refData == null ? null : refData.bodyTypeById(_bodyTypeId!).code;
    return isVolumeBodyType(code);
  }

  /// 045 п.5: кузов и тоннаж из регистрации подставляются в первую машину.
  @override
  void initState() {
    super.initState();
    final driver = ref.read(sessionProvider)?.driver;
    _bodyTypeId = driver?.preferredBodyTypeId;
    final tons = driver?.preferredCapacityTons;
    if (tons != null) _capacityController.text = tons == tons.roundToDouble() ? tons.toStringAsFixed(0) : tons.toString();
  }

  @override
  void dispose() {
    _plateController.dispose();
    _vinController.dispose();
    _brandController.dispose();
    _capacityController.dispose();
    _lengthController.dispose();
    _innerLengthController.dispose();
    _innerWidthController.dispose();
    _innerHeightController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (!await ensurePdConsent(context, ref) || !mounted) return;
    final picked = await pickPhoto(source);
    if (picked != null) setState(() { _photo = picked; _photoError = null; });
  }

  Future<void> _submit() async {
    final t = context.l10n;
    if (_photo == null) {
      setState(() => _photoError = t.garagePhotoRequired);
      return;
    }

    setState(() => _submitting = true);
    try {
      final isTractor = _kind == VehicleKind.tractor;
      // 032 п.12 (038) — сначала файл, потом машина+документ ОДНИМ запросом
      // (сервер создаёт их в транзакции): обрыв между шагами больше не
      // оставляет машину без техпаспорта.
      final bytes = await _photo!.readAsBytes();
      final key = await ref.read(uploadsRepositoryProvider).uploadDocument(bytes, filename: _photo!.name);
      final vehicle = await ref.read(driverRepositoryProvider).addVehicle(
            kind: _kind,
            documentFileUrl: key,
            bodyTypeId: isTractor ? null : _bodyTypeId,
            plateNumber: _plateController.text.trim().isEmpty ? null : _plateController.text.trim(),
            vin: _vinController.text.trim().isEmpty ? null : _vinController.text.trim(),
            brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
            capacityTons: isTractor || !_isVolume ? null : double.tryParse(_capacityController.text.trim()),
            lengthM: isTractor || !_isVolume ? null : double.tryParse(_lengthController.text.trim()),
            sizePresetId: isTractor || _customSize || !_isVolume ? null : _sizePresetId,
            innerLengthM: isTractor || !_customSize || !_isVolume ? null : double.tryParse(_innerLengthController.text.trim()),
            innerWidthM: isTractor || !_customSize || !_isVolume ? null : double.tryParse(_innerWidthController.text.trim()),
            innerHeightM: isTractor || !_customSize || !_isVolume ? null : double.tryParse(_innerHeightController.text.trim()),
            specs: isTractor || _isVolume ? null : _specs,
          );

      if (mounted) Navigator.of(context).pop(vehicle);
    } catch (e) {
      debugPrint('AddVehicleSheet: failed to add vehicle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.garageAddFailed)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final refData = ref.watch(referenceDataProvider).valueOrNull;
    final isTrailer = _kind == VehicleKind.trailer;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.garageAddVehicle, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.lg),
              Text(t.garageKindTitle, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SelectableTile(
                      label: t.garageKindTractor,
                      selected: _kind == VehicleKind.tractor,
                      onTap: () => setState(() => _kind = VehicleKind.tractor),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SelectableTile(
                      key: const Key('addVehicleKindTrailer'),
                      label: t.garageKindTrailer,
                      selected: isTrailer,
                      onTap: () => setState(() => _kind = VehicleKind.trailer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isTrailer && refData != null) ...[
                DropdownButtonFormField<String>(
                  key: const Key('addVehicleBodyType'),
                  initialValue: _bodyTypeId,
                  decoration: InputDecoration(labelText: t.driverSetupVehicleBodyType),
                  items: refData.bodyTypes.map((b) => DropdownMenuItem(key: Key('addVehicleBodyType-${b.code}'), value: b.id, child: Text(b.name.forLanguageCode(locale)))).toList(),
                  onChanged: (v) => setState(() {
                    _bodyTypeId = v;
                    _specs = {};
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                // 048: у необъёмных кузовов — свои поля по профилю вместо тоннажа/длины/размера.
                if (_selectedBodyType(refData) != null && !_selectedBodyType(refData)!.isVolume) ...[
                  Text(t.bodySpecsTitle, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.sm),
                  SpecsForm(
                    key: ValueKey('specs-${_bodyTypeId}'),
                    fields: _selectedBodyType(refData)!.vehicleFields,
                    values: _specs,
                    onChanged: (v) => setState(() => _specs = v),
                  ),
                ] else ...[
                AppTextField(key: const Key('addVehicleCapacity'), label: t.driverSetupCapacity, controller: _capacityController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: AppSpacing.md),
                AppTextField(key: const Key('addVehicleLength'), label: t.garageLength, controller: _lengthController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: AppSpacing.md),
                // 045 п.6: размер/шаблоны — только у объёмных кузовов.
                if (isVolumeBodyType(_bodyTypeId == null ? null : refData.bodyTypeById(_bodyTypeId!).code)) ...[
                Text(t.garageSizeTitle, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final preset in refData.sizePresetsForBodyType(_bodyTypeId))
                      SelectableTile(
                        key: Key('addVehicleSizePreset-${preset.id}'),
                        label: preset.volumeM3 != null && preset.palletsEuro != null
                            ? '${preset.name.forLanguageCode(locale)}\n≈ ${preset.volumeM3!.toStringAsFixed(0)} ${t.unitM3} · ${preset.palletsEuro} ${t.unitPallets}'
                            : preset.name.forLanguageCode(locale),
                        selected: !_customSize && _sizePresetId == preset.id,
                        onTap: () => setState(() {
                          _sizePresetId = preset.id;
                          _customSize = false;
                        }),
                      ),
                    SelectableTile(
                      label: t.garageSizeCustom,
                      selected: _customSize,
                      onTap: () => setState(() => _customSize = true),
                    ),
                  ],
                ),
                if (_customSize) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(label: t.garageSizeLength, controller: _innerLengthController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(label: t.garageSizeWidth, controller: _innerWidthController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(label: t.garageSizeHeight, controller: _innerHeightController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ],
                ],
                ],
                const SizedBox(height: AppSpacing.md),
              ] else ...[
                AppTextField(label: t.driverSetupVehicleTitle, controller: _brandController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: t.garageVin, controller: _vinController),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(key: const Key('addVehiclePlate'), label: t.driverSetupVehiclePlate, controller: _plateController),
              const SizedBox(height: AppSpacing.lg),
              Text(t.garagePhotoRequired, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              if (_photo != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.success),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(_photo!.name, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(LucideIcons.camera),
                      label: Text(t.postCargoAddPhotoCamera),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('addVehiclePhotoGallery'),
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(LucideIcons.image),
                      label: Text(t.postCargoAddPhotoGallery),
                    ),
                  ),
                ],
              ),
              if (_photoError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(_photoError!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(key: const Key('addVehicleSubmit'), label: t.garageSubmit, loading: _submitting, onPressed: _submit),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
