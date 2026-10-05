import { WeComService } from './wecom.service';

const VALID_URL = 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=test-key-123';

describe('WeComService.send', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('posts a text message to the webhook', async () => {
    const fetchMock = jest.fn().mockResolvedValue({ ok: true, type: 'basic', json: async () => ({ errcode: 0 }) });
    global.fetch = fetchMock as any;
    const service = new WeComService();

    await service.send(VALID_URL, 'Hello');

    expect(fetchMock).toHaveBeenCalledWith(
      VALID_URL,
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ msgtype: 'text', text: { content: 'Hello' } }),
        redirect: 'manual',
      }),
    );
  });

  it('throws when WeCom responds with a non-zero errcode', async () => {
    global.fetch = jest.fn().mockResolvedValue({ ok: true, type: 'basic', json: async () => ({ errcode: 93000, errmsg: 'invalid webhook url' }) }) as any;
    const service = new WeComService();

    await expect(service.send(VALID_URL, 'Hello')).rejects.toThrow('93000');
  });

  it('throws when the HTTP request itself fails', async () => {
    global.fetch = jest.fn().mockResolvedValue({ ok: false, status: 404, type: 'basic', text: async () => 'not found' }) as any;
    const service = new WeComService();

    await expect(service.send(VALID_URL, 'Hello')).rejects.toThrow('404');
  });

  describe('SSRF protection (задача 029, п.2)', () => {
    const fetchMock = jest.fn();
    beforeEach(() => {
      fetchMock.mockClear();
      global.fetch = fetchMock as any;
    });

    const maliciousUrls = [
      'http://169.254.169.254/latest/meta-data/',
      'http://minio:9000/some-bucket',
      'http://localhost:3000/admin/stats',
      'https://evil.example.com/cgi-bin/webhook/send?key=x',
      'https://qyapi.weixin.qq.com.evil.com/cgi-bin/webhook/send?key=x',
      'ftp://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=x',
      'https://qyapi.weixin.qq.com/some/other/path?key=x',
      'https://qyapi.weixin.qq.com/cgi-bin/webhook/send',
      'not a url at all',
    ];

    it.each(maliciousUrls)('rejects %s without ever calling fetch', async (url) => {
      const service = new WeComService();
      await expect(service.send(url, 'Hello')).rejects.toThrow('Invalid WeCom webhook URL');
      expect(fetchMock).not.toHaveBeenCalled();
    });

    it('treats a redirect response (opaqueredirect) as a failure instead of following it', async () => {
      fetchMock.mockResolvedValue({ ok: false, status: 0, type: 'opaqueredirect' });
      const service = new WeComService();

      await expect(service.send(VALID_URL, 'Hello')).rejects.toThrow('WeCom webhook failed');
      // убеждаемся, что именно redirect:'manual' был передан — иначе fetch
      // сам пошёл бы по Location, и этот тест ничего бы не проверял
      expect(fetchMock).toHaveBeenCalledWith(VALID_URL, expect.objectContaining({ redirect: 'manual' }));
    });

    it('aborts the request after 5 seconds', async () => {
      jest.useFakeTimers();
      let capturedSignal: AbortSignal | undefined;
      fetchMock.mockImplementation((_url: string, options: RequestInit) => {
        capturedSignal = options.signal as AbortSignal;
        return new Promise(() => {}); // никогда не резолвится — таймаут должен сработать первым
      });
      const service = new WeComService();

      const pending = service.send(VALID_URL, 'Hello');
      jest.advanceTimersByTime(5000);

      expect(capturedSignal?.aborted).toBe(true);
      jest.useRealTimers();
      // не ждём pending — мок fetch никогда не резолвится, это нормально для этого теста
      void pending;
    });
  });
});
