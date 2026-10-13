import 'package:dio/dio.dart';

import '../l10n/generated/lubao_localizations.dart';
import 'auth_error_text.dart';

// 074: текст ошибки по коду сервера (backend/src/common/error-codes.ts →
// USER_ERROR_CODES). Список кодов и ключи ARB проверяет тест
// error_codes_arb_test.dart — новый код без текста не пройдёт CI.

/// Текст по коду сервера; неизвестный код — null.
String? errorCodeText(LubaoLocalizations t, String code) => switch (code) {
  'BAD_REQUEST' => t.errBadRequest,
  'SESSION_EXPIRED' => t.errSessionExpired,
  'FORBIDDEN' => t.errForbidden,
  'NOT_FOUND' => t.errNotFound,
  'CONFLICT' => t.errConflict,
  'FILE_TOO_LARGE' => t.errFileTooLarge,
  'RATE_LIMITED' => t.errRateLimited,
  'SERVER_ERROR' => t.errServerError,
  'NOT_DRIVER_ACCOUNT' => t.errNotDriverAccount,
  'NOT_COMPANY_ACCOUNT' => t.errNotCompanyAccount,
  'ACCOUNT_BLOCKED' => t.errAccountBlocked,
  'ALREADY_COMPANY_MEMBER' => t.errAlreadyCompanyMember,
  'EMAIL_TAKEN' => t.errEmailTaken,
  'INVITATION_EXPIRED' => t.errInvitationExpired,
  'LINK_EXPIRED' => t.errLinkExpired,
  'PD_CONSENT_REQUIRED' => t.errPdConsentRequired,
  'TELEGRAM_DISABLED' => t.errTelegramDisabled,
  'NONCE_EXPIRED' => t.errNonceExpired,
  'NONCE_USED' => t.errNonceUsed,
  'INVALID_CREDENTIALS' => t.errInvalidCredentials,
  'LOCKED_OUT' => t.errLockedOut,
  'INVALID_CODE' => t.errInvalidCode,
  'CODE_EXPIRED' => t.errCodeExpired,
  'CODE_ATTEMPTS_EXCEEDED' => t.errCodeAttemptsExceeded,
  'PHONE_OTHER_ROLE' => t.errPhoneOtherRole,
  'TOO_MANY_REQUESTS' => t.errTooManyRequests,
  'CARGO_NOT_FOUND' => t.errCargoNotFound,
  'DRIVER_NOT_FOUND' => t.errDriverNotFound,
  'DEAL_NOT_FOUND' => t.errDealNotFound,
  'COMPANY_NOT_FOUND' => t.errCompanyNotFound,
  'RESPONSE_NOT_FOUND' => t.errResponseNotFound,
  'DOCUMENT_NOT_FOUND' => t.errDocumentNotFound,
  'VEHICLE_NOT_FOUND' => t.errVehicleNotFound,
  'USER_NOT_FOUND' => t.errUserNotFound,
  'PHOTO_NOT_FOUND' => t.errPhotoNotFound,
  'CITY_NOT_FOUND' => t.errCityNotFound,
  'COMPLAINT_NOT_FOUND' => t.errComplaintNotFound,
  'MEMBER_NOT_FOUND' => t.errMemberNotFound,
  'LINK_NOT_FOUND' => t.errLinkNotFound,
  'ARRIVAL_NOT_FOUND' => t.errArrivalNotFound,
  'POINT_NOT_FOUND' => t.errPointNotFound,
  'CHAT_NOT_FOUND' => t.errChatNotFound,
  'NOT_YOUR_CARGO' => t.errNotYourCargo,
  'NOT_YOUR_RESPONSE' => t.errNotYourResponse,
  'NOT_YOUR_DEAL' => t.errNotYourDeal,
  'COMPANY_ONLY' => t.errCompanyOnly,
  'NOT_VERIFIED' => t.errNotVerified,
  'DRIVER_NOT_VERIFIED' => t.errDriverNotVerified,
  'COMPANY_NOT_VERIFIED' => t.errCompanyNotVerified,
  'CARGO_NOT_AVAILABLE' => t.errCargoNotAvailable,
  'CARGO_NOT_PUBLISHED' => t.errCargoNotPublished,
  'CARGO_TAKEN' => t.errCargoTaken,
  'CARGO_ALREADY_HAS_DEAL' => t.errCargoAlreadyHasDeal,
  'CARGO_CREATE_IN_PROGRESS' => t.errCargoCreateInProgress,
  'POINT_REQUIRED' => t.errPointRequired,
  'CATEGORY_REQUIRED' => t.errCategoryRequired,
  'BODY_TYPE_REQUIRED' => t.errBodyTypeRequired,
  'CONTACT_PHONE_REQUIRED' => t.errContactPhoneRequired,
  'COMPANY_ACTIVE_LIMIT' => t.errCompanyActiveLimit,
  'COMPANY_PAUSED' => t.errCompanyPaused,
  'CURRENCY_LOCKED' => t.errCurrencyLocked,
  'PRICE_CHANGED' => t.errPriceChanged,
  'RESPONSE_NOT_PENDING' => t.errResponseNotPending,
  'RESPONSE_ALREADY_EXISTS' => t.errResponseAlreadyExists,
  'COUNTER_ALREADY_SENT' => t.errCounterAlreadySent,
  'COUNTER_PENDING' => t.errCounterPending,
  'NO_DRIVER_PRICE' => t.errNoDriverPrice,
  'NO_PENDING_COUNTER' => t.errNoPendingCounter,
  'INVALID_BODY_FIELDS' => t.errInvalidBodyFields,
  'BODY_HAS_NO_SIZE' => t.errBodyHasNoSize,
  'VEHICLE_FULL' => t.errVehicleFull,
  'VEHICLE_REQUIRED' => t.errVehicleRequired,
  'DEAL_CANNOT_CANCEL' => t.errDealCannotCancel,
  'DEAL_STATUS_CHANGED' => t.errDealStatusChanged,
  'CANCEL_ALREADY_REQUESTED' => t.errCancelAlreadyRequested,
  'NO_CANCEL_REQUEST' => t.errNoCancelRequest,
  'OWN_CANCEL_REQUEST' => t.errOwnCancelRequest,
  'NO_DISPUTE' => t.errNoDispute,
  'REASON_REQUIRED' => t.errReasonRequired,
  'REASON_NOT_ALLOWED' => t.errReasonNotAllowed,
  'REASON_TEXT_REQUIRED' => t.errReasonTextRequired,
  'ACTIVE_DEALS' => t.errActiveDeals,
  'DOCS_EXPIRED' => t.errDocsExpired,
  'DOCS_NOT_YET' => t.errDocsNotYet,
  'COMPLAINT_ALREADY_OPEN' => t.errComplaintAlreadyOpen,
  'TOO_MANY_ARRIVALS' => t.errTooManyArrivals,
  'TERMINAL_NEEDS_GEOFENCE' => t.errTerminalNeedsGeofence,
  'RESPOND_FIRST' => t.errRespondFirst,
  'CONTACT_LIMIT' => t.errContactLimit,
  'NO_PHONE' => t.errNoPhone,
  'CREATE_DRIVER_LIMIT' => t.errCreateDriverLimit,
  'DRIVER_LEFT_LIST' => t.errDriverLeftList,
  'DRIVER_BLACKLISTED' => t.errDriverBlacklisted,
  'BLACKLIST_MATCH' => t.errBlacklistMatch,
  'OWNER_HAS_MEMBERS' => t.errOwnerHasMembers,
  'NO_LICENSE_NAME' => t.errNoLicenseName,
  'NO_APPROVED_SELFIE' => t.errNoApprovedSelfie,
  'NO_INVITATION' => t.errNoInvitation,
  'IDENTIFIER_INVALID' => t.errIdentifierInvalid,
  'IMAGE_TOO_LARGE' => t.errImageTooLarge,
  'INVALID_IMAGE' => t.errInvalidImage,
  'INVALID_FILE' => t.errInvalidFile,
  'UNSUPPORTED_IMAGE_FORMAT' => t.errUnsupportedImageFormat,
  'UPLOAD_QUOTA_EXCEEDED' => t.errUploadQuotaExceeded,
  _ => null,
};

