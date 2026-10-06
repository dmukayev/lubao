import { HttpException, HttpStatus } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';

export const DAILY_UPLOAD_LIMIT = 50;

/// Квота загрузок на пользователя в сутки (задача 043, п.4): 50 файлов, все
/// виды вместе. Счётчик в Redis с суточным окном от первой загрузки.
export async function consumeUploadQuota(redis: RedisService, userId: string, limit = DAILY_UPLOAD_LIMIT): Promise<void> {
  const key = `uploads:count:${userId}`;
  const count = await redis.client.incr(key);
  if (count === 1) await redis.client.expire(key, 24 * 60 * 60);
  if (count > limit) {
    throw new HttpException({ code: 'UPLOAD_QUOTA_EXCEEDED', message: `Daily upload limit of ${limit} files reached` }, HttpStatus.TOO_MANY_REQUESTS);
  }
}
