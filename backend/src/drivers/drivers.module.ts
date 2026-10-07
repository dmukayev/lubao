import { Module } from '@nestjs/common';
import { IdentifiersModule } from '../identifiers/identifiers.module';
import { RecognitionModule } from '../recognition/recognition.module';
import { UploadsModule } from '../uploads/uploads.module';
import { DriversController } from './drivers.controller';
import { DriversService } from './drivers.service';
import { ContactEventsModule } from '../contact-events/contact-events.module';

@Module({
  imports: [IdentifiersModule, RecognitionModule, UploadsModule, ContactEventsModule],
  controllers: [DriversController],
  providers: [DriversService],
  exports: [DriversService],
})
export class DriversModule {}
