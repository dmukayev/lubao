import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../shared/city_picking.dart';
import '../../shared/photo_picker.dart';
import '../../shared/error_feedback.dart';

class PostCargoScreen extends ConsumerStatefulWidget {
  const PostCargoScreen({super.key, this.cargo});

  /// Если передан — экран работает в режиме редактирования существующего
  /// груза (предзаполняет поля, сохраняет через PATCH вместо POST).
  final Cargo? cargo;

  @override
  ConsumerState<PostCargoScreen> createState() => _PostCargoScreenState();
}

class _PostCargoScreenState extends ConsumerState<PostCargoScreen> {
  final _volumeController = TextEditingController();
  final _weightController = TextEditingController();
  final _palletController = TextEditingController();
  // «Подходит N водителям на точке» (задача 033, п.10) — пересчитывается
  // по кнопке-подсказке, не на каждый символ.
  int? _fitCount;
  bool _fitCountLoading = false;
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _pointId;
  String? _pointError;
  bool _allowPartial = false;
  String? _countryId;
  String? _cityId;
  String? _bodyTypeId;
  Currency _currency = Currency.usd;
  DateTime _readyDate = DateTime.now();
  String? _destinationError;
  String? _bodyTypeError;
  String? _priceError;
  bool _saving = false;
  final List<String> _photoUrls = [];
  bool _uploadingPhoto = false;

  bool get _isEditing => widget.cargo != null;

  @override
  void initState() {
    super.initState();
    final cargo = widget.cargo;
    _pointId = cargo?.pointId;
    if (cargo == null) _defaultPointFromLastCargo();
    if (cargo != null) {
      _allowPartial = cargo.allowPartial;
      _countryId = cargo.destinationCountryId;
      _cityId = cargo.destinationCityId;
      _bodyTypeId = cargo.bodyTypeId;
      _currency = cargo.currency;
      _readyDate = cargo.readyDate;
      _photoUrls.addAll(cargo.photoUrls);
      if (cargo.volumeM3 != null) _volumeController.text = _trimNum(cargo.volumeM3!);
      // Вес вводится в тоннах (можно 12,5), хранится в кг (041, п.9).
      if (cargo.weightKg != null) _weightController.text = _trimNum(cargo.weightKg! / 1000);
      if (cargo.palletCount != null) _palletController.text = cargo.palletCount.toString();
      _priceController.text = _trimNum(cargo.price);
      _descriptionController.text = cargo.description ?? '';
    }
  }

  /// Новый груз — по умолчанию из города последнего груза компании (040, п.7);
  /// выбранный вручную город не перезаписывается.
  Future<void> _defaultPointFromLastCargo() async {
    try {
      final cargos = await ref.read(myCargosProvider.future);
      final last = cargos.firstOrNull?.pointId;
      if (mounted && _pointId == null && last != null) setState(() => _pointId = last);
    } catch (e) {
      debugPrint('PostCargoScreen: default city failed: $e');
    }
  }

