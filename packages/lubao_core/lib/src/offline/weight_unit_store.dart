import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/cargo_weight.dart';

/// 055: единица ввода веса, выбранная логистом, — на устройстве. По умолчанию кг.
class WeightUnitStore {
  WeightUnitStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'lubao.cargoWeightUnit';

  Future<WeightUnit> load() async {
    try {
      return await _storage.read(key: _key) == 't' ? WeightUnit.t : WeightUnit.kg;
    } catch (_) {
      return WeightUnit.kg;
    }
  }

  Future<void> save(WeightUnit unit) async {
    try {
      await _storage.write(key: _key, value: unit == WeightUnit.t ? 't' : 'kg');
    } catch (_) {
      // не критично: в следующий раз — по умолчанию кг
    }
  }
}
