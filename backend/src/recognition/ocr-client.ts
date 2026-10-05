export interface OcrResult {
  lines: string[];
}

/// Задача 031/032 — HTTP-клиент к OCR-сервису (внутренняя сеть докера, без
/// публичного порта — infra/ocr/). Принимает уже прочитанные байты
/// документа, а не URL (задача 032, п.1) — раньше `fileUrl` от клиента
/// шёл прямиком в OCR-контейнер, который сам его скачивал (`requests.get`),
/// то есть произвольный URL от клиента = SSRF во внутреннюю сеть. Теперь
/// единственный, кто ходит за байтами — бэкенд (`uploads.service.ts`),
/// OCR получает готовый файл мультипартом и никогда не видит URL.
/// Если OCR_SERVICE_URL не задан, сервис недоступен или ответил ошибкой —
/// возвращает null, а не бросает: вызывающий код (recognition.service.ts)
/// пишет DocumentRecognition.status = SKIPPED и продолжает — ручная
/// проверка документа админом остаётся рабочим путём независимо от
/// доступности OCR.
export async function recognizeDocument(buffer: Buffer, contentType: string, lang: 'ru' | 'ch'): Promise<OcrResult | null> {
  const baseUrl = process.env.OCR_SERVICE_URL;
  if (!baseUrl) return null;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 30_000);
    const form = new FormData();
    form.append('file', new Blob([new Uint8Array(buffer)], { type: contentType }), 'document');
    form.append('lang', lang);
    const response = await fetch(`${baseUrl}/recognize`, {
      method: 'POST',
      body: form,
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
