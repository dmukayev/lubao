import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

/// Карточка водителя в админке падала с «Что-то пошло не так» при переходе
/// из списка «Водители»: `AdminDriverVehicle.bodyTypeName` требовался
/// non-null, а тип кузова есть только у прицепа (задача 031, этап A) — у
/// тягача/одиночки сервер шлёт `bodyTypeName: null`, и `I18nText.fromJson`
/// падал с `type 'Null' is not a subtype of type 'Map<String, dynamic>'`.
/// Найдено живой проверкой в браузере, не юнит-тестами — этот файл закрывает
/// дыру в покрытии на уровне парсинга JSON (widget-тесты конструируют Dart-
/// объекты напрямую и не ловят баги именно в fromJson).
void main() {
  group('AdminDriverVehicle.fromJson — тягач без типа кузова (задача 031)', () {
    test('parses a TRACTOR vehicle where bodyTypeId/bodyTypeName are both null', () {
      final vehicle = AdminDriverVehicle.fromJson({
        'id': 'v1',
        'kind': 'TRACTOR',
        'bodyTypeId': null,
        'bodyTypeName': null,
        'capacityTons': null,
        'lengthM': null,
        'plateNumber': '1234 AB-7',
        'vin': null,
        'brand': 'MAZ',
      });

      expect(vehicle.bodyTypeName, isNull);
      expect(vehicle.brand, 'MAZ');
      expect(vehicle.plateNumber, '1234 AB-7');
    });

    test('still parses a TRAILER vehicle with a real bodyTypeName', () {
      final vehicle = AdminDriverVehicle.fromJson({
        'id': 'v2',
        'kind': 'TRAILER',
        'bodyTypeId': 'bt1',
        'bodyTypeName': {'ru': 'Автовоз', 'kk': 'Автотасығыш', 'zh': '汽车运输车'},
        'capacityTons': 16,
        'lengthM': 13.6,
        'plateNumber': null,
        'vin': null,
        'brand': null,
      });

      expect(vehicle.bodyTypeName?.ru, 'Автовоз');
    });
  });

  group('AdminDriverRow.fromJson — та же дыра в строке списка водителей', () {
    test('parses a driver row whose vehicle has no body type', () {
      final row = AdminDriverRow.fromJson({
        'id': 'd1',
        'fullName': 'Виктор Ковалёв',
        'phone': '+375291234567',
        'homeCityName': {'ru': 'Минск', 'kk': 'Минск', 'zh': '明斯克'},
        'vehicle': {'bodyTypeName': null, 'capacityTons': null},
        'isVerified': true,
        'pendingDocsCount': 0,
        'ratingAvg': 0,
        'ratingCount': 0,
        'completedDeals': 0,
        'isBlocked': false,
        'registeredAt': '2026-10-01T00:00:00.000Z',
      });

      expect(row.vehicleBodyTypeName, isNull);
    });

    test('still parses a row whose vehicle has a real body type', () {
      final row = AdminDriverRow.fromJson({
        'id': 'd2',
        'fullName': 'Нурбек Асанов',
        'phone': null,
        'homeCityName': {'ru': 'Бишкек', 'kk': 'Бішкек', 'zh': '比什凯克'},
        'vehicle': {
          'bodyTypeName': {'ru': 'Изотермический', 'kk': 'Изотермиялық', 'zh': '保温车'},
          'capacityTons': 10,
        },
        'isVerified': false,
        'pendingDocsCount': 1,
        'ratingAvg': 0,
        'ratingCount': 0,
        'completedDeals': 0,
        'isBlocked': false,
        'registeredAt': '2026-10-01T00:00:00.000Z',
      });

      expect(row.vehicleBodyTypeName?.ru, 'Изотермический');
    });
  });
}
