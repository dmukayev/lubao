import { Module } from '@nestjs/common';
import { CargosModule } from '../cargos/cargos.module';
import { ChatsModule } from '../chats/chats.module';
import { DealsController } from './deals.controller';
import { DealsService } from './deals.service';
import { ReviewsService } from './reviews.service';

@Module({
  imports: [CargosModule, ChatsModule],
  controllers: [DealsController],
  providers: [DealsService, ReviewsService],
  exports: [DealsService],
})
export class DealsModule {}
