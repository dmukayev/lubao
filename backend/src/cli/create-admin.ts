import * as bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';

/// Заведение администратора в проде (задача 043, п.5): `pnpm admin:create
/// --email a@b.kz --password '…'` (или ADMIN_EMAIL/ADMIN_PASSWORD в env,
/// чтобы пароль не оседал в истории shell). Пароль хэшируется bcrypt,
/// открытым нигде не хранится и не печатается.

const MIN_PASSWORD_LENGTH = 12;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

type Db = Pick<PrismaClient, 'user'>;

export function validateAdminCredentials(email: string, password: string): string | null {
  if (!EMAIL_RE.test(email)) return 'Некорректный email';
  if (password.length < MIN_PASSWORD_LENGTH) return `Пароль короче ${MIN_PASSWORD_LENGTH} символов`;
  if (/^(.)\1+$/.test(password) || /^(password|qwerty|12345678)/i.test(password)) return 'Слишком простой пароль';
  return null;
}

/// Создаёт админа или сбрасывает пароль существующему админу. Аккаунт
/// водителя/логиста с этим email админом не становится — это ошибка, а не
/// тихое повышение прав.
export async function createAdmin(db: Db, input: { email: string; password?: string; passwordHash?: string }): Promise<{ id: string; created: boolean }> {
  const email = input.email.trim().toLowerCase();
  const passwordHash = input.passwordHash ?? (await bcrypt.hash(input.password!, 10));
  const existing = await db.user.findUnique({ where: { email } });
  if (existing) {
    if (existing.role !== 'ADMIN') throw new Error('Пользователь с таким email уже существует и не является администратором');
    await db.user.update({ where: { id: existing.id }, data: { passwordHash } });
    return { id: existing.id, created: false };
  }
  const user = await db.user.create({ data: { role: 'ADMIN', email, passwordHash, emailVerifiedAt: new Date() } });
  return { id: user.id, created: true };
}

/// Первый старт на чистом сервере: админов нет, в env заданы
/// ADMIN_BOOTSTRAP_EMAIL и ADMIN_BOOTSTRAP_PASSWORD_HASH (bcrypt-хэш, не пароль) —
/// создаём первого. Админы уже есть — env игнорируется.
export async function bootstrapAdminFromEnv(db: Db, env: NodeJS.ProcessEnv): Promise<boolean> {
  const email = env.ADMIN_BOOTSTRAP_EMAIL;
  const passwordHash = env.ADMIN_BOOTSTRAP_PASSWORD_HASH;
  if (!email || !passwordHash) return false;
  if (!/^\$2[aby]\$\d{2}\$/.test(passwordHash)) throw new Error('ADMIN_BOOTSTRAP_PASSWORD_HASH должен быть bcrypt-хэшем ($2b$…), а не паролем');
  if ((await db.user.count({ where: { role: 'ADMIN' } })) > 0) return false;
  await createAdmin(db, { email, passwordHash });
  return true;
}

function arg(name: string): string | undefined {
  const index = process.argv.indexOf(`--${name}`);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

async function main() {
  const email = arg('email') ?? process.env.ADMIN_EMAIL ?? '';
  const password = arg('password') ?? process.env.ADMIN_PASSWORD ?? '';
  const problem = validateAdminCredentials(email, password);
  if (problem) {
    console.error(`Администратор не создан: ${problem}`);
    process.exit(1);
  }
  const prisma = new PrismaClient();
  try {
    const { created } = await createAdmin(prisma, { email, password });
    console.log(created ? `Администратор ${email} создан.` : `Пароль администратора ${email} обновлён.`);
  } catch (e) {
    console.error(`Администратор не создан: ${(e as Error).message}`);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) void main();
