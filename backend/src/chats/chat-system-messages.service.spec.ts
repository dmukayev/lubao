import { ChatSystemMessagesService } from './chat-system-messages.service';

// 049 п.9: русский фолбэк (админка, старые клиенты) — причина отмены по коду.
describe('ChatSystemMessagesService — RU-фолбэк строки отмены', () => {
  function setup() {
    const prisma: any = {
      message: { create: jest.fn(async ({ data }: any) => ({ id: 'm1', createdAt: new Date(), translations: null, ...data })) },
      chat: { update: jest.fn() },
    };
    const realtime: any = { emitMessageNew: jest.fn() };
    return { prisma, service: new ChatSystemMessagesService(prisma, realtime) };
  }

  it('код причины → русская подпись, а не пустота', async () => {
    const { prisma, service } = setup();
    await service.postToChat('chat1', 'u1', 'CANCEL_REQUESTED', { reasonCode: 'VEHICLE_BREAKDOWN' });
    expect(prisma.message.create.mock.calls[0][0].data.originalText).toContain('Машина сломалась');
  });

  it('«Другое» — текст причины', async () => {
    const { prisma, service } = setup();
    await service.postToChat('chat1', 'u1', 'CANCEL_REQUESTED', { reasonCode: 'OTHER', reason: 'Заказчик передумал' });
    expect(prisma.message.create.mock.calls[0][0].data.originalText).toContain('Заказчик передумал');
  });
});
