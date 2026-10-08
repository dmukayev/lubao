/// Ответы бота входа (050 п.4) — на языке из `language_code` Telegram.
type Lang = 'ru' | 'kk' | 'zh' | 'en';
type BotText = 'askContact' | 'shareButton' | 'done' | 'openApp' | 'foreignContact' | 'expired' | 'hello';

const T: Record<BotText, Record<Lang, string>> = {
  hello: {
    ru: 'Здравствуйте! Это вход в Lubao.',
    kk: 'Сәлеметсіз бе! Бұл Lubao-ға кіру.',
    zh: '您好！这是 Lubao 登录。',
    en: 'Hello! This is the Lubao sign-in.',
  },
  askContact: {
    ru: 'Нажмите «Поделиться номером» — так мы узнаем, что номер ваш. Код вводить не нужно.',
    kk: '«Нөмірмен бөлісу» түймесін басыңыз — нөмірдің сіздікі екенін осылай білеміз. Код енгізудің қажеті жоқ.',
    zh: '请点击“分享号码”——这样我们确认号码属于您，无需输入验证码。',
    en: 'Tap “Share my number” so we know it’s yours. No code needed.',
  },
  shareButton: { ru: 'Поделиться номером', kk: 'Нөмірмен бөлісу', zh: '分享号码', en: 'Share my number' },
  done: {
    ru: 'Готово! Вернитесь в приложение Lubao — вход уже выполнен.',
    kk: 'Дайын! Lubao қосымшасына оралыңыз — кіру орындалды.',
    zh: '完成！请返回 Lubao 应用——已登录。',
    en: 'Done! Go back to the Lubao app — you’re signed in.',
  },
  openApp: { ru: 'Открыть Lubao', kk: 'Lubao ашу', zh: '打开 Lubao', en: 'Open Lubao' },
  foreignContact: {
    ru: 'Нужен ваш собственный номер — нажмите кнопку «Поделиться номером», а не пересылайте чужой контакт.',
    kk: 'Өз нөміріңіз қажет — басқа біреудің контактісін жібермей, «Нөмірмен бөлісу» түймесін басыңыз.',
    zh: '需要您本人的号码——请点击“分享号码”，不要转发他人的联系人。',
    en: 'We need your own number — tap “Share my number” instead of forwarding someone else’s contact.',
  },
  expired: {
    ru: 'Ссылка для входа устарела. Нажмите «Войти через Telegram» в приложении ещё раз.',
    kk: 'Кіру сілтемесінің мерзімі өтті. Қосымшада «Telegram арқылы кіру» түймесін қайта басыңыз.',
    zh: '登录链接已过期。请在应用中再次点击“通过 Telegram 登录”。',
    en: 'This sign-in link has expired. Tap “Sign in with Telegram” in the app again.',
  },
};

export function botLang(code: string | undefined): Lang {
  const c = (code ?? '').toLowerCase();
  if (c.startsWith('kk')) return 'kk';
  if (c.startsWith('zh')) return 'zh';
  if (c.startsWith('en')) return 'en';
  return 'ru';
}

export function botText(key: BotText, lang: Lang): string {
  return T[key][lang];
}
