import { assertProductionConfig, productionConfigProblems } from './production-guard';

const GOOD: NodeJS.ProcessEnv = {
  NODE_ENV: 'production',
  SMS_PROVIDER: 'mobizon',
  MOBIZON_API_KEY: 'key',
  EMAIL_PROVIDER: 'smtp',
  SMTP_HOST: 'smtp.example.com',
  SMTP_FROM: 'Lubao <no-reply@lubao.kz>',
  CORS_ALLOWED_ORIGINS: 'https://app.lubao.kz',
  DATABASE_URL: 'postgresql://lubao:Xk3-very-strong-pw@postgres:5432/lubao?schema=public',
  MINIO_SECRET_KEY: 'a-long-random-minio-secret',
  JWT_ACCESS_SECRET: 'x'.repeat(48),
  IDENTIFIER_KEY: 'k'.repeat(64),
  IDENTIFIER_PEPPER: 'p'.repeat(32),
  APP_PUBLIC_URL: 'https://app.lubao.kz',
};

describe('предохранитель прода (задача 043, п.3)', () => {
  it('хорошая конфигурация — проблем нет', () => {
    expect(productionConfigProblems(GOOD)).toEqual([]);
  });

  it.each([
    ['консольный SMS (код 1111 всем)', { SMS_PROVIDER: 'console' }, 'SMS_PROVIDER'],
    ['mobizon без ключа', { MOBIZON_API_KEY: '' }, 'MOBIZON_API_KEY'],
    ['консольная почта', { EMAIL_PROVIDER: 'console' }, 'EMAIL_PROVIDER'],
    ['SMTP без хоста', { SMTP_HOST: '' }, 'SMTP_HOST'],
    ['пустой CORS', { CORS_ALLOWED_ORIGINS: '' }, 'CORS_ALLOWED_ORIGINS'],
    ['CORS «*»', { CORS_ALLOWED_ORIGINS: 'https://a.kz,*' }, '«*»'],
    ['пароль Postgres по умолчанию', { DATABASE_URL: 'postgresql://lubao:lubao@postgres:5432/lubao' }, 'Postgres'],
    ['нет DATABASE_URL', { DATABASE_URL: '' }, 'DATABASE_URL'],
    ['пароль MinIO по умолчанию', { MINIO_SECRET_KEY: 'lubao_minio_password' }, 'MINIO_SECRET_KEY'],
    ['короткий MinIO-секрет', { MINIO_SECRET_KEY: 'short' }, 'MINIO_SECRET_KEY'],
    ['короткий JWT-секрет', { JWT_ACCESS_SECRET: 'x'.repeat(31) }, 'JWT_ACCESS_SECRET'],
    ['короткий IDENTIFIER_KEY', { IDENTIFIER_KEY: 'k'.repeat(10) }, 'IDENTIFIER_KEY'],
    ['короткий IDENTIFIER_PEPPER', { IDENTIFIER_PEPPER: 'p' }, 'IDENTIFIER_PEPPER'],
    ['http вместо https для APP_PUBLIC_URL', { APP_PUBLIC_URL: 'http://app.lubao.kz' }, 'APP_PUBLIC_URL'],
  ])('%s — сервер не стартует', (_name, override, mention) => {
    const problems = productionConfigProblems({ ...GOOD, ...override });
    expect(problems.length).toBeGreaterThan(0);
    expect(problems.join('\n')).toContain(mention);
  });

  it('пустое окружение: перечислены все проблемы разом, а не по одной за запуск', () => {
    expect(productionConfigProblems({ NODE_ENV: 'production' }).length).toBeGreaterThanOrEqual(8);
  });

  describe('assertProductionConfig', () => {
    it('в проде с проблемами печатает причины и завершает процесс кодом 1', () => {
      const lines: string[] = [];
      const exit = jest.fn(() => {
        throw new Error('exit');
      }) as unknown as (code: number) => never;
      expect(() => assertProductionConfig({ NODE_ENV: 'production', SMS_PROVIDER: 'console' }, exit, (m) => lines.push(m))).toThrow('exit');
      expect(exit).toHaveBeenCalledWith(1);
      expect(lines.join('\n')).toContain('SMS_PROVIDER');
    });

    it('в проде с хорошей конфигурацией — стартует', () => {
      const exit = jest.fn() as unknown as (code: number) => never;
      assertProductionConfig(GOOD, exit, () => undefined);
      expect(exit).not.toHaveBeenCalled();
    });

    it('вне прода (dev/test) предохранитель молчит даже с консольными провайдерами', () => {
      const exit = jest.fn() as unknown as (code: number) => never;
      assertProductionConfig({ NODE_ENV: 'development', SMS_PROVIDER: 'console' }, exit, () => undefined);
      assertProductionConfig({}, exit, () => undefined);
      expect(exit).not.toHaveBeenCalled();
    });
  });
});
