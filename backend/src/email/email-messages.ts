import { Locale } from '@prisma/client';

/// Тексты писем (задача 042, п.2, п.6): 4 языка, простой текст без вёрстки
/// (решение 022, п.14). Названия точек/городов в письма не вшиваются — только
/// то, что приходит параметрами из справочника.

export type EmailKind = 'CODE' | 'INVITE' | 'AGREED_DIGEST';

type Params = Record<string, string | number>;
type Template = (p: Params) => { subject: string; text: string };

const T: Record<EmailKind, Record<Locale, Template>> = {
  CODE: {
    ru: (p) => ({
      subject: 'Код подтверждения Lubao',
      text: `Ваш код: ${p.code}\nОн действует ${p.minutes} минут. Если вы его не запрашивали — просто проигнорируйте письмо.`,
    }),
    kk: (p) => ({
      subject: 'Lubao растау коды',
      text: `Сіздің кодыңыз: ${p.code}\nОл ${p.minutes} минут жарамды. Егер сіз сұрамаған болсаңыз — хатқа назар аудармаңыз.`,
    }),
    zh: (p) => ({
      subject: 'Lubao 验证码',
      text: `您的验证码：${p.code}\n有效期 ${p.minutes} 分钟。如非本人操作，请忽略此邮件。`,
    }),
    en: (p) => ({
      subject: 'Your Lubao verification code',
      text: `Your code: ${p.code}\nIt is valid for ${p.minutes} minutes. If you did not request it, just ignore this email.`,
    }),
  },
  INVITE: {
    ru: (p) => ({
      subject: `Приглашение в ${p.company} на Lubao`,
      text: `Вас пригласили в компанию «${p.company}» на Lubao.\nПерейдите по ссылке, чтобы принять приглашение (действует ${p.days} дней):\n${p.link}`,
    }),
    kk: (p) => ({
      subject: `${p.company} компаниясына Lubao-ға шақыру`,
      text: `Сізді Lubao-дағы «${p.company}» компаниясына шақырды.\nШақыруды қабылдау үшін сілтемеге өтіңіз (${p.days} күн жарамды):\n${p.link}`,
    }),
    zh: (p) => ({
      subject: `邀请您加入 ${p.company}（Lubao）`,
      text: `您被邀请加入 Lubao 上的公司“${p.company}”。\n请点击链接接受邀请（${p.days} 天内有效）：\n${p.link}`,
    }),
    en: (p) => ({
      subject: `You are invited to ${p.company} on Lubao`,
      text: `You have been invited to the company “${p.company}” on Lubao.\nOpen the link to accept the invitation (valid for ${p.days} days):\n${p.link}`,
    }),
  },
  AGREED_DIGEST: {
    ru: (p) => ({
      subject: 'Договорились с водителями?',
      text: `За сутки по вашим грузам звонили водители: ${p.count}. Если договорились — выберите водителя в приложении, и сделка пойдёт по шагам.\n${p.link}`,
    }),
    kk: (p) => ({
      subject: 'Жүргізушілермен келістіңіз бе?',
      text: `Тәулік ішінде жүктеріңіз бойынша жүргізушілер қоңырау шалды: ${p.count}. Келіскен болсаңыз — қолданбада жүргізушіні таңдаңыз.\n${p.link}`,
    }),
    zh: (p) => ({
      subject: '和司机谈妥了吗？',
      text: `过去 24 小时内，司机就您的货物来电 ${p.count} 次。如已谈妥，请在应用中选择司机，交易将按步骤进行。\n${p.link}`,
    }),
    en: (p) => ({
      subject: 'Did you agree with the drivers?',
      text: `Drivers called about your cargos in the last 24 hours: ${p.count}. If you agreed, select the driver in the app and the deal will go step by step.\n${p.link}`,
    }),
  },
};

export function renderEmail(kind: EmailKind, locale: Locale | undefined, params: Params): { subject: string; text: string } {
  return T[kind][locale && T[kind][locale] ? locale : 'ru'](params);
}

/// Язык из заголовка Accept-Language (kk/ru/zh/en → этот язык, иначе ru).
export function localeFromAcceptLanguage(header: string | undefined): Locale {
  for (const part of (header ?? '').split(',')) {
    const code = part.trim().slice(0, 2).toLowerCase();
    if (code === 'kk' || code === 'ru' || code === 'zh' || code === 'en') return code;
  }
  return 'ru';
}

/// Публичная https-ссылка в приложение/веб (universal/app link): `lubao://`
/// не используем (задача 042, п.2).
export function appLink(path: string, base = process.env.APP_PUBLIC_URL || 'https://app.lubao.kz'): string {
  return `${base.replace(/\/+$/, '')}/${path.replace(/^\/+/, '')}`;
}

/// Ссылка приглашения: на вебе открывает экран принятия.
export function inviteLink(token: string, base?: string): string {
  return appLink(`invite/${token}`, base);
}
