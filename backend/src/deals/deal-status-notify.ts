import { Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { resolveCargoContactUserId } from '../cargos/resolve-contact';

export type DealActor = 'DRIVER' | 'COMPANY' | 'ADMIN';

type DealForNotify = {
  id: string;
  cargoId: string;
  companyId: string;
  driverId: string;
  status?: string;
  cancelReason?: string | null;
};

/// Push о статусе сделки — по роли и по-человечески (042 п.8): тот, кто
/// нажал, push не получает; второй стороне — текст от её лица с городами из
/// справочника (не «Хоргос» строкой). Отмена/правка админом — обеим сторонам.
export async function notifyDealStatus(
  prisma: PrismaService,
  notifications: Pick<NotificationsService, 'notify'> | undefined,
  deal: DealForNotify,
  status: string,
  actor: DealActor,
): Promise<void> {
  if (!notifications) return;
  // Уведомление — по возможности: его сбой не должен ломать смену статуса.
  try {
    await send(prisma, notifications, deal, status, actor);
  } catch (e) {
    new Logger('DealStatusNotify').warn(`push о статусе сделки ${deal.id} не отправлен: ${(e as Error).message}`);
  }
}

async function send(
  prisma: PrismaService,
  notifications: Pick<NotificationsService, 'notify'>,
  deal: DealForNotify,
  status: string,
  actor: DealActor,
): Promise<void> {
  const [driver, cargo, company] = await Promise.all([
    prisma.driver.findUnique({ where: { id: deal.driverId }, select: { userId: true, fullName: true } }),
    prisma.cargo.findUnique({
      where: { id: deal.cargoId },
      select: {
        companyId: true,
        publishedByUserId: true,
        point: { select: { name: true } },
        destinationCity: { select: { name: true } },
        destinationCountry: { select: { name: true } },
      },
    }),
    prisma.company.findUnique({ where: { id: deal.companyId }, select: { name: true } }),
  ]);
  if (!driver || !cargo) return;

  const payload = {
    dealId: deal.id,
    status,
    driverName: driver.fullName,
    companyName: company?.name ?? '',
    origin: cargo.point?.name ?? null,
    destination: cargo.destinationCity?.name ?? cargo.destinationCountry?.name ?? null,
    reason: deal.cancelReason ?? '',
  };

  if (actor !== 'DRIVER') {
    await notifications.notify({ userIds: [driver.userId] }, 'DEAL_FOR_DRIVER', payload);
  }
  if (actor !== 'COMPANY') {
    const contactUserId = await resolveCargoContactUserId(prisma, cargo);
    await notifications.notify({ userIds: contactUserId ? [contactUserId] : [], companyId: deal.companyId }, 'DEAL_FOR_LOGIST', payload);
  }
}
