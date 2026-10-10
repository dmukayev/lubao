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
    case DealStatus.cancelRequested:
      return (t.dealStatusCancelRequested, StatusBadge.warning);
    case DealStatus.disputed:
      return (t.dealStatusDisputed, StatusBadge.danger);
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
    case 'CANCEL_REQUESTED':
      return t.dealStatusCancelRequested;
    case 'DISPUTED':
      return t.dealStatusDisputed;
    default:
      return status;
  }
}

String cargoStatusLabel(LubaoLocalizations t, String status) {
  switch (status) {
    case 'PUBLISHED':
      return t.cargoStatusPublished;
    case 'IN_DEAL':
      return t.cargoStatusInDeal;
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

String responseStatusLabel(LubaoLocalizations t, String status) {
  switch (status) {
    case 'PENDING':
      return t.responseStatusPending;
    case 'SELECTED':
      return t.responseStatusSelected;
    case 'REJECTED':
      return t.responseStatusRejected;
    case 'CANCELLED':
      return t.responseStatusCancelled;
    default:
      return status;
  }
}

String complaintResolutionLabel(LubaoLocalizations t, String resolution) {
  switch (resolution) {
    case 'DISMISSED':
      return t.adminComplaintResolutionDismissed;
    case 'WARNED':
      return t.adminComplaintResolutionWarned;
    case 'CARGO_UNPUBLISHED':
      return t.adminComplaintResolutionCargoUnpublished;
    case 'BLOCKED':
      return t.adminComplaintResolutionBlocked;
    default:
      return resolution;
  }
}

String cancelledByRoleLabel(LubaoLocalizations t, String role) {
  switch (role) {
    case 'DRIVER':
      return t.roleDriver;
    case 'COMPANY':
      return t.roleCompany;
    case 'ADMIN':
      return t.roleAdmin;
    default:
      return role;
  }
}

/// Код действия audit_log → читаемый текст (задача 029, п.19 — карточки
/// показывали сырой код типа `DRIVER_RETURNED_FOR_REWORK`).
String auditActionLabel(LubaoLocalizations t, String action) {
  switch (action) {
    case 'ADMIN_VIEWED_CHAT':
      return t.adminAuditActionAdminViewedChat;
    case 'CARGO_UNPUBLISHED':
      return t.adminAuditActionCargoUnpublished;
    case 'CARGO_UPDATED':
      return t.adminAuditActionCargoUpdated;
    case 'CITY_UPDATED':
      return t.adminAuditActionCityUpdated;
    case 'COMPANY_BLOCKED':
      return t.adminAuditActionCompanyBlocked;
    case 'COMPANY_MEMBER_EMAIL_CHANGED':
      return t.adminAuditActionCompanyMemberEmailChanged;
    case 'COMPANY_MEMBER_REMOVED':
      return t.adminAuditActionCompanyMemberRemoved;
    case 'COMPANY_MEMBER_ROLE_CHANGED':
      return t.adminAuditActionCompanyMemberRoleChanged;
    case 'COMPANY_PASSWORD_RESET':
      return t.adminAuditActionCompanyPasswordReset;
    case 'COMPANY_RETURNED_FOR_REWORK':
      return t.adminAuditActionCompanyReturnedForRework;
    case 'COMPANY_UNBLOCKED':
      return t.adminAuditActionCompanyUnblocked;
    case 'COMPANY_UNVERIFIED':
      return t.adminAuditActionCompanyUnverified;
    case 'COMPANY_UPDATED':
      return t.adminAuditActionCompanyUpdated;
    case 'COMPANY_VERIFIED':
      return t.adminAuditActionCompanyVerified;
    case 'COMPLAINT_ASSIGNED':
      return t.adminAuditActionComplaintAssigned;
    case 'COMPLAINT_RESOLVED':
      return t.adminAuditActionComplaintResolved;
    case 'COMPLAINT_UNASSIGNED':
      return t.adminAuditActionComplaintUnassigned;
    case 'DEAL_CANCELLED_BY_ADMIN':
      return t.adminAuditActionDealCancelledByAdmin;
    case 'DEAL_STATUS_FIXED':
      return t.adminAuditActionDealStatusFixed;
    case 'DRIVER_RETURNED_FOR_REWORK':
      return t.adminAuditActionDriverReturnedForRework;
    case 'DRIVER_UNVERIFIED':
      return t.adminAuditActionDriverUnverified;
    case 'DRIVER_UPDATED':
      return t.adminAuditActionDriverUpdated;
    case 'DRIVER_VERIFIED':
      return t.adminAuditActionDriverVerified;
    case 'POINT_UPDATED':
      return t.adminAuditActionPointUpdated;
    case 'SESSIONS_REVOKED':
      return t.adminAuditActionSessionsRevoked;
    case 'SETTING_CHANGED':
      return t.adminAuditActionSettingChanged;
    case 'USER_BLOCKED':
      return t.adminAuditActionUserBlocked;
    case 'USER_UNBLOCKED':
      return t.adminAuditActionUserUnblocked;
    case 'BODYTYPE_UPDATED':
      return t.adminAuditActionBodyTypeUpdated;
    case 'PERMIT_UPDATED':
      return t.adminAuditActionPermitUpdated;
    default:
      return action;
  }
}

/// Имя изменённого поля в `metadata.changes` → читаемый текст (та же
/// задача). Непредусмотренный ключ — показываем как есть, не прячем.
String auditFieldLabel(LubaoLocalizations t, String field) {
  switch (field) {
    case 'destinationCountryId':
      return t.adminAuditFieldDestinationCountry;
    case 'destinationCityId':
      return t.adminAuditFieldDestinationCity;
    case 'bodyTypeId':
      return t.adminAuditFieldBodyType;
    case 'weightKg':
      return t.adminAuditFieldWeight;
    case 'volumeM3':
      return t.adminAuditFieldVolume;
    case 'photoUrls':
      return t.adminAuditFieldPhotos;
    case 'price':
      return t.adminAuditFieldPrice;
    case 'currency':
      return t.adminAuditFieldCurrency;
    case 'readyDate':
      return t.adminAuditFieldReadyDate;
    case 'description':
      return t.adminAuditFieldDescription;
    case 'name':
      return t.adminAuditFieldName;
    case 'nameRu':
      return t.adminAuditFieldNameRu;
    case 'countryId':
      return t.adminAuditFieldCountry;
    case 'city':
      return t.adminAuditFieldCity;
    case 'legalAddress':
      return t.adminAuditFieldLegalAddress;
    case 'taxId':
      return t.adminAuditFieldTaxId;
    case 'fullName':
      return t.adminAuditFieldFullName;
    case 'phone':
      return t.adminAuditFieldPhone;
    case 'homeCityId':
      return t.adminAuditFieldHomeCity;
    case 'anyCountry':
      return t.adminAuditFieldAnyCountry;
    case 'countryIds':
      return t.adminAuditFieldCountries;
    case 'permitIds':
      return t.adminAuditFieldPermits;
    case 'vehicle':
      return t.adminAuditFieldVehicle;
    case 'plateNumber':
      return t.adminAuditFieldPlateNumber;
    case 'capacityTons':
      return t.adminAuditFieldCapacity;
    case 'lengthM':
      return t.adminAuditFieldLength;
    case 'brand':
      return t.adminAuditFieldBrand;
    case 'isActive':
      return t.adminAuditFieldIsActive;
    case 'sortOrder':
      return t.adminAuditFieldSortOrder;
    default:
      return field;
  }
}

/// Значение в «было → стало» — `null`/список/bool в читаемом виде, не
/// Dart-представление объекта.
String formatAuditValue(LubaoLocalizations t, dynamic value) {
  if (value == null) return '—';
  if (value is bool) return value ? t.commonYes : t.commonNo;
  if (value is List) return value.isEmpty ? '—' : value.join(', ');
  return value.toString();
}

String contactEventTypeLabel(LubaoLocalizations t, String type) {
  switch (type) {
    case 'CALL':
      return t.adminContactEventCall;
    case 'WHATSAPP':
      return t.adminContactEventWhatsapp;
    default:
      return type;
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

/// Как везде (058 п.4: «1 250 000 ₽», «95 000 000 сум»).
String formatMoney(double price, Currency currency) => formatCurrencyAmount(price, currency);

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
