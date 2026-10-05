/// Один звонок/WhatsApp, который не удалось записать на сервер сразу
/// (задача 029, п.14 — обычно нет сети на границе). Хранится локально до
/// следующей успешной попытки, см. [ContactEventQueue].
class PendingContactEvent {
  const PendingContactEvent({
    required this.driverId,
    required this.companyId,
    this.cargoId,
    this.dealId,
    required this.type,
  });

  final String driverId;
  final String companyId;
  final String? cargoId;
  final String? dealId;
  final String type;

  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        'companyId': companyId,
        if (cargoId != null) 'cargoId': cargoId,
        if (dealId != null) 'dealId': dealId,
        'type': type,
      };

  factory PendingContactEvent.fromJson(Map<String, dynamic> json) => PendingContactEvent(
        driverId: json['driverId'] as String,
        companyId: json['companyId'] as String,
        cargoId: json['cargoId'] as String?,
        dealId: json['dealId'] as String?,
        type: json['type'] as String,
      );
}
