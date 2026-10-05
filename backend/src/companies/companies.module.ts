import { Module } from '@nestjs/common';
import { EmailModule } from '../email/email.module';
import { RecognitionModule } from '../recognition/recognition.module';
import { CompaniesController } from './companies.controller';
import { CompaniesService } from './companies.service';

@Module({
  imports: [EmailModule, RecognitionModule],
  controllers: [CompaniesController],
  providers: [CompaniesService],
  exports: [CompaniesService],
})
export class CompaniesModule {}
