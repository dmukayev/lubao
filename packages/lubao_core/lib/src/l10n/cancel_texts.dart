import '../models/common.dart';
import 'generated/lubao_localizations.dart';

/// Тексты отмены сделки (046): причина по коду, этап, «отменил 1 из 15 ·
/// после загрузки 1». Общие для приложения и админки.
String cancelReasonLabel(LubaoLocalizations t, String? code, {String? text}) {
  switch (code) {
    case 'VEHICLE_BREAKDOWN':
      return t.cancelReasonVehicleBreakdown;
    case 'CARGO_NOT_READY':
      return t.cancelReasonCargoNotReady;
    case 'OTHER_PARTY_UNRESPONSIVE':
      return t.cancelReasonOtherPartyUnresponsive;
    case 'TERMS_CHANGED':
      return t.cancelReasonTermsChanged;
    case 'TOOK_OTHER_CARGO':
      return t.dealCancelReasonTookAnother;
    default:
      return (text != null && text.trim().isNotEmpty) ? text.trim() : t.cancelReasonOther;
  }
}

String? cancelStageLabel(LubaoLocalizations t, String? stage) => switch (stage) {
      'BEFORE_CONFIRM' => t.cancelStageBeforeConfirm,
      'AFTER_CONFIRM' => t.cancelStageAfterConfirm,
      'AFTER_LOAD' => t.cancelStageAfterLoad,
      'IN_TRANSIT' => t.cancelStageInTransit,
      _ => null,
    };

/// `null` — отмен нет, строку не показываем.
String? cancelStatsText(LubaoLocalizations t, CancelStats? stats) {
  if (stats == null || stats.cancelled == 0) return null;
  final parts = [t.cancelStatsLine(stats.cancelled, stats.total)];
  if (stats.afterLoad > 0) parts.add(t.cancelStatsAfterLoad(stats.afterLoad));
  return parts.join(' · ');
}
