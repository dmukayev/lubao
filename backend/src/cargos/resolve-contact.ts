import { PrismaService } from '../prisma/prisma.service';

/// Кому из логистов компании адресован push о событии по этому грузу
/// (decisions.md «Компания: проверка, роли, контакты», задача 012) — тот
/// же приоритет, что у CargosService.resolveContact (публикатор груза,
/// иначе самый старый OWNER), но возвращает только userId — для
/// NotificationsService этого достаточно, доставать имя/телефон незачем.
export async function resolveCargoContactUserId(
  prisma: PrismaService,
  cargo: { companyId: string; publishedByUserId: string | null },
): Promise<string | null> {
  if (cargo.publishedByUserId) return cargo.publishedByUserId;
  const owner = await prisma.companyMember.findFirst({
    where: { companyId: cargo.companyId, role: 'OWNER' },
    orderBy: { createdAt: 'asc' },
  });
  return owner?.userId ?? null;
}
