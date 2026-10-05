"""
Задача 031, этап D, п.17 — минимальный HTTP-обёртка над EasyOCR для
распознавания документов (кириллица + китайский). Внутренний сервис
docker-сети, без аутентификации — не торчит наружу (см. docker-compose.yml,
нет published-порта), backend — единственный вызывающий.

EasyOCR не позволяет грузить 'ru' и 'ch_sim' в одном Reader (несовместимые
группы языков) — поэтому backend вызывает /recognize отдельно на каждый
язык и сам объединяет строки (recognition.service.ts).
"""

import easyocr
import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

_readers: dict[str, "easyocr.Reader"] = {}


def _reader_for(lang: str) -> "easyocr.Reader":
    model = {"ru": "ru", "ch": "ch_sim"}.get(lang)
    if model is None:
        raise ValueError(f"unsupported lang: {lang}")
    if model not in _readers:
        _readers[model] = easyocr.Reader([model], gpu=False)
    return _readers[model]


@app.post("/recognize")
def recognize():
    body = request.get_json(force=True) or {}
    file_url = body.get("fileUrl")
    lang = body.get("lang")
    if not file_url or lang not in ("ru", "ch"):
        return jsonify({"error": "fileUrl and lang (ru|ch) are required"}), 400

    image_bytes = requests.get(file_url, timeout=10).content
    reader = _reader_for(lang)
    results = reader.readtext(image_bytes, detail=0)
    return jsonify({"lines": results})


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
