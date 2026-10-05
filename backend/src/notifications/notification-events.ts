import { Locale, NotificationEventGroup } from '@prisma/client';

/// Json-поле справочника ({kk,ru,zh,en}, нет перевода — ru — CLAUDE.md
/// «Языки»). Нет общего бэкенд-хелпера для выбора локали (он есть только
/// на Flutter, `I18nText.forLanguageCode`) — тексты push заводим здесь же,
/// это единственное место на бэкенде, где это сейчас нужно.
export type I18nName = Partial<Record<Locale, string>>;

export function pickLocaleText(name: I18nName, locale: Locale): string {
  return name[locale] || name.ru || Object.values(name).find((v) => !!v) || '';
}

/// Названия типов документов (задача 029, п.7 — «Вернуть на доработку»
/// должен присылать список документов и причин, не общую фразу).
const DOC_TYPE_LABEL: Record<string, Record<Locale, string>> = {
  DRIVER_LICENSE: { ru: 'водительское удостоверение', kk: 'жүргізуші куәлігі', zh: '驾驶证', en: "driver's license" },
  VEHICLE_PASSPORT: { ru: 'техпаспорт тягача', kk: 'тартқыштың техпаспорты', zh: '牵引车行驶证', en: 'tractor unit registration' },
  TRAILER_PASSPORT: { ru: 'техпаспорт прицепа', kk: 'тіркеменің техпаспорты', zh: '挂车行驶证', en: 'trailer registration' },
  SELFIE: { ru: 'селфи', kk: 'селфи', zh: '自拍照', en: 'selfie' },
  COMPANY_REGISTRATION: { ru: 'свидетельство о регистрации', kk: 'тіркеу туралы куәлік', zh: '注册证书', en: 'registration certificate' },
  IDENTITY: { ru: 'документ, удостоверяющий личность', kk: 'жеке куәландыратын құжат', zh: '身份证件', en: 'identity document' },
  OTHER: { ru: 'документ', kk: 'құжат', zh: '文件', en: 'document' },
};

export interface RejectedDocument {
  type: string;
  reason: string;
}

function formatVerificationReturnedBody(p: NotificationPayload, locale: Locale, fallback: string): string {
  const documents: RejectedDocument[] | undefined = p.documents;
  const documentsText = documents?.length
    ? documents.map((d) => `${DOC_TYPE_LABEL[d.type]?.[locale] ?? d.type}: ${d.reason}`).join('; ')
    : null;
  return [documentsText, p.note].filter((part): part is string => !!part).join(' — ') || fallback;
}

/// DEAL_STATUS шлётся всегда на русском тексте статуса (упрощение — полный
/// 4-язычный набор статусов сделки не входит в объём 011; `render`
/// всё равно оборачивает его в заголовок на языке получателя).
export const DEAL_STATUS_LABEL_RU: Record<string, string> = {
  SELECTED: 'Водитель выбран',
  CONFIRMED_BY_DRIVER: 'Водитель подтвердил перевозку',
  LOADED: 'Груз загружен',
  IN_TRANSIT: 'В пути',
  DELIVERED: 'Доставлено',
  CANCELLED: 'Сделка отменена',
};

export type DeliveryChannel = 'PUSH' | 'WECOM';

export type NotificationEvent =
  | 'NEW_CARGO_MATCH'
  | 'CARGO_INVITE'
  | 'CHAT_MESSAGE'
  | 'NEW_RESPONSE'
  | 'NEW_DRIVER_DIGEST'
  | 'DEAL_STATUS'
  | 'VERIFICATION_RETURNED'
  | 'VERIFICATION_APPROVED'
  | 'AGREED_CHECK'
  | 'CARGO_UNPUBLISHED'
  | 'COMPLAINT_RESOLVED'
  | 'COMPLAINT_WARNED';

