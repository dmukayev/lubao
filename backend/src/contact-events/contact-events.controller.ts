import { Body, Controller, ForbiddenException, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { PrismaService } from '../prisma/prisma.service';
import { CreateContactEventDto } from './dto/create-contact-event.dto';

@Controller('contact-events')
export class ContactEventsController {
  constructor(private readonly prisma: PrismaService) {}

  @Post()
  async create(@CurrentUser() ctx: RequestContext, @Body() dto: CreateContactEventDto) {
    if (!ctx.driver && !ctx.companyMember) throw new ForbiddenException('Not a driver or company account');
    await this.prisma.contactEvent.create({
      data: {
        driverId: dto.driverId,
        companyId: dto.companyId,
        cargoId: dto.cargoId,
        dealId: dto.dealId,
        actorUserId: ctx.user.id,
        type: dto.type,
      },
    });
    return { ok: true };
  }
}
