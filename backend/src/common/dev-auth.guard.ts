import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { IS_PUBLIC_KEY } from './public.decorator';

/**
 * Временная dev-авторизация: доверяем заголовку X-User-Id вместо проверки
 * JWT/сессии. Реальные SMS/email-логины подключаются позже (см. auth/).
 */
@Injectable()
export class DevAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest<Request>();
    const userId = request.header('X-User-Id');
    if (!userId) {
      throw new UnauthorizedException('Missing X-User-Id header (dev auth)');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new UnauthorizedException('Unknown X-User-Id');
    }

    const [driver, companyMember] = await Promise.all([
      this.prisma.driver.findUnique({ where: { userId: user.id } }),
      this.prisma.companyMember.findUnique({ where: { userId: user.id }, include: { company: true } }),
    ]);

    request.authContext = { user, driver, companyMember };
    return true;
  }
}
