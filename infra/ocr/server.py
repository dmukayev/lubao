"""
Задача 031/032 — HTTP-обёртка над Tesseract для распознавания документов
(кириллица, казахский, китайский). Внутренний сервис docker-сети, без
аутентификации — не торчит наружу (docker-compose.yml, нет published-порта),
backend — единственный вызывающий.

Задача 032, п.1 — принимает только файл (multipart), никогда URL: раньше
сервис сам скачивал `fileUrl`, который фактически задавал клиент бэкенда —
SSRF во внутреннюю сеть. Теперь бэкенд сам читает байты документа и шлёт их
сюда, этот сервис URL не видит и никуда не ходит за данными.
"""

import io

import pytesseract
from flask import Flask, jsonify, request
from PIL import Image, ImageOps

app = Flask(__name__)

MAX_SIZE_BYTES = 10 * 1024 * 1024
# Задача 032, п.8 — язык подбирается по тому же 'ru'/'ch', что раньше
# выбирал recognition.service.ts (ru — казахстанские документы, ch —
# китайские), но здесь это уже готовый набор языковых моделей Tesseract.
TESSERACT_LANGS = {"ru": "kaz+rus+eng", "ch": "chi_sim+eng"}
LONG_SIDE_PX = 2000


def _preprocess(image: Image.Image) -> Image.Image:
    # Поворот по EXIF (фото с телефона часто приходят повёрнутыми),
    # увеличение до ~2000px по длинной стороне и автоконтраст — заметно
    # поднимают точность Tesseract на фото со телефона по сравнению со
    # сканами.
    image = ImageOps.exif_transpose(image)
    image = image.convert("L")
    w, h = image.size
    long_side = max(w, h)
    if long_side < LONG_SIDE_PX:
        scale = LONG_SIDE_PX / long_side
        image = image.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
    image = ImageOps.autocontrast(image)
    return image


@app.post("/recognize")
def recognize():
    file = request.files.get("file")
    lang = request.form.get("lang")
    if file is None or lang not in TESSERACT_LANGS:
        return jsonify({"error": "file and lang (ru|ch) are required"}), 400

    raw = file.read(MAX_SIZE_BYTES + 1)
    if len(raw) > MAX_SIZE_BYTES:
        return jsonify({"error": "file too large"}), 413

    try:
        image = Image.open(io.BytesIO(raw))
        image.load()
    except Exception:
        return jsonify({"error": "not a valid image"}), 400

    processed = _preprocess(image)
    text = pytesseract.image_to_string(processed, lang=TESSERACT_LANGS[lang], config="--psm 6")
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    return jsonify({"lines": lines})


@app.get("/health")
def health():
    return jsonify({"status": "ok"})
