/// Абстракция канала email. Реализация выбирается через .env (EMAIL_PROVIDER),
/// бизнес-логика (лимиты, TTL кода, хранение) — в EmailService, не здесь.
/// По аналогии с SmsProvider (задача 006/022: вход логиста — код на email).
export abstract class EmailProvider {
  /// Код для конкретной попытки входа. Для dev-провайдера — всегда "111111"
  /// (чтобы разработчику не нужно было лезть в лог), для прод — случайный.
  abstract generateCode(): string;

  abstract sendCode(email: string, code: string): Promise<void>;

  /// Произвольное письмо (задача 025: приглашение сотрудника — ссылка, а не
  /// код). `bodyText` — простой текст, без вёрстки (решение 022, п. 14).
  abstract sendMessage(email: string, subject: string, bodyText: string): Promise<void>;
}
