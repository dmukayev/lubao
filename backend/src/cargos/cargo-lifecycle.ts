/// Груз архивируется через 3 дня после даты готовности (CLAUDE.md), а не
/// через 48 ч, как было до задачи 042: `expiresAt` и фоновая задача архива
/// считают от одной константы.
export const CARGO_ARCHIVE_AFTER_DAYS = 3;
export const CARGO_ARCHIVE_AFTER_MS = CARGO_ARCHIVE_AFTER_DAYS * 24 * 60 * 60 * 1000;