  static String _trimNum(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

  @override
  void dispose() {
    _volumeController.dispose();
    _weightController.dispose();
    _palletController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(ImageSource source) async {
    final picked = await pickPhoto(source);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(uploadsRepositoryProvider).uploadImage(bytes, filename: picked.name);
      setState(() => _photoUrls.add(url));
    } catch (e) {
      if (mounted) showApiError(context, e, fallback: context.l10n.postCargoPhotoUploadFailed);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _removePhoto(String url) => setState(() => _photoUrls.remove(url));

  /// Тонны из поля → кг (запятая как разделитель допускается).
  double? _weightKg() {
    final tons = double.tryParse(_weightController.text.trim().replaceAll(',', '.'));
    return tons == null ? null : (tons * 1000).roundToDouble();
  }

  Future<void> _refreshFitCount() async {
    final weightKg = _weightKg();
    final volumeM3 = double.tryParse(_volumeController.text);
    final palletCount = int.tryParse(_palletController.text);
    if (volumeM3 == null && palletCount == null) {
      setState(() => _fitCount = null);
      return;
    }
    setState(() => _fitCountLoading = true);
    try {
      final count = await ref.read(cargoRepositoryProvider).fitCount(weightKg: weightKg, volumeM3: volumeM3, palletCount: palletCount, pointId: _pointId);
      if (mounted) setState(() => _fitCount = count);
    } catch (e) {
      // Подсказка best-effort: при сбое просто не показываем (но в лог пишем).
      debugPrint('PostCargoScreen: fitCount failed: $e');
      if (mounted) setState(() => _fitCount = null);
    } finally {
      if (mounted) setState(() => _fitCountLoading = false);
    }
  }

  Future<void> _pickCity(ReferenceData refData) async {
    final picked = await pickCity(context, ref, refData: refData, selectedId: _pointId);
    if (picked != null && mounted) {
      setState(() {
        _pointId = picked.id;
        _pointError = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _readyDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _readyDate = picked);
  }

  Future<void> _submit() async {
    if (!_isEditing && !(ref.read(sessionProvider)?.company?.isVerified ?? false)) return;
    final t = context.l10n;
    final price = double.tryParse(_priceController.text.trim().replaceAll(',', '.'));
    setState(() {
      _pointError = _pointId == null ? t.postCargoPickupCityError : null;
      _destinationError = _countryId == null ? t.postCargoDestinationError : null;
      _bodyTypeError = _bodyTypeId == null ? t.postCargoBodyTypeError : null;
      _priceError = price == null ? t.postCargoPriceError : null;
    });
    if (_pointError != null || _destinationError != null || _bodyTypeError != null || _priceError != null) return;
    setState(() => _saving = true);
    try {
      final input = CreateCargoInput(
        pointId: _pointId!,
        allowPartial: _allowPartial,
        destinationCountryId: _countryId!,
        destinationCityId: _cityId,
        bodyTypeId: _bodyTypeId!,
        weightKg: _weightKg(),
        volumeM3: double.tryParse(_volumeController.text),
        palletCount: int.tryParse(_palletController.text),
        photoUrls: _photoUrls,
        price: price!,
        currency: _currency,
        readyDate: _readyDate,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );
      if (_isEditing) {
        await ref.read(cargoRepositoryProvider).update(widget.cargo!.id, input);
        ref.invalidate(cargoByIdProvider(widget.cargo!.id));
      } else {
        await ref.read(cargoRepositoryProvider).create(input);
      }
      ref.invalidate(myCargosProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
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
    // Задача 012, п.4 — непроверенная компания не публикует новые грузы
    // (decisions.md «Компания: проверка, роли, контакты»); редактировать
    // уже опубликованный груз можно — isVerified тут не при чём.
    final isVerified = ref.watch(sessionProvider.select((s) => s?.company?.isVerified)) ?? false;
    final blockedByVerification = !_isEditing && !isVerified;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? t.editCargoTitle : t.postCargoTitle)),
      body: referenceData.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('PostCargoScreen: $e');
          return ErrorView(message: t.commonError);
        },
        data: (refData) {
          final destinationOptions = refData.countryCityOptions(locale, wholeCountrySuffix: t.wholeCountrySuffix);
          String initialDestinationLabel = '';
          if (_countryId != null) {
            final matches = destinationOptions.where((o) => o.countryId == _countryId && o.cityId == _cityId);
            initialDestinationLabel =
                matches.isNotEmpty ? matches.first.label : refData.countryById(_countryId!).name.forLanguageCode(locale);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (blockedByVerification) ...[
                Card(
                  key: const Key('postCargoVerificationBanner'),
                  color: AppColors.primarySoft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.shieldAlert),
                        const SizedBox(width: 12),
                        Expanded(child: Text(t.postCargoVerificationRequired)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              CityField(
                key: const Key('postCargoPickupCity'),
                label: t.postCargoPickupCity,
                value: _pointId == null ? null : refData.pointOrNull(_pointId!)?.name.forLanguageCode(locale),
                errorText: _pointError,
                onTap: () => _pickCity(refData),
              ),
              const SizedBox(height: 12),
              Autocomplete<CountryCityOption>(
                initialValue: TextEditingValue(text: initialDestinationLabel),
                displayStringForOption: (o) => o.label,
                optionsBuilder: (value) {
                  if (value.text.isEmpty) return destinationOptions;
                  final query = value.text.toLowerCase();
                  return destinationOptions.where((o) => o.label.toLowerCase().contains(query));
                },
                onSelected: (option) => setState(() {
                  _countryId = option.countryId;
                  _cityId = option.cityId;
                }),
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) => AppTextField(
                  key: const Key('postCargoDestination'),
                  label: t.cargoDestination,
                  errorText: _destinationError,
                  hintText: t.searchCityCountryHint,
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (_) => onSubmitted(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('postCargoBodyType'),
                initialValue: _bodyTypeId,
                decoration: InputDecoration(labelText: t.postCargoBodyType, border: const OutlineInputBorder(), errorText: _bodyTypeError),
                items: refData.bodyTypes
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name.forLanguageCode(locale))))
                    .toList(),
                onChanged: (value) => setState(() => _bodyTypeId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      key: const Key('postCargoVolume'),
                      label: t.postCargoVolume,
                      controller: _volumeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _refreshFitCount(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      key: const Key('postCargoWeight'),
                      label: t.postCargoWeight,
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: t.postCargoPallets,
                controller: _palletController,
                keyboardType: TextInputType.number,
                onChanged: (_) => _refreshFitCount(),
              ),
              if (_fitCount != null && !_fitCountLoading) ...[
                const SizedBox(height: 4),
                Text(t.postCargoFitCount(_fitCount!), style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ],
              SwitchListTile(
                key: const Key('postCargoAllowPartial'),
                contentPadding: EdgeInsets.zero,
                title: Text(t.postCargoAllowPartial),
                subtitle: Text(t.postCargoAllowPartialHint),
                value: _allowPartial,
                onChanged: (value) => setState(() => _allowPartial = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(key: const Key('postCargoPrice'), label: t.postCargoPrice, errorText: _priceError, controller: _priceController, keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Currency>(
                      initialValue: _currency,
                      decoration: InputDecoration(labelText: t.postCargoCurrency, border: const OutlineInputBorder()),
                      items: Currency.values
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase())))
                          .toList(),
                      onChanged: (value) => setState(() => _currency = value ?? _currency),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.postCargoReadyDate),
                subtitle: Text('${_readyDate.day}.${_readyDate.month}.${_readyDate.year}'),
                trailing: const Icon(LucideIcons.calendar),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              Text(t.postCargoPhotos, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final url in _photoUrls)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(url, width: 88, height: 88, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: IconButton(
                            icon: const Icon(LucideIcons.xCircle, size: 20),
                            tooltip: t.postCargoRemovePhoto,
                            onPressed: () => _removePhoto(url),
                          ),
                        ),
                      ],
                    ),
                  if (_uploadingPhoto)
                    const SizedBox(
                      width: 88,
                      height: 88,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadingPhoto ? null : () => _addPhoto(ImageSource.camera),
                      icon: const Icon(LucideIcons.camera),
                      label: Text(t.postCargoAddPhotoCamera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadingPhoto ? null : () => _addPhoto(ImageSource.gallery),
                      icon: const Icon(LucideIcons.image),
                      label: Text(t.postCargoAddPhotoGallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(label: t.postCargoDescription, controller: _descriptionController, maxLines: 3),
              const SizedBox(height: 24),
              PrimaryButton(
                key: const Key('postCargoSubmit'),
                label: _isEditing ? t.commonSave : t.postCargoSubmit,
                loading: _saving,
                onPressed: blockedByVerification ? null : _submit,
              ),
            ],
          );
        },
      ),
    );
  }
}
