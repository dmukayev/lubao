/// Предохранитель прода (задача 043, п.3): при NODE_ENV=production сервер
/// не стартует с dev-настройками. Чистая функция — её проверяют тесты, а
/// main.ts лишь вызывает и завершает процесс.

const DEFAULT_SECRETS = new Set(['', 'lubao', 'postgres', 'password', 'changeme', 'minioadmin', 'lubao_minio_password']);
const MIN_JWT_SECRET = 32;
const MIN_IDENTIFIER_KEY = 32;
const MIN_PEPPER = 16;

function passwordOf(databaseUrl: string | undefined): string | null {
  if (!databaseUrl) return null;
  try {
    return decodeURIComponent(new URL(databaseUrl).password);
  } catch {
    return null;
  }
}

export function productionConfigProblems(env: NodeJS.ProcessEnv): string[] {
  const problems: string[] = [];

  if (env.SMS_PROVIDER !== 'mobizon') {
    problems.push('SMS_PROVIDER должен быть mobizon: консольный провайдер отдаёт код 1111 всем');
  } else if (!env.MOBIZON_API_KEY) {
    problems.push('MOBIZON_API_KEY не задан: SMS не уйдут');
  }

  if (env.EMAIL_PROVIDER !== 'smtp') {
    problems.push('EMAIL_PROVIDER должен быть smtp: консольный провайдер не отправляет письма');
  } else {
    if (!env.SMTP_HOST) problems.push('SMTP_HOST не задан');
    if (!env.SMTP_FROM && !env.SMTP_USER) problems.push('SMTP_FROM (или SMTP_USER) не задан');
  }

  const origins = (env.CORS_ALLOWED_ORIGINS ?? '').split(',').map((o) => o.trim()).filter(Boolean);
  if (origins.length === 0) problems.push('CORS_ALLOWED_ORIGINS пуст: без него CORS открыт для всех');
  else if (origins.includes('*')) problems.push('CORS_ALLOWED_ORIGINS содержит «*»');

  const dbPassword = passwordOf(env.DATABASE_URL);
  if (dbPassword === null) problems.push('DATABASE_URL не задан или некорректен');
  else if (DEFAULT_SECRETS.has(dbPassword.toLowerCase())) problems.push('пароль Postgres в DATABASE_URL — значение по умолчанию');

  const minioSecret = env.MINIO_SECRET_KEY ?? '';
  if (DEFAULT_SECRETS.has(minioSecret.toLowerCase()) || minioSecret.length < 16) {
    problems.push('MINIO_SECRET_KEY — значение по умолчанию или короче 16 символов');
  }

  if ((env.JWT_ACCESS_SECRET ?? '').length < MIN_JWT_SECRET) problems.push(`JWT_ACCESS_SECRET короче ${MIN_JWT_SECRET} символов`);
  if ((env.IDENTIFIER_KEY ?? '').length < MIN_IDENTIFIER_KEY) problems.push(`IDENTIFIER_KEY короче ${MIN_IDENTIFIER_KEY} символов`);
  if ((env.IDENTIFIER_PEPPER ?? '').length < MIN_PEPPER) problems.push(`IDENTIFIER_PEPPER короче ${MIN_PEPPER} символов`);

  if (!/^https:\/\//.test(env.APP_PUBLIC_URL ?? '')) problems.push('APP_PUBLIC_URL должен быть https-адресом: ссылки приглашений и force-update');

  return problems;
}

/// Вызывается из main.ts: в проде с проблемами — печатает их и завершает процесс.
export function assertProductionConfig(env: NodeJS.ProcessEnv, exit: (code: number) => never = (code) => process.exit(code), log: (msg: string) => void = (m) => console.error(m)): void {
  if (env.NODE_ENV !== 'production') return;
  const problems = productionConfigProblems(env);
  if (problems.length === 0) return;
  log('Сервер не стартует: небезопасная конфигурация для NODE_ENV=production:');
  for (const p of problems) log(`  • ${p}`);
  exit(1);
}
