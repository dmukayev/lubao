/// Защита от зависшего Redis (задача 029, п.8): BullMQ требует
/// `maxRetriesPerRequest: null` на соединении (иначе сам кидает ошибку
/// валидации опций при старте), а это значит ioredis при недоступном
/// Redis ретраит команду БЕСКОНЕЧНО — `queue.add()` никогда не
/// резолвится и не падает сам по себе. Без этой обёртки `await
/// notify(...)`/`await enqueueTranslation(...)` подвесили бы весь HTTP-
/// запрос (отправку сообщения, отклик на груз и т.д.) навечно при
/// простом перезапуске Redis. Настоящие ошибки (быстрый reject) всё
/// равно долетают до вызывающего — таймаут только ограничивает ЗАВИСШИЙ
/// случай.
export function withTimeout<T>(promise: Promise<T>, ms: number, timeoutMessage: string): Promise<T> {
  let timer: ReturnType<typeof setTimeout>;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error(timeoutMessage)), ms);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}
