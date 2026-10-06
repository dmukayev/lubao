import { JobLockService } from './job-lock.service';

function makeRedis(initial: Record<string, string> = {}) {
  const store = new Map(Object.entries(initial));
  return {
    store,
    client: {
      set: jest.fn(async (key: string, value: string, _ex: string, _ttl: number, nx: string) => {
        if (nx === 'NX' && store.has(key)) return null;
        store.set(key, value);
        return 'OK';
      }),
      eval: jest.fn(async (_script: string, _n: number, key: string, token: string) => {
        if (store.get(key) === token) {
          store.delete(key);
          return 1;
        }
        return 0;
      }),
    },
  };
}

describe('JobLockService (задача 042, п.4: блокировка в Redis)', () => {
  it('выполняет задачу и снимает замок', async () => {
    const redis = makeRedis();
    const lock = new JobLockService(redis as any);
    const task = jest.fn().mockResolvedValue(42);

    const res = await lock.runExclusive('rates', 60, task);

    expect(res).toEqual({ ran: true, result: 42 });
    expect(redis.store.has('job:lock:rates')).toBe(false);
  });

  it('второй экземпляр, пока замок занят, задачу не запускает', async () => {
    const redis = makeRedis({ 'job:lock:rates': 'other-instance' });
    const lock = new JobLockService(redis as any);
    const task = jest.fn();

    const res = await lock.runExclusive('rates', 60, task);

    expect(res).toEqual({ ran: false });
    expect(task).not.toHaveBeenCalled();
    expect(redis.store.get('job:lock:rates')).toBe('other-instance');
  });

  it('падение задачи снимает замок и пробрасывает ошибку', async () => {
    const redis = makeRedis();
    const lock = new JobLockService(redis as any);

    await expect(lock.runExclusive('rates', 60, async () => { throw new Error('boom'); })).rejects.toThrow('boom');
    expect(redis.store.has('job:lock:rates')).toBe(false);
  });

  it('чужой замок после истечения нашего TTL не снимаем (снятие — только владельцем)', async () => {
    const redis = makeRedis();
    const lock = new JobLockService(redis as any);

    const res = await lock.runExclusive('slow', 60, async () => {
      // Наш замок истёк, и его занял другой экземпляр.
      redis.store.set('job:lock:slow', 'new-owner');
      return 'done';
    });

    expect(res).toEqual({ ran: true, result: 'done' });
    expect(redis.store.get('job:lock:slow')).toBe('new-owner');
  });

  it('устанавливает TTL, чтобы упавший экземпляр не держал замок вечно', async () => {
    const redis = makeRedis();
    const lock = new JobLockService(redis as any);
    await lock.runExclusive('x', 120, async () => 1);
    expect(redis.client.set).toHaveBeenCalledWith('job:lock:x', expect.any(String), 'EX', 120, 'NX');
  });
});
