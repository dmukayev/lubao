import { TranslationProcessor } from './translation.processor';

// bullmq.Worker в конструкторе реально лезет в Redis — мокаем модуль
// целиком, чтобы протестировать только сам handler, переданный в Worker.
const workerInstances: any[] = [];
jest.mock('bullmq', () => ({
  Worker: jest.fn().mockImplementation((_queue: string, handler: any) => {
    const instance = { handler, on: jest.fn(), close: jest.fn() };
    workerInstances.push(instance);
    return instance;
  }),
}));

jest.mock('ioredis', () => ({ __esModule: true, default: jest.fn().mockImplementation(() => ({})) }));

describe('TranslationProcessor — перевод в фоне (задача 029, п.6)', () => {
  beforeEach(() => {
    workerInstances.length = 0;
  });

  it('on a translated job, updates the message row and emits message:translated to the chat room', async () => {
    const translation = { translateMessage: jest.fn().mockResolvedValue({ translations: { zh: '你好' }, status: 'DONE' }) };
    const prisma = {
      message: {
        update: jest.fn().mockResolvedValue({ id: 'm1', chatId: 'chat1', translations: { zh: '你好' }, translationStatus: 'DONE' }),
      },
    };
    const realtime = { emitMessageTranslated: jest.fn() };
    const processor = new TranslationProcessor(translation as any, prisma as any, realtime as any);

    processor.onModuleInit();
    const handler = workerInstances[0].handler;
    await handler({ data: { messageId: 'm1', chatId: 'chat1', text: 'hi', from: 'ru', to: 'zh', senderUserId: 'u1' } });

    expect(translation.translateMessage).toHaveBeenCalledWith('u1', 'hi', 'ru', 'zh');
    expect(prisma.message.update).toHaveBeenCalledWith({
      where: { id: 'm1' },
      data: { translations: { zh: '你好' }, translationStatus: 'DONE' },
    });
    expect(realtime.emitMessageTranslated).toHaveBeenCalledWith('chat1', {
      id: 'm1',
      chatId: 'chat1',
      translations: { zh: '你好' },
      translationStatus: 'DONE',
    });
  });

  it('stores translations as undefined (not an empty object) when the translation failed', async () => {
    const translation = { translateMessage: jest.fn().mockResolvedValue({ translations: {}, status: 'FAILED' }) };
    const prisma = {
      message: { update: jest.fn().mockResolvedValue({ id: 'm1', chatId: 'chat1', translations: null, translationStatus: 'FAILED' }) },
    };
    const realtime = { emitMessageTranslated: jest.fn() };
    const processor = new TranslationProcessor(translation as any, prisma as any, realtime as any);

    processor.onModuleInit();
    const handler = workerInstances[0].handler;
    await handler({ data: { messageId: 'm1', chatId: 'chat1', text: 'hi', from: 'ru', to: 'zh', senderUserId: 'u1' } });

    expect(prisma.message.update).toHaveBeenCalledWith({
      where: { id: 'm1' },
      data: { translations: undefined, translationStatus: 'FAILED' },
    });
  });
});
