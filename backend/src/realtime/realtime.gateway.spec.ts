import { RealtimeGateway } from './realtime.gateway';

function socketMock(overrides: Record<string, unknown> = {}) {
  return {
    id: 'socket-1',
    data: {},
    handshake: { auth: {}, query: {} },
    disconnect: jest.fn(),
    join: jest.fn(),
    leave: jest.fn(),
    to: jest.fn().mockReturnValue({ emit: jest.fn() }),
    ...overrides,
  };
}

describe('RealtimeGateway auth middleware (задача 011, п.6) — registered via afterInit, not handleConnection', () => {
  // Nest does not await handleConnection before a client can send messages,
  // so the JWT check has to run as a Socket.IO handshake middleware
  // (server.use) — that's the only hook guaranteed to finish before the
  // 'connection'/first message fires. We grab the middleware afterInit()
  // registers and drive it directly.
  function getMiddleware(gateway: RealtimeGateway) {
    const use = jest.fn();
    gateway.afterInit({ use } as any);
    return use.mock.calls[0][0] as (socket: any, next: (err?: Error) => void) => Promise<void>;
  }

  it('rejects a connection with no token', async () => {
    const gateway = new RealtimeGateway({} as any, {} as any, {} as any);
    const middleware = getMiddleware(gateway);
    const next = jest.fn();

    await middleware(socketMock(), next);

    expect(next).toHaveBeenCalledWith(expect.any(Error));
  });

  it('rejects a connection whose token fails verification', async () => {
    const tokens = { verifyAccessToken: jest.fn().mockRejectedValue(new Error('bad token')) };
    const gateway = new RealtimeGateway({} as any, tokens as any, {} as any);
    const middleware = getMiddleware(gateway);
    const next = jest.fn();

    await middleware(socketMock({ handshake: { auth: { token: 'bad' }, query: {} } }), next);

    expect(next).toHaveBeenCalledWith(expect.any(Error));
  });

  it('rejects when the session is no longer active (e.g. logged out elsewhere)', async () => {
    const tokens = { verifyAccessToken: jest.fn().mockResolvedValue({ sub: 'u1', sid: 's1' }) };
    const prisma = { user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1', isActive: true, isBlocked: false }) } };
    const sessions = { isSessionActive: jest.fn().mockResolvedValue(false) };
    const gateway = new RealtimeGateway(prisma as any, tokens as any, sessions as any);
    const middleware = getMiddleware(gateway);
    const next = jest.fn();

    await middleware(socketMock({ handshake: { auth: { token: 'good' }, query: {} } }), next);

    expect(next).toHaveBeenCalledWith(expect.any(Error));
  });

  it('attaches a RequestContext and calls next() with no error for a valid, active session', async () => {
    const tokens = { verifyAccessToken: jest.fn().mockResolvedValue({ sub: 'u1', sid: 's1' }) };
    const prisma = {
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1', isActive: true, isBlocked: false }) },
      driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1' }) },
      companyMember: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    const sessions = { isSessionActive: jest.fn().mockResolvedValue(true) };
    const gateway = new RealtimeGateway(prisma as any, tokens as any, sessions as any);
    const middleware = getMiddleware(gateway);
    const next = jest.fn();
    const socket = socketMock({ handshake: { auth: { token: 'good' }, query: {} } });

    await middleware(socket, next);

    expect(next).toHaveBeenCalledWith();
    expect((socket.data as any).ctx).toEqual(expect.objectContaining({ sessionId: 's1', driver: { id: 'd1' } }));
  });
});

describe('RealtimeGateway.handleJoin — only a party to the chat may join its room (задача 011, п.6)', () => {
  it('joins the room when the socket\'s driver is a party to the chat', async () => {
    const prisma = { chat: { findUnique: jest.fn().mockResolvedValue({ driverId: 'd1', companyId: 'c1' }) } };
    const gateway = new RealtimeGateway(prisma as any, {} as any, {} as any);
    const client = socketMock({ data: { ctx: { driver: { id: 'd1' }, companyMember: null } } });

    await gateway.handleJoin(client as any, { chatId: 'chat1' });

    expect(client.join).toHaveBeenCalledWith('chat:chat1');
  });

  it('refuses to join when the socket is not a party', async () => {
    const prisma = { chat: { findUnique: jest.fn().mockResolvedValue({ driverId: 'other', companyId: 'c1' }) } };
    const gateway = new RealtimeGateway(prisma as any, {} as any, {} as any);
    const client = socketMock({ data: { ctx: { driver: { id: 'd1' }, companyMember: null } } });

    await gateway.handleJoin(client as any, { chatId: 'chat1' });

    expect(client.join).not.toHaveBeenCalled();
  });

  it('refuses to join an unknown chat', async () => {
    const prisma = { chat: { findUnique: jest.fn().mockResolvedValue(null) } };
    const gateway = new RealtimeGateway(prisma as any, {} as any, {} as any);
    const client = socketMock({ data: { ctx: { driver: { id: 'd1' }, companyMember: null } } });

    await gateway.handleJoin(client as any, { chatId: 'missing' });

    expect(client.join).not.toHaveBeenCalled();
  });
});

describe('RealtimeGateway — typing and server-pushed events', () => {
  it('handleTyping broadcasts to the room, excluding the sender', () => {
    const gateway = new RealtimeGateway({} as any, {} as any, {} as any);
    const emit = jest.fn();
    const client = socketMock({ data: { ctx: { user: { id: 'u1' } } }, to: jest.fn().mockReturnValue({ emit }) });

    gateway.handleTyping(client as any, { chatId: 'chat1' });

    expect(client.to).toHaveBeenCalledWith('chat:chat1');
    expect(emit).toHaveBeenCalledWith('typing', { chatId: 'chat1', userId: 'u1' });
  });

  it('emitMessageNew sends to the whole chat room via the server', () => {
    const gateway = new RealtimeGateway({} as any, {} as any, {} as any);
    const emit = jest.fn();
    (gateway as any).server = { to: jest.fn().mockReturnValue({ emit }) };

    gateway.emitMessageNew('chat1', { id: 'm1' });

    expect((gateway as any).server.to).toHaveBeenCalledWith('chat:chat1');
    expect(emit).toHaveBeenCalledWith('message:new', { id: 'm1' });
  });

  it('emitMessageRead sends to the whole chat room via the server', () => {
    const gateway = new RealtimeGateway({} as any, {} as any, {} as any);
    const emit = jest.fn();
    (gateway as any).server = { to: jest.fn().mockReturnValue({ emit }) };

    gateway.emitMessageRead('chat1', 'u1');

    expect(emit).toHaveBeenCalledWith('message:read', { chatId: 'chat1', readerUserId: 'u1' });
  });

  it('emitChatUpdated sends to the user\'s personal room, not a chat room', () => {
    const gateway = new RealtimeGateway({} as any, {} as any, {} as any);
    const emit = jest.fn();
    (gateway as any).server = { to: jest.fn().mockReturnValue({ emit }) };

    gateway.emitChatUpdated('user-1', { chatId: 'chat1' });

    expect((gateway as any).server.to).toHaveBeenCalledWith('user:user-1');
    expect(emit).toHaveBeenCalledWith('chat:updated', { chatId: 'chat1' });
  });
});

describe('RealtimeGateway.handleConnection — joins the personal room (задача 029, п.3)', () => {
  it('joins user:<id> once ctx is set (guaranteed by the auth middleware having already run)', () => {
    const gateway = new RealtimeGateway({} as any, {} as any, {} as any);
    const client = socketMock({ data: { ctx: { user: { id: 'user-1' } } } });

    gateway.handleConnection(client as any);

    expect(client.join).toHaveBeenCalledWith('user:user-1');
  });

  it('does nothing if ctx is somehow missing (defensive — should not happen post-middleware)', () => {
    const gateway = new RealtimeGateway({} as any, {} as any, {} as any);
    const client = socketMock();

    gateway.handleConnection(client as any);

    expect(client.join).not.toHaveBeenCalled();
  });
});
