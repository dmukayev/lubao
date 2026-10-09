import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, ShareType } from '@prisma/client';
import { randomInt } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';
import { RequestContext } from '../common/request-context';

/// Без похожих символов (0/O, 1/l/I) — код диктуют и перепечатывают.
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
export const SHARE_CODE_LENGTH = 7;
/// Путь короткой ссылки по типу: груз, все грузы компании, анонс водителя.
export const SHARE_PATH: Record<ShareType, string> = { CARGO: 'c', COMPANY: 'co', DRIVER: 'd' };

export function newShareCode(length = SHARE_CODE_LENGTH): string {
  let code = '';
  for (let i = 0; i < length; i++) code += ALPHABET[randomInt(ALPHABET.length)];
  return code;
}

export function shareBaseUrl(): string {
  return (process.env.SHARE_BASE_URL || process.env.APP_PUBLIC_URL || 'https://lubao.kz').replace(/\/+$/, '');
}

/// 052: «Поделиться» — короткие ссылки с автором; счётчики открытий, входов по
/// ссылке, откликов и сделок пришедших.
@Injectable()
export class ShareService {
  constructor(private readonly prisma: PrismaService) {}

  /// Ссылка автора на объект — одна и та же при повторном «Поделиться».
  async create(ctx: RequestContext, type: ShareType, targetId: string) {
    await this.assertMayShare(ctx, type, targetId);
    const existing = await this.prisma.shareLink.findUnique({ where: { authorUserId_type_targetId: { authorUserId: ctx.user.id, type, targetId } } });
    const link = existing ?? (await this.createUnique(ctx.user.id, type, targetId));
    return { code: link.code, type: link.type, url: `${shareBaseUrl()}/${SHARE_PATH[link.type]}/${link.code}` };
  }

  private async createUnique(authorUserId: string, type: ShareType, targetId: string) {
    for (let attempt = 0; attempt < 5; attempt++) {
      try {
        return await this.prisma.shareLink.create({ data: { code: newShareCode(), type, targetId, authorUserId } });
      } catch (e) {
        // Совпал код (P2002 по code) — новый; совпала пара автор+объект (гонка) — берём её.
        if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
          const raced = await this.prisma.shareLink.findUnique({ where: { authorUserId_type_targetId: { authorUserId, type, targetId } } });
          if (raced) return raced;
          continue;
        }
        throw e;
      }
    }
    throw new Error('Could not allocate a share code');
  }

  /// Груз — опубликованный (водитель делится любым из ленты, логист — своим);
  /// все грузы — только своей компании; анонс — только свой.
  private async assertMayShare(ctx: RequestContext, type: ShareType, targetId: string) {
    if (type === 'CARGO') {
      const cargo = await this.prisma.cargo.findUnique({ where: { id: targetId }, select: { companyId: true, status: true } });
      if (!cargo) throw new NotFoundException('Cargo not found');
      if (ctx.companyMember && cargo.companyId === ctx.companyMember.companyId) return;
      if (ctx.driver && cargo.status === 'PUBLISHED') return;
      throw new ForbiddenException('Cannot share this cargo');
    }
    if (type === 'COMPANY') {
      if (ctx.companyMember?.companyId === targetId) return;
      throw new ForbiddenException('Cannot share another company');
    }
    if (ctx.driver?.id === targetId) return;
    throw new ForbiddenException('Cannot share another driver');
  }

  async findByCode(code: string) {
    if (!/^[A-Za-z0-9]{4,12}$/.test(code)) return null;
    return this.prisma.shareLink.findUnique({ where: { code } });
  }

  async countOpen(id: string) {
    await this.prisma.shareLink.update({ where: { id }, data: { opens: { increment: 1 } } }).catch(() => undefined);
  }

  /// Для приложения: куда вести по ссылке (вошедший пользователь).
  async resolve(code: string) {
    const link = await this.findByCode(code);
    if (!link) throw new NotFoundException('Link not found');
    await this.countOpen(link.id);
    return { type: link.type, targetId: link.targetId };
  }

  /// Вход по ссылке (сразу после установки — отложенная ссылка): засчитать
  /// автору один раз на пользователя, свои ссылки не считаются.
  async claim(userId: string, code: string) {
    const link = await this.findByCode(code);
    if (!link) throw new NotFoundException('Link not found');
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { referredByShareId: true } });
    if (!user?.referredByShareId && link.authorUserId !== userId) {
      await this.prisma.user.update({ where: { id: userId }, data: { referredByShareId: link.id } });
      await this.prisma.shareLink.update({ where: { id: link.id }, data: { logins: { increment: 1 } } });
    }
    return { type: link.type, targetId: link.targetId };
  }
}

/// Отклик или сделка пришедшего по ссылке — засчитать её автору (052 п.1).
export async function bumpShareReferral(prisma: Pick<PrismaService, 'user' | 'shareLink'>, userId: string, field: 'responses' | 'deals') {
  try {
    const user = await prisma.user.findUnique({ where: { id: userId }, select: { referredByShareId: true } });
    if (user?.referredByShareId) await prisma.shareLink.update({ where: { id: user.referredByShareId }, data: { [field]: { increment: 1 } } });
  } catch {
    // счётчик не критичен
  }
}
