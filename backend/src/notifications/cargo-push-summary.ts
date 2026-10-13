import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { I18nName } from './notification-events';
import { companyLatin } from '../companies/latin-name';
import { goodsLabel } from '../goods/goods-label';

/// 053 п.6а: суть груза для push водителю («Приглашение», «Вас выбрали») —
/// маршрут из справочника, цена, вес, кузов, дата погрузки, компания.
/// Тексты на языке получателя собирает шаблон (`cargoLine` в notification-events).
export interface CargoPushSummary {
  cargoId: string;
  /// 062: короткий номер груза.
  cargoNumber: number;
  companyName: string;
  companyNameLatin: string | null;
  origin: I18nName | null;
  destination: I18nName | null;
  price: number;
  currency: string;
  /// 058 п.1: условия оплаты.
  advanceAmount: number | null;
  paymentForm: string | null;
  paymentDelayDays: number | null;
  weightKg: number | null;
  bodyType: I18nName | null;
  /// 075: что везут — товар или свой текст логиста.
  goods: I18nName | null;
  /// YYYY-MM-DD — дата готовности (погрузки).
  readyDate: string;
}

/// По возможности: сбой чтения не ломает приглашение — push уйдёт с прежним
/// общим текстом.
export async function loadCargoPushSummary(prisma: Pick<PrismaService, 'cargo'>, cargoId: string): Promise<CargoPushSummary | null> {
  try {
    return await load(prisma, cargoId);
  } catch {
    return null;
  }
}

async function load(prisma: Pick<PrismaService, 'cargo'>, cargoId: string): Promise<CargoPushSummary | null> {
  const cargo = await prisma.cargo.findUnique({
    where: { id: cargoId },
    select: {
      number: true,
      price: true,
      currency: true,
      advanceAmount: true,
      paymentForm: true,
      paymentDelayDays: true,
      weightKg: true,
      readyDate: true,
      company: { select: { name: true, nameRu: true, nameLatin: true } },
      point: { select: { name: true } },
      destinationCity: { select: { name: true } },
      destinationCountry: { select: { name: true } },
      bodyType: { select: { name: true } },
      goods: { select: { name: true } },
      goodsText: true,
      goodsTextLocale: true,
      goodsTextTranslations: true,
    },
  });
  if (!cargo || cargo.price == null) return null;
  const num = (d: Prisma.Decimal | number | null | undefined) => (d == null ? null : Number(d));
  return {
    cargoId,
    cargoNumber: cargo.number,
    companyName: cargo.company?.name ?? '',
    companyNameLatin: companyLatin(cargo.company),
    origin: (cargo.point?.name as I18nName | undefined) ?? null,
    destination: ((cargo.destinationCity?.name ?? cargo.destinationCountry?.name) as I18nName | undefined) ?? null,
    price: num(cargo.price) ?? 0,
    currency: cargo.currency,
    advanceAmount: num(cargo.advanceAmount),
    paymentForm: cargo.paymentForm ?? null,
    paymentDelayDays: cargo.paymentDelayDays ?? null,
    weightKg: num(cargo.weightKg),
    bodyType: (cargo.bodyType?.name as I18nName | undefined) ?? null,
    goods: (goodsLabel(cargo) as I18nName | null) ?? null,
    readyDate: cargo.readyDate.toISOString().slice(0, 10),
  };
}
