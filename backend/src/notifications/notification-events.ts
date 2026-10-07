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

/// Задача 029, п.11 — раньше тело push всегда было на русском (статус
/// рендерился в RU на стороне вызывающего и клался в payload как готовая
/// строка); теперь передаём сырой статус, а текст на языке получателя
/// выбирает `render` ниже.
export const DEAL_STATUS_LABEL: Record<string, Record<Locale, string>> = {
  SELECTED: { ru: 'Водитель выбран', kk: 'Жүргізуші таңдалды', zh: '司机已选定', en: 'Driver selected' },
  CONFIRMED_BY_DRIVER: { ru: 'Водитель подтвердил перевозку', kk: 'Жүргізуші тасымалды растады', zh: '司机已确认运输', en: 'Driver confirmed the haul' },
  LOADED: { ru: 'Груз загружен', kk: 'Жүк тиелді', zh: '货物已装载', en: 'Cargo loaded' },
  IN_TRANSIT: { ru: 'В пути', kk: 'Жолда', zh: '运输中', en: 'In transit' },
  DELIVERED: { ru: 'Доставлено', kk: 'Жеткізілді', zh: '已送达', en: 'Delivered' },
  CANCELLED: { ru: 'Сделка отменена', kk: 'Мәміле болдырылмады', zh: '交易已取消', en: 'Deal cancelled' },
};

export type DeliveryChannel = 'PUSH' | 'WECOM';

export type NotificationEvent =
  | 'NEW_CARGO_MATCH'
  | 'CARGO_INVITE'
  | 'CHAT_MESSAGE'
  | 'NEW_RESPONSE'
  | 'DRIVER_AGREED'
  | 'NEW_DRIVER_DIGEST'
  | 'DEAL_STATUS'
  | 'DEAL_FOR_LOGIST'
  | 'DEAL_FOR_DRIVER'
  | 'DEAL_SELECTED'
  | 'VERIFICATION_RETURNED'
  | 'VERIFICATION_APPROVED'
  | 'AGREED_CHECK'
  | 'ARRIVAL_DAY_CHECK'
  | 'ARRIVAL_STILL_LOOKING'
  | 'CARGO_UNPUBLISHED'
  | 'COMPLAINT_RESOLVED'
  | 'COMPLAINT_WARNED';

