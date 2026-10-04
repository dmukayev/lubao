import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { SessionService } from '../auth/session.service';
import { TokenService } from '../token/token.service';
import { IS_PUBLIC_KEY } from './public.decorator';

/// Настоящая авторизация: access-токен (JWT, 15 мин) в заголовке
/// Authorization: Bearer <token>. Роль и статус активности берутся из
/// свежей записи БД (не слепо из токена), сессия должна быть живой —
/// иначе разлогин «на всех остальных устройствах» подействовал бы только
/// после истечения access-токена, а не «при следующем запросе».
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
    private readonly sessions: SessionService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest<Request>();
    const header = request.header('Authorization');
    const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : null;
    if (!token) {
      throw new UnauthorizedException('Missing bearer token');
    }

    const payload = await this.tokens.verifyAccessToken(token);

    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user || !user.isActive || user.isBlocked) {
      throw new UnauthorizedException('User is inactive or blocked');
    }

    const sessionActive = await this.sessions.isSessionActive(payload.sid);
    if (!sessionActive) {
      throw new UnauthorizedException('Session has been revoked or expired');
    }

    const [driver, companyMember] = await Promise.all([
      this.prisma.driver.findUnique({ where: { userId: user.id } }),
      this.prisma.companyMember.findUnique({ where: { userId: user.id }, include: { company: true } }),
    ]);

    request.authContext = { user, driver, companyMember, sessionId: payload.sid };
    return true;
  }
}
