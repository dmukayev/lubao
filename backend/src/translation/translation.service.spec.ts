import { TranslationService } from './translation.service';

describe('TranslationService.translateMessage (задача 010; задача 029, п.5)', () => {
  let prisma: any;
  let redis: any;
  let provider: any;
  let queue: any;
  let service: TranslationService;

  beforeEach(() => {
    prisma = { translationLog: { create: jest.fn().mockResolvedValue(undefined) } };
    redis = { client: { incr: jest.fn().mockResolvedValue(1), expire: jest.fn().mockResolvedValue(undefined) } };
    provider = { isAvailable: true, translate: jest.fn() };
    queue = { add: jest.fn().mockResolvedValue(undefined) };
    service = new TranslationService(prisma, redis, provider, queue);
  });

  it('skips translation entirely when sender and recipient share a language', async () => {
    const result = await service.translateMessage('u1', 'Привет', 'ru', 'ru');

    expect(result).toEqual({ translations: {}, status: 'SKIPPED' });
    expect(provider.translate).not.toHaveBeenCalled();
  });

  it('translates, unmasks numbers, and logs successful usage', async () => {
    provider.translate.mockResolvedValue({ translations: { zh: '货物在⟦1⟧' }, tokensUsed: 42 });

    const result = await service.translateMessage('u1', 'Груз в 18:30', 'ru', 'zh');

    expect(provider.translate).toHaveBeenCalledWith('Груз в ⟦1⟧', 'ru', ['zh']);
    expect(result).toEqual({ translations: { zh: '货物在18:30' }, status: 'DONE' });
    expect(prisma.translationLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ success: true, tokensUsed: 42 }) }),
    );
  });

  it('retries once and succeeds when the first attempt throws but the second works', async () => {
    provider.translate.mockRejectedValueOnce(new Error('timeout')).mockResolvedValueOnce({ translations: { zh: '你好' } });

    const result = await service.translateMessage('u1', 'Привет', 'ru', 'zh');

    expect(provider.translate).toHaveBeenCalledTimes(2);
    expect(result).toEqual({ translations: { zh: '你好' }, status: 'DONE' });
  });

  it('returns FAILED and logs two failed attempts when the provider throws twice in a row', async () => {
    provider.translate.mockRejectedValue(new Error('timeout'));

    const result = await service.translateMessage('u1', 'Привет', 'ru', 'zh');

    expect(provider.translate).toHaveBeenCalledTimes(2);
    expect(result).toEqual({ translations: {}, status: 'FAILED' });
    expect(prisma.translationLog.create).toHaveBeenCalledTimes(2);
    expect(prisma.translationLog.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ success: false }) }));
  });

  it('returns FAILED when the provider responds but omits the requested language, on both attempts', async () => {
    provider.translate.mockResolvedValue({ translations: {} });

    const result = await service.translateMessage('u1', 'Привет', 'ru', 'zh');

    expect(result.status).toBe('FAILED');
    expect(provider.translate).toHaveBeenCalledTimes(2);
  });

  describe('label-integrity guard (задача 029, п.5 — перевод не должен «съедать» числа)', () => {
    it('retries, then FAILS, when the model drops the label entirely (phone number silently disappears)', async () => {
      provider.translate.mockResolvedValue({ translations: { zh: '货物到了' } }); // ⟦1⟧ пропала

      const result = await service.translateMessage('u1', 'Буду в 18:30', 'ru', 'zh');

      expect(provider.translate).toHaveBeenCalledTimes(2);
      expect(result).toEqual({ translations: {}, status: 'FAILED' });
    });

    it('retries, then FAILS, when the model duplicates the label', async () => {
      provider.translate.mockResolvedValue({ translations: { zh: '⟦1⟧ и ещё раз ⟦1⟧' } });

      const result = await service.translateMessage('u1', 'Буду в 18:30', 'ru', 'zh');

      expect(result.status).toBe('FAILED');
    });

    it('retries, then FAILS, when the model substitutes a look-alike bracket style (【1】 instead of ⟦1⟧)', async () => {
      provider.translate.mockResolvedValue({ translations: { zh: '货物到了【1】' } });

      const result = await service.translateMessage('u1', 'Буду в 18:30', 'ru', 'zh');

      expect(result.status).toBe('FAILED');
    });

    it('succeeds on the second attempt if only the first response had a broken label', async () => {
      provider.translate
        .mockResolvedValueOnce({ translations: { zh: '货物到了' } }) // пропала метка
        .mockResolvedValueOnce({ translations: { zh: '货物在⟦1⟧' } }); // а тут всё на месте

      const result = await service.translateMessage('u1', 'Буду в 18:30', 'ru', 'zh');

      expect(provider.translate).toHaveBeenCalledTimes(2);
      expect(result).toEqual({ translations: { zh: '货物在18:30' }, status: 'DONE' });
    });
  });

  it('returns SKIPPED, not FAILED, when the provider is not configured (задача 029, п.20 — Noop default without a DeepSeek key)', async () => {
    provider.isAvailable = false;

    const result = await service.translateMessage('u1', 'Привет', 'ru', 'zh');

    expect(result).toEqual({ translations: {}, status: 'SKIPPED' });
    expect(provider.translate).not.toHaveBeenCalled();
  });

  it('skips (not fails) once the per-user rate limit is exceeded, without calling the provider', async () => {
    redis.client.incr.mockResolvedValue(61);

    const result = await service.translateMessage('u1', 'Привет', 'ru', 'zh');

    expect(result).toEqual({ translations: {}, status: 'SKIPPED' });
    expect(provider.translate).not.toHaveBeenCalled();
  });

  it('sets a 60s expiry only on the first message of the window', async () => {
    redis.client.incr.mockResolvedValue(1);
    provider.translate.mockResolvedValue({ translations: { zh: 'x' } });

    await service.translateMessage('u1', 'a', 'ru', 'zh');

    expect(redis.client.expire).toHaveBeenCalledWith('translation:rate:u1', 60);
  });
});

