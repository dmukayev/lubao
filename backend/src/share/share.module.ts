import { Module } from '@nestjs/common';
import { SharePageController, ShareController } from './share.controller';
import { SharePagesService } from './share-pages.service';
import { ShareService } from './share.service';

@Module({
  controllers: [ShareController, SharePageController],
  providers: [ShareService, SharePagesService],
  exports: [ShareService],
})
export class ShareModule {}
