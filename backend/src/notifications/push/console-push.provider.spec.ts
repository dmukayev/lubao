import { Logger } from '@nestjs/common';
import { ConsolePushProvider } from './console-push.provider';

/// Задача 029, п.12 — лог разработки не должен содержать текст
/// уведомления (имя собеседника, превью сообщения, причину отмены и
/// т.п.), только тип события и deep-link id.
describe('ConsolePushProvider logs only event metadata, never the notification text (задача 029, п.12)', () => {
  it('does not include title or body in the log line', async () => {
    const logSpy = jest.spyOn(Logger.prototype, 'log').mockImplementation();
    const provider = new ConsolePushProvider();

    await provider.send('token-abcdefghijklmnop', 'ANDROID' as any, {
      title: 'Асхат Ниязов',
      body: 'Привет, груз ещё актуален?',
      data: { event: 'CHAT_MESSAGE', deepLink: '/chats/chat1' },
    });

    expect(logSpy).toHaveBeenCalledTimes(1);
    const line = logSpy.mock.calls[0][0] as string;
    expect(line).not.toContain('Асхат Ниязов');
    expect(line).not.toContain('Привет, груз ещё актуален?');
    expect(line).toContain('CHAT_MESSAGE');
    expect(line).toContain('/chats/chat1');

    logSpy.mockRestore();
  });
});
