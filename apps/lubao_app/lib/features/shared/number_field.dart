/// Пределы размеров машины — те же, что проверяет сервер (CreateVehicleDto).
abstract final class VehicleLimits {
  static const double lengthM = 25;
  static const double capacityTons = 80;
  static const double innerLengthM = 20;
  static const double innerWidthM = 3;
  static const double innerHeightM = 4.5;
}

// Разбор и текст ошибки числа — parseDecimal / numberFieldError из lubao_core.
