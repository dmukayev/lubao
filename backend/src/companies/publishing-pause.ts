import { PrismaClient } from '@prisma/client';

/// 066 п.5 (decisions.md «Компания публикует грузы без проверки»): жалобы от
/// стольких разных водителей — публикация непроверенной компании на паузе.
export const COMPLAINTS_TO_PAUSE = 2;

type Db = Pick<PrismaClient, 'company' | 'complaint' | 'cargo' | 'deal' | 'user' | 'auditLog'>;

/// Разные водители, пожаловавшиеся на компанию после последнего снятия паузы:
/// на её груз, на сделку с ней (жалоба водителя) или на саму компанию.
/// Отклонённые админом жалобы не считаются.
export async function driverComplaintsAgainst(db: Db, companyId: string, since: Date | null): Promise<number> {
  const [cargos, deals] = await Promise.all([
    db.cargo.findMany({ where: { companyId }, select: { id: true } }),
    db.deal.findMany({ where: { companyId }, select: { id: true } }),
  ]);
  const complaints = await db.complaint.findMany({
    where: {
      status: { not: 'REJECTED' },
      ...(since ? { createdAt: { gt: since } } : {}),
      reporter: { role: 'DRIVER' },
      OR: [
        { targetType: 'COMPANY', targetId: companyId },
        ...(cargos.length ? [{ targetType: 'CARGO' as const, targetId: { in: cargos.map((c) => c.id) } }] : []),
        ...(deals.length ? [{ targetType: 'DEAL' as const, targetId: { in: deals.map((d) => d.id) } }] : []),
      ],
    },
    select: { reporterUserId: true },
  });
  return new Set(complaints.map((c) => c.reporterUserId)).size;
}

/// После новой жалобы водителя: непроверенная компания с жалобами от двух
/// водителей уходит на паузу (грузы скрыты из ленты, новые не публикуются).
/// Проверенную не трогаем — с ней разбирается админ.
export async function pauseAfterComplaints(db: Db, companyId: string): Promise<boolean> {
  const company = await db.company.findUnique({ where: { id: companyId }, select: { isVerified: true, publishingPausedAt: true, complaintsResetAt: true } });
  if (!company || company.isVerified || company.publishingPausedAt) return false;
  const reporters = await driverComplaintsAgainst(db, companyId, company.complaintsResetAt);
  if (reporters < COMPLAINTS_TO_PAUSE) return false;
  await db.company.update({ where: { id: companyId }, data: { publishingPausedAt: new Date() } });
  await db.auditLog.create({ data: { action: 'COMPANY_PUBLISHING_PAUSED', entityType: 'Company', entityId: companyId, metadata: { reporters } } });
  return true;
}
