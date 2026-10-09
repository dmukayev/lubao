// Фото профиля (054): миниатюры, сделанные до исправления, несли EXIF селфи —
// пометку Orientation поверх уже повёрнутых пикселей (фото «лёжа») и, возможно,
// координаты съёмки. Скрипт вырезает метаданные из сохранённых миниатюр без
// перекодирования; ключ файла и версия обновляются, чтобы клиенты сбросили кэш.
// Повторный запуск безопасен. Запуск: npx ts-node scripts/strip-avatar-metadata.ts
import { PrismaClient } from '@prisma/client';
import { UploadsService } from '../src/uploads/uploads.service';
import { stripJpegMetadata } from '../src/drivers/image-header';

(async () => {
  const prisma = new PrismaClient();
  const uploads = new UploadsService();
  const drivers = await prisma.driver.findMany({ where: { avatarFileKey: { not: null } }, select: { id: true, userId: true, avatarFileKey: true } });
  let fixed = 0;
  for (const d of drivers) {
    const { buffer } = await uploads.getDocumentBuffer(d.avatarFileKey!);
    const clean = stripJpegMetadata(buffer);
    if (clean.length === buffer.length) continue;
    const key = await uploads.uploadDocument(clean, 'jpg', 'image/jpeg', d.userId);
    await prisma.driver.update({ where: { id: d.id }, data: { avatarFileKey: key, avatarUpdatedAt: new Date() } });
    await uploads.removeDocument(d.avatarFileKey!).catch(() => undefined);
    fixed += 1;
  }
  console.log(`фото профиля: ${drivers.length}, очищено от метаданных: ${fixed}`);
  await prisma.$disconnect();
})();
