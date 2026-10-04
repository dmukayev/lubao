import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

(String, Color) dealStatusPresentation(LubaoLocalizations t, DealStatus status) {
  switch (status) {
    case DealStatus.selected:
      return (t.dealStatusSelected, StatusBadge.info);
    case DealStatus.confirmedByDriver:
      return (t.dealStatusConfirmed, StatusBadge.info);
    case DealStatus.loaded:
      return (t.dealStatusLoaded, StatusBadge.warning);
    case DealStatus.inTransit:
      return (t.dealStatusInTransit, StatusBadge.warning);
    case DealStatus.delivered:
      return (t.dealStatusDelivered, StatusBadge.success);
    case DealStatus.cancelled:
      return (t.dealStatusCancelled, StatusBadge.danger);
  }
}

/// Статус сделки по сырому коду с бэкенда (задача 028 — таблицы /deals,
/// /cargos получают строковый enum, не типизированный `DealStatus`).
String dealStatusLabel(LubaoLocalizations t, String status) {
  switch (status) {
    case 'SELECTED':
      return t.dealStatusSelected;
    case 'CONFIRMED_BY_DRIVER':
      return t.dealStatusConfirmed;
    case 'LOADED':
      return t.dealStatusLoaded;
    case 'IN_TRANSIT':
      return t.dealStatusInTransit;
    case 'DELIVERED':
      return t.dealStatusDelivered;
    case 'CANCELLED':
      return t.dealStatusCancelled;
    default:
      return status;
  }
}

String cargoStatusLabel(LubaoLocalizations t, String status) {
  switch (status) {
    case 'PUBLISHED':
      return t.cargoStatusPublished;
    case 'ARCHIVED':
      return t.cargoStatusArchived;
    case 'EXPIRED':
      return t.cargoStatusExpired;
    case 'CANCELLED':
      return t.cargoStatusCancelled;
    default:
      return status;
  }
}

/// Тип документа — человекочитаемое название (задача 026, п.3: очередь и
/// карточка не должны показывать сырой код enum). Для 4 водительских типов
/// переиспользуются существующие driverVerification*-ключи; для компании —
/// новые adminDocType*.
String verificationDocTypeLabel(LubaoLocalizations t, String type) {
  switch (type) {
    case 'SELFIE':
      return t.driverVerificationSelfie;
    case 'VEHICLE_PASSPORT':
      return t.driverVerificationVehiclePassport;
    case 'TRAILER_PASSPORT':
      return t.driverVerificationTrailerPassport;
    case 'DRIVER_LICENSE':
      return t.driverVerificationLicense;
    case 'COMPANY_REGISTRATION':
      return t.adminDocTypeCompanyRegistration;
    case 'IDENTITY':
      return t.adminDocTypeIdentity;
    default:
      return t.adminDocTypeOther;
  }
}

(String, Color) verificationStatusPresentation(LubaoLocalizations t, VerificationStatus status) {
  switch (status) {
    case VerificationStatus.pending:
      return (t.driverVerificationStatusPending, StatusBadge.warning);
    case VerificationStatus.approved:
      return (t.driverVerificationStatusApproved, StatusBadge.success);
    case VerificationStatus.rejected:
      return (t.driverVerificationStatusRejected, StatusBadge.danger);
  }
}

String _groupThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-${buffer.toString()}' : buffer.toString();
}

String formatMoney(double price, Currency currency) {
  return '${currencySymbol(currency)}${_groupThousands(price.round())}';
}

String formatAdminDate(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year}';
}

String formatAdminDateTime(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${formatAdminDate(date)} ${two(local.hour)}:${two(local.minute)}';
}
