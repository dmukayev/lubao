import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _countryId;
  String? _cityId;
  String? _bodyTypeId;
  Currency _currency = Currency.usd;
  DateTime _readyDate = DateTime.now();
  bool _saving = false;
  final List<String> _photoUrls = [];
  bool _uploadingPhoto = false;

  bool get _isEditing => widget.cargo != null;

  @override
  void initState() {
    super.initState();
    final cargo = widget.cargo;
    if (cargo != null) {
      _countryId = cargo.destinationCountryId;
      _cityId = cargo.destinationCityId;
      _bodyTypeId = cargo.bodyTypeId;
      _currency = cargo.currency;
      _readyDate = cargo.readyDate;
      _photoUrls.addAll(cargo.photoUrls);
      if (cargo.volumeM3 != null) _volumeController.text = _trimNum(cargo.volumeM3!);
      if (cargo.weightKg != null) _weightController.text = _trimNum(cargo.weightKg!);
      _priceController.text = _trimNum(cargo.price);
      _descriptionController.text = cargo.description ?? '';
    }
  }

  static String _trimNum(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

  @override
  void dispose() {
    _volumeController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(uploadsRepositoryProvider).uploadImage(bytes, filename: picked.name);
      setState(() => _photoUrls.add(url));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postCargoPhotoUploadFailed)));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _removePhoto(String url) => setState(() => _photoUrls.remove(url));

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
    if (_countryId == null || _bodyTypeId == null || _priceController.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final input = CreateCargoInput(
        destinationCountryId: _countryId!,
        destinationCityId: _cityId,
        bodyTypeId: _bodyTypeId!,
        weightKg: double.tryParse(_weightController.text),
        volumeM3: double.tryParse(_volumeController.text),
        photoUrls: _photoUrls,
        price: double.parse(_priceController.text),
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final referenceData = ref.watch(referenceDataProvider);

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
                  label: t.cargoDestination,
                  hintText: t.searchCityCountryHint,
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (_) => onSubmitted(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _bodyTypeId,
                decoration: InputDecoration(labelText: t.postCargoBodyType, border: const OutlineInputBorder()),
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
                      label: t.postCargoVolume,
                      controller: _volumeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: t.postCargoWeight,
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(label: t.postCargoPrice, controller: _priceController, keyboardType: TextInputType.number),
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
                label: _isEditing ? t.commonSave : t.postCargoSubmit,
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
