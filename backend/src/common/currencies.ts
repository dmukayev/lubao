/// Валюты груза (058 п.4: + RUB, UZS). Пересчёт в ₸ — по курсу НБ РК.
export const CARGO_CURRENCIES = ['USD', 'CNY', 'KZT', 'RUB', 'UZS'] as const;
export type CargoCurrency = (typeof CARGO_CURRENCIES)[number];

/// Валюты с курсом НБ РК (всё, кроме самого тенге).
export const RATE_CURRENCIES = ['USD', 'CNY', 'RUB', 'UZS'] as const;
export type RateCurrency = (typeof RATE_CURRENCIES)[number];

/// 058 п.1: форма оплаты.
export const PAYMENT_FORMS = ['CASH', 'CARD', 'CASHLESS'] as const;
export type PaymentFormCode = (typeof PAYMENT_FORMS)[number];
