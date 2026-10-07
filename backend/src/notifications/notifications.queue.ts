import { DevicePlatform } from '@prisma/client';

export const NOTIFICATIONS_QUEUE = 'notifications';

export type NotificationJob =
  | { channel: 'PUSH'; token: string; platform: DevicePlatform; title: string; body: string; data: Record<string, string>; category?: 'STILL_LOOKING' | 'AGREED_CHECK' }
  | { channel: 'WECOM'; webhookUrl: string; text: string };
