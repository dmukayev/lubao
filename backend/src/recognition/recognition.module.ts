import { Module } from '@nestjs/common';
import { Queue } from 'bullmq';
import IORedis from 'ioredis';
import { UploadsModule } from '../uploads/uploads.module';
import { RecognitionService } from './recognition.service';
import { RecognitionProcessor } from './recognition.processor';
import { RECOGNITION_QUEUE, RecognitionJob } from './recognition.queue';

/// Не @Global(), в отличие от NotificationsModule — распознавание нужно
/// только там, где создаются VerificationDocument (drivers/companies),
/// а не повсеместно.
@Module({
  imports: [UploadsModule],
  providers: [
    {
      provide: Queue,
      useFactory: () => {
        const connection = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', { maxRetriesPerRequest: null });
        return new Queue<RecognitionJob>(RECOGNITION_QUEUE, { connection });
      },
    },
    RecognitionService,
    RecognitionProcessor,
  ],
  exports: [RecognitionService],
})
export class RecognitionModule {}
