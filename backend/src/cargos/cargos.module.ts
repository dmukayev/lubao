import { Module } from '@nestjs/common';
import { ResponsesModule } from '../responses/responses.module';
import { CargosController } from './cargos.controller';
import { CargosService } from './cargos.service';
import { ContactEventsModule } from '../contact-events/contact-events.module';

@Module({
  imports: [ResponsesModule, ContactEventsModule],
  controllers: [CargosController],
  providers: [CargosService],
  exports: [CargosService],
})
export class CargosModule {}
