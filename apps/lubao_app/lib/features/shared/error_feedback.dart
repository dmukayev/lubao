import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import 'status_helpers.dart';

/// Единый обработчик ошибок API (041 п.7, 074): ошибки полей (072) и
/// конфликты откликов — своим разбором, остальное — общей функцией
/// `apiErrorText` (lubao_core): нет сети / таймаут → код сервера → вид ответа →
/// «Что-то пошло не так» с номером ошибки. [fallback] — свой текст вместо
/// последнего (например, «Не удалось загрузить фото»).
String errorMessage(LubaoLocalizations t, Object error, {String? fallback}) {
  if (error is DioException && error.response != null) {
    final data = error.response!.data;
    final code = data is Map ? data['code'] : null;
    final status = error.response!.statusCode;
    if (code == 'VALIDATION_FAILED' || code == 'INVALID_SPECS' || ((status == 400 || status == 422) && code == null)) {
      final fields = validationErrorText(t, data);
      if (fields != null) return fields;
    }
    final coded = responseConflictText(t, error);
    if (coded != null) return coded;
  }
  final text = apiErrorText(t, error);
  return fallback != null && (text == t.commonError || text.startsWith(t.errUnknownWithId('').trim())) ? fallback : text;
}

/// SnackBar с понятной причиной; при [onRetry] — кнопка «Повторить».
void showApiError(BuildContext context, Object error, {String? fallback, VoidCallback? onRetry}) {
  if (!context.mounted) return;
  final t = context.l10n;
  debugPrint('API error: $error');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(errorMessage(t, error, fallback: fallback)),
    // С кнопкой Flutter не убирает SnackBar сам (persist) — висел до нажатия.
    persist: false,
    action: onRetry == null ? null : SnackBarAction(label: t.commonRetry, onPressed: onRetry),
  ));
}

/// Поле → подпись на языке пользователя (как в форме).
String? _fieldLabel(LubaoLocalizations t, String field) => switch (field.split('.').last) {
      'innerLengthM' => t.garageSizeLength,
      'innerWidthM' => t.garageSizeWidth,
      'innerHeightM' => t.garageSizeHeight,
      'lengthM' => t.garageLength,
      'capacityTons' => t.driverSetupCapacity,
      'vin' => t.garageVin,
      'weightKg' => t.postCargoWeight,
      'volumeM3' => t.postCargoVolume,
      'palletCount' => t.postCargoPallets,
      'price' => t.postCargoPrice,
      'description' => t.postCargoDescription,
      'fullName' => t.driverSetupFullName,
      _ => null,
    };

/// 072: ответ сервера `VALIDATION_FAILED` → текст ошибки для каждого поля
/// (по имени поля сервера) — форма покажет его под полем и прокрутит к нему.
Map<String, String> serverFieldErrors(LubaoLocalizations t, Object error) {
  final data = error is DioException ? error.response?.data : null;
  if (data is! Map || data['fields'] is! List) return const {};
  final out = <String, String>{};
  for (final raw in data['fields'] as List) {
    if (raw is! Map || raw['field'] == null) continue;
    final text = validationErrorText(t, {...data, 'fields': [raw]});
    if (text != null) out[raw['field'].toString().split('.').last] = text;
  }
  return out;
}

/// Ответ сервера `VALIDATION_FAILED` (поле, правило, предел) → «Длина внутри,
/// м — не больше 20». Поле без подписи — null (общий текст).
String? validationErrorText(LubaoLocalizations t, Object? data) {
  if (data is! Map || (data['code'] != 'VALIDATION_FAILED' && data['code'] != 'INVALID_SPECS') || data['fields'] is! List) return null;
  final lang = t.localeName.split('_').first;
  for (final raw in data['fields'] as List) {
    if (raw is! Map) continue;
    // Поле кузова (INVALID_SPECS) — подпись из справочника на языке пользователя.
    final serverLabel = raw['label'] is Map ? I18nText.fromJson(Map<String, dynamic>.from(raw['label'] as Map)).forLanguageCode(lang) : null;
    final label = (serverLabel != null && serverLabel.isNotEmpty ? serverLabel : null) ?? _fieldLabel(t, raw['field']?.toString() ?? '');
    if (label == null) continue;
    final limit = raw['limit'] is num ? formatLimit((raw['limit'] as num).toDouble()) : null;
    return switch (raw['rule']) {
      'max' when limit != null => t.errorFieldMax(label, limit),
      'min' when limit != null => t.errorFieldMin(label, limit),
      'maxLength' when limit != null => t.errorFieldMaxLength(label, limit),
      'required' => t.errorFieldRequired(label),
      _ => t.errorFieldInvalid(label),
    };
  }
  return null;
}
