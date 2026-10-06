import { randomUUID } from 'crypto';
import { Injectable } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';

const RELEASE_IF_OWNER = `
if redis.call('get', KEYS[1]) == ARGV[1] then
  return redis.call('del', KEYS[1])
end
return 0`;

/// Блокировка фоновых задач в Redis (задача 042, п.4): при нескольких
/// экземплярах бэкенда задача идёт ровно в одном; замок сам истекает через
/// `ttlSeconds`, если экземпляр упал посреди задачи. Сама задача при этом
/// всё равно идемпотентна — замок защищает от лишней работы, а не от порчи.
@Injectable()
export class JobLockService {
  constructor(private readonly redis: RedisService) {}

  async runExclusive<T>(name: string, ttlSeconds: number, task: () => Promise<T>): Promise<{ ran: true; result: T } | { ran: false }> {
    const key = `job:lock:${name}`;
    const token = randomUUID();
    const acquired = await this.redis.client.set(key, token, 'EX', ttlSeconds, 'NX');
    if (acquired !== 'OK') return { ran: false };
    try {
      return { ran: true, result: await task() };
    } finally {
      await this.redis.client.eval(RELEASE_IF_OWNER, 1, key, token).catch(() => undefined);
    }
  }
}
