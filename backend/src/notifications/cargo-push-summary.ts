import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { I18nName } from './notification-events';

/// 053 п.6а: суть груза для push водителю («Приглашение», «Вас выбрали») —
/// маршрут из справочника, цена, вес, кузов, дата погрузки, компания.
/// Тексты на языке получателя собирает шаблон (`cargoLine` в notification-events).
export interface CargoPushSummary {
  cargoId: string;
  companyName: string;
  origin: I18nName | null;
  destination: I18nName | null;
  price: number;
  currency: string;
  weightKg: number | null;
  bodyType: I18nName | null;
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
      price: true,
      currency: true,
      weightKg: true,
      readyDate: true,
      company: { select: { name: true } },
      point: { select: { name: true } },
      destinationCity: { select: { name: true } },
      destinationCountry: { select: { name: true } },
      bodyType: { select: { name: true } },
    },
  });
  if (!cargo || cargo.price == null) return null;
  const num = (d: Prisma.Decimal | number | null | undefined) => (d == null ? null : Number(d));
  return {
    cargoId,
    companyName: cargo.company?.name ?? '',
    origin: (cargo.point?.name as I18nName | undefined) ?? null,
    destination: ((cargo.destinationCity?.name ?? cargo.destinationCountry?.name) as I18nName | undefined) ?? null,
    price: num(cargo.price) ?? 0,
    currency: cargo.currency,
    weightKg: num(cargo.weightKg),
    bodyType: (cargo.bodyType?.name as I18nName | undefined) ?? null,
    readyDate: cargo.readyDate.toISOString().slice(0, 10),
  };
}
