export interface OcrResult {
  lines: string[];
}

/// Задача 031, этап D, п.17/18 — HTTP-клиент к OCR-сервису (внутренняя сеть
/// докера, без публичного порта — infra/ocr/). Если OCR_SERVICE_URL не
/// задан, сервис недоступен или ответил ошибкой — возвращает null, а не
/// бросает: вызывающий код (recognition.service.ts) пишет
/// DocumentRecognition.status = SKIPPED и продолжает — ручная проверка
/// документа админом остаётся рабочим путём независимо от доступности OCR.
export async function recognizeDocument(fileUrl: string, lang: 'ru' | 'ch'): Promise<OcrResult | null> {
  const baseUrl = process.env.OCR_SERVICE_URL;
  if (!baseUrl) return null;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15_000);
    const response = await fetch(`${baseUrl}/recognize`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ fileUrl, lang }),
      signal: controller.signal,
    });
    clearTimeout(timeout);
    if (!response.ok) return null;

    const data = (await response.json()) as { lines?: unknown };
    if (!Array.isArray(data.lines)) return null;
    return { lines: data.lines.filter((l): l is string => typeof l === 'string') };
  } catch {
    return null;
  }
}
