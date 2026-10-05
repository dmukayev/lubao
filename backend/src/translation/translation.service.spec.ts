import { TranslationService } from './translation.service';

describe('TranslationService.translateMessage (задача 010)', () => {
  let prisma: any;
  let redis: any;
  let provider: any;
  let service: TranslationService;

  beforeEach(() => {
    prisma = { translationLog: { create: jest.fn().mockResolvedValue(undefined) } };
    redis = { client: { incr: jest.fn().mockResolvedValue(1), expire: jest.fn().mockResolvedValue(undefined) } };
    provider = { translate: jest.fn() };
    service = new TranslationService(prisma, redis, provider);
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

  it('returns FAILED and logs a failed attempt when the provider throws', async () => {
    provider.translate.mockRejectedValue(new Error('timeout'));

    const result = await service.translateMessage('u1', 'Привет', 'ru', 'zh');

    expect(result).toEqual({ translations: {}, status: 'FAILED' });
    expect(prisma.translationLog.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ success: false }) }));
  });

  it('returns FAILED when the provider responds but omits the requested language', async () => {
    provider.translate.mockResolvedValue({ translations: {} });

    const result = await service.translateMessage('u1', 'Привет', 'ru', 'zh');

    expect(result.status).toBe('FAILED');
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
