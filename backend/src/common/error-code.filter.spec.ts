import { BadRequestException, ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { ErrorCodeFilter } from './error-code.filter';
import { resolveErrorCode, USER_ERROR_CODES } from './error-codes';

function run(exception: unknown) {
  const res: any = { status: jest.fn().mockReturnThis(), json: jest.fn() };
  const host: any = { getType: () => 'http', switchToHttp: () => ({ getResponse: () => res }) };
  const onServerError = jest.fn();
  new ErrorCodeFilter(onServerError).catch(exception, host);
  return { status: res.status.mock.calls[0][0], body: res.json.mock.calls[0][0], onServerError };
}

describe('074: у каждой ошибки — код и номер', () => {
  it('свой код остаётся, номер добавляется', () => {
    const { status, body } = run(new ConflictException({ code: 'PRICE_CHANGED', message: 'x' }));
    expect(status).toBe(409);
    expect(body).toMatchObject({ code: 'PRICE_CHANGED', message: 'x', requestId: expect.stringMatching(/^[0-9a-f]{8}$/) });
  });

  it('текст-код и текст из таблицы → код; иначе — по статусу', () => {
    expect(run(new BadRequestException('POINT_REQUIRED')).body.code).toBe('POINT_REQUIRED');
    expect(run(new NotFoundException('Cargo not found')).body.code).toBe('CARGO_NOT_FOUND');
    expect(run(new ForbiddenException('Not a driver account')).body.code).toBe('NOT_DRIVER_ACCOUNT');
    expect(run(new NotFoundException('Something odd')).body.code).toBe('NOT_FOUND');
    expect(resolveErrorCode(400, { message: ['a must be b'] })).toBe('BAD_REQUEST');
  });

  it('неизвестная ошибка — 500 SERVER_ERROR без подробностей, в журнал/Sentry', () => {
    const { status, body, onServerError } = run(new Error('db is down: password=secret'));
    expect(status).toBe(500);
    expect(body).toEqual({ statusCode: 500, code: 'SERVER_ERROR', message: 'Internal server error', requestId: expect.any(String) });
    expect(onServerError).toHaveBeenCalled();
  });

  it('все коды из таблицы текстов — в списке для перевода', () => {
    const { MESSAGE_CODES } = jest.requireActual('./error-codes');
    for (const code of Object.values(MESSAGE_CODES) as string[]) expect(USER_ERROR_CODES).toContain(code);
  });
});

describe('074: каждый код ошибки сервера — в списке для перевода', () => {
  it('коды в throw … Exception({ code }) и текстах-кодах есть в USER_ERROR_CODES / SPECIAL_CODES', () => {
    const fs = jest.requireActual('fs') as typeof import('fs');
    const path = jest.requireActual('path') as typeof import('path');
    const { SPECIAL_CODES } = jest.requireActual('./error-codes');
    const files: string[] = [];
    const walk = (dir: string) => {
      for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
        const p = path.join(dir, e.name);
        if (e.isDirectory()) walk(p);
        else if (p.endsWith('.ts') && !p.endsWith('.spec.ts')) files.push(p);
      }
    };
    walk(path.join(__dirname, '..'));
    const known = new Set<string>([...USER_ERROR_CODES, ...SPECIAL_CODES]);
    const missing = new Set<string>();
    for (const f of files) {
      const src = fs.readFileSync(f, 'utf8');
      // throw new XxxException({ code: 'CODE' …   и   throw new XxxException('CODE')
      for (const m of src.matchAll(/Exception\(\s*\{\s*code:\s*'([A-Z][A-Z0-9_]+)'/g)) if (!known.has(m[1])) missing.add(`${m[1]} (${path.basename(f)})`);
      for (const m of src.matchAll(/Exception\('([A-Z][A-Z0-9_]+)'\)/g)) if (!known.has(m[1])) missing.add(`${m[1]} (${path.basename(f)})`);
    }
    expect([...missing]).toEqual([]);
  });
});
