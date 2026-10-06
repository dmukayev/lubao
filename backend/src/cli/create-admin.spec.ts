import * as bcrypt from 'bcryptjs';
import { bootstrapAdminFromEnv, createAdmin, validateAdminCredentials } from './create-admin';

function makeDb(existing: Record<string, unknown> | null = null, adminCount = 0) {
  return {
    user: {
      findUnique: jest.fn().mockResolvedValue(existing),
      create: jest.fn().mockResolvedValue({ id: 'new-admin' }),
      update: jest.fn().mockResolvedValue({}),
      count: jest.fn().mockResolvedValue(adminCount),
    },
  } as any;
}

describe('admin:create (задача 043, п.5)', () => {
  describe('validateAdminCredentials', () => {
    it('нормальные данные — без замечаний', () => {
      expect(validateAdminCredentials('admin@lubao.kz', 'Correct-Horse-9')).toBeNull();
    });
    it.each([
      ['не email', 'admin', 'Correct-Horse-9', 'email'],
      ['короткий пароль', 'admin@lubao.kz', 'short1', 'короче'],
      ['пароль из одного символа', 'admin@lubao.kz', 'aaaaaaaaaaaaaaaa', 'простой'],
      ['очевидный пароль', 'admin@lubao.kz', 'password123456', 'простой'],
    ])('%s — отказ', (_n, email, password, mention) => {
      expect(validateAdminCredentials(email, password)).toContain(mention);
    });
  });

  describe('createAdmin', () => {
    it('создаёт ADMIN с bcrypt-хэшем (пароль в базе открытым не лежит), email нормализуется', async () => {
      const db = makeDb();
      const res = await createAdmin(db, { email: '  Admin@Lubao.KZ ', password: 'Correct-Horse-9' });
      expect(res).toEqual({ id: 'new-admin', created: true });
      const data = db.user.create.mock.calls[0][0].data;
      expect(data).toMatchObject({ role: 'ADMIN', email: 'admin@lubao.kz' });
      expect(data.passwordHash).not.toContain('Correct-Horse-9');
      expect(await bcrypt.compare('Correct-Horse-9', data.passwordHash)).toBe(true);
    });

    it('повторный запуск для существующего админа сбрасывает пароль, а не плодит второго', async () => {
      const db = makeDb({ id: 'a1', role: 'ADMIN' });
      const res = await createAdmin(db, { email: 'admin@lubao.kz', password: 'Another-Pass-77' });
      expect(res).toEqual({ id: 'a1', created: false });
      expect(db.user.create).not.toHaveBeenCalled();
      expect(db.user.update).toHaveBeenCalledWith({ where: { id: 'a1' }, data: { passwordHash: expect.stringMatching(/^\$2[aby]\$/) } });
    });

    it('аккаунт водителя/логиста с таким email админом не становится — ошибка', async () => {
      const db = makeDb({ id: 'u1', role: 'COMPANY' });
      await expect(createAdmin(db, { email: 'logist@example.com', password: 'Correct-Horse-9' })).rejects.toThrow('не является администратором');
      expect(db.user.update).not.toHaveBeenCalled();
    });
  });

  describe('bootstrapAdminFromEnv — первый старт на чистом сервере', () => {
    const HASH = bcrypt.hashSync('Correct-Horse-9', 4);

    it('админов нет и env задан — создаёт первого с готовым хэшем', async () => {
      const db = makeDb(null, 0);
      expect(await bootstrapAdminFromEnv(db, { ADMIN_BOOTSTRAP_EMAIL: 'root@lubao.kz', ADMIN_BOOTSTRAP_PASSWORD_HASH: HASH })).toBe(true);
      expect(db.user.create.mock.calls[0][0].data).toMatchObject({ role: 'ADMIN', email: 'root@lubao.kz', passwordHash: HASH });
    });

    it('админ уже есть — env игнорируется (повторный старт ничего не меняет)', async () => {
      const db = makeDb(null, 1);
      expect(await bootstrapAdminFromEnv(db, { ADMIN_BOOTSTRAP_EMAIL: 'root@lubao.kz', ADMIN_BOOTSTRAP_PASSWORD_HASH: HASH })).toBe(false);
      expect(db.user.create).not.toHaveBeenCalled();
    });

    it('env не задан — ничего не делает', async () => {
      const db = makeDb();
      expect(await bootstrapAdminFromEnv(db, {})).toBe(false);
      expect(db.user.count).not.toHaveBeenCalled();
    });

    it('вместо хэша положили пароль — отказ (иначе открытый пароль жил бы в env)', async () => {
      const db = makeDb();
      await expect(bootstrapAdminFromEnv(db, { ADMIN_BOOTSTRAP_EMAIL: 'root@lubao.kz', ADMIN_BOOTSTRAP_PASSWORD_HASH: 'Correct-Horse-9' })).rejects.toThrow('bcrypt-хэшем');
      expect(db.user.create).not.toHaveBeenCalled();
    });
  });
});
