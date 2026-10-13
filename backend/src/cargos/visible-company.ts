import { Prisma } from '@prisma/client';

/// Грузы компании видны водителям: компания не заблокирована (026 п.5) и
/// публикация не на паузе после жалоб (066 п.5).
export const VISIBLE_COMPANY = { isBlocked: false, publishingPausedAt: null } satisfies Prisma.CompanyWhereInput;
