import 'dart:async';
import 'dart:math';

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
import '../../shared/status_helpers.dart';
import '../../../services/push_service.dart';

class PostCargoScreen extends ConsumerStatefulWidget {
  const PostCargoScreen({super.key, this.cargo, this.template});

  /// Если передан — экран работает в режиме редактирования существующего
  /// груза (предзаполняет поля, сохраняет через PATCH вместо POST).
  final Cargo? cargo;

  /// 056 п.3 «Повторить»: новый груз, заполненный по старому; дата погрузки —
  /// сегодня (вечером — завтра). Старый груз не трогается.
  final Cargo? template;

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
  // 058 п.1: условия оплаты — аванс (в валюте груза), форма, отсрочка.
  final _advanceController = TextEditingController();
  final _delayController = TextEditingController();
  // 058 п.2: сколько машин нужно (1–20).
  final _trucksController = TextEditingController(text: '1');
  PaymentForm? _paymentForm;
  // Остаток после выгрузки: «Сразу» или «Через N дней» (058 п.1, уточнение).
  bool _restLater = false;
  String? _pointId;
  String? _pointError;
  bool _allowPartial = false;
  String? _countryId;
  String? _cityId;
  String? _bodyTypeId;
  /// 047: категория груза (обязательна) и «рынок за месяц» по маршруту.
  String? _categoryId;
  String? _categoryError;
  RouteMarket? _market;
  // Расстояние по дорогам для выбранной пары городов; null и _distanceLoading —
  // «Считаем расстояние…» (новая пара на сервере считается до ~30 с).
  int? _distanceKm;
  bool _distanceLoading = false;
  Timer? _distanceRetry;
  Timer? _marketDebounce;
  /// 048: параметры груза по профилю кузова и другие подходящие кузова.
  Map<String, dynamic> _specs = {};
  bool _showSpecsRequired = false;
  final _extraBodyTypeIds = <String>{};
  Currency _currency = Currency.usd;
  DateTime _readyDate = DateTime.now();
  String? _destinationError;
  String? _bodyTypeError;
  String? _priceError;
  String? _weightError;
  /// 055: единица ввода веса (по умолчанию кг; выбор логиста — на устройстве).
  WeightUnit _weightUnit = WeightUnit.kg;
  bool _saving = false;

  /// Ключ публикации этой формы: «Опубликовать» ещё раз после ошибки (сеть,
  /// долгий ответ) не создаёт второй такой же груз.
  final String _publishKey = List.generate(24, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[Random.secure().nextInt(36)]).join();
  final List<String> _photoUrls = [];
  bool _uploadingPhoto = false;

  bool get _isEditing => widget.cargo != null;