export interface RenderedNotification {
  title: string;
  body: string;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type NotificationPayload = Record<string, any>;

/// 042 п.8: статус сделки — по роли и по-человечески, города из справочника.
type Loc = 'ru' | 'kk' | 'zh' | 'en';
function place(p: NotificationPayload, key: 'origin' | 'destination', locale: Loc): string {
  return p[key] ? pickLocaleText(p[key], locale) : '';
}
function route(p: NotificationPayload, locale: Loc): string {
  const from = place(p, 'origin', locale);
  const to = place(p, 'destination', locale);
  return from && to ? `${from} → ${to}` : to || from;
}
const LOGIST_STATUS: Record<Loc, (p: NotificationPayload) => { title: string; body: string }> = {
  ru: (p) => {
    switch (p.status) {
      case 'CONFIRMED_BY_DRIVER': return { title: 'Перевозка подтверждена', body: `${p.driverName} подтвердил перевозку ${route(p, 'ru')}`.trim() };
      case 'LOADED': return { title: 'Загрузился', body: `${p.driverName} загрузился, едет в ${place(p, 'destination', 'ru')}`.trim() };
      case 'IN_TRANSIT': return { title: 'В пути', body: `${p.driverName} в пути в ${place(p, 'destination', 'ru')}`.trim() };
      case 'DELIVERED': return { title: 'Груз доставлен', body: `${p.driverName} доставил груз — оцените водителя` };
      case 'CANCELLED': return { title: 'Сделка отменена', body: p.reason ? `${p.driverName}: ${p.reason}` : p.driverName };
      default: return { title: 'Сделка', body: DEAL_STATUS_LABEL[p.status]?.ru ?? p.status };
    }
  },
  kk: (p) => {
    switch (p.status) {
      case 'CONFIRMED_BY_DRIVER': return { title: 'Тасымал расталды', body: `${p.driverName} тасымалды растады ${route(p, 'kk')}`.trim() };
      case 'LOADED': return { title: 'Тиелді', body: `${p.driverName} жүк тиеді, ${place(p, 'destination', 'kk')} бағытына барады`.trim() };
      case 'IN_TRANSIT': return { title: 'Жолда', body: `${p.driverName} ${place(p, 'destination', 'kk')} бағытында жолда`.trim() };
      case 'DELIVERED': return { title: 'Жүк жеткізілді', body: `${p.driverName} жүкті жеткізді — жүргізушіні бағалаңыз` };
      case 'CANCELLED': return { title: 'Мәміле болдырылмады', body: p.reason ? `${p.driverName}: ${p.reason}` : p.driverName };
      default: return { title: 'Мәміле', body: DEAL_STATUS_LABEL[p.status]?.kk ?? p.status };
    }
  },
  zh: (p) => {
    switch (p.status) {
      case 'CONFIRMED_BY_DRIVER': return { title: '运输已确认', body: `${p.driverName} 已确认运输 ${route(p, 'zh')}`.trim() };
      case 'LOADED': return { title: '已装货', body: `${p.driverName} 已装货，正前往${place(p, 'destination', 'zh')}` };
      case 'IN_TRANSIT': return { title: '运输中', body: `${p.driverName} 正在前往${place(p, 'destination', 'zh')}` };
      case 'DELIVERED': return { title: '货物已送达', body: `${p.driverName} 已送达货物 — 请评价司机` };
      case 'CANCELLED': return { title: '交易已取消', body: p.reason ? `${p.driverName}：${p.reason}` : p.driverName };
      default: return { title: '交易', body: DEAL_STATUS_LABEL[p.status]?.zh ?? p.status };
    }
  },
  en: (p) => {
    switch (p.status) {
      case 'CONFIRMED_BY_DRIVER': return { title: 'Haul confirmed', body: `${p.driverName} confirmed the haul ${route(p, 'en')}`.trim() };
      case 'LOADED': return { title: 'Loaded', body: `${p.driverName} has loaded and is heading to ${place(p, 'destination', 'en')}`.trim() };
      case 'IN_TRANSIT': return { title: 'In transit', body: `${p.driverName} is on the way to ${place(p, 'destination', 'en')}`.trim() };
      case 'DELIVERED': return { title: 'Cargo delivered', body: `${p.driverName} delivered the cargo — rate the driver` };
      case 'CANCELLED': return { title: 'Deal cancelled', body: p.reason ? `${p.driverName}: ${p.reason}` : p.driverName };
      default: return { title: 'Deal', body: DEAL_STATUS_LABEL[p.status]?.en ?? p.status };
    }
  },
};
const DRIVER_STATUS: Record<Loc, (p: NotificationPayload) => { title: string; body: string }> = {
  ru: (p) =>
    p.status === 'DELIVERED' ? { title: 'Доставка отмечена', body: `${p.companyName} отметила доставку — оставьте отзыв` }
    : p.status === 'CANCELLED' ? { title: 'Сделка отменена', body: p.reason ? `Причина: ${p.reason}` : p.companyName }
    : { title: p.companyName, body: DEAL_STATUS_LABEL[p.status]?.ru ?? p.status },
  kk: (p) =>
    p.status === 'DELIVERED' ? { title: 'Жеткізу белгіленді', body: `${p.companyName} жеткізуді белгіледі — пікір қалдырыңыз` }
    : p.status === 'CANCELLED' ? { title: 'Мәміле болдырылмады', body: p.reason ? `Себебі: ${p.reason}` : p.companyName }
    : { title: p.companyName, body: DEAL_STATUS_LABEL[p.status]?.kk ?? p.status },
  zh: (p) =>
    p.status === 'DELIVERED' ? { title: '已确认送达', body: `${p.companyName} 已确认送达 — 请留下评价` }
    : p.status === 'CANCELLED' ? { title: '交易已取消', body: p.reason ? `原因：${p.reason}` : p.companyName }
    : { title: p.companyName, body: DEAL_STATUS_LABEL[p.status]?.zh ?? p.status },
  en: (p) =>
    p.status === 'DELIVERED' ? { title: 'Delivery confirmed', body: `${p.companyName} marked the delivery — leave a review` }
    : p.status === 'CANCELLED' ? { title: 'Deal cancelled', body: p.reason ? `Reason: ${p.reason}` : p.companyName }
    : { title: p.companyName, body: DEAL_STATUS_LABEL[p.status]?.en ?? p.status },
};

export interface NotificationEventDef {
  eventGroup: NotificationEventGroup;
  channels: DeliveryChannel[];
  render: (locale: Locale, payload: NotificationPayload) => RenderedNotification;
  /// Путь go_router в приложении (042 п.1): тап по push открывает его.
  /// `/verification`, `/arrival`, `/profile` — общие псевдонимы, приложение
  /// разворачивает их по роли (водитель/логист).
  deepLink: (payload: NotificationPayload) => string;
  /// Категория кнопок в push (042 п.1): iOS — `aps.category`, Android —
  /// уведомление с кнопками рисует само приложение.
  category?: 'STILL_LOOKING' | 'AGREED_CHECK';
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
  /// Задача 029, п.11 — если отправитель и получатель на разных языках,
  /// перевод в момент отправки ещё не готов (п.6: он всегда асинхронный),
  /// поэтому оригинал в push получателю не понятен; показываем нейтральный
  /// текст на его языке, а не чужую кириллицу/иероглифы (`preview` придёт
  /// `null` из ChatsService ровно в этом случае).
  CHAT_MESSAGE: {
    ru: (p) => ({ title: p.senderName, body: p.preview ?? 'Новое сообщение' }),
    kk: (p) => ({ title: p.senderName, body: p.preview ?? 'Жаңа хабарлама' }),
    zh: (p) => ({ title: p.senderName, body: p.preview ?? '新消息' }),
    en: (p) => ({ title: p.senderName, body: p.preview ?? 'New message' }),
  },
  NEW_RESPONSE: {
    ru: (p) => ({ title: 'Новый отклик', body: `${p.driverName} откликнулся на ваш груз` }),
    kk: (p) => ({ title: 'Жаңа жауап', body: `${p.driverName} сіздің жүгіңізге жауап берді` }),
    zh: (p) => ({ title: '新响应', body: `${p.driverName} 回应了您的货物` }),
    en: (p) => ({ title: 'New response', body: `${p.driverName} responded to your cargo` }),
  },
  /// Водитель ответил «Да» на «Договорились?» (договорились мимо кнопок —
  /// decisions.md): логисту — выбрать его, чтобы сделка пошла в приложении.
  DRIVER_AGREED: {
    ru: (p) => ({ title: 'Водитель говорит: договорились', body: `${p.driverName} — выберите его в откликах, чтобы сделка пошла по шагам` }),
    kk: (p) => ({ title: 'Жүргізуші: келістік', body: `${p.driverName} — мәміле қадамдармен жүруі үшін оны жауаптардан таңдаңыз` }),
    zh: (p) => ({ title: '司机表示：已谈妥', body: `${p.driverName} — 请在响应中选择他，交易将按步骤进行` }),
    en: (p) => ({ title: 'Driver says: agreed', body: `${p.driverName} — select them in the responses so the deal goes step by step` }),
  },
  NEW_DRIVER_DIGEST: {
    ru: (p) => ({ title: 'Новые водители на точке', body: `${p.count} новых водителей под ваши фильтры` }),
    kk: (p) => ({ title: 'Нүктеде жаңа жүргізушілер', body: `Сүзгілеріңізге сай ${p.count} жаңа жүргізуші` }),
    zh: (p) => ({ title: '该点新司机', body: `符合您筛选条件的新司机 ${p.count} 名` }),
    en: (p) => ({ title: 'New drivers at point', body: `${p.count} new drivers matching your filters` }),
  },
  /// Водителю — когда логист выбрал его (042 п.1, «Готово, когда»):
  /// от его лица, а не общее «Статус сделки: Водитель выбран».
  DEAL_FOR_LOGIST: LOGIST_STATUS,
  DEAL_FOR_DRIVER: DRIVER_STATUS,
  DEAL_SELECTED: {
    ru: () => ({ title: 'Вас выбрали', body: 'Логист выбрал вас на груз. Подтвердите перевозку в приложении.' }),
    kk: () => ({ title: 'Сізді таңдады', body: 'Логист сізді жүкке таңдады. Тасымалды қолданбада растаңыз.' }),
    zh: () => ({ title: '您已被选中', body: '物流方已为该货物选择了您。请在应用中确认运输。' }),
    en: () => ({ title: 'You were selected', body: 'A logistician selected you for the cargo. Confirm the haul in the app.' }),
  },
  DEAL_STATUS: {
    ru: (p) => ({ title: 'Статус сделки изменился', body: DEAL_STATUS_LABEL[p.status]?.ru ?? p.status }),
    kk: (p) => ({ title: 'Мәміле мәртебесі өзгерді', body: DEAL_STATUS_LABEL[p.status]?.kk ?? p.status }),
    zh: (p) => ({ title: '交易状态已变更', body: DEAL_STATUS_LABEL[p.status]?.zh ?? p.status }),
    en: (p) => ({ title: 'Deal status changed', body: DEAL_STATUS_LABEL[p.status]?.en ?? p.status }),
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
  /// Задача 040 — правило свежести анонса: в день приезда и каждые 12 ч
  /// на месте. Город — из справочника (`p.pointName`
  /// — `Point.name` целиком (JSON {kk,ru,zh,en}), язык выбирается здесь).
  ARRIVAL_DAY_CHECK: {
    ru: (p) => ({ title: 'Доехали?', body: `Нажмите «Я на месте» — ${pickLocaleText(p.pointName, 'ru')}` }),
    kk: (p) => ({ title: 'Жеттіңіз бе?', body: `«Мен осындамын» түймесін басыңыз — ${pickLocaleText(p.pointName, 'kk')}` }),
    zh: (p) => ({ title: '到了吗？', body: `请点击“我已到达” — ${pickLocaleText(p.pointName, 'zh')}` }),
    en: (p) => ({ title: 'Arrived?', body: `Tap “I'm here” — ${pickLocaleText(p.pointName, 'en')}` }),
  },
  ARRIVAL_STILL_LOOKING: {
    ru: (p) => ({ title: 'Ещё ищете груз?', body: `${pickLocaleText(p.pointName, 'ru')} — подтвердите, что вы ещё на месте` }),
    kk: (p) => ({ title: 'Әлі жүк іздеп жүрсіз бе?', body: `${pickLocaleText(p.pointName, 'kk')} — әлі осында екеніңізді растаңыз` }),
    zh: (p) => ({ title: '还在找货吗？', body: `${pickLocaleText(p.pointName, 'zh')} — 请确认您仍在当地` }),
    en: (p) => ({ title: 'Still looking for cargo?', body: `${pickLocaleText(p.pointName, 'en')} — confirm you are still there` }),
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
    deepLink: (p) => `/driver/cargo/${p.cargoId}`,
  },
  CARGO_INVITE: {
    eventGroup: 'CARGO_INVITE',
    channels: ['PUSH'],
    render: (locale, p) => T.CARGO_INVITE[locale](p),
    deepLink: (p) => `/driver/cargo/${p.cargoId}`,
  },
  CHAT_MESSAGE: {
    eventGroup: 'CHAT_MESSAGE',
    // WeCom — сообщения водителя тоже уходят в бот компании (задача 042, п.5).
    channels: ['PUSH', 'WECOM'],
    render: (locale, p) => T.CHAT_MESSAGE[locale](p),
    deepLink: (p) => `/chat/${p.chatId}`,
    throttleSeconds: 60,
    throttleKey: (p) => `chat:${p.chatId}:${p.recipientUserId}`,
  },
  DRIVER_AGREED: {
    eventGroup: 'NEW_RESPONSE',
    channels: ['PUSH', 'WECOM'],
    render: (locale, p) => T.DRIVER_AGREED[locale](p),
    deepLink: (p) => `/company/cargos/${p.cargoId}/responses`,
  },
  NEW_RESPONSE: {
    eventGroup: 'NEW_RESPONSE',
    channels: ['PUSH', 'WECOM'],
    render: (locale, p) => T.NEW_RESPONSE[locale](p),
    deepLink: (p) => `/company/cargos/${p.cargoId}/responses`,
  },
  NEW_DRIVER_DIGEST: {
    eventGroup: 'NEW_DRIVER_DIGEST',
    channels: ['WECOM'],
    render: (locale, p) => T.NEW_DRIVER_DIGEST[locale](p),
    deepLink: () => '/company/drivers',
  },
  DEAL_FOR_LOGIST: {
    eventGroup: 'DEAL_STATUS',
    channels: ['PUSH', 'WECOM'],
    render: (locale, p) => LOGIST_STATUS[locale as Loc](p),
    deepLink: (p) => `/deal/${p.dealId}`,
  },
  DEAL_FOR_DRIVER: {
    eventGroup: 'DEAL_STATUS',
    channels: ['PUSH'],
    render: (locale, p) => DRIVER_STATUS[locale as Loc](p),
    deepLink: (p) => `/deal/${p.dealId}`,
  },
  DEAL_SELECTED: {
    eventGroup: 'DEAL_STATUS',
    channels: ['PUSH'],
    render: (locale, p) => T.DEAL_SELECTED[locale](p),
    deepLink: (p) => `/deal/${p.dealId}`,
  },
  DEAL_STATUS: {
    eventGroup: 'DEAL_STATUS',
    channels: ['PUSH', 'WECOM'],
    render: (locale, p) => T.DEAL_STATUS[locale](p),
    deepLink: (p) => `/deal/${p.dealId}`,
  },
  VERIFICATION_RETURNED: {
    eventGroup: 'VERIFICATION',
    channels: ['PUSH'],
    render: (locale, p) => T.VERIFICATION_RETURNED[locale](p),
    deepLink: () => '/verification',
  },
  VERIFICATION_APPROVED: {
    eventGroup: 'VERIFICATION',
    channels: ['PUSH'],
    render: (locale, p) => T.VERIFICATION_APPROVED[locale](p),
    deepLink: () => '/verification',
  },
  AGREED_CHECK: {
    eventGroup: 'AGREED_CHECK',
    channels: ['PUSH'],
    render: (locale, p) => T.AGREED_CHECK[locale](p),
    category: 'AGREED_CHECK',
    deepLink: (p) => (p.chatId ? `/chat/${p.chatId}` : `/driver/cargo/${p.cargoId}`),
  },
  ARRIVAL_DAY_CHECK: {
    eventGroup: 'ARRIVAL_CHECK',
    channels: ['PUSH'],
    render: (locale, p) => T.ARRIVAL_DAY_CHECK[locale](p),
    deepLink: () => '/arrival',
  },
  ARRIVAL_STILL_LOOKING: {
    eventGroup: 'ARRIVAL_CHECK',
    channels: ['PUSH'],
    render: (locale, p) => T.ARRIVAL_STILL_LOOKING[locale](p),
    category: 'STILL_LOOKING',
    deepLink: () => '/arrival',
  },
  CARGO_UNPUBLISHED: {
    eventGroup: 'ADMIN_ACTION',
    channels: ['PUSH'],
    render: (locale, p) => T.CARGO_UNPUBLISHED[locale](p),
    deepLink: (p) => `/driver/cargo/${p.cargoId}`,
  },
  COMPLAINT_RESOLVED: {
    eventGroup: 'ADMIN_ACTION',
    channels: ['PUSH'],
    render: (locale, p) => T.COMPLAINT_RESOLVED[locale](p),
    deepLink: (p) => '/profile',
  },
  COMPLAINT_WARNED: {
    eventGroup: 'ADMIN_ACTION',
    channels: ['PUSH'],
    render: (locale, p) => T.COMPLAINT_WARNED[locale](p),
    deepLink: () => '/profile',
  },
};
