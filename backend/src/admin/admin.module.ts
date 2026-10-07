import { SmsModule } from '../sms/sms.module';
import { Module } from '@nestjs/common';
import { AppSettingsModule } from '../app-settings/app-settings.module';
import { AuthModule } from '../auth/auth.module';
import { UploadsModule } from '../uploads/uploads.module';
import { IdentifiersModule } from '../identifiers/identifiers.module';
import { RecognitionModule } from '../recognition/recognition.module';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';

@Module({
  imports: [AppSettingsModule, AuthModule, UploadsModule, IdentifiersModule, RecognitionModule, SmsModule],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
