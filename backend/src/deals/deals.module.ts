import { PricingModule } from '../pricing/pricing.module';
import { Module } from '@nestjs/common';
import { CargosModule } from '../cargos/cargos.module';
import { ChatsModule } from '../chats/chats.module';
import { DealsController, ResponseOffersController } from './deals.controller';
import { ResponsesModule } from '../responses/responses.module';
import { DealsService } from './deals.service';
import { ReviewsService } from './reviews.service';
import { DriverDocumentsService } from './driver-documents.service';
import { UploadsModule } from '../uploads/uploads.module';

@Module({
  imports: [CargosModule, ChatsModule, UploadsModule, PricingModule, ResponsesModule],
  controllers: [DealsController, ResponseOffersController],
  providers: [DealsService, ReviewsService, DriverDocumentsService],
  exports: [DealsService],
})
export class DealsModule {}