describe('TranslationService.enqueueTranslation (задача 029, п.6 — перевод в фоне, не на пути отправки)', () => {
  it('adds a job to the queue with retry/backoff options', async () => {
    const queue = { add: jest.fn().mockResolvedValue(undefined) };
    const service = new TranslationService({} as any, {} as any, {} as any, queue as any);

    await service.enqueueTranslation({ messageId: 'm1', chatId: 'c1', text: 'hi', from: 'ru', to: 'zh', senderUserId: 'u1' });

    expect(queue.add).toHaveBeenCalledWith(
      'translate',
      { messageId: 'm1', chatId: 'c1', text: 'hi', from: 'ru', to: 'zh', senderUserId: 'u1' },
      expect.objectContaining({ attempts: 3 }),
    );
  });

  it('resolves instead of hanging forever when queue.add never settles — задача 029, п.6/8 (Redis outage must not block send())', async () => {
    jest.useFakeTimers();
    const queue = { add: jest.fn().mockReturnValue(new Promise(() => {})) };
    const service = new TranslationService({} as any, {} as any, {} as any, queue as any);

    const promise = service.enqueueTranslation({ messageId: 'm1', chatId: 'c1', text: 'hi', from: 'ru', to: 'zh', senderUserId: 'u1' });
    await jest.advanceTimersByTimeAsync(3000);
    await expect(promise).resolves.toBeUndefined();

    jest.useRealTimers();
  });

  it('resolves instead of rejecting when queue.add rejects outright', async () => {
    const queue = { add: jest.fn().mockRejectedValue(new Error('ECONNREFUSED')) };
    const service = new TranslationService({} as any, {} as any, {} as any, queue as any);

    await expect(
      service.enqueueTranslation({ messageId: 'm1', chatId: 'c1', text: 'hi', from: 'ru', to: 'zh', senderUserId: 'u1' }),
    ).resolves.toBeUndefined();
  });
});
