import { Module } from '@nestjs/common';
import { GoodsController } from './goods.controller';
import { GoodsService } from './goods.service';
import { AdminGoodsController } from './admin-goods.controller';
import { AdminGoodsService } from './admin-goods.service';

@Module({
  controllers: [GoodsController, AdminGoodsController],
  providers: [GoodsService, AdminGoodsService],
  exports: [GoodsService],
})
export class GoodsModule {}
