import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Worker } from 'bullmq';
import IORedis from 'ioredis';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { TranslationService } from './translation.service';
import { TRANSLATION_QUEUE, TranslationJob } from './translation.queue';

/// Фактический перевод — здесь, не в `ChatsService.send` (задача 029,
/// п.6): до ~15с ожидания DeepSeek (таймаут 5с × до 3 попыток SDK) больше
/// не блокируют отправку сообщения. По готовности — `message:translated`
/// в комнату чата, тот же канал, что и `message:new`.
@Injectable()
export class TranslationProcessor implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(TranslationProcessor.name);
  private worker: Worker<TranslationJob> | null = null;

  constructor(
    private readonly translation: TranslationService,
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeGateway,
  ) {}

  onModuleInit() {
    const connection = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', { maxRetriesPerRequest: null });
    this.worker = new Worker<TranslationJob>(
      TRANSLATION_QUEUE,
      async (job) => {
        const { messageId, chatId, text, from, to, senderUserId } = job.data;
        const { translations, status } = await this.translation.translateMessage(senderUserId, text, from, to);
        const updated = await this.prisma.message.update({
          where: { id: messageId },
          data: {
            translations: Object.keys(translations).length > 0 ? translations : undefined,
            translationStatus: status,
          },
        });
        this.realtime.emitMessageTranslated(chatId, {
          id: updated.id,
          chatId: updated.chatId,
          translations: updated.translations,
          translationStatus: updated.translationStatus,
        });
      },
      { connection },
    );
    this.worker.on('failed', (job, err) => {
      this.logger.error(`Translation job ${job?.id} failed: ${err.message}`);
    });
  }

  async onModuleDestroy() {
    await this.worker?.close();
  }
}
