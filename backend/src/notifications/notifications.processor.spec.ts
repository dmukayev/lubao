import { UnrecoverableError } from 'bullmq';
import { NotificationsProcessor } from './notifications.processor';
import { PushTokenGoneError, isApnsTokenGone, isFcmTokenGone } from './push/push-provider';

/// Умерший токен устройства: удаляется, повторов нет; прочие ошибки — повтор BullMQ.
describe('NotificationsProcessor — умерший push-токен', () => {
  const job = { channel: 'PUSH', token: 'dRxb16-token', platform: 'FCM', title: 't', body: 'b', data: {} } as any;
  function make(err: Error | null) {
    const push = { send: jest.fn(err ? () => Promise.reject(err) : () => Promise.resolve()) };
    const prisma: any = { deviceToken: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) } };
    return { push, prisma, p: new NotificationsProcessor(push as any, {} as any, prisma) };
  }

  it('FCM ответил «токен не зарегистрирован» → токен удалён, задание без повторов', async () => {
    const { p, prisma } = make(new PushTokenGoneError('FCM token gone: 404'));
    await expect(p.process(job)).rejects.toBeInstanceOf(UnrecoverableError);
    expect(prisma.deviceToken.deleteMany).toHaveBeenCalledWith({ where: { token: 'dRxb16-token' } });
  });

  it('сеть/квота/ключ → ошибка как есть (BullMQ повторит), токен не трогаем', async () => {
    const { p, prisma } = make(new Error('FCM send failed: 503'));
    await expect(p.process(job)).rejects.toThrow('FCM send failed: 503');
    expect(prisma.deviceToken.deleteMany).not.toHaveBeenCalled();
  });

  it('распознавание ответов FCM и APNs', () => {
    expect(isFcmTokenGone(404, '{"error":{"status":"NOT_FOUND","details":[{"errorCode":"UNREGISTERED"}]}}')).toBe(true);
    expect(isFcmTokenGone(400, 'The registration token is not a valid FCM registration token')).toBe(true);
    expect(isFcmTokenGone(400, 'Invalid JSON payload')).toBe(false);
    expect(isFcmTokenGone(503, 'UNAVAILABLE')).toBe(false);
    expect(isApnsTokenGone(410, '{"reason":"Unregistered"}')).toBe(true);
    expect(isApnsTokenGone(400, '{"reason":"BadDeviceToken"}')).toBe(true);
    expect(isApnsTokenGone(403, '{"reason":"InvalidProviderToken"}')).toBe(false);
  });
});
