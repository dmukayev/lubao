import { Module } from '@nestjs/common';
import { IdentifiersModule } from '../identifiers/identifiers.module';
import { RecognitionModule } from '../recognition/recognition.module';
import { DriversController } from './drivers.controller';
import { DriversService } from './drivers.service';

@Module({
  imports: [IdentifiersModule, RecognitionModule],
  controllers: [DriversController],
  providers: [DriversService],
  exports: [DriversService],
})
export class DriversModule {}
