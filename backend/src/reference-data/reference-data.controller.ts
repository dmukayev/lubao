import { Controller, Get } from '@nestjs/common';
import { Public } from '../common/public.decorator';
import { ReferenceDataService } from './reference-data.service';

@Controller('reference-data')
export class ReferenceDataController {
  constructor(private readonly referenceData: ReferenceDataService) {}

  @Public()
  @Get()
  getAll() {
    return this.referenceData.getAll();
  }
}
