import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { HealthController } from './health/health.controller';
import { JwtAuthGuard } from './common/jwt-auth.guard';
import { AuthModule } from './auth/auth.module';
import { ReferenceDataModule } from './reference-data/reference-data.module';
import { DriversModule } from './drivers/drivers.module';
import { ArrivalsModule } from './arrivals/arrivals.module';
import { CompaniesModule } from './companies/companies.module';
import { CargosModule } from './cargos/cargos.module';
import { ResponsesModule } from './responses/responses.module';
import { DealsModule } from './deals/deals.module';
import { ChatsModule } from './chats/chats.module';
import { ContactEventsModule } from './contact-events/contact-events.module';
import { AdminModule } from './admin/admin.module';
import { UploadsModule } from './uploads/uploads.module';
import { RedisModule } from './redis/redis.module';
import { SmsModule } from './sms/sms.module';
import { TokenModule } from './token/token.module';
import { AppSettingsModule } from './app-settings/app-settings.module';
import { NotificationsModule } from './notifications/notifications.module';
import { RealtimeModule } from './realtime/realtime.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    RedisModule,
    SmsModule,
    TokenModule,
    AppSettingsModule,
    NotificationsModule,
    RealtimeModule,
    AuthModule,
    ReferenceDataModule,
    DriversModule,
    ArrivalsModule,
    CompaniesModule,
    CargosModule,
    ResponsesModule,
    DealsModule,
    ChatsModule,
    ContactEventsModule,
    AdminModule,
    UploadsModule,
  ],
  controllers: [HealthController],
  providers: [{ provide: APP_GUARD, useClass: JwtAuthGuard }],
})
export class AppModule {}
