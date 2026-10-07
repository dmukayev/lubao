import { ForbiddenException } from '@nestjs/common';
import { User } from '@prisma/client';

/// Версия текста согласия на обработку ПДн (043 п.2) — дата редакции
/// `infra/site/legal/privacy.html`. Меняется вместе с текстом: у всех, кто
/// соглашался на старую, согласие спросят заново перед следующей загрузкой.
export const PD_CONSENT_VERSION = '2026-10-08';

/// Версия оферты для компании (043 п.2, `infra/site/legal/offer.html`):
/// принимается галочкой при регистрации компании.
export const OFFER_VERSION = '2026-10-08';

export function pdConsentRequired(user: Pick<User, 'pdConsentAt' | 'pdConsentVersion'>): boolean {
  return !user.pdConsentAt || user.pdConsentVersion !== PD_CONSENT_VERSION;
}

/// Документы (селфи, права, техпаспорта, документы компании) — только после
/// согласия: 403 с кодом, по которому приложение показывает экран согласия.
export function assertPdConsent(user: Pick<User, 'pdConsentAt' | 'pdConsentVersion'>): void {
  if (pdConsentRequired(user)) {
    throw new ForbiddenException({ code: 'PD_CONSENT_REQUIRED', version: PD_CONSENT_VERSION, message: 'Consent to personal data processing is required' });
  }
}