export interface RenderedNotification {
  title: string;
  body: string;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type NotificationPayload = Record<string, any>;

export interface NotificationEventDef {
  eventGroup: NotificationEventGroup;
  channels: DeliveryChannel[];
  render: (locale: Locale, payload: NotificationPayload) => RenderedNotification;
  deepLink: (payload: NotificationPayload) => string;
  /// Не чаще одного push в этот интервал на один throttleKey (задача 011,
  /// таблица событий: «не чаще 1 раза в минуту на чат»).
  throttleSeconds?: number;
  throttleKey?: (payload: NotificationPayload) => string;
}

const T: Record<NotificationEvent, Record<Locale, (p: NotificationPayload) => RenderedNotification>> = {
  NEW_CARGO_MATCH: {
    ru: (p) => ({ title: 'Новый груз рядом', body: `${p.routeLabel} · ${p.price} ${p.currency}` }),
    kk: (p) => ({ title: 'Жақын жерде жаңа жүк', body: `${p.routeLabel} · ${p.price} ${p.currency}` }),
    zh: (p) => ({ title: '附近有新货物', body: `${p.routeLabel} · ${p.price} ${p.currency}` }),
    en: (p) => ({ title: 'New cargo nearby', body: `${p.routeLabel} · ${p.price} ${p.currency}` }),
  },
  CARGO_INVITE: {
    ru: (p) => ({ title: 'Приглашение на груз', body: `${p.companyName} приглашает вас на груз` }),
    kk: (p) => ({ title: 'Жүкке шақыру', body: `${p.companyName} сізді жүкке шақырады` }),
    zh: (p) => ({ title: '货物邀请', body: `${p.companyName} 邀请您承运货物` }),
    en: (p) => ({ title: 'Cargo invitation', body: `${p.companyName} invited you to a cargo` }),
  },
  CHAT_MESSAGE: {
    ru: (p) => ({ title: p.senderName, body: p.preview }),
    kk: (p) => ({ title: p.senderName, body: p.preview }),
    zh: (p) => ({ title: p.senderName, body: p.preview }),
    en: (p) => ({ title: p.senderName, body: p.preview }),
  },
  NEW_RESPONSE: {
    ru: (p) => ({ title: 'Новый отклик', body: `${p.driverName} откликнулся на ваш груз` }),
    kk: (p) => ({ title: 'Жаңа жауап', body: `${p.driverName} сіздің жүгіңізге жауап берді` }),
    zh: (p) => ({ title: '新响应', body: `${p.driverName} 回应了您的货物` }),
    en: (p) => ({ title: 'New response', body: `${p.driverName} responded to your cargo` }),
  },
  NEW_DRIVER_DIGEST: {
    ru: (p) => ({ title: 'Новые водители на точке', body: `${p.count} новых водителей под ваши фильтры` }),
    kk: (p) => ({ title: 'Нүктеде жаңа жүргізушілер', body: `Сүзгілеріңізге сай ${p.count} жаңа жүргізуші` }),
    zh: (p) => ({ title: '该点新司机', body: `符合您筛选条件的新司机 ${p.count} 名` }),
    en: (p) => ({ title: 'New drivers at point', body: `${p.count} new drivers matching your filters` }),
  },
  DEAL_STATUS: {
    ru: (p) => ({ title: 'Статус сделки изменился', body: p.statusLabelRu }),
    kk: (p) => ({ title: 'Мәміле мәртебесі өзгерді', body: p.statusLabelRu }),
    zh: (p) => ({ title: '交易状态已变更', body: p.statusLabelRu }),
    en: (p) => ({ title: 'Deal status changed', body: p.statusLabelRu }),
  },
  VERIFICATION_RETURNED: {
    ru: (p) => ({ title: 'Документы нужно доработать', body: formatVerificationReturnedBody(p, 'ru', 'Проверьте профиль') }),
    kk: (p) => ({ title: 'Құжаттарды түзету қажет', body: formatVerificationReturnedBody(p, 'kk', 'Профильді тексеріңіз') }),
    zh: (p) => ({ title: '需要修改文件', body: formatVerificationReturnedBody(p, 'zh', '请检查您的资料') }),
    en: (p) => ({ title: 'Documents need rework', body: formatVerificationReturnedBody(p, 'en', 'Check your profile') }),
  },
  VERIFICATION_APPROVED: {
    ru: () => ({ title: 'Вы проверены', body: 'Все документы одобрены' }),
    kk: () => ({ title: 'Сіз тексерілдіңіз', body: 'Барлық құжаттар мақұлданды' }),
    zh: () => ({ title: '您已通过验证', body: '所有文件已批准' }),
    en: () => ({ title: "You're verified", body: 'All documents approved' }),
  },
  AGREED_CHECK: {
    ru: (p) => ({ title: 'Договорились?', body: `С ${p.counterpartName} по грузу?` }),
    kk: (p) => ({ title: 'Келістіңіз бе?', body: `${p.counterpartName}-мен жүк бойынша?` }),
    zh: (p) => ({ title: '谈妥了吗？', body: `与 ${p.counterpartName} 关于货物？` }),
    en: (p) => ({ title: 'Agreed?', body: `With ${p.counterpartName} about the cargo?` }),
  },
  CARGO_UNPUBLISHED: {
    ru: (p) => ({ title: 'Груз снят с публикации', body: p.reason || 'Администратор снял груз с витрины' }),
    kk: (p) => ({ title: 'Жүк жарияланымнан алынды', body: p.reason || 'Әкімші жүкті витринадан алып тастады' }),
    zh: (p) => ({ title: '货物已下架', body: p.reason || '管理员已将货物从展示中移除' }),
    en: (p) => ({ title: 'Cargo unpublished', body: p.reason || 'An admin removed the cargo from listings' }),
  },
  COMPLAINT_RESOLVED: {
    ru: (p) => ({ title: 'Ответ по вашей жалобе', body: p.resolutionNote }),
    kk: (p) => ({ title: 'Шағымыңыз бойынша жауап', body: p.resolutionNote }),
    zh: (p) => ({ title: '您的投诉回复', body: p.resolutionNote }),
    en: (p) => ({ title: 'Reply to your complaint', body: p.resolutionNote }),
  },
  COMPLAINT_WARNED: {
    ru: (p) => ({ title: 'Предупреждение', body: p.reason || 'Нарушение правил платформы' }),
    kk: (p) => ({ title: 'Ескерту', body: p.reason || 'Платформа ережелерін бұзу' }),
    zh: (p) => ({ title: '警告', body: p.reason || '违反平台规则' }),
    en: (p) => ({ title: 'Warning', body: p.reason || 'Platform rules violation' }),
  },
};

export const NOTIFICATION_EVENTS: Record<NotificationEvent, NotificationEventDef> = {
  NEW_CARGO_MATCH: {
    eventGroup: 'NEW_CARGO_MATCH',
    channels: ['PUSH'],
    render: (locale, p) => T.NEW_CARGO_MATCH[locale](p),
    deepLink: (p) => `lubao://cargo/${p.cargoId}`,
  },
  CARGO_INVITE: {
    eventGroup: 'CARGO_INVITE',
    channels: ['PUSH'],
    render: (locale, p) => T.CARGO_INVITE[locale](p),
    deepLink: (p) => `lubao://cargo/${p.cargoId}`,
  },
  CHAT_MESSAGE: {
    eventGroup: 'CHAT_MESSAGE',
    channels: ['PUSH'],
    render: (locale, p) => T.CHAT_MESSAGE[locale](p),
    deepLink: (p) => `lubao://chat/${p.chatId}`,
    throttleSeconds: 60,
    throttleKey: (p) => `chat:${p.chatId}:${p.recipientUserId}`,
  },
  NEW_RESPONSE: {
    eventGroup: 'NEW_RESPONSE',
    channels: ['PUSH', 'WECOM'],
    render: (locale, p) => T.NEW_RESPONSE[locale](p),
    deepLink: (p) => `lubao://cargo/${p.cargoId}/responses`,
  },
  NEW_DRIVER_DIGEST: {
    eventGroup: 'NEW_DRIVER_DIGEST',
    channels: ['WECOM'],
    render: (locale, p) => T.NEW_DRIVER_DIGEST[locale](p),
    deepLink: () => 'lubao://company/drivers',
  },
  DEAL_STATUS: {
    eventGroup: 'DEAL_STATUS',
    channels: ['PUSH', 'WECOM'],
    render: (locale, p) => T.DEAL_STATUS[locale](p),
    deepLink: (p) => `lubao://deal/${p.dealId}`,
  },
  VERIFICATION_RETURNED: {
    eventGroup: 'VERIFICATION',
    channels: ['PUSH'],
    render: (locale, p) => T.VERIFICATION_RETURNED[locale](p),
    deepLink: () => 'lubao://profile/verification',
  },
  VERIFICATION_APPROVED: {
    eventGroup: 'VERIFICATION',
    channels: ['PUSH'],
    render: (locale, p) => T.VERIFICATION_APPROVED[locale](p),
    deepLink: () => 'lubao://profile/verification',
  },
  AGREED_CHECK: {
    eventGroup: 'AGREED_CHECK',
    channels: ['PUSH'],
    render: (locale, p) => T.AGREED_CHECK[locale](p),
    deepLink: (p) => `lubao://chat/${p.chatId}`,
  },
  CARGO_UNPUBLISHED: {
    eventGroup: 'ADMIN_ACTION',
    channels: ['PUSH'],
    render: (locale, p) => T.CARGO_UNPUBLISHED[locale](p),
    deepLink: (p) => `lubao://cargo/${p.cargoId}`,
  },
  COMPLAINT_RESOLVED: {
    eventGroup: 'ADMIN_ACTION',
    channels: ['PUSH'],
    render: (locale, p) => T.COMPLAINT_RESOLVED[locale](p),
    deepLink: (p) => `lubao://complaint/${p.complaintId}`,
  },
  COMPLAINT_WARNED: {
    eventGroup: 'ADMIN_ACTION',
    channels: ['PUSH'],
    render: (locale, p) => T.COMPLAINT_WARNED[locale](p),
    deepLink: () => 'lubao://profile',
  },
};
