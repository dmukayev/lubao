import { IsOptional } from 'class-validator';
import { IsWeComWebhookUrl } from '../../common/validators/wecom-webhook-url.validator';

export class UpdateWeComWebhookDto {
  @IsOptional()
  @IsWeComWebhookUrl()
  wecomWebhookUrl?: string | null;
}
