import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Worker } from 'bullmq';
import IORedis from 'ioredis';
import { RecognitionService } from './recognition.service';
import { RECOGNITION_QUEUE, RecognitionJob } from './recognition.queue';

/// Обработчик очереди распознавания (задача 031, п.18) — по образцу
/// notifications.processor.ts: отдельное ioredis-соединение
/// (maxRetriesPerRequest: null — требование BullMQ), фактическая работа
/// делегирована RecognitionService.process (тестируется без воркера).
@Injectable()
export class RecognitionProcessor implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RecognitionProcessor.name);
  private worker: Worker<RecognitionJob> | null = null;

  constructor(private readonly recognition: RecognitionService) {}

  onModuleInit() {
    const connection = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', { maxRetriesPerRequest: null });
    this.worker = new Worker<RecognitionJob>(
      RECOGNITION_QUEUE,
      async (job) => {
        await this.recognition.process(job.data.documentId, { attemptsMade: job.attemptsMade, maxAttempts: job.opts.attempts ?? 1 });
      },
      { connection },
    );
    this.worker.on('failed', (job, err) => {
      this.logger.error(`Recognition job ${job?.id} failed: ${err.message}`);
    });
  }

  async onModuleDestroy() {
    await this.worker?.close();
  }
}
