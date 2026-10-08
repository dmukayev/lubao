import { Module } from '@nestjs/common';
import { DistanceService } from './distance.service';
import { PricingService } from './pricing.service';

/// 047: расстояния (OSRM), ₸/км и статистика цен по маршрутам.
@Module({
  providers: [DistanceService, PricingService],
  exports: [DistanceService, PricingService],
})
export class PricingModule {}
