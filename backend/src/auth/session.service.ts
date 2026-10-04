import { ForbiddenException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { TokenService } from '../token/token.service';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

const ROTATION_GRACE_SECONDS = 30;
const GRACE_LOOKUP_RETRIES = 5;
const GRACE_LOOKUP_DELAY_MS = 50;

function rotationGraceKey(oldRefreshTokenHash: string): string {
  return `session:rotated:${oldRefreshTokenHash}`;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function toDeviceDto(session: { id: string; deviceName: string | null; platform: string | null; createdAt: Date; lastUsedAt: Date }, currentSessionId: string) {
  return {
    id: session.id,
    deviceName: session.deviceName,
    platform: session.platform,
    createdAt: session.createdAt,
    lastUsedAt: session.lastUsedAt,
    isCurrent: session.id === currentSessionId,
  };
}

/// Сессии/устройства: выпуск, ротация (при /auth/refresh) и отзыв refresh-токенов.
/// Несколько устройств одновременно разрешены — каждое своя строка Session.
@Injectable()
export class SessionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
    private readonly redis: RedisService,
  ) {}

  async createSession(userId: string, role: UserRole, deviceName?: string, platform?: string): Promise<TokenPair> {
    const refreshToken = this.tokens.generateRefreshToken();
    const session = await this.prisma.session.create({
      data: {
        userId,
        refreshTokenHash: this.tokens.hashToken(refreshToken),
        deviceName,
        platform,
        expiresAt: new Date(Date.now() + this.tokens.refreshTtlMs(role)),
      },
    });
    const accessToken = await this.tokens.signAccessToken({ sub: userId, role, sid: session.id });
    return { accessToken, refreshToken };
  }

  /// Ротация refresh-токена. Два нюанса из ревью 006 (024 п.4):
  /// 1. Обновление — условное (`updateMany` с `refreshTokenHash: hash` в
  ///    WHERE, не просто `update` по id): если два запроса с одним и тем же
  ///    токеном стартуют параллельно (две вкладки веб-кабинета), оба читают
  ///    один и тот же session, но запишет (count===1) только первый — у
  ///    второго WHERE уже не совпадёт (count===0), т.к. refreshTokenHash
  ///    успел смениться.
  /// 2. Grace-период ~30 с: проигравший не считается «кражей» и не отзывает
  ///    сессию — в Redis на короткое время сохраняется пара токенов
  ///    победителя (по старому hash), и проигравший получает ту же пару
  ///    вместо ошибки. Без этого у логиста с двумя открытыми вкладками
  ///    после истечения access-токена вылетало разом обе.
  async rotateSession(presentedRefreshToken: string): Promise<TokenPair> {
    const hash = this.tokens.hashToken(presentedRefreshToken);

    const session = await this.prisma.session.findUnique({ where: { refreshTokenHash: hash }, include: { user: true } });
    // Блокировка (задача 026, п.5) — без этой проверки заблокированный
    // пользователь тихо продолжал бы получать новые access-токены через
    // /auth/refresh, даже когда JwtAuthGuard уже режет его на каждом другом
    // запросе; явный код ACCOUNT_BLOCKED, а не generic 401, чтобы клиент
    // показал понятный экран, а не бесконечный цикл релогина.
    if (session?.user.isBlocked) {
      throw new ForbiddenException({ code: 'ACCOUNT_BLOCKED', message: 'Аккаунт заблокирован' });
    }
    if (session && !session.revokedAt && session.expiresAt > new Date()) {
      const newRefreshToken = this.tokens.generateRefreshToken();
      const newHash = this.tokens.hashToken(newRefreshToken);
      const { count } = await this.prisma.session.updateMany({
        where: { id: session.id, refreshTokenHash: hash },
        data: {
          refreshTokenHash: newHash,
          previousTokenHash: hash,
          lastUsedAt: new Date(),
          expiresAt: new Date(Date.now() + this.tokens.refreshTtlMs(session.user.role)),
        },
      });
      if (count === 1) {
        const accessToken = await this.tokens.signAccessToken({ sub: session.userId, role: session.user.role, sid: session.id });
        const pair: TokenPair = { accessToken, refreshToken: newRefreshToken };
        await this.redis.client.set(rotationGraceKey(hash), JSON.stringify(pair), 'EX', ROTATION_GRACE_SECONDS);
        return pair;
      }
      // count === 0 — параллельный запрос обновил эту же сессию на долю
      // секунды раньше; не кража, просто проигранная гонка за тот же hash.
      const cached = await this.lookupGraceCache(hash);
      if (cached) return cached;
    }

    // Токен, который уже был заменён ротацией выше, пришёл снова. В пределах
    // grace-периода это, скорее всего, вторая вкладка — отдаём пару
    // победителя. Позже grace-периода — похоже на кражу/повторное
    // использование, отзываем всю сессию.
    const reused = await this.prisma.session.findUnique({ where: { previousTokenHash: hash } });
    if (reused) {
      const rotatedRecently = Date.now() - reused.lastUsedAt.getTime() < ROTATION_GRACE_SECONDS * 1000;
      if (rotatedRecently) {
        const cached = await this.lookupGraceCache(hash);
        if (cached) return cached;
      }
      await this.prisma.session.update({ where: { id: reused.id }, data: { revokedAt: new Date() } });
      throw new UnauthorizedException('Refresh token reuse detected');
    }

    throw new UnauthorizedException('Invalid refresh token');
  }

  private async lookupGraceCache(oldRefreshTokenHash: string): Promise<TokenPair | null> {
    const key = rotationGraceKey(oldRefreshTokenHash);
    for (let attempt = 0; attempt < GRACE_LOOKUP_RETRIES; attempt++) {
      const cached = await this.redis.client.get(key);
      if (cached) return JSON.parse(cached) as TokenPair;
      await sleep(GRACE_LOOKUP_DELAY_MS);
    }
    return null;
  }

  async revokeByRefreshToken(presentedRefreshToken: string): Promise<void> {
    const hash = this.tokens.hashToken(presentedRefreshToken);
    await this.prisma.session.updateMany({
      where: { OR: [{ refreshTokenHash: hash }, { previousTokenHash: hash }], revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  async revokeSession(sessionId: string, userId: string): Promise<void> {
    const { count } = await this.prisma.session.updateMany({
      where: { id: sessionId, userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    if (count === 0) throw new NotFoundException('Session not found');
  }

  async revokeAllExceptCurrent(userId: string, currentSessionId: string): Promise<void> {
    await this.prisma.session.updateMany({
      where: { userId, id: { not: currentSessionId }, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  /// После смены пароля (задача 025, п. 9) — все сессии завершаются, без
  /// исключения для текущей: пароль мог утечь, новый вход требует нового
  /// пароля заново на всех устройствах.
  async revokeAllForUser(userId: string): Promise<void> {
    await this.prisma.session.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  async listActiveSessions(userId: string, currentSessionId: string) {
    const sessions = await this.prisma.session.findMany({
      where: { userId, revokedAt: null, expiresAt: { gt: new Date() } },
      orderBy: { lastUsedAt: 'desc' },
    });
    return sessions.map((s) => toDeviceDto(s, currentSessionId));
  }

  async isSessionActive(sessionId: string): Promise<boolean> {
    const session = await this.prisma.session.findUnique({ where: { id: sessionId } });
    if (!session) return false;
    return session.revokedAt === null && session.expiresAt > new Date();
  }
}
