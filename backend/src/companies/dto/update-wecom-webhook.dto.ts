import { IsOptional, IsUrl } from 'class-validator';

export class UpdateWeComWebhookDto {
  @IsOptional()
  @IsUrl({ require_tld: false })
  wecomWebhookUrl?: string | null;
}
