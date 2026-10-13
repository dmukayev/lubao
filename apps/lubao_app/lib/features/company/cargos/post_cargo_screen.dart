import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lubao_core/lubao_core.dart';

import 'goods_field.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../shared/city_picking.dart';
import '../../shared/photo_picker.dart';
import '../../shared/error_feedback.dart';
import '../../shared/status_helpers.dart';
import '../../../services/push_service.dart';
import '../../shared/cached_photo.dart';

/// Телефон логиста сохранён из формы груза в этой сессии приложения — второй
/// раз не спрашивать (профиль в сессии обновится при следующей загрузке).
final contactPhoneSavedProvider = StateProvider<bool>((ref) => false);

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
  /// 072: прокрутка к первому незаполненному полю.
  final _fields = FieldScroller();
  static const _fieldOrder = ['pointId', 'destinationCountryId', 'goods', 'categoryId', 'bodyTypeId', 'specs', 'volumeM3', 'weightKg', 'palletCount', 'trucksNeeded', 'price', 'paymentDelayDays', 'advanceAmount', 'contactPhone'];
  /// Поля, ошибки сервера по которым форма показывает у поля (остальное — всплывашкой).
  static const _serverFields = {'price', 'weightKg'};
  // «Подходит N водителям на точке» (задача 033, п.10) — пересчитывается
  // по кнопке-подсказке, не на каждый символ.
  int? _fitCount;
  bool _fitCountLoading = false;
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  // 058 п.1: условия оплаты — аванс (в валюте груза), форма, отсрочка.
  final _advanceController = TextEditingController();
  // Телефон логиста для водителей — обязателен до публикации (decisions.md
  // «Обязательные поля компании»); нет в профиле — поле прямо в форме.
  final _phoneController = TextEditingController();
  String? _phoneError;
  bool _askPhone = false;
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
  /// «изменить» у строки категории раскрыл чипы (077).
  bool _categoryExpanded = false;

  /// Товар (или код) выбран и категория из него — строкой; свой вариант,
  /// категорию не определить или «изменить» — чипами; поле пусто — ничего.
  _CategoryMode get _categoryMode {
    final picked = _goodsId != null || _hsCode != null;
    if (picked && _categoryId != null && !_categoryExpanded) return _CategoryMode.line;
    if (_goodsText != null || picked || _categoryExpanded) return _CategoryMode.chips;
    return _CategoryMode.hidden;
  }
  /// 075: что везут — товар из справочника, свой текст, код HS.
  String? _goodsId;
  String? _goodsText;
  String? _hsCode;
  String _goodsLabel = '';
  String? _goodsError;
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
      _goodsId = cargo.goodsId;
      _goodsText = cargo.goodsText;
      _hsCode = cargo.hsCode;
      _goodsLabel = cargo.goodsText ?? '';
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
    _fields.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _advanceController.dispose();
    _phoneController.dispose();
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

  /// 068: поле паллет — только у объёмного кузова с включёнными паллетами.
  bool _showPallets(ReferenceData refData) => _bodyType(refData)?.palletsShown ?? false;

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

  /// 063: «Входит в 850 000 ₸, остаток — 550 000 ₸ через 5 дн. после выгрузки» — на лету.
  String? _advanceHint(LubaoLocalizations t) {
    final price = parseDecimal(_priceController.text);
    final advance = parseDecimal(_advanceController.text);
    if (price == null || advance == null || advance <= 0 || advance >= price) return null;
    final total = formatCurrencyAmount(price, _currency);
    final rest = formatCurrencyAmount(price - advance, _currency);
    final days = int.tryParse(_delayController.text.trim());
    return _restLater && days != null && days > 0 ? t.postCargoAdvanceHintDays(total, rest, '$days') : t.postCargoAdvanceHintNow(total, rest);
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

  /// Нет телефона ни в «Моём профиле», ни у пользователя — спросить в форме.
  bool get _needsPhone {
    if (_isEditing) return false;
    // read, а не watch: геттер зовётся и из обработчика публикации; экран
    // перестраивается сам — сессия обновляется через setState после сохранения.
    final session = ref.read(sessionProvider);
    if (_askPhone) return true;
    if (ref.read(contactPhoneSavedProvider)) return false;
    return session?.companyMember?.contactPhone == null && session?.user.phone == null;
  }

  Future<void> _submit() async {
    final t = context.l10n;
    // Телефон проверяется вместе с остальными полями — все ошибки видны сразу.
    final needsPhone = _needsPhone;
    setState(() => _phoneError = needsPhone && _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '').length < 5 ? t.postCargoPhoneRequired : null);
    final refData = ref.read(referenceDataProvider).valueOrNull;
    final price = double.tryParse(_priceController.text.trim().replaceAll(',', '.'));
    setState(() {
      _pointError = _pointId == null ? t.postCargoPickupCityError : null;
      _destinationError = _countryId == null ? t.postCargoDestinationError : null;
      _bodyTypeError = _bodyTypeId == null ? t.postCargoBodyTypeError : null;
      _categoryError = _categoryId == null ? t.postCargoCategoryRequired : null;
      // 075: пустое «Что везёте?» — ошибка у поля (072).
      _goodsError = _goodsId == null && (_goodsText ?? '').trim().isEmpty ? t.postCargoWhatRequired : null;
      _priceError = price == null ? t.postCargoPriceError : null;
      // 055: в кг или т; пусто — можно, иначе 0 < вес ≤ 60 т (сервер — свой максимум).
      final weightText = _weightController.text.trim();
      final kg = _weightKg();
      _weightError = weightText.isEmpty || (kg != null && kg > 0 && kg <= maxCargoTons * 1000) ? null : t.postCargoWeightError;
    });
    // Поля груза по кузову (литры, число машин…) — ошибки под полями.
    final specsOk = _bodyTypeId == null || refData == null || specsValid(refData.bodyTypeById(_bodyTypeId!).cargoFields, _specs);
    if (!specsOk) setState(() => _showSpecsRequired = true);
    // 072: первое неверное поле — прокрутить к нему (фокус или мигание рамки).
    final invalid = <String>{
      if (_pointError != null) 'pointId',
      if (_destinationError != null) 'destinationCountryId',
      if (_goodsError != null) 'goods',
      if (_categoryError != null) 'categoryId',
      if (_bodyTypeError != null) 'bodyTypeId',
      if (!specsOk) 'specs',
      if (_volumeError(t) != null) 'volumeM3',
      if (_weightError != null) 'weightKg',
      if (_palletError(t) != null) 'palletCount',
      if (_trucksError(t) != null) 'trucksNeeded',
      if (_priceError != null) 'price',
      if (_delayError(t) != null) 'paymentDelayDays',
      if (_advanceError(t) != null) 'advanceAmount',
      if (_phoneError != null) 'contactPhone',
    };
    if (invalid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fields.showFirstInvalid(_fieldOrder, invalid));
      return;
    }
    setState(() => _saving = true);
    try {
      // Сначала — телефон в «Мой профиль» на сервере, потом публикация. Сессию
      // здесь не трогаем: её смена перестраивает навигацию (форма открывалась
      // заново, список «Активные» — пустой); телефон помечаем отдельно.
      if (_needsPhone) {
        await ref.read(companyRepositoryProvider).updateMyContact(contactPhone: _phoneController.text.trim());
        ref.read(contactPhoneSavedProvider.notifier).state = true;
        _askPhone = false;
      }
      final input = CreateCargoInput(
        pointId: _pointId!,
        allowPartial: _allowPartial && (refData?.partialLoadsEnabled ?? false),
        destinationCountryId: _countryId!,
        destinationCityId: _cityId,
        bodyTypeId: _bodyTypeId!,
        categoryId: _categoryId,
        goodsId: _goodsId,
        goodsText: _goodsId == null ? _goodsText : null,
        hsCode: _hsCode,
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
      final code = e is DioException && e.response?.data is Map ? (e.response!.data as Map)['code'] : null;
      // 072: ошибки сервера по полям — под полем, с прокруткой к первому.
      final fieldErrors = serverFieldErrors(t, e);
      if (fieldErrors.isNotEmpty && fieldErrors.keys.any(_serverFields.contains)) {
        if (mounted) {
          setState(() {
            _priceError = fieldErrors['price'] ?? _priceError;
            _weightError = fieldErrors['weightKg'] ?? _weightError;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _fields.showFirstInvalid(_fieldOrder, fieldErrors.keys.toSet()));
        }
      } else if (code == 'COMPANY_ACTIVE_LIMIT' || code == 'COMPANY_PAUSED') {
        if (mounted) await _showVerificationNeeded(e);
      } else if (code == 'CONTACT_PHONE_REQUIRED') {
        if (mounted) {
          setState(() {
            _askPhone = true;
            _phoneError = t.postCargoPhoneRequired;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _fields.reveal('contactPhone'));
        }
      } else if (mounted) {
        showApiError(context, e, onRetry: _submit);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 066 (decisions.md «Компания публикует грузы без проверки»): лимит 10
  /// активных грузов до проверки или пауза после жалоб — понятный текст и
  /// «Пройти проверку» (профиль компании, загрузка свидетельства).
  Future<void> _showVerificationNeeded(Object error) async {
    final t = context.l10n;
    final goVerify = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('postCargoLimitDialog'),
        title: Text(t.postCargoLimitTitle),
        content: SingleChildScrollView(child: Text(errorMessage(t, error), style: AppTextStyles.body)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.commonCancel)),
          FilledButton(key: const Key('postCargoGoVerify'), onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.postCargoGoVerify)),
        ],
      ),
    );
    if (goVerify == true && mounted) context.go('/company/profile');
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
                      focusNode: _fields.focusOf('weightKg'),
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

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? t.editCargoTitle : t.postCargoTitle)),
      body: referenceData.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('PostCargoScreen: $e');
          return ErrorView(message: errorMessage(t, e));
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
            // 072: поля за краем экрана уже построены — к ним можно прокрутить.
            cacheExtent: 20000,
            padding: const EdgeInsets.all(16),
            children: [
              FieldAnchor(scroller: _fields, name: 'pointId', child: CityField(
                key: const Key('postCargoPickupCity'),
                label: t.postCargoPickupCity,
                value: _pointId == null ? null : refData.pointOrNull(_pointId!)?.name.forLanguageCode(locale),
                errorText: _pointError,
                onTap: () => _pickCity(refData),
              )),
              const SizedBox(height: 12),
              FieldAnchor(scroller: _fields, name: 'destinationCountryId', child: Autocomplete<CountryCityOption>(
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
                    _destinationError = null;
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
              )),
              const SizedBox(height: 12),
              // 075: «Что везёте?» — поиск товара по названию и коду, свой вариант.
              FieldAnchor(
                scroller: _fields,
                name: 'goods',
                child: GoodsField(
                  initialText: _goodsLabel.isNotEmpty ? _goodsLabel : (widget.cargo ?? widget.template)?.goodsName?.forLanguageCode(locale) ?? '',
                  focusNode: _fields.focusOf('goods'),
                  errorText: _goodsError,
                  onSelected: (hit, label) => setState(() {
                    _goodsId = hit.goodsId;
                    _hsCode = hit.hsCode;
                    _goodsText = hit.goodsId == null ? label : null;
                    _goodsError = null;
                    _categoryExpanded = false;
                    // Категория — из товара или главы кода; видна ниже и меняется.
                    if (hit.categoryId != null) {
                      _categoryId = hit.categoryId;
                      _categoryError = null;
                    }
                    // Подсказка кузова — если кузов ещё не выбран.
                    if (_bodyTypeId == null && hit.suggestedBodyTypeId != null) _bodyTypeId = hit.suggestedBodyTypeId;
                  }),
                  onOwnText: (text) => setState(() {
                    _goodsId = null;
                    _hsCode = null;
                    _goodsText = text;
                    _goodsError = null;
                  }),
                  onCleared: () {
                    if (_goodsId != null || _hsCode != null || _goodsText != null) {
                      setState(() {
                        _goodsId = null;
                        _hsCode = null;
                        _goodsText = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              // 077 (decisions.md «„Что везёте?“ — один вопрос»): товар выбран —
              // категория одной строкой «Категория: … · изменить»; чипы — только
              // для своего варианта (категорию не определить) или по «изменить».
              if (_categoryMode == _CategoryMode.line)
                FieldAnchor(
                  scroller: _fields,
                  name: 'categoryId',
                  child: Text.rich(
                    key: const Key('postCargoCategoryLine'),
                    TextSpan(
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      children: [
                        TextSpan(text: '${t.postCargoCategoryLine(refData.cargoCategories.where((c) => c.id == _categoryId).firstOrNull?.name.forLanguageCode(locale) ?? '')} · '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: InkWell(
                            key: const Key('postCargoCategoryChange'),
                            onTap: () => setState(() => _categoryExpanded = true),
                            child: Text(t.postCargoCategoryChange, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_categoryMode == _CategoryMode.chips) ...[
                Text(t.postCargoCategory, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 8),
                FieldAnchor(scroller: _fields, name: 'categoryId', child: Wrap(
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
                          // Выбор по «изменить» — чипы снова сворачиваются в строку.
                          _categoryExpanded = false;
                        }),
                      ),
                  ],
                )),
                if (_categoryError != null) ...[
                  const SizedBox(height: 4),
                  Text(_categoryError!, key: const Key('postCargoCategoryError'), style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.error)),
                ],
              ],
              const SizedBox(height: 12),
              FieldAnchor(scroller: _fields, name: 'bodyTypeId', child: DropdownButtonFormField<String>(
                key: const Key('postCargoBodyType'),
                initialValue: _bodyTypeId,
                decoration: InputDecoration(labelText: t.postCargoBodyType, border: const OutlineInputBorder(), errorText: _bodyTypeError),
                items: refData.bodyTypes
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name.forLanguageCode(locale))))
                    .toList(),
                onChanged: (value) => setState(() {
                  _bodyTypeId = value;
                  _bodyTypeError = null;
                  _specs = {};
                }),
              )),
              const SizedBox(height: 12),
              // 048 п.4: поля груза по профилю выбранного кузова (продукт и литры,
              // тип контейнера, число машин…) и другие подходящие кузова.
              if (_bodyTypeId != null && refData.bodyTypeById(_bodyTypeId!).cargoFields.isNotEmpty) ...[
                Text(t.cargoSpecsTitle, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 8),
                FieldAnchor(scroller: _fields, name: 'specs', child: SpecsForm(
                  key: ValueKey('cargoSpecs-$_bodyTypeId'),
                  showRequired: _showSpecsRequired,
                  fields: refData.bodyTypeById(_bodyTypeId!).cargoFields,
                  values: _specs,
                  onChanged: (v) {
                    setState(() => _specs = v);
                    _refreshFitCount();
                  },
                )),
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
                    child: FieldAnchor(scroller: _fields, name: 'volumeM3', child: AppTextField(
                      key: const Key('postCargoVolume'),
                      focusNode: _fields.focusOf('volumeM3'),
                      label: t.postCargoVolume,
                      controller: _volumeController,
                      errorText: _volumeError(t),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) {
                        setState(() {});
                        _refreshFitCount();
                      },
                    )),
                  ),
                ],
              ),
              if (_showVolume(refData)) const SizedBox(height: 12),
              FieldAnchor(scroller: _fields, name: 'weightKg', child: _weightField(t)),
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
              FieldAnchor(scroller: _fields, name: 'trucksNeeded', child: AppTextField(
                key: const Key('postCargoTrucks'),
                      focusNode: _fields.focusOf('trucksNeeded'),
                label: t.postCargoTrucks,
                controller: _trucksController,
                errorText: _trucksError(t),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              )),
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
              // 063, эталон 34: «Оплата» — стоимость всей суммой, когда и как платите,
              // ниже отдельно — аванс при погрузке (необязательно).
              Text(t.postCargoPaymentTitle, style: AppTextStyles.bodyStrong),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FieldAnchor(scroller: _fields, name: 'price', child: AppTextField(
                      key: const Key('postCargoPrice'),
                      focusNode: _fields.focusOf('price'),
                      label: t.postCargoPriceTotal,
                      errorText: _priceError,
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      // Цена за км под расстоянием пересчитывается на ходу; 072: ошибка уходит при вводе.
                      onChanged: (_) => setState(() => _priceError = null),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Currency>(
                      // 360 dp и крупный шрифт: код валюты не вылезает за поле.
                      isExpanded: true,
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
              Text(t.postCargoWhenPay, style: AppTextStyles.caption),
              const SizedBox(height: 4),
              _PaySegments(
                options: [
                  (const Key('postCargoRestNow'), t.paymentWhenAfterUnload, !_restLater, () => setState(() => _restLater = false)),
                  (const Key('postCargoRestLater'), t.paymentWhenLater, _restLater, () => setState(() => _restLater = true)),
                ],
              ),
              if (_restLater) ...[
                const SizedBox(height: 8),
                FieldAnchor(scroller: _fields, name: 'paymentDelayDays', child: AppTextField(
                  key: const Key('postCargoPaymentDelay'),
                      focusNode: _fields.focusOf('paymentDelayDays'),
                  label: t.postCargoWhenPay,
                  suffixText: t.postCargoDaysAfterUnload,
                  controller: _delayController,
                  errorText: _delayError(t),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                )),
              ],
              const SizedBox(height: 12),
              Text(t.postCargoHowPay, style: AppTextStyles.caption),
              const SizedBox(height: 4),
              _PaySegments(
                options: [
                  for (final form in PaymentForm.values)
                    (Key('postCargoPaymentForm-${form.name}'), paymentFormLabel(t, form), _paymentForm == form, () => setState(() => _paymentForm = _paymentForm == form ? null : form)),
                ],
              ),
              const Divider(height: 32),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: t.postCargoAdvanceTitle),
                  TextSpan(text: ' ${t.postCargoOptional}', style: AppTextStyles.small.copyWith(color: AppColors.textSecondary)),
                ]),
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 4),
              FieldAnchor(scroller: _fields, name: 'advanceAmount', child: AppTextField(
                key: const Key('postCargoAdvance'),
                      focusNode: _fields.focusOf('advanceAmount'),
                label: t.postCargoAdvanceTitle,
                suffixText: currencySymbol(_currency),
                controller: _advanceController,
                errorText: _advanceError(t),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              )),
              if (_advanceHint(t) case final hint?) ...[
                const SizedBox(height: 8),
                Container(
                  key: const Key('postCargoAdvanceHint'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                  child: Text(hint, style: AppTextStyles.caption.copyWith(color: AppColors.text)),
                ),
              ],
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
                          child: CachedPhoto(url, size: 88),
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
              if (_needsPhone) ...[
                const SizedBox(height: 16),
                FieldAnchor(scroller: _fields, name: 'contactPhone', child: AppTextField(
                  key: const Key('postCargoContactPhone'),
                      focusNode: _fields.focusOf('contactPhone'),
                  label: t.postCargoContactPhone,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  errorText: _phoneError,
                  onChanged: (_) => setState(() => _phoneError = null),
                )),
                const SizedBox(height: 4),
                Text(t.postCargoContactPhoneHint, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                key: const Key('postCargoSubmit'),
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

/// 055: единица ввода веса — на устройстве логиста.
final weightUnitStoreProvider = Provider((ref) => WeightUnitStore());

/// 056 п.3: дата погрузки повторённого груза — сегодня; после 18:00 — завтра.
DateTime repeatReadyDate(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return now.hour >= 18 ? today.add(const Duration(days: 1)) : today;
}


/// 063, эталон 34: переключатель на сером фоне, выбранный — белой плашкой.
class _PaySegments extends StatelessWidget {
  const _PaySegments({required this.options});

  final List<(Key, String, bool, VoidCallback)> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.divider.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (final (key, label, selected, onTap) in options)
            Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                child: InkWell(
                  key: key,
                  borderRadius: BorderRadius.circular(10),
                  onTap: onTap,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: selected ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))] : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: selected ? AppTextStyles.bodyStrong : AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _CategoryMode { hidden, line, chips }
