#!/usr/bin/env bash
# Карта для OSRM (047 п.2, 049 п.11; decisions.md 2026-10-08 «Расстояния — свой OSRM»).
#
# Собирается ОДИН раз (обновление — раз в полгода) на машине с большой памятью:
# полная выдержка OSM — Казахстан, Кыргызстан, Узбекистан, Китай, приграничные
# федеральные округа РФ (Сибирский, Уральский, Приволжский, Южный). Карту не
# урезаем. Ресурсы: ~3,5 ГБ pbf, 16–32 ГБ RAM на extract/contract, 1–2 часа,
# ~10 ГБ диска. На Маке/проде сборку не запускать — туда копируется готовая
# папка (сервису osrm хватает 2–4 ГБ RAM).
#
#   infra/osrm/prepare.sh                         # Docker (по умолчанию, если есть)
#   OSRM_MODE=native infra/osrm/prepare.sh        # без Docker: osmium, osrm-extract, osrm-contract в PATH
#   OUT_DIR=/data/osrm infra/osrm/prepare.sh      # куда сложить результат (по умолчанию ./osrm-build)
#   REGIONS="asia/kazakhstan" infra/osrm/prepare.sh   # только для отладки скрипта — не для прода
#   PBF=/path/region.osm.pbf infra/osrm/prepare.sh    # pbf уже склеен — сразу extract/contract
#
# Результат: $OUT_DIR/region.osrm* — скопировать в volume `osrm-data` (см. конец вывода).
set -euo pipefail

OUT_DIR="$(mkdir -p "${OUT_DIR:-./osrm-build}" && cd "${OUT_DIR:-./osrm-build}" && pwd)"
OSRM_IMAGE="${OSRM_IMAGE:-ghcr.io/project-osrm/osrm-backend:v5.27.1}"
OSMIUM_IMAGE="${OSMIUM_IMAGE:-debian:bookworm-slim}"
GEOFABRIK="https://download.geofabrik.de"
REGIONS="${REGIONS:-asia/kazakhstan asia/kyrgyzstan asia/uzbekistan asia/china russia/siberian-fed-district russia/ural-fed-district russia/volga-fed-district russia/south-fed-district}"
if [[ -z "${OSRM_MODE:-}" ]]; then
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then OSRM_MODE=docker; else OSRM_MODE=native; fi
fi
started=$(date +%s)
echo "== режим: $OSRM_MODE · папка: $OUT_DIR"
echo "== регионы: $REGIONS"

# Выполнить команду в окружении сборки; пути — относительно $OUT_DIR (в Docker — /data).
run() {
  local image="$1"; shift
  if [[ "$OSRM_MODE" == docker ]]; then
    docker run --rm -v "$OUT_DIR:/data" -w /data "$image" "$@"
  else
    (cd "$OUT_DIR" && "$@")
  fi
}
profile() { [[ "$OSRM_MODE" == docker ]] && echo /opt/car.lua || echo "${OSRM_PROFILE:-/usr/local/share/osrm/profiles/car.lua}"; }

if [[ -n "${PBF:-}" ]]; then
  # Готовый склеенный pbf (например, собранный заранее) — шаги 1–2 пропускаем.
  echo "== 1–2/4 пропущены: беру $PBF"
  [[ "$(cd "$(dirname "$PBF")" && pwd)/$(basename "$PBF")" == "$OUT_DIR/region.osm.pbf" ]] || cp "$PBF" "$OUT_DIR/region.osm.pbf"
else
  echo "== 1/4 скачивание (Geofabrik, докачка по -N)"
  mkdir -p "$OUT_DIR/src"
  for path in $REGIONS; do
    (cd "$OUT_DIR/src" && curl -fsSL -z "$(basename "$path")-latest.osm.pbf" -o "$(basename "$path")-latest.osm.pbf" "$GEOFABRIK/$path-latest.osm.pbf")
  done
  ls -lh "$OUT_DIR/src"

  echo "== 2/4 склейка (osmium merge)"
  files=""
  for path in $REGIONS; do files="$files src/$(basename "$path")-latest.osm.pbf"; done
  if [[ "$OSRM_MODE" == docker ]]; then
    docker run --rm -v "$OUT_DIR:/data" -w /data "$OSMIUM_IMAGE" bash -c \
      "apt-get update -qq && apt-get install -y -qq osmium-tool >/dev/null && osmium merge --overwrite $files -o region.osm.pbf"
  else
    (cd "$OUT_DIR" && osmium merge --overwrite $files -o region.osm.pbf)
  fi

fi

echo "== 3/4 osrm-extract (профиль car) — самый тяжёлый шаг по памяти"
run "$OSRM_IMAGE" osrm-extract -p "$(profile)" region.osm.pbf
echo "== 4/4 osrm-contract"
run "$OSRM_IMAGE" osrm-contract region.osrm

elapsed=$(( $(date +%s) - started ))
echo
echo "Готово за $((elapsed / 60)) мин. Карта: $(du -ch "$OUT_DIR"/region.osrm* | tail -1 | cut -f1)"
cat <<INSTR

Дальше — на сервере с бэкендом (или на Маке):
  1) скопировать папку:   rsync -a $OUT_DIR/region.osrm* <сервер>:/tmp/osrm/
  2) положить в volume:   docker volume create osrm-data
                          docker run --rm -v osrm-data:/data -v /tmp/osrm:/src alpine sh -c 'cp /src/region.osrm* /data/'
  3) перезапустить:       docker compose -f docker-compose.prod.yml restart osrm
  4) проверка (≈ 1 200 км): docker compose -f docker-compose.prod.yml exec backend \\
       wget -qO- 'http://osrm:5000/route/v1/driving/76.9286,43.2567;71.4704,51.1605?overview=false'
INSTR
