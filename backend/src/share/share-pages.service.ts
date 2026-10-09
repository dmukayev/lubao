import { Injectable } from '@nestjs/common';
import { Prisma, ShareLink } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { I18nName } from '../notifications/notification-events';
import { PageCargo, PageDriver, PageLinks, PageLocale, renderCargoPage, renderCompanyPage, renderDriverPage } from './share-page';
import { SHARE_PATH, ShareService, shareBaseUrl } from './share.service';

const cargoInclude = {
  point: { select: { name: true } },
  destinationCity: { select: { name: true } },
  destinationCountry: { select: { name: true } },
  category: { select: { name: true } },
  bodyType: { select: { name: true } },
  company: { select: { name: true, ratingAvg: true, ratingCount: true, isBlocked: true } },
} as const;
type CargoRow = Prisma.CargoGetPayload<{ include: typeof cargoInclude }>;

/// Ссылка на Google Play — с `referrer=share_<код>` (Play Install Referrer).
export function withPlayReferrer(storeUrl: string, code: string): string {
  if (!/play\.google\.com/.test(storeUrl)) return storeUrl;
  return `${storeUrl}${storeUrl.includes('?') ? '&' : '?'}referrer=${encodeURIComponent(`share_${code}`)}`;
}

/// Android + встроенный браузер мессенджера (Telegram, WeChat).
export function androidInAppBrowser(ua: string): boolean {
  return /Android/i.test(ua) && /(Telegram|MicroMessenger|WeChat)/i.test(ua);
}

/// `intent://<хост>/open/…#Intent;scheme=https;package=…;S.browser_fallback_url=…;end`.
export function androidIntentUrl(httpsUrl: string): string {
  const u = new URL(httpsUrl);
  const pkg = process.env.ANDROID_PACKAGE || 'kz.darkhan.lubao';
  return `intent://${u.host}${u.pathname}#Intent;scheme=https;package=${pkg};S.browser_fallback_url=${encodeURIComponent(httpsUrl)};end`;
}

/// «Ерлан Сейткали» → «Ерлан С.»; одно слово — как есть.
export function publicName(full: string): string {
  const parts = full.trim().split(/\s+/).filter(Boolean);
  if (parts.length < 2) return parts[0] ?? '';
  return `${parts[0]} ${parts[1].charAt(0).toUpperCase()}.`;
}

function toPageCargo(c: CargoRow): PageCargo {
  return {
    id: c.id,
    origin: (c.point?.name as I18nName) ?? null,
    destination: ((c.destinationCity?.name ?? c.destinationCountry?.name) as I18nName) ?? null,
    category: (c.category?.name as I18nName) ?? null,
    bodyType: (c.bodyType?.name as I18nName) ?? null,
    weightKg: c.weightKg != null ? Number(c.weightKg) : null,
    distanceKm: c.distanceKm ?? null,
    price: Number(c.price),
    pricePerKm: c.pricePerKm != null ? Number(c.pricePerKm) : null,
    currency: c.currency,
    readyDate: c.readyDate,
    companyName: c.company?.name ?? '',
    companyRatingAvg: Number(c.company?.ratingAvg ?? 0),
    companyRatingCount: c.company?.ratingCount ?? 0,
  };
}

