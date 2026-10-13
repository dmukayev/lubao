/// 074: у каждой ошибки, которую может увидеть пользователь, — код; текст на
/// языке пользователя подставляет приложение (ARB). Источник правды по кодам:
/// этот файл; проверка «у каждого кода есть текст на 4 языках» —
/// error-codes.spec.ts.

/// Ошибки, брошенные текстом (до 074), — код по тексту.
export const MESSAGE_CODES: Record<string, string> = {
  'Not a driver account': 'NOT_DRIVER_ACCOUNT',
  'Not a company account': 'NOT_COMPANY_ACCOUNT',
  'Only company accounts': 'NOT_COMPANY_ACCOUNT',
  'Not a driver or company account': 'FORBIDDEN',
  'Cargo not found': 'CARGO_NOT_FOUND',
  'Driver not found': 'DRIVER_NOT_FOUND',
  'Driver profile not found': 'DRIVER_NOT_FOUND',
  'Deal not found': 'DEAL_NOT_FOUND',
  'Company not found': 'COMPANY_NOT_FOUND',
  'Response not found': 'RESPONSE_NOT_FOUND',
  'Not your cargo': 'NOT_YOUR_CARGO',
  'Not your response': 'NOT_YOUR_RESPONSE',
  'Document not found': 'DOCUMENT_NOT_FOUND',
  'Vehicle not found': 'VEHICLE_NOT_FOUND',
  'User not found': 'USER_NOT_FOUND',
  'Photo not found': 'PHOTO_NOT_FOUND',
  'City not found': 'CITY_NOT_FOUND',
  'Complaint not found': 'COMPLAINT_NOT_FOUND',
  'Member not found': 'MEMBER_NOT_FOUND',
  'Link not found': 'LINK_NOT_FOUND',
  'Arrival not found': 'ARRIVAL_NOT_FOUND',
  'Point not found': 'POINT_NOT_FOUND',
  'Chat not found': 'CHAT_NOT_FOUND',
  'Invalid or expired access token': 'SESSION_EXPIRED',
  'Missing bearer token': 'SESSION_EXPIRED',
  'Session has been revoked or expired': 'SESSION_EXPIRED',
  'Invalid refresh token': 'SESSION_EXPIRED',
  'Refresh token reuse detected': 'SESSION_EXPIRED',
  'User is inactive or blocked': 'ACCOUNT_BLOCKED',
  'User is already a member of a company': 'ALREADY_COMPANY_MEMBER',
  'This deal can no longer be cancelled': 'DEAL_CANNOT_CANCEL',
  'Invite not found or expired': 'INVITATION_EXPIRED',
  'Email already registered': 'EMAIL_TAKEN',
};

/// Нет кода и текст не из таблицы — код по статусу ответа.
export function statusCode(status: number): string {
  if (status >= 500) return 'SERVER_ERROR';
  return (
    { 400: 'BAD_REQUEST', 401: 'SESSION_EXPIRED', 403: 'FORBIDDEN', 404: 'NOT_FOUND', 409: 'CONFLICT', 413: 'FILE_TOO_LARGE', 429: 'RATE_LIMITED' } as Record<number, string>
  )[status] ?? 'BAD_REQUEST';
}