  @override
  void initState() {
    super.initState();
    final cargo = widget.cargo ?? widget.template;
    _pointId = cargo?.pointId;
    if (cargo == null) _defaultPointFromLastCargo();
    _loadWeightUnit();
    if (cargo != null) WidgetsBinding.instance.addPostFrameCallback((_) => _loadMarket());
    if (cargo != null) {
      _allowPartial = cargo.allowPartial;
      _countryId = cargo.destinationCountryId;
      _cityId = cargo.destinationCityId;
      _bodyTypeId = cargo.bodyTypeId;
      _categoryId = cargo.categoryId;
      _specs = {...?cargo.cargoSpecs};
      _extraBodyTypeIds.addAll(cargo.extraBodyTypeIds);
      _currency = cargo.currency;
      _readyDate = widget.template != null ? repeatReadyDate(DateTime.now()) : cargo.readyDate;
      if (widget.template == null) _photoUrls.addAll(cargo.photoUrls);
      if (cargo.volumeM3 != null) _volumeController.text = _trimNum(cargo.volumeM3!);
      // 055: вес хранится в кг, в поле — в единице логиста (после загрузки выбора).
      if (cargo.weightKg != null) _weightController.text = weightKgToInput(cargo.weightKg!, _weightUnit);
      if (cargo.palletCount != null) _palletController.text = cargo.palletCount.toString();
      _priceController.text = _trimNum(cargo.price);
      _descriptionController.text = cargo.description ?? '';
      // «Повторить» копирует и условия оплаты.
      if (cargo.advanceAmount != null) _advanceController.text = _trimNum(cargo.advanceAmount!);
      if (cargo.paymentDelayDays != null && cargo.paymentDelayDays! > 0) {
        _delayController.text = '${cargo.paymentDelayDays}';
        _restLater = true;
      }
      _paymentForm = cargo.paymentForm;
      _trucksController.text = '${cargo.trucksNeeded}';
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

  Future<void> _loadWeightUnit() async {
    final unit = await ref.read(weightUnitStoreProvider).load();
    if (!mounted || unit == _weightUnit) return;
    _setWeightUnit(unit, remember: false);
  }

  /// Переключить единицу: число в поле пересчитывается, вес не меняется.
  void _setWeightUnit(WeightUnit unit, {bool remember = true}) {
    final kg = _weightKg();
    setState(() {
      _weightUnit = unit;
      if (kg != null) _weightController.text = weightKgToInput(kg, unit, languageCode: Localizations.localeOf(context).languageCode);
      _weightError = null;
    });
    if (remember) ref.read(weightUnitStoreProvider).save(unit);
    _onWeightChanged();
  }

  /// Подсказка «лишние нули»: одно нажатие — то же число в другой единице.
  void _applyWeightHint(WeightHint hint) {
    final kg = switch (hint) {
      WeightLooksLikeKg(:final kg) => kg,
      WeightLooksLikeTons(:final tons) => tons * 1000,
    };
    final unit = hint is WeightLooksLikeKg ? WeightUnit.kg : WeightUnit.t;
    setState(() {
      _weightUnit = unit;
      _weightController.text = weightKgToInput(kg, unit, languageCode: Localizations.localeOf(context).languageCode);
      _weightError = null;
    });
    ref.read(weightUnitStoreProvider).save(unit);
    _onWeightChanged();
  }

  void _onWeightChanged() {
    setState(() {});
    // 049 п.11: класс тоннажа меняет «рынок» — пересчёт после паузы в вводе.
    _marketDebounce?.cancel();
    _marketDebounce = Timer(const Duration(milliseconds: 600), _loadMarket);
  }

  static String _trimNum(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

  @override
  void dispose() {
    _marketDebounce?.cancel();
    _distanceRetry?.cancel();
    _volumeController.dispose();
    _weightController.dispose();
    _palletController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _advanceController.dispose();
    _delayController.dispose();
    _trucksController.dispose();
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

  BodyType? _bodyType(ReferenceData refData) => _bodyTypeId == null ? null : refData.bodyTypes.where((b) => b.id == _bodyTypeId).firstOrNull;
  bool _showVolume(ReferenceData refData) {
    final bt = _bodyType(refData);
    return bt == null || bt.isVolume || bt.profile == 'BULK';
  }

  bool _showPallets(ReferenceData refData) => _bodyType(refData)?.isVolume ?? true;

  /// Поле (кг или т) → кг; запятая как разделитель допускается.
  double? _weightKg() => weightInputToKg(_weightController.text, _weightUnit);

  Future<void> _refreshFitCount() async {
    final weightKg = _weightKg();
    final volumeM3 = parseDecimal(_volumeController.text);
    final palletCount = int.tryParse(_palletController.text);
    if (volumeM3 == null && palletCount == null && _specs.isEmpty) {
      setState(() => _fitCount = null);
      return;
    }
    setState(() => _fitCountLoading = true);
    try {
      final count = await ref.read(cargoRepositoryProvider).fitCount(
            weightKg: weightKg,
            volumeM3: volumeM3,
            palletCount: palletCount,
            pointId: _pointId,
            // 048 п.4: «подходит N» — по профилю выбранных кузовов.
            bodyTypeIds: [if (_bodyTypeId != null) _bodyTypeId!, ..._extraBodyTypeIds],
            specs: _specs,
          );
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
      unawaited(_loadMarket());
    }
  }

  /// 047 п.7: медиана ₸/км по маршруту — подсказка, при сбое просто не показываем.
  Future<void> _loadMarket({int attempt = 0}) async {
    _distanceRetry?.cancel();
    if (_pointId == null || _countryId == null || _cityId == null) {
      if (_market != null || _distanceKm != null || _distanceLoading) {
        setState(() {
          _market = null;
          _distanceKm = null;
          _distanceLoading = false;
        });
      }
      return;
    }
    final route = (_pointId, _cityId);
    if (attempt == 0) setState(() => _distanceLoading = true);
    try {
      final hint = await ref.read(cargoRepositoryProvider).marketHint(
            pointId: _pointId!,
            destinationCountryId: _countryId!,
            destinationCityId: _cityId,
            weightKg: _weightKg(),
          );
      if (!mounted || route != (_pointId, _cityId)) return;
      // Сервер ещё считает — спросить ещё раз (к тому времени пара в кэше).
      final retry = hint.distanceKm == null && attempt < 2;
      setState(() {
        _market = hint.market;
        _distanceKm = hint.distanceKm;
        _distanceLoading = retry;
      });
      if (retry) _distanceRetry = Timer(const Duration(seconds: 5), () => _loadMarket(attempt: attempt + 1));
    } catch (e) {
      debugPrint('PostCargoScreen: marketHint failed: $e');
      if (mounted) setState(() => _distanceLoading = false);
    }
  }

  /// 058 п.1: аванс — число, не больше цены; отсрочка — целые дни до 365.
  String? _advanceError(LubaoLocalizations t) {
    if (_advanceController.text.trim().isEmpty) return null;
    final advance = parseDecimal(_advanceController.text);
    if (advance == null || advance < 0) return t.fieldNotNumber;
    final price = parseDecimal(_priceController.text);
    return price != null && advance > price ? t.postCargoAdvanceTooBig : null;
  }

  /// 058 п.2: целое 1–20.
  String? _trucksError(LubaoLocalizations t) {
    final text = _trucksController.text.trim();
    if (text.isEmpty) return t.fieldRequired;
    return int.tryParse(text) == null ? t.fieldNotNumber : numberFieldError(t, text, min: 1, max: 20);
  }

  String? _delayError(LubaoLocalizations t) {
    if (!_restLater) return null;
    final text = _delayController.text.trim();
    if (text.isEmpty) return t.fieldRequired;
    final days = int.tryParse(text);
    if (days == null || days < 0) return t.fieldNotNumber;
    return days > 365 ? t.fieldMax('365') : null;
  }

  /// Пределы — как на сервере (объём кузова до 200 м³, до 60 европаллет).
  String? _volumeError(LubaoLocalizations t) => numberFieldError(t, _volumeController.text, max: 200);
  String? _palletError(LubaoLocalizations t) => int.tryParse(_palletController.text.trim()) == null && _palletController.text.trim().isNotEmpty
      ? t.fieldNotNumber
      : numberFieldError(t, _palletController.text, min: 1, max: 60);

  /// «≈ 1 115 км по дорогам · ваша цена ≈ 8 970 ₸/км» — цена в ₸ по курсу НБ РК.
  String? _distanceLabel(LubaoLocalizations t, ReferenceData refData) {
    if (_distanceKm == null || _distanceKm == 0) return _distanceLoading ? t.postCargoDistanceCounting : null;
    final km = formatThousands(_distanceKm!);
    final price = double.tryParse(_priceController.text.replaceAll(' ', '').replaceAll(',', '.'));
    final kzt = price == null || price <= 0 ? null : refData.convertToKzt(price, _currency);
    return kzt == null ? t.postCargoDistanceHint(km) : t.postCargoDistancePerKm(km, formatThousands((kzt / _distanceKm!).round()));
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
    final refData = ref.read(referenceDataProvider).valueOrNull;
    final price = double.tryParse(_priceController.text.trim().replaceAll(',', '.'));
    setState(() {
      _pointError = _pointId == null ? t.postCargoPickupCityError : null;
      _destinationError = _countryId == null ? t.postCargoDestinationError : null;
      _bodyTypeError = _bodyTypeId == null ? t.postCargoBodyTypeError : null;
      _categoryError = _categoryId == null ? t.postCargoCategoryRequired : null;
      _priceError = price == null ? t.postCargoPriceError : null;
      // 055: в кг или т; пусто — можно, иначе 0 < вес ≤ 60 т (сервер — свой максимум).
      final weightText = _weightController.text.trim();
      final kg = _weightKg();
      _weightError = weightText.isEmpty || (kg != null && kg > 0 && kg <= maxCargoTons * 1000) ? null : t.postCargoWeightError;
    });
    // Поля груза по кузову (литры, число машин…) — ошибки под полями.
    final specsOk = _bodyTypeId == null || refData == null || specsValid(refData.bodyTypeById(_bodyTypeId!).cargoFields, _specs);
    if (!specsOk) setState(() => _showSpecsRequired = true);
    final sizesOk = _volumeError(t) == null && _palletError(t) == null && _advanceError(t) == null && _delayError(t) == null && _trucksError(t) == null;
    if (!sizesOk) return;
    if (_pointError != null || _destinationError != null || _bodyTypeError != null || _categoryError != null || _priceError != null || _weightError != null || !specsOk) return;
    setState(() => _saving = true);
    try {
      final input = CreateCargoInput(
        pointId: _pointId!,
        allowPartial: _allowPartial && (refData?.partialLoadsEnabled ?? false),
        destinationCountryId: _countryId!,
        destinationCityId: _cityId,
        bodyTypeId: _bodyTypeId!,
        categoryId: _categoryId,
        weightKg: _weightKg(),
        volumeM3: refData == null || _showVolume(refData) ? parseDecimal(_volumeController.text) : null,
        palletCount: refData == null || _showPallets(refData) ? int.tryParse(_palletController.text) : null,
        photoUrls: _photoUrls,
        price: price!,
        currency: _currency,
        readyDate: _readyDate,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        advanceAmount: parseDecimal(_advanceController.text),
        paymentForm: _paymentForm,
        paymentDelayDays: _restLater ? int.tryParse(_delayController.text.trim()) : null,
        trucksNeeded: int.tryParse(_trucksController.text.trim()) ?? 1,
        specs: _specs.isEmpty ? null : _specs,
        extraBodyTypeIds: _extraBodyTypeIds.where((id) => id != _bodyTypeId).toList(),
      );
      if (_isEditing) {
        await ref.read(cargoRepositoryProvider).update(widget.cargo!.id, input);
        ref.invalidate(cargoByIdProvider(widget.cargo!.id));
      } else {
        await ref.read(cargoRepositoryProvider).create(input, idempotencyKey: _publishKey);
        unawaited(ref.read(pushServiceProvider).requestPermissionAndRegister());
      }
      ref.invalidate(myCargosProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showApiError(context, e, onRetry: _submit);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 055: «Вес» — переключатель `кг | т` справа, пересчёт под полем и
  /// подсказка против лишних нулей (одно нажатие — другая единица).
  Widget _weightField(LubaoLocalizations t) {
    final lang = Localizations.localeOf(context).languageCode;
    final text = _weightController.text;
    final conversion = weightConversionLine(text, _weightUnit, tonUnit: t.unitTon, kgUnit: t.unitKg, languageCode: lang);
    final hint = weightHint(text, _weightUnit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                key: const Key('postCargoWeight'),
                label: t.postCargoWeight,
                errorText: _weightError,
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _onWeightChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SegmentedButton<WeightUnit>(
                key: const Key('postCargoWeightUnit'),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.padded),
                segments: [
                  ButtonSegment(value: WeightUnit.kg, label: Text(t.unitKg, key: const Key('postCargoWeightUnit-kg'))),
                  ButtonSegment(value: WeightUnit.t, label: Text(t.unitTon, key: const Key('postCargoWeightUnit-t'))),
                ],
                selected: {_weightUnit},
                onSelectionChanged: (s) => _setWeightUnit(s.first),
              ),
            ),
          ],
        ),
        if (conversion != null && hint == null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(conversion, key: const Key('postCargoWeightConversion'), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ),
        if (hint != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('postCargoWeightHint'),
              icon: const Icon(LucideIcons.helpCircle, size: 18),
              style: TextButton.styleFrom(foregroundColor: AppColors.accentText, padding: const EdgeInsets.symmetric(horizontal: 4)),
              onPressed: () => _applyWeightHint(hint),
              label: Text(switch (hint) {
                WeightLooksLikeKg(:final kg) => t.postCargoWeightLooksLikeKg(formatWeightKgNumber(kg), formatWeightTonsNumber(kg / 1000, languageCode: lang)),
                WeightLooksLikeTons(:final tons) => t.postCargoWeightLooksLikeTons(formatWeightTonsNumber(tons, languageCode: lang)),
              }),
            ),
          ),
      ],
    );
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
                  // Только что выбранный город в поле — список не держим открытым
                  // (на Android после выбора он оставался до второго нажатия).
                  if (destinationOptions.any((o) => o.countryId == _countryId && o.cityId == _cityId && o.label == value.text)) {
                    return const Iterable<CountryCityOption>.empty();
                  }
                  final query = value.text.toLowerCase();
                  return destinationOptions.where((o) => o.label.toLowerCase().contains(query));
                },
                onSelected: (option) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() {
                    _countryId = option.countryId;
                    _cityId = option.cityId;
                  });
                  unawaited(_loadMarket());
                },
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
              // 047 п.1, 7: категория — чипами, обязательна.
              Text(t.postCargoCategory, style: AppTextStyles.bodyStrong),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in refData.cargoCategories.where((c) => c.isActive || c.id == _categoryId))
                    ChoiceChip(
                      key: Key('postCargoCategory-${c.code}'),
                      label: Text(c.name.forLanguageCode(locale)),
                      selected: _categoryId == c.id,
                      onSelected: (_) => setState(() {
                        _categoryId = c.id;
                        _categoryError = null;
                      }),
                    ),
                ],
              ),
              if (_categoryError != null) ...[
                const SizedBox(height: 4),
                Text(_categoryError!, key: const Key('postCargoCategoryError'), style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('postCargoBodyType'),
                initialValue: _bodyTypeId,
                decoration: InputDecoration(labelText: t.postCargoBodyType, border: const OutlineInputBorder(), errorText: _bodyTypeError),
                items: refData.bodyTypes
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name.forLanguageCode(locale))))
                    .toList(),
                onChanged: (value) => setState(() {
                  _bodyTypeId = value;
                  _specs = {};
                }),
              ),
              const SizedBox(height: 12),
              // 048 п.4: поля груза по профилю выбранного кузова (продукт и литры,
              // тип контейнера, число машин…) и другие подходящие кузова.
              if (_bodyTypeId != null && refData.bodyTypeById(_bodyTypeId!).cargoFields.isNotEmpty) ...[
                Text(t.cargoSpecsTitle, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 8),
                SpecsForm(
                  key: ValueKey('cargoSpecs-$_bodyTypeId'),
                  showRequired: _showSpecsRequired,
                  fields: refData.bodyTypeById(_bodyTypeId!).cargoFields,
                  values: _specs,
                  onChanged: (v) {
                    setState(() => _specs = v);
                    _refreshFitCount();
                  },
                ),
              ],
              if (_bodyTypeId != null) ...[
                Text(t.cargoExtraBodyTypes, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in refData.bodyTypes.where((b) => b.isActive && b.id != _bodyTypeId))
                      SelectableTile(
                        key: Key('postCargoExtraBody-${b.code}'),
                        label: b.name.forLanguageCode(locale),
                        selected: _extraBodyTypeIds.contains(b.id),
                        onTap: () {
                          setState(() => _extraBodyTypeIds.contains(b.id) ? _extraBodyTypeIds.remove(b.id) : _extraBodyTypeIds.add(b.id));
                          _refreshFitCount();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  // 048 п.4: м³ — объёмным и насыпным, паллеты — только объёмным.
                  if (_showVolume(refData))
                  Expanded(
                    child: AppTextField(
                      key: const Key('postCargoVolume'),
                      label: t.postCargoVolume,
                      controller: _volumeController,
                      errorText: _volumeError(t),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) {
                        setState(() {});
                        _refreshFitCount();
                      },
                    ),
                  ),
                ],
              ),
              if (_showVolume(refData)) const SizedBox(height: 12),
              _weightField(t),
              if (_showPallets(refData)) ...[
                const SizedBox(height: 12),
                AppTextField(
                  label: t.postCargoPallets,
                  controller: _palletController,
                  errorText: _palletError(t),
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    setState(() {});
                    _refreshFitCount();
                  },
                ),
              ],
              if (_fitCount != null && !_fitCountLoading) ...[
                const SizedBox(height: 4),
                Text(t.postCargoFitCount(_fitCount!), style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ],
              // 049 п.1: догруз за флагом — выключен, переключателя нет.
              if (refData.partialLoadsEnabled)
                SwitchListTile(
                  key: const Key('postCargoAllowPartial'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.postCargoAllowPartial),
                  subtitle: Text(t.postCargoAllowPartialHint),
                  value: _allowPartial,
                  onChanged: (value) => setState(() => _allowPartial = value),
                ),
              const SizedBox(height: 12),
              if (_distanceLabel(t, refData) case final distance?) ...[
                Text(distance, key: const Key('postCargoDistanceHint'), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
              ],
              if (_market != null) ...[
                Text(
                  t.postCargoMarketHint(formatThousands(_market!.median.round()), _market!.dealPoints),
                  key: const Key('postCargoMarketHint'),
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      key: const Key('postCargoPrice'),
                      label: t.postCargoPrice,
                      errorText: _priceError,
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      // Цена за км под расстоянием пересчитывается на ходу.
                      onChanged: (_) => setState(() {}),
                    ),
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
              AppTextField(
                key: const Key('postCargoTrucks'),
                label: t.postCargoTrucks,
                controller: _trucksController,
                errorText: _trucksError(t),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              // 058 п.1: «Оплата» — аванс при погрузке, остаток после выгрузки, форма (всё необязательно).
              Text(t.postCargoPaymentTitle, style: AppTextStyles.bodyStrong),
              const SizedBox(height: 8),
              AppTextField(
                key: const Key('postCargoAdvance'),
                label: '${t.postCargoAdvance}, ${currencySymbol(_currency)}',
                controller: _advanceController,
                errorText: _advanceError(t),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(t.postCargoPaymentDelay, style: AppTextStyles.caption),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SelectableTile(key: const Key('postCargoRestNow'), label: t.paymentRestNow, selected: !_restLater, onTap: () => setState(() => _restLater = false)),
                  SelectableTile(key: const Key('postCargoRestLater'), label: t.paymentRestLater, selected: _restLater, onTap: () => setState(() => _restLater = true)),
                ],
              ),
              if (_restLater) ...[
                const SizedBox(height: 8),
                AppTextField(
                  key: const Key('postCargoPaymentDelay'),
                  label: t.postCargoDelayDays,
                  controller: _delayController,
                  errorText: _delayError(t),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final form in PaymentForm.values)
                    SelectableTile(
                      key: Key('postCargoPaymentForm-${form.name}'),
                      label: paymentFormLabel(t, form),
                      selected: _paymentForm == form,
                      onTap: () => setState(() => _paymentForm = _paymentForm == form ? null : form),
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

/// 055: единица ввода веса — на устройстве логиста.
final weightUnitStoreProvider = Provider((ref) => WeightUnitStore());

/// 056 п.3: дата погрузки повторённого груза — сегодня; после 18:00 — завтра.
DateTime repeatReadyDate(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return now.hour >= 18 ? today.add(const Duration(days: 1)) : today;
}