/// 052 п.2: данные публичных страниц — только то, что можно показать без
/// входа: ни телефона, ни госномера, ни документов.
@Injectable()
export class SharePagesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly shares: ShareService,
  ) {}

  links(link: Pick<ShareLink, 'type' | 'code'>, userAgent = ''): PageLinks {
    const app = (process.env.APP_PUBLIC_URL || shareBaseUrl()).replace(/\/+$/, '');
    const path = `/${SHARE_PATH[link.type]}/${link.code}`;
    const openUrl = `${app}/open${path}`;
    return {
      // С этой страницы — /open/… (входит в App Links: приложение откроется, нет —
      // веб-приложение); сам /c/… отдаёт эту страницу.
      // 057 п.5: встроенные браузеры Telegram/WeChat на Android App Links не
      // открывают — intent:// с переходом на тот же адрес, если приложения нет.
      appUrl: androidInAppBrowser(userAgent) ? androidIntentUrl(openUrl) : openUrl,
      // 057 п.8: Google Play передаёт приложению `referrer` — код без буфера обмена.
      androidUrl: withPlayReferrer(process.env.ANDROID_STORE_URL || `${app}/app`, link.code),
      iosUrl: process.env.IOS_STORE_URL || `${app}/app`,
      code: link.code,
      canonicalUrl: `${shareBaseUrl()}${path}`,
    };
  }

  /// null — ссылки нет (404).
  async render(code: string, locale: PageLocale, userAgent = ''): Promise<string | null> {
    const link = await this.shares.findByCode(code);
    if (!link) return null;
    await this.shares.countOpen(link.id);
    const links = this.links(link, userAgent);
    // Похожие и грузы компании открываются в приложении по id груза.
    const app = (process.env.APP_PUBLIC_URL || shareBaseUrl()).replace(/\/+$/, '');
    const cargoHref = (c: PageCargo) => `${app}/driver/cargo/${c.id}`;
    if (link.type === 'CARGO') {
      const cargo = await this.prisma.cargo.findUnique({ where: { id: link.targetId }, include: cargoInclude });
      // 057 п.7: груз заблокированной компании — «Уже неактуально».
      if (cargo && cargo.status === 'PUBLISHED' && !cargo.company?.isBlocked) return renderCargoPage(locale, toPageCargo(cargo), [], links, cargoHref);
      // «Уже неактуально» + 3–5 похожих: опубликованные туда же (страна назначения), ближайшие по дате.
      const similar = await this.prisma.cargo.findMany({
        where: { status: 'PUBLISHED', company: { isBlocked: false }, id: { not: link.targetId }, ...(cargo ? { destinationCountryId: cargo.destinationCountryId } : {}) },
        include: cargoInclude,
        orderBy: { readyDate: 'asc' },
        take: 5,
      });
      return renderCargoPage(locale, null, similar.map(toPageCargo), links, cargoHref);
    }
    if (link.type === 'COMPANY') {
      const company = await this.prisma.company.findUnique({ where: { id: link.targetId }, select: { name: true, isBlocked: true } });
      const cargos = await this.prisma.cargo.findMany({ where: { companyId: link.targetId, status: 'PUBLISHED', company: { isBlocked: false } }, include: cargoInclude, orderBy: { readyDate: 'asc' }, take: 30 });
      return renderCompanyPage(locale, company?.name ?? '', cargos.map(toPageCargo), links, cargoHref);
    }
    return renderDriverPage(locale, await this.driver(link.targetId), links);
  }

  private async driver(driverId: string): Promise<PageDriver> {
    const driver = await this.prisma.driver.findUnique({ where: { id: driverId }, include: { preferredBodyType: { select: { name: true } }, homeCity: { select: { name: true } } } });
    const arrival = await this.prisma.arrival.findFirst({
      where: { driverId, status: { in: ['PLANNED', 'ON_SITE'] } },
      orderBy: { createdAt: 'desc' },
      include: {
        point: { select: { name: true } },
        directions: { include: { country: { select: { name: true } } } },
        trailer: { include: { bodyType: { select: { name: true } } } },
        tractor: { include: { bodyType: { select: { name: true } } } },
      },
    });
    const trips = driver ? await this.prisma.deal.count({ where: { driverId, status: 'DELIVERED' } }) : 0;
    const vehicle = arrival?.trailer ?? arrival?.tractor ?? null;
    return {
      // 057 п.11: на публичной странице — «Имя Ф.», не полное ФИО.
      fullName: publicName(driver?.fullName ?? ''),
      isVerified: driver?.isVerified ?? false,
      ratingAvg: Number(driver?.ratingAvg ?? 0),
      ratingCount: driver?.ratingCount ?? 0,
      trips,
      bodyType: ((vehicle?.bodyType?.name ?? driver?.preferredBodyType?.name) as I18nName) ?? null,
      capacityTons: vehicle?.capacityTons != null ? Number(vehicle.capacityTons) : driver?.preferredCapacityTons != null ? Number(driver.preferredCapacityTons) : null,
      volumeM3: vehicle?.volumeM3 != null ? Number(vehicle.volumeM3) : null,
      city: (arrival?.point?.name as I18nName) ?? null,
      countries: (arrival?.directions ?? []).map((d) => d.country.name as I18nName),
      anyCountry: arrival?.anyCountry ?? false,
      // Анонс истёк / водитель не ищет — «Уже неактуально».
      active: !!driver && !!arrival,
    };
  }
}