/// Коды, которые приложение показывает пользователю своим текстом (ARB,
/// ключ `err` + код в CamelCase: `CARGO_NOT_FOUND` → `errCargoNotFound`).
export const USER_ERROR_CODES = [
  // общие — по статусу
  'BAD_REQUEST', 'SESSION_EXPIRED', 'FORBIDDEN', 'NOT_FOUND', 'CONFLICT', 'FILE_TOO_LARGE', 'RATE_LIMITED', 'SERVER_ERROR',
  // учётная запись и вход
  'NOT_DRIVER_ACCOUNT', 'NOT_COMPANY_ACCOUNT', 'ACCOUNT_BLOCKED', 'ALREADY_COMPANY_MEMBER', 'EMAIL_TAKEN', 'INVITATION_EXPIRED', 'LINK_EXPIRED',
  'PD_CONSENT_REQUIRED', 'TELEGRAM_DISABLED', 'NONCE_EXPIRED', 'NONCE_USED',
  // 073: вход и код
  'INVALID_CREDENTIALS', 'LOCKED_OUT', 'INVALID_CODE', 'CODE_EXPIRED', 'CODE_ATTEMPTS_EXCEEDED', 'PHONE_OTHER_ROLE', 'TOO_MANY_REQUESTS',
  // не найдено
  'CARGO_NOT_FOUND', 'DRIVER_NOT_FOUND', 'DEAL_NOT_FOUND', 'COMPANY_NOT_FOUND', 'RESPONSE_NOT_FOUND', 'DOCUMENT_NOT_FOUND', 'VEHICLE_NOT_FOUND',
  'USER_NOT_FOUND', 'PHOTO_NOT_FOUND', 'CITY_NOT_FOUND', 'COMPLAINT_NOT_FOUND', 'MEMBER_NOT_FOUND', 'LINK_NOT_FOUND', 'ARRIVAL_NOT_FOUND', 'POINT_NOT_FOUND', 'CHAT_NOT_FOUND',
  // доступ
  'NOT_YOUR_CARGO', 'NOT_YOUR_RESPONSE', 'NOT_YOUR_DEAL', 'COMPANY_ONLY', 'NOT_VERIFIED', 'DRIVER_NOT_VERIFIED', 'COMPANY_NOT_VERIFIED',
  // груз и отклики
  'CARGO_NOT_AVAILABLE', 'CARGO_NOT_PUBLISHED', 'CARGO_TAKEN', 'CARGO_ALREADY_HAS_DEAL', 'CARGO_CREATE_IN_PROGRESS', 'POINT_REQUIRED', 'CATEGORY_REQUIRED',
  'BODY_TYPE_REQUIRED', 'CONTACT_PHONE_REQUIRED', 'COMPANY_ACTIVE_LIMIT', 'COMPANY_PAUSED', 'LATIN_NAME_REQUIRED', 'GOODS_NOT_FOUND', 'HS_CODE_NOT_FOUND', 'CURRENCY_LOCKED', 'PRICE_CHANGED', 'RESPONSE_NOT_PENDING', 'RESPONSE_ALREADY_EXISTS', 'COUNTER_ALREADY_SENT',
  'COUNTER_PENDING', 'NO_DRIVER_PRICE', 'NO_PENDING_COUNTER', 'INVALID_BODY_FIELDS', 'BODY_HAS_NO_SIZE', 'VEHICLE_FULL', 'VEHICLE_REQUIRED',
  // сделка
  'DEAL_CANNOT_CANCEL', 'DEAL_STATUS_CHANGED', 'CANCEL_ALREADY_REQUESTED', 'NO_CANCEL_REQUEST', 'OWN_CANCEL_REQUEST', 'NO_DISPUTE', 'REASON_REQUIRED',
  'REASON_NOT_ALLOWED', 'REASON_TEXT_REQUIRED', 'ACTIVE_DEALS', 'DOCS_EXPIRED', 'DOCS_NOT_YET', 'COMPLAINT_ALREADY_OPEN',
  // водители, анонсы, контакты
  'TOO_MANY_ARRIVALS', 'TERMINAL_NEEDS_GEOFENCE', 'RESPOND_FIRST', 'CONTACT_LIMIT', 'NO_PHONE', 'CREATE_DRIVER_LIMIT', 'DRIVER_LEFT_LIST', 'DRIVER_BLACKLISTED',
  'BLACKLIST_MATCH', 'OWNER_HAS_MEMBERS', 'NO_LICENSE_NAME', 'NO_APPROVED_SELFIE', 'NO_INVITATION', 'IDENTIFIER_INVALID',
  // файлы
  'IMAGE_TOO_LARGE', 'INVALID_IMAGE', 'INVALID_FILE', 'UNSUPPORTED_IMAGE_FORMAT', 'UPLOAD_QUOTA_EXCEEDED',
] as const;

/// Коды в ответах, у которых свой разбор в приложении (не общий текст):
/// ошибки полей (072), версии согласий, системные строки чата.
export const SPECIAL_CODES = ['VALIDATION_FAILED', 'INVALID_SPECS', 'OFFER_VERSION_MISMATCH', 'PD_CONSENT_VERSION_MISMATCH'] as const;

/// Код ошибки для ответа: свой → он; текст-код (`POINT_REQUIRED`) → он; текст
/// из таблицы → его код; иначе — по статусу.
export function resolveErrorCode(status: number, body: { code?: unknown; message?: unknown }): string {
  if (typeof body.code === 'string' && body.code) return body.code;
  const message = Array.isArray(body.message) ? undefined : body.message;
  if (typeof message === 'string') {
    if (/^[A-Z][A-Z0-9_]+$/.test(message)) return message;
    if (MESSAGE_CODES[message]) return MESSAGE_CODES[message];
  }
  return statusCode(status);
}
