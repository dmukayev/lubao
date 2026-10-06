/// Задача 038, п.24 — одноразовый идемпотентный пересчёт `identifiers` после
/// изменения нормализации/маски (032 п.9–10): VIN и номер прав теперь
/// транслитерируют кириллические двойники ДО хеша, маска прав — 2+2.
/// Старые строки хранят хеш/маску по старым правилам, и чёрный список по
/// ним не срабатывал бы. Запуск: `ts-node prisma/backfill-identifiers.ts`
/// (нужны DATABASE_URL, IDENTIFIER_PEPPER, IDENTIFIER_KEY; `--dry` — только
/// показать). Повторный запуск ничего не меняет (значения уже новые).
import { PrismaClient } from '@prisma/client';
import { decryptIdentifier, encryptIdentifier, hashIdentifier, isSensitiveIdentifierType, maskIdentifier } from '../src/identifiers/crypto';
import { IdentifierTypeValue, normalizeIdentifier } from '../src/identifiers/normalize';

const prisma = new PrismaClient();
const DRY = process.argv.includes('--dry');
const TYPES: IdentifierTypeValue[] = ['VIN', 'DRIVER_LICENSE_NO'];

async function main() {
  const rows = await prisma.identifier.findMany({ where: { type: { in: TYPES } } });
  let changed = 0;
  let blockedUpdated = 0;
  for (const row of rows) {
    const type = row.type as IdentifierTypeValue;
    // Исходное значение: у прав — расшифровать, у VIN (не чувствительный)
    // valueMasked хранит его целиком.
    const raw = isSensitiveIdentifierType(type)
      ? row.valueEncrypted
        ? decryptIdentifier(row.valueEncrypted)
        : null
      : row.valueMasked;
    if (!raw) {
      console.warn(`пропуск ${row.id}: нет исходного значения`);
      continue;
    }
    const normalized = normalizeIdentifier(type, raw);
    const newHash = hashIdentifier(normalized);
    const newMask = maskIdentifier(type, normalized);
    if (newHash === row.valueHash && newMask === row.valueMasked) continue;

    changed++;
    console.log(`${DRY ? '[dry] ' : ''}${type} ${row.id}: ${row.valueMasked} → ${newMask}${newHash !== row.valueHash ? ' (хеш обновлён)' : ''}`);
    if (DRY) continue;

    await prisma.$transaction(async (tx) => {
      await tx.identifier.update({
        where: { id: row.id },
        data: { valueHash: newHash, valueMasked: newMask, valueEncrypted: isSensitiveIdentifierType(type) ? encryptIdentifier(normalized) : null },
      });
      // Блокировки по старому хешу переезжают на новый — иначе чёрный
      // список «осиротеет».
      if (newHash !== row.valueHash) {
        const res = await tx.blockedIdentifier.updateMany({
          where: { type: row.type, valueHash: row.valueHash },
          data: { valueHash: newHash, valueMasked: newMask },
        });
        blockedUpdated += res.count;
      }
    });
  }
  console.log(`Готово: изменено identifiers — ${changed}, блокировок перенесено — ${blockedUpdated}${DRY ? ' (dry run)' : ''}.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
