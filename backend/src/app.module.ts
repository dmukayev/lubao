import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule } from '@nestjs/throttler';
import { AppThrottlerGuard, THROTTLE_TTL_MS, defaultLimit, userThrottler } from './common/app-throttler.guard';
import { PrismaModule } from './prisma/prisma.module';
import { ClientErrorsController } from './observability/client-errors.controller';
import { HealthController } from './health/health.controller';
import { JwtAuthGuard } from './common/jwt-auth.guard';
import { AuthModule } from './auth/auth.module';
import { ReferenceDataModule } from './reference-data/reference-data.module';
import { DriversModule } from './drivers/drivers.module';
import { ShareModule } from './share/share.module';
import { CompanyDriversModule } from './company-drivers/company-drivers.module';
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
import { ScheduleModule } from '@nestjs/schedule';
import { JobsModule } from './jobs/jobs.module';
import { AdminBootstrapService } from './cli/admin-bootstrap.service';
import { NotificationsModule } from './notifications/notifications.module';
import { RealtimeModule } from './realtime/realtime.module';
import { TranslationModule } from './translation/translation.module';
import { IdentifiersModule } from './identifiers/identifiers.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ name: 'default', ttl: THROTTLE_TTL_MS, limit: defaultLimit() }, userThrottler()]),
    PrismaModule,
    RedisModule,
    SmsModule,
    TokenModule,
    AppSettingsModule,
    ScheduleModule.forRoot(),
    JobsModule,
    NotificationsModule,
    RealtimeModule,
    TranslationModule,
    IdentifiersModule,
    AuthModule,
    ReferenceDataModule,
    DriversModule,
    CompanyDriversModule,
    ShareModule,
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
  controllers: [HealthController, ClientErrorsController],
  providers: [
    AdminBootstrapService,
    { provide: APP_GUARD, useClass: AppThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
  ],
})
export class AppModule {}
