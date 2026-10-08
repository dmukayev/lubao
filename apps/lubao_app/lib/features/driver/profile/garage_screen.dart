import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/photo_picker.dart';
import 'add_vehicle_sheet.dart';
import 'add_vehicle_banner.dart';
import 'vehicle_photos.dart';
import '../../shared/pd_consent.dart';

/// «Мой гараж» (задача 031, этап B, макет 26) — тягачи и прицепы по
/// отдельности, каждый со своим статусом проверки.
class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  /// 048 п.3: параметры машины по профилю кузова (цистерна, автовоз…).
  Future<void> _editSpecs(BuildContext context, WidgetRef ref, GarageVehicle vehicle, BodyType bodyType) async {
    var values = <String, dynamic>{...?vehicle.specs};
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: StatefulBuilder(
          builder: (sheetContext, setSheet) => SingleChildScrollView(
            key: const Key('vehicleSpecsSheet'),
            padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xl + MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(sheetContext.l10n.bodySpecsTitle, style: AppTextStyles.headline),
                const SizedBox(height: AppSpacing.md),
                SpecsForm(fields: bodyType.vehicleFields, values: values, onChanged: (v) => setSheet(() => values = v)),
                PrimaryButton(key: const Key('vehicleSpecsSave'), label: sheetContext.l10n.commonSave, onPressed: () => Navigator.pop(sheetContext, true)),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved != true || !context.mounted) return;
    try {
      await ref.read(driverRepositoryProvider).setVehicleSpecs(vehicle.id, values);
      ref.invalidate(garageVehiclesProvider);
    } catch (e) {
      debugPrint('GarageScreen: specs: $e');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.garageAddFailed)));
    }
  }

  Future<void> _addPhotos(BuildContext context, WidgetRef ref, GarageVehicle vehicle) async {
    await showVehiclePhotosSheet(context, ref, vehicle);
    ref.invalidate(garageVehiclesProvider);
  }

  Future<void> _addVehicle(BuildContext context, WidgetRef ref) async {
    final added = await showAddVehicleSheet(context, ref);
    if (added != null) ref.invalidate(garageVehiclesProvider);
  }

  /// Мягкая подсказка (задача 033, п.5) — прицепам/одиночкам, созданным до
  /// шаблонов, размер проставляется здесь, одним касанием чипа.
  /// Сентинел «Свой размер» в шторке выбора шаблона (033 п.6 / 038 п.14).
  static const _customSizeMarker = BodySizePreset(
    id: '__custom__',
    code: '__custom__',
    name: I18nText(kk: '', ru: '', zh: ''),
  );

  /// Диалог ввода Д/Ш/В для «Свой размер» — то же, что в шторке добавления
  /// машины; ввод с запятой («13,6») принимается.
  Future<(double, double, double)?> _askCustomSize(BuildContext context, LubaoLocalizations t) async {
    final lengthController = TextEditingController();
    final widthController = TextEditingController();
    final heightController = TextEditingController();
    double? parse(String raw) => double.tryParse(raw.trim().replaceAll(',', '.'));

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final l = parse(lengthController.text);
          final w = parse(widthController.text);
          final h = parse(heightController.text);
          final valid = l != null && l > 0 && l <= 20 && w != null && w > 0 && w <= 3 && h != null && h > 0 && h <= 4.5;
          return AlertDialog(
            title: Text(t.garageSizeCustom),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: t.garageSizeLength, controller: lengthController, keyboardType: TextInputType.number, onChanged: (_) => setDialogState(() {})),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(label: t.garageSizeWidth, controller: widthController, keyboardType: TextInputType.number, onChanged: (_) => setDialogState(() {})),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(label: t.garageSizeHeight, controller: heightController, keyboardType: TextInputType.number, onChanged: (_) => setDialogState(() {})),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.commonCancel)),
              FilledButton(onPressed: valid ? () => Navigator.pop(dialogContext, true) : null, child: Text(t.commonDone)),
            ],
          );
        },
      ),
    );
    if (ok != true) return null;
    return (parse(lengthController.text)!, parse(widthController.text)!, parse(heightController.text)!);
  }

  Future<void> _setSize(BuildContext context, WidgetRef ref, GarageVehicle vehicle) async {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final refData = ref.read(referenceDataProvider).valueOrNull;
    if (refData == null) return;
    final presets = refData.sizePresetsForBodyType(vehicle.bodyTypeId);
    final chosen = await showModalBottomSheet<BodySizePreset>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.garageSizeTitle, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final preset in presets)
                    SelectableTile(
                      label: preset.volumeM3 != null && preset.palletsEuro != null
                          ? '${preset.name.forLanguageCode(locale)}\n≈ ${preset.volumeM3!.toStringAsFixed(0)} ${t.unitM3} · ${preset.palletsEuro} ${t.unitPallets}'
                          : preset.name.forLanguageCode(locale),
                      selected: vehicle.sizePresetId == preset.id,
                      onTap: () => Navigator.pop(sheetContext, preset),
                    ),
                  // 033 п.6 (хвост, задача 038 п.14) — «Свой размер» был
                  // только при добавлении машины, в подсказке для уже
                  // существующего прицепа его не было.
                  SelectableTile(
                    label: t.garageSizeCustom,
                    selected: vehicle.sizePresetId == null && vehicle.volumeM3 != null,
                    onTap: () => Navigator.pop(sheetContext, _customSizeMarker),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    if (!context.mounted) return;

    double? lengthM;
    double? widthM;
    double? heightM;
    if (identical(chosen, _customSizeMarker)) {
      final dims = await _askCustomSize(context, t);
      if (dims == null) return;
      (lengthM, widthM, heightM) = dims;
    }
    try {
      if (lengthM != null) {
        await ref.read(driverRepositoryProvider).setVehicleSize(
              vehicle.id,
              innerLengthM: lengthM,
              innerWidthM: widthM,
              innerHeightM: heightM,
            );
      } else {
        await ref.read(driverRepositoryProvider).setVehicleSize(vehicle.id, sizePresetId: chosen.id);
      }
      ref.invalidate(garageVehiclesProvider);
    } catch (e) {
      debugPrint('GarageScreen: failed to set vehicle size: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.commonError)));
      }
    }
  }

  /// «Добавить документ» (041, п.6): машина из мастера регистрации создана
  /// без техпаспорта — прикладываем фото здесь, оно уходит на проверку.
  Future<void> _addDocument(BuildContext context, WidgetRef ref, GarageVehicle vehicle) async {
    final t = context.l10n;
    if (!await ensurePdConsent(context, ref) || !context.mounted) return;
    final picked = await pickPhoto(ImageSource.gallery);
    if (picked == null) return;
    try {
      final bytes = await picked.readAsBytes();
      final key = await ref.read(uploadsRepositoryProvider).uploadDocument(bytes, filename: picked.name);
      await ref.read(driverRepositoryProvider).submitVerificationDocument(
            type: vehicle.kind == VehicleKind.trailer ? VerificationDocType.trailerPassport : VerificationDocType.vehiclePassport,
            fileUrl: key,
            vehicleId: vehicle.id,
          );
      ref.invalidate(garageVehiclesProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.garageDocumentSent)));
    } catch (e) {
      debugPrint('GarageScreen: failed to add document: $e');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.driverVerificationUploadFailed)));
    }
  }

  Future<void> _archive(BuildContext context, WidgetRef ref, GarageVehicle vehicle) async {
    final t = context.l10n;
    try {
      await ref.read(driverRepositoryProvider).archiveVehicle(vehicle.id);
      ref.invalidate(garageVehiclesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.garageArchived)));
      }
    } catch (e) {
      debugPrint('GarageScreen: failed to archive vehicle: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.commonError)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final vehiclesAsync = ref.watch(garageVehiclesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.garageTitle)),
      body: vehiclesAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('GarageScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(garageVehiclesProvider));
        },
        data: (vehicles) {
          final refData = ref.watch(referenceDataProvider).valueOrNull;
          BodyType? typeOf(String? bodyTypeId) => bodyTypeId == null ? null : refData?.bodyTypes.where((b) => b.id == bodyTypeId).firstOrNull;
          String? codeOf(String? bodyTypeId) => typeOf(bodyTypeId)?.code;
          final tractors = vehicles.where((v) => v.kind == VehicleKind.tractor || v.kind == VehicleKind.rigid).toList();
          final trailers = vehicles.where((v) => v.kind == VehicleKind.trailer).toList();

          // 045 п.5: после регистрации гараж пуст — одна карточка-призыв вместо
          // заглушек «Тягач/Прицеп» без номера.
          if (vehicles.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                // 053 п.1: та же плашка, что в профиле (кузов из регистрации).
                const AddVehicleBanner(key: Key('garageEmptyCta'), buttonKey: Key('garageAddVehicle')),
              ],
            );
          }

          return ListView(
            key: const Key('garageList'),
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              _SectionLabel(t.garageTractorsSection),
              const SizedBox(height: AppSpacing.sm),
              if (tractors.isEmpty)
                _EmptyRow(t.garageEmptyTractors)
              else
                for (final v in tractors) ...[
                  _VehicleCard(
                    vehicle: v,
                    bodyTypeCode: codeOf(v.bodyTypeId),
                    onArchive: () => _archive(context, ref, v),
                    onAddDocument: () => _addDocument(context, ref, v),
                    onAddPhotos: () => _addPhotos(context, ref, v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              const SizedBox(height: AppSpacing.lg),
              _SectionLabel(t.garageTrailersSection),
              const SizedBox(height: AppSpacing.sm),
              if (trailers.isEmpty)
                _EmptyRow(t.garageEmptyTrailers)
              else
                for (final v in trailers) ...[
                  _VehicleCard(
                    vehicle: v,
                    bodyTypeCode: codeOf(v.bodyTypeId),
                    bodyType: typeOf(v.bodyTypeId),
                    onEditSpecs: typeOf(v.bodyTypeId) != null && !typeOf(v.bodyTypeId)!.isVolume ? () => _editSpecs(context, ref, v, typeOf(v.bodyTypeId)!) : null,
                    onArchive: () => _archive(context, ref, v),
                    onAddDocument: () => _addDocument(context, ref, v),
                    onAddPhotos: () => _addPhotos(context, ref, v),
                    // Размер можно сменить и позже (033 п.6 / 038 п.14) — только
                    // у объёмных кузовов (045 п.6).
                    onSetSize: (typeOf(v.bodyTypeId)?.isVolume ?? isVolumeBodyType(codeOf(v.bodyTypeId))) ? () => _setSize(context, ref, v) : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                key: const Key('garageAddVehicle'),
                onPressed: () => _addVehicle(context, ref),
                icon: const Icon(LucideIcons.plus),
                label: Text(t.garageAddVehicle),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Text(t.garageOcrHint, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600));
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onArchive, required this.onAddDocument, this.onSetSize, this.bodyTypeCode, this.bodyType, this.onAddPhotos, this.onEditSpecs});

  /// 048 п.3: «Параметры кузова» у необъёмных.
  final VoidCallback? onEditSpecs;

  /// «Добавьте фото машины» (044 п.7) — мягкое напоминание, если фото нет.
  final VoidCallback? onAddPhotos;

  final GarageVehicle vehicle;
  final String? bodyTypeCode;
  final BodyType? bodyType;
  final VoidCallback onArchive;
  final VoidCallback onAddDocument;

  /// Не-null только у прицепа/одиночки без размера (задача 033, п.5) —
  /// мягкая подсказка, тап открывает выбор шаблона.
  final VoidCallback? onSetSize;

  /// 045 п.5: первой строкой — госномер (его водитель и логист ищут глазами).
  String _title(BuildContext context) {
    final plate = vehicle.plateNumber;
    return plate != null && plate.isNotEmpty ? plate : context.l10n.garageNoPlate;
  }

  /// Под номером — тип и параметры: «Тягач · MAN», «Прицеп · 20 т · 90 м³ · 33 пал.»,
  /// у необъёмных — по профилю: «Цистерна · 30 000 л · Пищевое» (048 п.3).
  String? _subtitle(BuildContext context) {
    final t = context.l10n;
    final bt = bodyType;
    if (bt != null && !bt.isVolume && vehicle.specs != null) {
      return specsSummary(t, Localizations.localeOf(context).languageCode, bt, vehicle.specs);
    }
    final parts = <String>[
      vehicle.kind == VehicleKind.trailer ? t.garageKindTrailer : t.garageKindTractor,
      if (vehicle.brand != null) vehicle.brand!,
      if (vehicle.kind == VehicleKind.trailer) ...[
        if (vehicle.capacityTons != null) '${vehicle.capacityTons!.toStringAsFixed(0)} ${t.unitTon}',
        // 045 п.6: «м³ · пал.» — только у объёмных кузовов.
        if (vehicle.volumeM3 != null && isVolumeBodyType(bodyTypeCode)) '${vehicle.volumeM3!.toStringAsFixed(0)} ${t.unitM3}',
        if (vehicle.palletsEuro != null && isVolumeBodyType(bodyTypeCode)) '${vehicle.palletsEuro} ${t.unitPallets}',
      ] else if (vehicle.vin != null && vehicle.vin!.length > 4)
        '${t.garageVin} …${vehicle.vin!.substring(vehicle.vin!.length - 4)}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final subtitle = _subtitle(context);

    return AppCard(
      child: Row(
        children: [
          // 053 п.4: фото спереди вместо иконки; нет фото — миниатюра кузова (045 п.4).
          VehicleFrontThumb(vehicle: vehicle, bodyTypeCode: bodyTypeCode, width: 72),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title(context), key: Key('garageVehicleTitle-${vehicle.id}'), style: AppTextStyles.bodyStrong),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
                // Статус — отдельной строкой, а не в ряду: на узком экране с
                // крупным шрифтом (Huawei Y7, 360 dp × 1,3) ряд «значок + текст
                // + статус + меню» сжимал текст до буквы в строке.
                const SizedBox(height: 4),
                StatusBadge(
                  label: vehicle.isVerified ? t.garageVerified : t.garagePending,
                  color: vehicle.isVerified ? StatusBadge.success : StatusBadge.warning,
                ),
                if (!vehicle.isVerified && !vehicle.hasDocument) ...[
                  const SizedBox(height: 2),
                  GestureDetector(
                    key: Key('garageAddDocument-${vehicle.id}'),
                    onTap: onAddDocument,
                    child: Text(context.l10n.garageAddDocument, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                  ),
                ],
                if (onEditSpecs != null) ...[
                  const SizedBox(height: 2),
                  GestureDetector(
                    key: Key('garageEditSpecs-${vehicle.id}'),
                    onTap: onEditSpecs,
                    child: Text(context.l10n.bodySpecsTitle, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                  ),
                ],
                // 053 п.4: нет фото — плашка «Добавьте фото →», есть одно из двух — ссылка.
                if (onAddPhotos != null && !vehicle.hasPhotoFront) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    key: Key('garageAddPhotos-${vehicle.id}'),
                    onTap: onAddPhotos,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                      child: Text('${context.l10n.garageAddPhotoChip} →', style: AppTextStyles.small.copyWith(color: AppColors.accentText, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ] else if (onAddPhotos != null && !vehicle.hasPhotoSide) ...[
                  const SizedBox(height: 2),
                  GestureDetector(
                    key: Key('garageAddPhotos-${vehicle.id}'),
                    onTap: onAddPhotos,
                    child: Text(context.l10n.garagePhotosReminder, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                  ),
                ],
                if (onSetSize != null) ...[
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onSetSize,
                    child: Text(
                      // Размер можно менять и позже (033 п.6 / 038 п.14).
                      vehicle.volumeM3 == null ? context.l10n.garageSizePrompt : context.l10n.garageSizeChange,
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, size: 18),
            onSelected: (value) {
              if (value == 'archive') onArchive();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'archive', child: Text(t.garageArchive)),
            ],
          ),
        ],
      ),
    );
  }
}
