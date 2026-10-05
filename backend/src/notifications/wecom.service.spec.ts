import { WeComService } from './wecom.service';

describe('WeComService.send', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('posts a text message to the webhook', async () => {
    const fetchMock = jest.fn().mockResolvedValue({ ok: true, json: async () => ({ errcode: 0 }) });
    global.fetch = fetchMock as any;
    const service = new WeComService();

    await service.send('https://wecom.example/hook', 'Hello');

    expect(fetchMock).toHaveBeenCalledWith(
      'https://wecom.example/hook',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ msgtype: 'text', text: { content: 'Hello' } }),
      }),
    );
  });

  it('throws when WeCom responds with a non-zero errcode', async () => {
    global.fetch = jest.fn().mockResolvedValue({ ok: true, json: async () => ({ errcode: 93000, errmsg: 'invalid webhook url' }) }) as any;
    const service = new WeComService();

    await expect(service.send('https://wecom.example/hook', 'Hello')).rejects.toThrow('93000');
  });

  it('throws when the HTTP request itself fails', async () => {
    global.fetch = jest.fn().mockResolvedValue({ ok: false, status: 404, text: async () => 'not found' }) as any;
    const service = new WeComService();

    await expect(service.send('https://wecom.example/hook', 'Hello')).rejects.toThrow('404');
  });
});
