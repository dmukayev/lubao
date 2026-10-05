import { NotificationsService } from './notifications.service';

describe('NotificationsService.notify', () => {
  let prisma: any;
  let redis: any;
  let queue: any;
  let service: NotificationsService;

  beforeEach(() => {
    prisma = {
      notificationEventSetting: { findUnique: jest.fn().mockResolvedValue(null), findMany: jest.fn().mockResolvedValue([]), upsert: jest.fn() },
      notificationSetting: { findUnique: jest.fn().mockResolvedValue(null) },
      deviceToken: { findMany: jest.fn().mockResolvedValue([{ token: 'tok-1', platform: 'FCM' }]) },
      user: { findUnique: jest.fn().mockResolvedValue({ locale: 'ru' }) },
      company: { findUnique: jest.fn().mockResolvedValue({ wecomWebhookUrl: 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=test-key-123' }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ user: { locale: 'zh' } }) },
    };
    redis = { client: { set: jest.fn().mockResolvedValue('OK') } };
    queue = { add: jest.fn().mockResolvedValue(undefined) };
    service = new NotificationsService(prisma, redis, queue);
  });

  it('pushes to every device token of the recipient with rendered, localized text', async () => {
    prisma.deviceToken.findMany.mockResolvedValue([
      { token: 'tok-1', platform: 'FCM' },
      { token: 'tok-2', platform: 'APNS' },
    ]);

    await service.notify({ userIds: ['driver-1'] }, 'CARGO_INVITE', { cargoId: 'cargo-1', companyName: 'Yidao' });

    expect(queue.add).toHaveBeenCalledTimes(2);
    const [, firstJob] = queue.add.mock.calls[0];
    expect(firstJob).toEqual(
      expect.objectContaining({
        channel: 'PUSH',
        token: 'tok-1',
        platform: 'FCM',
        body: expect.stringContaining('Yidao'),
        data: expect.objectContaining({ deepLink: 'lubao://cargo/cargo-1', event: 'CARGO_INVITE' }),
      }),
    );
  });

  it('skips the user entirely when the event group is disabled', async () => {
    prisma.notificationEventSetting.findUnique.mockResolvedValue({ enabled: false });

    await service.notify({ userIds: ['driver-1'] }, 'CARGO_INVITE', { cargoId: 'cargo-1', companyName: 'Yidao' });

    expect(queue.add).not.toHaveBeenCalled();
  });

  it('skips the user when the PUSH channel itself is disabled', async () => {
    prisma.notificationSetting.findUnique.mockResolvedValue({ enabled: false });

    await service.notify({ userIds: ['driver-1'] }, 'CARGO_INVITE', { cargoId: 'cargo-1', companyName: 'Yidao' });

    expect(queue.add).not.toHaveBeenCalled();
  });

  it('skips a user with no registered device tokens', async () => {
    prisma.deviceToken.findMany.mockResolvedValue([]);

    await service.notify({ userIds: ['driver-1'] }, 'CARGO_INVITE', { cargoId: 'cargo-1', companyName: 'Yidao' });

    expect(queue.add).not.toHaveBeenCalled();
  });

  it('throttles CHAT_MESSAGE to at most one push per minute per chat+recipient', async () => {
    redis.client.set.mockResolvedValueOnce(null); // already throttled

    await service.notify({ userIds: ['driver-1'] }, 'CHAT_MESSAGE', { chatId: 'chat-1', senderName: 'Ли Вэй', preview: 'Привет' });

    expect(redis.client.set).toHaveBeenCalledWith(
      expect.stringContaining('chat:chat-1:driver-1'),
      '1',
      'EX',
      60,
      'NX',
    );
    expect(queue.add).not.toHaveBeenCalled();
  });

  it('sends one WeCom message to the company webhook, rendered in the owner locale', async () => {
    await service.notify({ companyId: 'company-1' }, 'NEW_RESPONSE', { driverName: 'Ерлан' });

    expect(queue.add).toHaveBeenCalledWith(
      'deliver',
      expect.objectContaining({ channel: 'WECOM', webhookUrl: 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=test-key-123', text: expect.stringContaining('Ерлан') }),
      expect.anything(),
    );
  });

  it('does not enqueue WeCom when the company has no webhook configured', async () => {
    prisma.company.findUnique.mockResolvedValue({ wecomWebhookUrl: null });

    await service.notify({ companyId: 'company-1' }, 'NEW_RESPONSE', { driverName: 'Ерлан' });

    expect(queue.add).not.toHaveBeenCalled();
  });

  it('sends both PUSH (to specific users) and WECOM (to the company) when a target has both', async () => {
    await service.notify({ userIds: ['logist-1'], companyId: 'company-1' }, 'NEW_RESPONSE', { driverName: 'Ерлан' });

    expect(queue.add).toHaveBeenCalledWith('deliver', expect.objectContaining({ channel: 'PUSH' }), expect.anything());
    expect(queue.add).toHaveBeenCalledWith('deliver', expect.objectContaining({ channel: 'WECOM' }), expect.anything());
  });
});

describe('NotificationsService settings', () => {
  it('getEventSettings returns every event group, defaulting unset ones to enabled:true', async () => {
    const prisma = {
      notificationEventSetting: {
        findMany: jest.fn().mockResolvedValue([{ eventGroup: 'CHAT_MESSAGE', enabled: false }]),
      },
    };
    const service = new NotificationsService(prisma as any, {} as any, {} as any);

    const settings = await service.getEventSettings('user-1');

    expect(settings).toEqual(
      expect.arrayContaining([
        { eventGroup: 'CHAT_MESSAGE', enabled: false },
        { eventGroup: 'DEAL_STATUS', enabled: true },
      ]),
    );
  });

  it('setEventSetting upserts the row', async () => {
    const prisma = { notificationEventSetting: { upsert: jest.fn().mockResolvedValue(undefined) } };
    const service = new NotificationsService(prisma as any, {} as any, {} as any);

    const result = await service.setEventSetting('user-1', 'CHAT_MESSAGE', false);

    expect(prisma.notificationEventSetting.upsert).toHaveBeenCalledWith({
      where: { userId_eventGroup: { userId: 'user-1', eventGroup: 'CHAT_MESSAGE' } },
      update: { enabled: false },
      create: { userId: 'user-1', eventGroup: 'CHAT_MESSAGE', enabled: false },
    });
    expect(result).toEqual({ eventGroup: 'CHAT_MESSAGE', enabled: false });
  });
});

describe('NotificationsService — не подвешивает и не роняет вызывающего при сбое Redis (задача 029, п.8)', () => {
  function fixture() {
    return {
      prisma: {
        notificationEventSetting: { findUnique: jest.fn().mockResolvedValue(null) },
        notificationSetting: { findUnique: jest.fn().mockResolvedValue(null) },
        deviceToken: { findMany: jest.fn().mockResolvedValue([{ token: 'tok-1', platform: 'FCM' }]) },
        user: { findUnique: jest.fn().mockResolvedValue({ locale: 'ru' }) },
        company: { findUnique: jest.fn().mockResolvedValue({ wecomWebhookUrl: 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=x' }) },
        companyMember: { findFirst: jest.fn().mockResolvedValue({ user: { locale: 'ru' } }) },
      },
      redis: { client: { set: jest.fn().mockResolvedValue('OK') } },
    };
  }

  it('resolves instead of hanging forever when queue.add never settles (simulated Redis outage)', async () => {
    jest.useFakeTimers();
    const { prisma, redis } = fixture();
    const queue = { add: jest.fn().mockReturnValue(new Promise(() => {})) }; // никогда не резолвится
    const service = new NotificationsService(prisma as any, redis as any, queue as any);

    const notifyPromise = service.notify({ userIds: ['driver-1'] }, 'CARGO_INVITE', { cargoId: 'c1', companyName: 'Acme' });
    await jest.advanceTimersByTimeAsync(3000);
    await expect(notifyPromise).resolves.toBeUndefined();

    jest.useRealTimers();
  });

  it('resolves instead of rejecting when queue.add rejects outright', async () => {
    const { prisma, redis } = fixture();
    const queue = { add: jest.fn().mockRejectedValue(new Error('ECONNREFUSED')) };
    const service = new NotificationsService(prisma as any, redis as any, queue as any);

    await expect(service.notify({ userIds: ['driver-1'] }, 'CARGO_INVITE', { cargoId: 'c1', companyName: 'Acme' })).resolves.toBeUndefined();
  });

  it('sends anyway (fails open) when the throttle check itself times out', async () => {
    jest.useFakeTimers();
    const { prisma } = fixture();
    const redis = { client: { set: jest.fn().mockReturnValue(new Promise(() => {})) } };
    const queue = { add: jest.fn().mockResolvedValue(undefined) };
    const service = new NotificationsService(prisma as any, redis as any, queue as any);

    const notifyPromise = service.notify({ userIds: ['driver-1'] }, 'CHAT_MESSAGE', { chatId: 'c1', senderName: 'A', preview: 'hi' });
    await jest.advanceTimersByTimeAsync(3000);
    await notifyPromise;

    expect(queue.add).toHaveBeenCalled();
    jest.useRealTimers();
  });
});
