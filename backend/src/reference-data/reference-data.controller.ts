import { Body, Controller, Get, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { Public } from '../common/public.decorator';
import { RequestContext } from '../common/request-context';
import { ReferenceDataService } from './reference-data.service';
import { SubmitCityDto } from './dto/submit-city.dto';

@Controller('reference-data')
export class ReferenceDataController {
  constructor(private readonly referenceData: ReferenceDataService) {}

  @Public()
  @Get()
  getAll() {
    return this.referenceData.getAll();
  }

  @Post('cities')
  submitCity(@CurrentUser() ctx: RequestContext, @Body() dto: SubmitCityDto) {
    return this.referenceData.submitCity(ctx.user.id, dto);
  }
}
