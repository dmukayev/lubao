import { Global, Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { RealtimeGateway } from './realtime.gateway';

/// Глобальный модуль (как Redis/Token/Notifications) — ChatsService
/// дёргает emitMessageNew/emitMessageRead напрямую, без события/шины.
/// AuthModule — за SessionService (проверка «сессия ещё жива» при
/// подключении, как и у JwtAuthGuard).
@Global()
@Module({
  imports: [AuthModule],
  providers: [RealtimeGateway],
  exports: [RealtimeGateway],
})
export class RealtimeModule {}
