import { Logger } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../prisma/prisma.service';
import { SessionService } from '../auth/session.service';
import { TokenService } from '../token/token.service';
import { RequestContext } from '../common/request-context';

function chatRoom(chatId: string): string {
  return `chat:${chatId}`;
}

/// Личная комната пользователя (задача 029, п.3) — чаты, которые клиент
/// не открывал (и поэтому не `join`-ил `chat:<id>`), всё равно должны
/// обновлять список «Мои чаты»: сюда шлём `chat:updated` при любом
/// новом сообщении в любом его чате, независимо от того, в каких
/// chat:<id>-комнатах он сейчас состоит.
function userRoom(userId: string): string {
  return `user:${userId}`;
}

/// Чат в реальном времени (задача 011, п.6-7): авторизация по тому же JWT,
/// что и HTTP (006), комнаты по chatId, события message:new/message:read/
/// typing. Клиент переподключается сам (socket.io-client делает это из
/// коробки); если сокет недоступен совсем — клиентский фоллбэк на polling
/// каждые 10с (см. packages/lubao_core/lib/src/realtime).
/// CORS шлюза — тот же список, что у HTTP (CORS_ALLOWED_ORIGINS, задача 043,
/// п.4); не задан — как раньше, открыто (локальная разработка).
const wsAllowedOrigins = process.env.CORS_ALLOWED_ORIGINS?.split(',').map((o) => o.trim()).filter(Boolean);

@WebSocketGateway({ cors: { origin: wsAllowedOrigins?.length ? wsAllowedOrigins : '*' } })
export class RealtimeGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(RealtimeGateway.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
    private readonly sessions: SessionService,
  ) {}

  /// Авторизация — через `server.use()` (handshake middleware), НЕ
  /// `handleConnection`: Nest не ждёт завершения `handleConnection` перед
  /// тем, как начать принимать сообщения от уже «connected» клиента, так
  /// что асинхронная проверка токена там гонится с первым же `join` —
  /// клиент успевает отправить `join` раньше, чем `client.data.ctx`
  /// проставится. `server.use()` — часть хендшейка, Socket.IO не эмитит
  /// `connection` клиенту, пока мидлвары не вызовут `next()`.
  afterInit(server: Server): void {
    server.use(async (socket: Socket, next: (err?: Error) => void) => {
      const token = (socket.handshake.auth?.token as string) || (socket.handshake.query?.token as string);
      if (!token) return next(new Error('Missing token'));
      try {
        const payload = await this.tokens.verifyAccessToken(token);
        const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
        if (!user || !user.isActive || user.isBlocked || !(await this.sessions.isSessionActive(payload.sid))) {
          return next(new Error('Invalid session'));
        }
        const [driver, companyMember] = await Promise.all([
          this.prisma.driver.findUnique({ where: { userId: user.id } }),
          this.prisma.companyMember.findUnique({ where: { userId: user.id }, include: { company: true } }),
        ]);
        const ctx: RequestContext = { user, driver, companyMember, sessionId: payload.sid };
        socket.data.ctx = ctx;
        next();
      } catch {
        next(new Error('Invalid token'));
      }
    });
  }

  /// `connection` эмитится Socket.IO только после того, как мидлвары из
  /// `afterInit` вызвали `next()` — `client.data.ctx` уже гарантированно
  /// проставлен (в отличие от старого `handleConnection`, где сама
  /// авторизация была асинхронной и гонялась с первым сообщением
  /// клиента). Кладём в личную комнату — задача 029, п.3.
  handleConnection(client: Socket): void {
    const ctx: RequestContext | undefined = client.data.ctx;
    if (ctx) client.join(userRoom(ctx.user.id));
  }

  handleDisconnect(client: Socket): void {
    this.logger.debug(`Socket disconnected: ${client.id}`);
  }

  private async assertParty(chatId: string, ctx: RequestContext): Promise<boolean> {
    const chat = await this.prisma.chat.findUnique({ where: { id: chatId } });
    if (!chat) return false;
    return chat.driverId === ctx.driver?.id || chat.companyId === ctx.companyMember?.companyId;
  }

  @SubscribeMessage('join')
  async handleJoin(@ConnectedSocket() client: Socket, @MessageBody() data: { chatId: string }): Promise<void> {
    const ctx: RequestContext | undefined = client.data.ctx;
    if (!ctx || !data?.chatId) return;
    if (!(await this.assertParty(data.chatId, ctx))) return;
    await client.join(chatRoom(data.chatId));
  }

  @SubscribeMessage('leave')
  handleLeave(@ConnectedSocket() client: Socket, @MessageBody() data: { chatId: string }): void {
    if (!data?.chatId) return;
    client.leave(chatRoom(data.chatId));
  }

  @SubscribeMessage('typing')
  handleTyping(@ConnectedSocket() client: Socket, @MessageBody() data: { chatId: string }): void {
    const ctx: RequestContext | undefined = client.data.ctx;
    if (!ctx || !data?.chatId) return;
    client.to(chatRoom(data.chatId)).emit('typing', { chatId: data.chatId, userId: ctx.user.id });
  }

  emitMessageNew(chatId: string, message: unknown): void {
    this.server.to(chatRoom(chatId)).emit('message:new', message);
  }

  emitMessageRead(chatId: string, readerUserId: string): void {
    this.server.to(chatRoom(chatId)).emit('message:read', { chatId, readerUserId });
  }

  /// Перевод подъехал отдельно от самого сообщения (задача 029, п.6 —
  /// `send()` не ждёт DeepSeek) — клиент подменяет текст в уже
  /// отрисованном пузыре по этому событию.
  emitMessageTranslated(chatId: string, payload: unknown): void {
    this.server.to(chatRoom(chatId)).emit('message:translated', payload);
  }

  /// Список «Мои чаты» обновляется у пользователя, даже если он не
  /// открывал конкретный chat:<id> и поэтому не в его комнате (задача
  /// 029, п.3) — личная комната ловит это независимо.
  emitChatUpdated(userId: string, payload: { chatId: string }): void {
    this.server.to(userRoom(userId)).emit('chat:updated', payload);
  }

  /// Задача 038, п.12 — закреплённая карточка/кнопки у ВТОРОЙ стороны
  /// обновляются сразу после отзыва отклика, привязки груза, выбора:
  /// комнатное событие тем, у кого чат открыт.
  emitThreadUpdated(chatId: string): void {
    this.server.to(chatRoom(chatId)).emit('chat:updated', { chatId });
  }

  /// Задача 038, п.12 — смена статуса сделки видна собеседнику в чате без
  /// перезахода (клиент инвалидирует dealByIdProvider).
  emitDealUpdated(chatId: string, payload: { dealId: string; status: string }): void {
    this.server.to(chatRoom(chatId)).emit('deal:updated', payload);
  }

  /// То же событие — в личную комнату участника сделки (041, п.13): приложение
  /// водителя узнаёт о начале/конце рейса («Загружен» → «Доставлено») и без
  /// открытого чата, и ему не нужно опрашивать /deals/mine каждые 45 секунд.
  emitDealUpdatedToUser(userId: string, payload: { dealId: string; status: string }): void {
    this.server.to(userRoom(userId)).emit('deal:updated', payload);
  }
}
