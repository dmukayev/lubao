#!/usr/bin/env bash
# 060 п.5: замер скорости на Android-эмуляторе 360 dp в --profile:
# время до первой ленты, прокрутка ленты из 200 грузов, переключение вкладок.
# Свой сервер на e2e-базе (dev-база не трогается). Эмулятор — с графикой Mac
# (-gpu host): программная отрисовка e2e (swiftshader) кадры не покажет.
# Скорость смотреть только в --profile/--release, не в debug.
set -uo pipefail
cd "$(dirname "$0")/.."
set -a; [[ -f .env ]] && source .env; set +a
export PUSH_PROVIDER=console TRANSLATION_PROVIDER=noop SMS_PROVIDER=console

PORT=3100
DB_URL="postgresql://lubao:lubao@localhost:${POSTGRES_PORT:-5434}/lubao_e2e?schema=public"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$SDK/platform-tools/adb"; EMU="$SDK/emulator/emulator"
AVD="${E2E_ANDROID_AVD:-lubao_e2e_360}"; SERIAL=emulator-5560
OUT=apps/lubao_app/build/perf; mkdir -p "$OUT"
BACKEND_PID=""; EMU_PID=""
cleanup() {
  [[ -n "$BACKEND_PID" ]] && kill "$BACKEND_PID" 2>/dev/null
  "$ADB" -s "$SERIAL" emu kill >/dev/null 2>&1 || true
  [[ -n "$EMU_PID" ]] && kill "$EMU_PID" 2>/dev/null
}
trap cleanup EXIT

echo "== e2e-база + сид + 200 грузов =="
docker exec lubao-postgres-1 psql -U lubao -d lubao -c "DROP DATABASE IF EXISTS lubao_e2e WITH (FORCE)" >/dev/null
docker exec lubao-postgres-1 createdb -U lubao lubao_e2e
(cd backend && DATABASE_URL="$DB_URL" bash -c 'npx prisma migrate deploy && npx ts-node prisma/seed.ts && npx ts-node prisma/seed-e2e.ts') >"$OUT/db.log" 2>&1 || { echo "сид не удался (см. $OUT/db.log)"; exit 1; }
docker exec lubao-postgres-1 psql -U lubao -d lubao_e2e -c "
  INSERT INTO cargos (id, \"companyId\", \"publishedByUserId\", \"pointId\", \"destinationCountryId\", \"destinationCityId\", \"bodyTypeId\", \"weightKg\", \"categoryId\", price, currency, \"readyDate\", status, \"publishedAt\", \"expiresAt\", \"createdAt\", \"updatedAt\", \"distanceKm\", \"pricePerKm\")
  SELECT gen_random_uuid()::text, \"companyId\", \"publishedByUserId\", \"pointId\", \"destinationCountryId\", \"destinationCityId\", \"bodyTypeId\", \"weightKg\", \"categoryId\", price + g, currency, \"readyDate\", 'PUBLISHED', now(), now() + interval '3 days', now(), now(), \"distanceKm\", \"pricePerKm\"
  FROM cargos, generate_series(1, 200) g WHERE id = '11111111-1111-4111-8111-111111111001';" >/dev/null
docker exec lubao-redis-1 redis-cli -n 1 flushdb >/dev/null

echo "== сервер :$PORT =="
rm -rf backend/dist-e2e && cp -R backend/dist backend/dist-e2e
(cd backend && DATABASE_URL="$DB_URL" REDIS_URL="redis://localhost:${REDIS_PORT:-6379}/1" PORT="$PORT" SMS_PROVIDER=console EMAIL_PROVIDER=console \
  TRANSLATION_PROVIDER=noop NODE_ENV=development JOBS_DISABLED=true SMS_MINUTE_LOCK_SECONDS=0 THROTTLE_USER_LIMIT=6000 \
  exec node dist-e2e/src/main.js >"../$OUT/backend.log" 2>&1) &
BACKEND_PID=$!
for _ in $(seq 1 60); do curl -sf "http://localhost:$PORT/reference-data" >/dev/null && break; sleep 1; done

echo "== эмулятор $AVD (-gpu host) =="
xcrun simctl shutdown all >/dev/null 2>&1 || true
"$EMU" -avd "$AVD" -port 5560 -no-window -no-audio -no-boot-anim -no-snapshot -wipe-data -gpu host >"$OUT/emulator.log" 2>&1 &
EMU_PID=$!
for _ in $(seq 1 150); do [[ "$("$ADB" -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]] && break; sleep 2; done
# Как в e2e: русский язык системы, без системных анимаций, крупный шрифт.
"$ADB" -s "$SERIAL" root >/dev/null 2>&1; "$ADB" -s "$SERIAL" wait-for-device
"$ADB" -s "$SERIAL" shell "setprop persist.sys.locale ru-RU; setprop ctl.restart zygote"; sleep 5
for _ in $(seq 1 90); do [[ "$("$ADB" -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]] && break; sleep 2; done
for k in window_animation_scale transition_animation_scale animator_duration_scale; do "$ADB" -s "$SERIAL" shell settings put global "$k" 0; done
"$ADB" -s "$SERIAL" shell settings put system font_scale 1.3
"$ADB" -s "$SERIAL" reverse "tcp:$PORT" "tcp:$PORT" >/dev/null

echo "== flutter drive --profile =="
(cd apps/lubao_app && flutter drive --profile --no-dds -d "$SERIAL" --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart \
  --dart-define=API_BASE_URL="http://localhost:$PORT" --dart-define=E2E_DEV_CODE=1111 >"build/perf/drive.log" 2>&1)
code=$?
echo "drive: код $code; сводка — $OUT/perf_summary.json"
[[ -f "$OUT/perf_summary.json" ]] && cat "$OUT/perf_summary.json"
exit $code
