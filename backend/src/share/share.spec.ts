import { ForbiddenException } from '@nestjs/common';
import { SHARE_CODE_LENGTH, ShareService, newShareCode } from './share.service';
import { escapeHtml, pageLocale, renderCargoPage, renderDriverPage, PageCargo } from './share-page';
import { SharePagesService } from './share-pages.service';

/// 052: «Поделиться» — коды, права, публичные страницы без телефона.
const links = { appUrl: 'https://app.lubao.kz/c/Abc2345', androidUrl: 'https://app.lubao.kz/app', iosUrl: 'https://app.lubao.kz/app', code: 'Abc2345', canonicalUrl: 'https://lubao.kz/c/Abc2345' };
const cargo: PageCargo = {
  id: 'c1', origin: { ru: 'Алматы', en: 'Almaty', zh: '阿拉木图', kk: 'Алматы' }, destination: { ru: 'Астана', en: 'Astana', zh: '阿斯塔纳', kk: 'Астана' },
  category: { ru: 'Стройматериалы', en: 'Building materials' }, bodyType: { ru: 'Тент', en: 'Tent' }, weightKg: 20000, distanceKm: 1230,
  price: 850000, pricePerKm: 691, currency: 'KZT', readyDate: new Date('2026-10-09T00:00:00Z'), companyName: 'ТОО <Транс>', companyRatingAvg: 4.8, companyRatingCount: 3,
};

describe('коды и язык страницы', () => {
  it('код — 7 символов без похожих (0/O, 1/l/I)', () => {
    for (let i = 0; i < 200; i++) {
      const code = newShareCode();
      expect(code).toHaveLength(SHARE_CODE_LENGTH);
      expect(code).toMatch(/^[A-HJ-NP-Za-km-z2-9]+$/);
    }
  });
  it('язык — по устройству открывшего, иначе ru', () => {
    expect(pageLocale('zh-CN,zh;q=0.9')).toBe('zh');
    expect(pageLocale('kk-KZ')).toBe('kk');
    expect(pageLocale('de-DE,en;q=0.5')).toBe('en');
    expect(pageLocale(undefined)).toBe('ru');
  });
});

describe('страница груза', () => {
  it('маршрут, км, вес, кузов, цена и ₸/км, погрузка, компания; OG-теги; экранирование; без телефона', () => {
    const html = renderCargoPage('ru', cargo, [], links, () => '#');
    expect(html).toContain('Алматы → Астана');
    expect(html).toContain('1 230 км');
    expect(html).toContain('20 т');
    expect(html).toContain('₸850 000');
    expect(html).toContain('₸691/км');
    expect(html).toContain('погрузка 9 окт');
    expect(html).toContain('ТОО &lt;Транс&gt; · ★ 4.8');
    expect(html).toContain('<meta property="og:title" content="Алматы → Астана · ₸850 000">');
    expect(html).not.toMatch(/\+7\d|tel:|contactPhone/i);
    expect(html).not.toContain('noindex');
  });
  it('груз забрали — «Уже неактуально» и похожие', () => {
    const html = renderCargoPage('en', null, [cargo], links, (c) => `/driver/cargo/${c.id}`);
    expect(html).toContain('No longer available');
    expect(html).toContain('Similar cargo');
    expect(html).toContain('/driver/cargo/c1');
  });
});

describe('страница водителя', () => {
  const driver = { fullName: 'Ерлан', isVerified: true, ratingAvg: 4.8, ratingCount: 5, trips: 12, bodyType: { ru: 'Тент' }, capacityTons: 20, volumeM3: 86, city: { ru: 'Алматы' }, countries: [{ ru: 'Россия' }], anyCountry: false, active: true };
  it('имя, машина, город, направление, рейтинг, «Проверен», рейсы; noindex; без телефона и госномера', () => {
    const html = renderDriverPage('ru', driver, links);
    expect(html).toContain('Ерлан');
    expect(html).toContain('Тент, 20 т, 86 м³');
    expect(html).toContain('Алматы');
    expect(html).toContain('Россия');
    expect(html).toContain('Проверен');
    expect(html).toContain('12 рейсов в Lubao');
    expect(html).toContain('noindex');
    expect(html).not.toMatch(/\+7\d|tel:|госномер/i);
  });
  it('анонс истёк — «Уже неактуально»', () => {
    expect(renderDriverPage('ru', { ...driver, active: false }, links)).toContain('Водитель уже не ищет груз');
  });
  it('экранирование HTML', () => {
    expect(escapeHtml('<b>"x"</b>')).toBe('&lt;b&gt;&quot;x&quot;&lt;/b&gt;');
  });
});

describe('ShareService — права и вход по ссылке', () => {
  function make(cargoRow: any = { companyId: 'co1', status: 'PUBLISHED' }) {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(cargoRow) },
      shareLink: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation(({ data }) => Promise.resolve({ id: 'l1', ...data })),
        update: jest.fn(),
      },
      user: { findUnique: jest.fn().mockResolvedValue({ referredByShareId: null }), update: jest.fn() },
    };
    return { prisma, service: new ShareService(prisma) };
  }

  it('водитель делится чужим опубликованным грузом; ссылка /c/<код>', async () => {
    const { service } = make();
    const r = await service.create({ user: { id: 'u1' }, driver: { id: 'd1' }, companyMember: null } as any, 'CARGO', 'cargo1');
    expect(r.url).toMatch(/\/c\/[A-Za-z0-9]{7}$/);
  });
  it('логист не делится чужими грузами и чужой компанией; водитель — чужим анонсом', async () => {
    const { service } = make({ companyId: 'other', status: 'PUBLISHED' });
    const logist = { user: { id: 'u2' }, driver: null, companyMember: { companyId: 'co1' } } as any;
    await expect(service.create(logist, 'CARGO', 'cargo1')).rejects.toThrow(ForbiddenException);
    await expect(service.create(logist, 'COMPANY', 'other')).rejects.toThrow(ForbiddenException);
    await expect(service.create({ user: { id: 'u1' }, driver: { id: 'd1' }, companyMember: null } as any, 'DRIVER', 'd2')).rejects.toThrow(ForbiddenException);
  });
  it('вход по ссылке засчитывается автору один раз; свои ссылки не считаются', async () => {
    const { prisma, service } = make();
    prisma.shareLink.findUnique.mockResolvedValue({ id: 'l1', code: 'Abc2345', type: 'CARGO', targetId: 'cargo1', authorUserId: 'author' });
    await service.claim('newbie', 'Abc2345');
    expect(prisma.user.update).toHaveBeenCalledWith({ where: { id: 'newbie' }, data: { referredByShareId: 'l1' } });
    expect(prisma.shareLink.update).toHaveBeenCalledWith({ where: { id: 'l1' }, data: { logins: { increment: 1 } } });
    prisma.user.update.mockClear();
    await service.claim('author', 'Abc2345');
    expect(prisma.user.update).not.toHaveBeenCalled();
  });
});

describe('SharePagesService — неизвестная ссылка', () => {
  it('нет ссылки — null (404)', async () => {
    const service = new SharePagesService({} as any, { findByCode: jest.fn().mockResolvedValue(null) } as any);
    expect(await service.render('nope123', 'ru')).toBeNull();
  });
});
