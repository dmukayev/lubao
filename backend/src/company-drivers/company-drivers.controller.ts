import { Body, Controller, Delete, ForbiddenException, Get, HttpCode, Param, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { CompanyDriversService } from './company-drivers.service';
import { CreateCompanyDriverDto } from './dto/create-company-driver.dto';

/// 058 п.6: «Мои водители» у логиста.
@Controller('company-drivers')
export class CompanyDriversController {
  constructor(private readonly service: CompanyDriversService) {}

  @Get()
  list(@CurrentUser() ctx: RequestContext) {
    return this.service.list(this.service.assertCompany(ctx));
  }

  @Post()
  create(@CurrentUser() ctx: RequestContext, @Body() dto: CreateCompanyDriverDto) {
    this.service.assertCompany(ctx);
    return this.service.create(ctx, dto.name, dto.phone);
  }

  @Post(':driverId/save')
  @HttpCode(200)
  save(@CurrentUser() ctx: RequestContext, @Param('driverId') driverId: string) {
    return this.service.save(this.service.assertCompany(ctx), driverId, ctx.user.id);
  }

  @Delete(':driverId/save')
  unsave(@CurrentUser() ctx: RequestContext, @Param('driverId') driverId: string) {
    return this.service.unsave(this.service.assertCompany(ctx), driverId, ctx.user.id);
  }
}

/// 058 п.6: водитель — «Компании, где я в списке», «Принять» / «Отказаться», выйти.
@Controller('drivers/me/companies')
export class DriverCompaniesController {
  constructor(private readonly service: CompanyDriversService) {}

  private driver(ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return ctx.driver;
  }

  @Get()
  list(@CurrentUser() ctx: RequestContext) {
    return this.service.listForDriver(this.driver(ctx).id, ctx.user.phone ?? null);
  }

  @Post(':companyId/accept')
  @HttpCode(200)
  accept(@CurrentUser() ctx: RequestContext, @Param('companyId') companyId: string) {
    return this.service.respond(this.driver(ctx).id, companyId, 'ACCEPT', ctx.user.id);
  }

  @Post(':companyId/decline')
  @HttpCode(200)
  decline(@CurrentUser() ctx: RequestContext, @Param('companyId') companyId: string) {
    return this.service.respond(this.driver(ctx).id, companyId, 'DECLINE', ctx.user.id);
  }

  @Post(':companyId/leave')
  @HttpCode(200)
  leave(@CurrentUser() ctx: RequestContext, @Param('companyId') companyId: string) {
    return this.service.leave(this.driver(ctx).id, companyId, ctx.user.id);
  }
}
