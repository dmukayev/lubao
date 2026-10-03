/// Абстракция канала SMS. Реализация выбирается через .env (SMS_PROVIDER),
/// бизнес-логика (лимиты, TTL кода, хранение) — в SmsService, не здесь.
export abstract class SmsProvider {
  /// Код для конкретной попытки входа. Для dev-провайдера — всегда "1111"
  /// (чтобы разработчику не нужно было лезть в лог), для прод — случайный.
  abstract generateCode(): string;

  abstract sendCode(phone: string, code: string): Promise<void>;
}
