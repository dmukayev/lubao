import { Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { TokenService } from '../token/token.service';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
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

  async rotateSession(presentedRefreshToken: string): Promise<TokenPair> {
    const hash = this.tokens.hashToken(presentedRefreshToken);

    const session = await this.prisma.session.findUnique({ where: { refreshTokenHash: hash }, include: { user: true } });
    if (session && !session.revokedAt && session.expiresAt > new Date()) {
      const newRefreshToken = this.tokens.generateRefreshToken();
      await this.prisma.session.update({
        where: { id: session.id },
        data: {
          refreshTokenHash: this.tokens.hashToken(newRefreshToken),
          previousTokenHash: hash,
          lastUsedAt: new Date(),
          expiresAt: new Date(Date.now() + this.tokens.refreshTtlMs(session.user.role)),
        },
      });
      const accessToken = await this.tokens.signAccessToken({ sub: session.userId, role: session.user.role, sid: session.id });
      return { accessToken, refreshToken: newRefreshToken };
    }

    // Токен, который уже был заменён ротацией выше, но пришёл снова —
    // похоже на кражу/повторное использование. Отзываем всю сессию.
    const reused = await this.prisma.session.findUnique({ where: { previousTokenHash: hash } });
    if (reused) {
      await this.prisma.session.update({ where: { id: reused.id }, data: { revokedAt: new Date() } });
      throw new UnauthorizedException('Refresh token reuse detected');
    }

    throw new UnauthorizedException('Invalid refresh token');
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
