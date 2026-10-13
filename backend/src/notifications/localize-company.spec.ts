import { localizeCompanyName } from './notifications.service';

/// 069: в push китайское название компании — латиницей, кроме китайского языка.
describe('localizeCompanyName', () => {
  const payload = { companyName: '霍尔果斯瑞达贸易有限公司', companyNameLatin: 'Horgos Ruida Trading Co., Ltd.' };

  it('ru/kk/en — латиница, zh — оригинал', () => {
    expect(localizeCompanyName(payload, 'ru').companyName).toBe('Horgos Ruida Trading Co., Ltd.');
    expect(localizeCompanyName(payload, 'en').companyName).toBe('Horgos Ruida Trading Co., Ltd.');
    expect(localizeCompanyName(payload, 'zh').companyName).toBe('霍尔果斯瑞达贸易有限公司');
  });

  it('нет латиницы — оригинал', () => {
    expect(localizeCompanyName({ companyName: 'ТОО Транс', companyNameLatin: null }, 'ru').companyName).toBe('ТОО Транс');
  });
});
