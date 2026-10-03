import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RequestContext } from '../common/request-context';

@Injectable()
export class ChatsService {
  constructor(private readonly prisma: PrismaService) {}

  private assertParty(deal: { driverId: string; companyId: string }, ctx: RequestContext) {
    const isParty = deal.driverId === ctx.driver?.id || deal.companyId === ctx.companyMember?.companyId;
    if (!isParty) throw new ForbiddenException('Not a party to this deal');
  }

  private async getOrCreateChat(dealId: string, ctx: RequestContext) {
    const deal = await this.prisma.deal.findUnique({ where: { id: dealId } });
    if (!deal) throw new NotFoundException('Deal not found');
    this.assertParty(deal, ctx);

    let chat = await this.prisma.chat.findFirst({ where: { dealId } });
    if (!chat) {
      chat = await this.prisma.chat.create({
        data: { dealId, cargoId: deal.cargoId, driverId: deal.driverId, companyId: deal.companyId },
      });
    }
    return chat;
  }

  async threadForDeal(dealId: string, ctx: RequestContext) {
    const chat = await this.getOrCreateChat(dealId, ctx);
    const [driver, companyOwner] = await Promise.all([
      this.prisma.driver.findUniqueOrThrow({ where: { id: chat.driverId }, include: { user: true } }),
      this.prisma.companyMember.findFirst({
        where: { companyId: chat.companyId },
        include: { user: true, company: true },
        orderBy: { role: 'asc' },
      }),
    ]);
    const counterpartName = ctx.driver ? companyOwner?.company.name ?? '' : driver.fullName;
    const counterpartLocale = ctx.driver ? companyOwner?.user.locale : driver.user.locale;
    return {
      id: chat.id,
      cargoId: chat.cargoId,
      dealId: chat.dealId,
      driverId: chat.driverId,
      companyId: chat.companyId,
      counterpartName,
      counterpartLocale,
    };
  }

  async messages(dealId: string, ctx: RequestContext) {
    const chat = await this.getOrCreateChat(dealId, ctx);
    const messages = await this.prisma.message.findMany({ where: { chatId: chat.id }, orderBy: { createdAt: 'asc' } });
    return messages.map((m) => ({
      id: m.id,
      chatId: m.chatId,
      senderUserId: m.senderUserId,
      isMine: m.senderUserId === ctx.user.id,
      originalText: m.originalText,
      originalLang: m.originalLang,
      translations: m.translations,
      isRead: m.isRead,
      createdAt: m.createdAt,
    }));
  }

  async send(dealId: string, ctx: RequestContext, text: string) {
    const chat = await this.getOrCreateChat(dealId, ctx);
    const message = await this.prisma.message.create({
      data: { chatId: chat.id, senderUserId: ctx.user.id, originalText: text, originalLang: ctx.user.locale },
    });
    return {
      id: message.id,
      chatId: message.chatId,
      senderUserId: message.senderUserId,
      isMine: true,
      originalText: message.originalText,
      originalLang: message.originalLang,
      translations: message.translations,
      isRead: message.isRead,
      createdAt: message.createdAt,
    };
  }
}
