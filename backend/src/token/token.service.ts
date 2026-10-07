import * as crypto from 'crypto';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';

const ACCESS_TOKEN_TTL = '15m';

const REFRESH_TTL_MS: Record<UserRole, number> = {
  // 043 п.9 (решение 2026-10-07): водитель — 180 дней бездействия, продление при каждом открытии.
  DRIVER: 180 * 24 * 60 * 60 * 1000,
  COMPANY: 30 * 24 * 60 * 60 * 1000,
  ADMIN: 12 * 60 * 60 * 1000,
};

export interface AccessTokenPayload {
  sub: string;
  role: UserRole;
  sid: string;
}

/// Выпуск/проверка access-токена (JWT) и генерация/хэширование refresh-токена
/// (случайная строка, в БД хранится только хэш — см. SessionService).
@Injectable()
export class TokenService {
  private readonly secret: string;

  constructor(private readonly jwt: JwtService) {
    const secret = process.env.JWT_ACCESS_SECRET;
    if (!secret) {
      throw new Error('JWT_ACCESS_SECRET is not configured');
    }
    this.secret = secret;
  }

  async signAccessToken(payload: AccessTokenPayload): Promise<string> {
    return this.jwt.signAsync(payload, { secret: this.secret, expiresIn: ACCESS_TOKEN_TTL });
  }

  async verifyAccessToken(token: string): Promise<AccessTokenPayload> {
    try {
      return await this.jwt.verifyAsync<AccessTokenPayload>(token, { secret: this.secret });
    } catch {
      throw new UnauthorizedException('Invalid or expired access token');
    }
  }

  generateRefreshToken(): string {
    return crypto.randomBytes(48).toString('base64url');
  }

  hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  refreshTtlMs(role: UserRole): number {
    return REFRESH_TTL_MS[role];
  }
}
