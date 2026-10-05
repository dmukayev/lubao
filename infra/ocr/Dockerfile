FROM python:3.11-slim

WORKDIR /app

# Задача 032, п.8 — Tesseract вместо EasyOCR: EasyOCR тянет PyTorch
# (1-2+ ГБ) и докачивает модели из интернета при первом запросе, что не
# собирается стабильно на Mac (см. docs/decisions.md «Движок распознавания
# — Tesseract»). Все языковые пакеты ставятся из apt прямо в образ —
# работает офлайн, без скачивания моделей при старте контейнера.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        tesseract-ocr \
        tesseract-ocr-rus \
        tesseract-ocr-kaz \
        tesseract-ocr-eng \
        tesseract-ocr-chi-sim \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server.py .

EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=3)" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--timeout", "60", "server:app"]
