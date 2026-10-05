import { Module } from '@nestjs/common';
import { IdentifiersModule } from '../identifiers/identifiers.module';
import { DriversController } from './drivers.controller';
import { DriversService } from './drivers.service';

@Module({
  imports: [IdentifiersModule],
  controllers: [DriversController],
  providers: [DriversService],
  exports: [DriversService],
})
export class DriversModule {}
