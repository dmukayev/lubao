import { Module } from '@nestjs/common';
import { ResponsesModule } from '../responses/responses.module';
import { CargosController } from './cargos.controller';
import { CargosService } from './cargos.service';

@Module({
  imports: [ResponsesModule],
  controllers: [CargosController],
  providers: [CargosService],
  exports: [CargosService],
})
export class CargosModule {}
