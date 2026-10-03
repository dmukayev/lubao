import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { HealthController } from './health/health.controller';
import { DevAuthGuard } from './common/dev-auth.guard';
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

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    RedisModule,
    SmsModule,
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
  providers: [{ provide: APP_GUARD, useClass: DevAuthGuard }],
})
export class AppModule {}