/// Номер ошибки из ответа сервера (requestId) — назвать поддержке.
String? errorRequestId(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  return data is Map ? data['requestId'] as String? : null;
}

/// 074: понятная причина ошибки запроса. Порядок: нет сети / таймаут → код
/// сервера (свой текст) → вид ответа (401, 403, 404, 409, 413, 429, 5xx) →
/// только если ничего не подошло — «Что-то пошло не так» с номером ошибки.
/// Ошибки полей (VALIDATION_FAILED, INVALID_SPECS) разбирает вызывающий (072).
String apiErrorText(LubaoLocalizations t, Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return t.errTimeout;
      case DioExceptionType.connectionError:
        return t.errNoInternet;
      case DioExceptionType.unknown:
        // Без dart:io (веб): нет сети на телефоне — SocketException внутри.
        if ('${error.error.runtimeType}' == 'SocketException') return t.errNoInternet;
      default:
        break;
    }
    final data = error.response?.data;
    final code = data is Map ? data['code'] as String? : null;
    if (code == 'LOCKED_OUT') return authErrorText(t, error)!;
    if (code != null) {
      final text = errorCodeText(t, code);
      if (text != null) return text;
    }
    final status = error.response?.statusCode;
    final byStatus = switch (status) {
      401 => t.errSessionExpired,
      403 => t.errForbidden,
      404 => t.errNotFound,
      409 => t.errConflict,
      413 => t.errFileTooLarge,
      429 => t.errRateLimited,
      _ => status != null && status >= 500 ? t.errServerError : null,
    };
    if (byStatus != null) return byStatus;
  }
  final id = errorRequestId(error);
  return id == null ? t.commonError : t.errUnknownWithId(id);
}
