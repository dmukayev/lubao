#!/usr/bin/env bash
# Карта для OSRM (047 п.2, decisions.md 2026-10-08 «Расстояния — свой OSRM»).
# Разово на сервере (~30 мин, ~2 ГБ в volume): скачать выдержки OSM с Geofabrik
# (Казахстан, Кыргызстан, Узбекистан, приграничные округа РФ, Синьцзян из КНР),
# склеить, подготовить для профиля car (extract + contract). Данные — в docker
# volume `osrmdata`, не в репозитории. Повторный запуск обновляет карту.
#
#   infra/osrm/prepare.sh                      # dev (docker-compose.yml)
#   COMPOSE_FILE=docker-compose.prod.yml infra/osrm/prepare.sh
set -euo pipefail

cd "$(dirname "$0")/../.."
PROJECT="${COMPOSE_PROJECT_NAME:-$(basename "$PWD" | tr '[:upper:]' '[:lower:]')}"
VOLUME="${OSRM_VOLUME:-${PROJECT}_osrmdata}"
OSRM_IMAGE="${OSRM_IMAGE:-osrm/osrm-backend:v5.27.1}"
GEOFABRIK="https://download.geofabrik.de"
# Синьцзян — прямоугольником из файла КНР: Geofabrik не режет Китай по провинциям.
XINJIANG_BBOX="73.4,34.3,96.4,49.2"

docker volume create "$VOLUME" >/dev/null

echo "== скачивание и склейка (osmium) =="
docker run --rm -v "$VOLUME:/data" debian:bookworm-slim bash -euo pipefail -c "
  apt-get update -qq && apt-get install -y -qq osmium-tool wget ca-certificates >/dev/null
  cd /data && mkdir -p src && cd src
  for path in asia/kazakhstan asia/kyrgyzstan asia/uzbekistan asia/china \
              russia/siberian-fed-district russia/ural-fed-district russia/volga-fed-district; do
    wget -q -N '$GEOFABRIK/'\$path'-latest.osm.pbf'
  done
  osmium extract --overwrite -b '$XINJIANG_BBOX' china-latest.osm.pbf -o xinjiang.osm.pbf
  osmium merge --overwrite kazakhstan-latest.osm.pbf kyrgyzstan-latest.osm.pbf uzbekistan-latest.osm.pbf \
    siberian-fed-district-latest.osm.pbf ural-fed-district-latest.osm.pbf volga-fed-district-latest.osm.pbf \
    xinjiang.osm.pbf -o ../region.osm.pbf
"

echo "== osrm-extract / osrm-contract (профиль car) =="
docker run --rm -v "$VOLUME:/data" "$OSRM_IMAGE" osrm-extract -p /opt/car.lua /data/region.osm.pbf
docker run --rm -v "$VOLUME:/data" "$OSRM_IMAGE" osrm-contract /data/region.osrm

echo "Готово. Перезапустите сервис osrm: docker compose restart osrm"
