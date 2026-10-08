import { PricingModule } from '../pricing/pricing.module';
import { Module } from '@nestjs/common';
import { CargosModule } from '../cargos/cargos.module';
import { ChatsModule } from '../chats/chats.module';
import { DealsController } from './deals.controller';
import { DealsService } from './deals.service';
import { ReviewsService } from './reviews.service';
import { DriverDocumentsService } from './driver-documents.service';
import { UploadsModule } from '../uploads/uploads.module';

@Module({
  imports: [CargosModule, ChatsModule, UploadsModule, PricingModule],
  controllers: [DealsController],
  providers: [DealsService, ReviewsService, DriverDocumentsService],
  exports: [DealsService],
})
export class DealsModule {}
