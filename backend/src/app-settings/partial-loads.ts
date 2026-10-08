import { Prisma } from '@prisma/client';

export const PARTIAL_LOADS_SETTING = 'partialLoadsEnabled';

/// Догруз (сборные грузы, 037) — за флагом, по умолчанию выключен
/// (decisions.md 2026-10-08 «Догруз скрыт флагом до спроса», 049 п.1).
export async function partialLoadsEnabled(db: { appSetting: Pick<Prisma.TransactionClient['appSetting'], 'findUnique'> }): Promise<boolean> {
  const row = await db.appSetting.findUnique({ where: { key: PARTIAL_LOADS_SETTING } });
  return row?.value === 'true';
}
