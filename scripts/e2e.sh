#!/usr/bin/env bash
# Задача 034 — сквозные сценарии одной командой, с защитой от зависаний.
#
# На каждом устройстве (по умолчанию iPhone SE с крупным шрифтом, затем
# Android-эмулятор 360 dp с font_scale 1.3 — 049 п.13) с нуля:
# пересоздаёт БД `lubao_e2e`, сидит детерминированные данные, поднимает
# backend на отдельном порту и OCR-контейнер, затем
#   1. API-смоук админки;
#   2. сценарии приложения на симуляторе (водитель/логист);
#   3. админку в Chrome (Playwright по семантике Flutter): 10–14;
#   4. сценарии приложения, которым нужны решения админа (публикация груза);
#   5. обход всех экранов (безопасная зона, переполнения).
# Итог — test-results/e2e/report.md (по шагам, со скриншотами) и код возврата:
#   0 — всё зелёное на всех устройствах; 1 — есть упавшие/TIMEOUT;
#   2 — iOS пропущен из-за окружения; 3 — неполный прогон (dev-флаги E2E_*).
#
# Правило устойчивости (CLAUDE.md, 034): каждая долгая команда — с лимитом
# времени; по истечении процесс (и его потомки) убивается, в отчёт идёт
# TIMEOUT. На выходе (trap) гасится только то, что запустил этот скрипт:
# учёт по PID, чужие `flutter test` не трогаем.
#
# Использование:
#   scripts/e2e.sh                      # iPhone SE (крупный шрифт) и Android 360 dp
#   scripts/e2e.sh -d "iPhone 17"       # одно устройство (iPhone 17 — только так)
#   scripts/e2e.sh -d android:lubao_e2e_360   # Android-эмулятор (AVD), headless
#   scripts/e2e.sh -d "iPhone SE (3rd generation)"   # узкий экран + крупный шрифт (по умолчанию для SE)
#   E2E_CONTENT_SIZE=extra-extra-extra-large scripts/e2e.sh -d "iPhone 17"   # крупный системный шрифт на любом
#   E2E_ONLY="driver_flow_test" scripts/e2e.sh   # dev: один сценарий (код 3)
#   E2E_SKIP_IOS=1 / E2E_SKIP_ADMIN_UI=1 / E2E_ADMIN_UI_ONLY=1   # dev: код 3
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"

DEVICES=("iPhone SE (3rd generation)" "android:${E2E_ANDROID_AVD:-lubao_e2e_360}")
if [[ "${1:-}" == "-d" ]]; then DEVICES=("$2"); fi

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
# CocoaPods (`pod`) нужен для сборки под симулятор — на этой машине он под rbenv.
[[ -d "$HOME/.rbenv/shims" ]] && export PATH="$HOME/.rbenv/shims:$PATH"

E2E_PORT="${E2E_BACKEND_PORT:-3100}"
ADMIN_WEB_PORT="${E2E_ADMIN_WEB_PORT:-3200}"
OCR_PORT="${E2E_OCR_PORT:-18000}"
OCR_CONTAINER="lubao-e2e-ocr"
E2E_DB_URL="postgresql://lubao:lubao@localhost:${POSTGRES_PORT:-5434}/lubao_e2e?schema=public"
RESULTS="$ROOT/test-results/e2e"
REPORT="$RESULTS/report.md"
SHOTS="$RESULTS/shots"

# PID корневых процессов, запущенных этим скриптом (и временно — под таймаутом).
OWN_PIDS=()
BACKEND_PID=""
STATIC_PID=""
BOOTED_UDIDS=()
# Android (049 п.13): эмулятор без окна, свой порт; гасится на выходе.
ANDROID_SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$ANDROID_SDK/platform-tools/adb"
EMULATOR_BIN="$ANDROID_SDK/emulator/emulator"
EMU_PORT="${E2E_EMULATOR_PORT:-5580}"
EMU_SERIAL="emulator-$EMU_PORT"
EMU_PID=""
APP_ID="kz.darkhan.lubao"
# Приёмник скриншотов/шагов с эмулятора (scripts/e2e-shot-sink.mjs, adb reverse).
SINK_PORT="${E2E_SHOT_SINK_PORT:-3301}"
SINK_PID=""
STARTED_OCR=0
FAILED=0
SKIPPED=0
TIMEOUTS=0
PARTIAL=0

# ---------------------------------------------------------------- утилиты --

kill_tree() {
  local pid="$1" child
  for child in $(pgrep -P "$pid" 2>/dev/null); do kill_tree "$child"; done
  kill -9 "$pid" 2>/dev/null || true
}

forget_pid() {
  local keep=() p
  for p in "${OWN_PIDS[@]:-}"; do [[ -n "$p" && "$p" != "$1" ]] && keep+=("$p"); done
  OWN_PIDS=("${keep[@]:-}")
}

# run_with_timeout <секунды> <лог> <команда...>; код 124 — истёк лимит.
run_with_timeout() {
  local limit="$1" log="$2"
  shift 2
  # RWT_DIR — рабочий каталог команды (без подоболочек, чтобы PID попадал в учёт).
  ( cd "${RWT_DIR:-.}" && exec "$@" ) >"$log" 2>&1 &
  local pid=$!
  OWN_PIDS+=("$pid")
  (
    sleep "$limit"
    if kill -0 "$pid" 2>/dev/null; then
      echo "[e2e] TIMEOUT ${limit}s — убиваю процесс $pid" >>"$log"
      kill_tree "$pid"
    fi
  ) &
  local watchdog=$!
  OWN_PIDS+=("$watchdog")
  wait "$pid" 2>/dev/null
  local code=$?
  kill_tree "$watchdog"
  wait "$watchdog" 2>/dev/null || true
  forget_pid "$pid"; forget_pid "$watchdog"
  # Убит сторожем (а не завершился сам) — он оставил маркер в логе.
  grep -q "^\[e2e\] TIMEOUT" "$log" && code=124
  return $code
}

# Короткие служебные команды (docker exec, createdb, redis) — тоже с лимитом.
quick() {
  local limit="$1"
  shift
  run_with_timeout "$limit" "$RESULTS/misc.log" "$@"
}

cleanup() {
  local p
  for p in "${OWN_PIDS[@]:-}"; do [[ -n "$p" ]] && kill_tree "$p"; done
  [[ -n "$BACKEND_PID" ]] && kill_tree "$BACKEND_PID"
  [[ -n "$STATIC_PID" ]] && kill_tree "$STATIC_PID"
  for u in "${BOOTED_UDIDS[@]:-}"; do [[ -n "$u" ]] && xcrun simctl shutdown "$u" >/dev/null 2>&1; done
  if [[ -n "$EMU_PID" ]]; then "$ADB" -s "$EMU_SERIAL" emu kill >/dev/null 2>&1; kill_tree "$EMU_PID"; fi
  [[ -n "$SINK_PID" ]] && kill_tree "$SINK_PID"
  if [[ $STARTED_OCR -eq 1 ]]; then docker rm -f "$OCR_CONTAINER" >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT
trap 'echo "[e2e] прервано"; exit 130' INT TERM

mkdir -p "$RESULTS"
rm -rf "$SHOTS"
mkdir -p "$SHOTS"
{
  echo "# E2E-отчёт"
  echo
  echo "Запуск: $(date '+%Y-%m-%d %H:%M:%S') · устройства: ${DEVICES[*]}"
  echo
} >"$REPORT"
row() { echo "| $1 | $2 | $3 |" >>"$REPORT"; }
table_header() {
  { echo; echo "## $1"; echo; echo "| Сценарий | Результат | Детали |"; echo "|---|---|---|"; } >>"$REPORT"
}

# Построчный отчёт шагов (steps.jsonl от Flutter-сценариев и Playwright).
append_steps() {
  local slug="$1" file="$SHOTS/$1/steps.jsonl"
  [[ -f "$file" ]] || return 0
  node -e '
    const fs = require("fs");
    const rows = fs.readFileSync(process.argv[1], "utf8").split("\n").filter(Boolean).map((l) => JSON.parse(l));
    const root = process.argv[2];
    const out = ["", "### Шаги", "", "| Сценарий | Шаг | Результат | Скриншот / ошибка |", "|---|---|---|---|"];
    for (const r of rows) {
      const shot = r.shot ? "[" + r.shot.split("/").pop() + "](" + r.shot.replace(root + "/", "") + ")" : "";
      out.push("| " + r.scenario + " | " + r.step + " | " + (r.ok ? "✅" : "❌") + " | " + (r.ok ? shot : (r.error || "") + " " + shot) + " |");
    }
    console.log(out.join("\n"));
  ' "$file" "$RESULTS" >>"$REPORT"
}

# --------------------------------------------------------------- окружение --

echo "== docker-сервисы =="
if ! run_with_timeout 300 "$RESULTS/docker.log" docker compose up -d postgres redis minio; then
  row "окружение: docker" "❌" "docker compose up не завершился (см. docker.log)"; cat "$RESULTS/docker.log"; exit 1
fi
for svc in postgres redis minio; do
  for _ in $(seq 1 90); do
    [[ "$(docker inspect -f '{{.State.Health.Status}}' "lubao-${svc}-1" 2>/dev/null)" == "healthy" ]] && break
    sleep 1
  done
done

# OCR для сценариев с документами: свой контейнер на отдельном порту, чтобы
# не трогать дев-окружение; образ тот же, что собирает docker compose.
echo "== OCR =="
docker rm -f "$OCR_CONTAINER" >/dev/null 2>&1 || true
if docker image inspect lubao-ocr:latest >/dev/null 2>&1 \
   && run_with_timeout 60 "$RESULTS/ocr.log" docker run -d --name "$OCR_CONTAINER" -p "${OCR_PORT}:8000" lubao-ocr:latest; then
  STARTED_OCR=1
  for _ in $(seq 1 60); do
    curl -sf "http://localhost:${OCR_PORT}/health" >/dev/null 2>&1 && break
    sleep 1
  done
else
  echo "OCR-образ lubao-ocr не найден или не стартовал — сценарии с распознаванием будут красными"
fi

# Ключи идентификаторов нужны сиду (хеш номера в чёрном списке) и backend.
set -a; source .env; set +a
# Внешние каналы в e2e — заглушки, что бы ни стояло в .env для dev: иначе
# сценарии слали бы настоящие push на тестовые токены и платно переводили чат.
export PUSH_PROVIDER=console TRANSLATION_PROVIDER=noop SMS_PROVIDER=console

echo "== сборка backend =="
if ! RWT_DIR=backend run_with_timeout 300 "$RESULTS/build.log" npx nest build; then
  row "окружение: сборка backend" "❌" "см. build.log"; tail -20 "$RESULTS/build.log"; exit 1
fi
# Снимок сборки: dev-бэкенд в Docker (`start:dev`, watch) пересобирает общий
# backend/dist при каждой правке кода — e2e не должен подхватить полусобранное.
rm -rf backend/dist-e2e && cp -R backend/dist backend/dist-e2e

# Playwright для админки: зависимости и браузер (Chromium качает сам Playwright,
# системный Chrome не нужен).
if [[ -z "${E2E_SKIP_ADMIN_UI:-}" ]]; then
  echo "== Playwright: npm ci + chromium =="
  if ! RWT_DIR=scripts/e2e-admin-ui run_with_timeout 900 "$RESULTS/playwright-install.log" \
       bash -c 'npm ci --no-audit --no-fund && npx playwright install chromium'; then
    row "окружение: Playwright" "❌" "npm ci / playwright install не завершились (см. playwright-install.log)"
    tail -20 "$RESULTS/playwright-install.log"; FAILED=$((FAILED + 1))
    E2E_SKIP_ADMIN_UI=playwright-install-failed
  fi
fi

# Админка: одна сборка web на весь прогон, раздаём со своего сервера.
ADMIN_WEB="$RESULTS/admin-web"
if [[ -z "${E2E_SKIP_ADMIN_UI:-}" && -z "${E2E_SKIP_ADMIN_BUILD:-}" ]]; then
  echo "== сборка админки (web, семантика включена) =="
  # Только в чистый каталог: поверх старой сборки Flutter теряет часть assets.
  rm -rf "$ADMIN_WEB"
  if ! RWT_DIR=apps/lubao_admin run_with_timeout 900 "$RESULTS/admin-build.log" \
        flutter build web --release --no-web-resources-cdn --dart-define=E2E=true --dart-define=API_BASE_URL="http://localhost:${E2E_PORT}" \
        --output "$ADMIN_WEB"; then
    row "окружение: сборка админки" "❌" "см. admin-build.log"; tail -20 "$RESULTS/admin-build.log"; FAILED=$((FAILED + 1))
    E2E_SKIP_ADMIN_UI=build-failed
  fi
fi

# Веб логиста (020 часть А, 043 п.8): одна сборка, проверка «ни одного
# запроса к Google» — на первом устройстве прогона.
APP_WEB="$RESULTS/app-web"
APP_WEB_PORT="${E2E_APP_WEB_PORT:-3201}"
if [[ -z "${E2E_SKIP_ADMIN_UI:-}" && -z "${E2E_ONLY:-}" ]]; then
  echo "== сборка веба логиста =="
  rm -rf "$APP_WEB"
  if ! RWT_DIR=apps/lubao_app run_with_timeout 900 "$RESULTS/app-web-build.log" \
        flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL="http://localhost:${E2E_PORT}" --output "$APP_WEB"; then
    APP_WEB=""
  fi
fi
WEB_CHECKED=""

start_backend() {
  (
    cd backend
    DATABASE_URL="$E2E_DB_URL" REDIS_URL="redis://localhost:${REDIS_PORT:-6379}/1" PORT="$E2E_PORT" \
      SMS_PROVIDER=console EMAIL_PROVIDER=console TRANSLATION_PROVIDER=noop NODE_ENV=development JOBS_DISABLED=true SMS_MINUTE_LOCK_SECONDS=0 LOGIN_CODE_CONSOLE_CHANNELS=whatsapp,telegram \
      OCR_SERVICE_URL="http://localhost:${OCR_PORT}" \
      THROTTLE_USER_LIMIT=600 TELEGRAM_BOT_TOKEN=e2e-token TELEGRAM_BOT_USERNAME=lubao_e2e_bot TELEGRAM_WEBHOOK_SECRET=e2e-telegram-secret TELEGRAM_API_URL=http://127.0.0.1:9 `# сценарии жмут быстрее человека; сам лимит 60/мин — HTTP-тест в бэкенде` \
      exec node dist-e2e/src/main.js >"$RESULTS/backend.log" 2>&1
  ) &
  BACKEND_PID=$!
  for _ in $(seq 1 60); do
    curl -sf "http://localhost:${E2E_PORT}/reference-data" >/dev/null 2>&1 && return 0
    sleep 1
  done
  return 1
}

# Свежая БД на каждый прогон устройства — сценарии меняют данные (машины,
# компании, проверки), и только чистая БД даёт тот же результат дважды.
reset_database() {
  [[ -n "$BACKEND_PID" ]] && { kill_tree "$BACKEND_PID"; BACKEND_PID=""; }
  quick 60 docker exec lubao-postgres-1 psql -U lubao -d lubao -c "DROP DATABASE IF EXISTS lubao_e2e WITH (FORCE)" || return 1
  quick 60 docker exec lubao-postgres-1 createdb -U lubao lubao_e2e || return 1
  RWT_DIR=backend run_with_timeout 300 "$RESULTS/db.log" env DATABASE_URL="$E2E_DB_URL" \
    bash -c 'npx prisma migrate deploy && npx ts-node prisma/seed.ts && npx ts-node prisma/seed-e2e.ts' || return 1
  # Лимит SMS-кодов (1/мин на номер, 20/ч на IP) живёт в Redis между
  # запусками — чистим логическую БД /1 перед каждым прогоном.
  quick 30 docker exec lubao-redis-1 redis-cli -n 1 flushdb || return 1
  start_backend
}

# ------------------------------------------------------------- сценарии iOS --

IOS_ENV_FAILURES=0
IOS_READY=0
UDID=""
DEVICE_SLUG=""

prepare_simulator() {
  local name="$1"
  UDID="$(xcrun simctl list devices available | grep -F "$name (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
  IOS_ENV_FAILURES=0
  IOS_READY=0
  if [[ -z "$UDID" ]]; then
    row "окружение: симулятор" "⏭ пропущено (окружение)" "устройство «$name» не найдено"
    IOS_ENV_FAILURES=2
    return
  fi
  # Только свои симуляторы: чужие запущенные не гасим.
  xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
  BOOTED_UDIDS+=("$UDID")
  if run_with_timeout 300 "$RESULTS/simctl-boot.log" xcrun simctl boot "$UDID" \
     && run_with_timeout 300 "$RESULTS/simctl-bootstatus.log" xcrun simctl bootstatus "$UDID" -b; then
    IOS_READY=1
    # Крупный системный шрифт: на узком SE — всегда (Huawei Y7: 360 dp × 1,3
    # ломал вёрстку), на остальных — по E2E_CONTENT_SIZE. extra-extra-extra-large
    # ≈ ×1,35 — самый крупный обычный размер iOS (без «Увеличенных размеров»).
    local size="${E2E_CONTENT_SIZE:-}"
    [[ -z "$size" && "$name" == *"SE"* ]] && size="extra-extra-extra-large"
    if [[ -n "$size" ]]; then
      xcrun simctl ui "$UDID" content_size "$size" >/dev/null 2>&1 && echo "  размер текста: $size"
    fi
  else
    row "окружение: симулятор" "⏭ пропущено (окружение)" "simctl boot/bootstatus не завершились за 5 мин"
    IOS_ENV_FAILURES=2
  fi
}

# Android-эмулятор (049 п.13): AVD 360×800 dp, API 34, без окна и звука;
# крупный шрифт (font_scale 1.3), бэкенд — через `adb reverse` на тот же localhost.
prepare_emulator() {
  local avd="$1"
  IOS_ENV_FAILURES=0
  IOS_READY=0
  UDID="$EMU_SERIAL"
  if ! "$EMULATOR_BIN" -list-avds 2>/dev/null | grep -qx "$avd"; then
    row "окружение: эмулятор" "⏭ пропущено (окружение)" "AVD «$avd» не найден (avdmanager create avd …)"
    IOS_ENV_FAILURES=2; return
  fi
  "$ADB" -s "$EMU_SERIAL" emu kill >/dev/null 2>&1 || true
  "$EMULATOR_BIN" -avd "$avd" -port "$EMU_PORT" -no-window -no-audio -no-boot-anim -no-snapshot -wipe-data -gpu swiftshader_indirect \
    >"$RESULTS/emulator.log" 2>&1 &
  EMU_PID=$!
  local booted=""
  for _ in $(seq 1 150); do
    [[ "$("$ADB" -s "$EMU_SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]] && { booted=1; break; }
    sleep 2
  done
  if [[ -z "$booted" ]]; then
    row "окружение: эмулятор" "⏭ пропущено (окружение)" "эмулятор не загрузился за 5 мин (см. emulator.log)"
    IOS_ENV_FAILURES=2; return
  fi
  # Язык системы — русский, как у симуляторов (иначе сценарии видят en до входа
  # и ru после). Образ google_apis даёт root: свойство + перезапуск zygote.
  local locale="${E2E_ANDROID_LOCALE:-ru-RU}"
  if [[ "$("$ADB" -s "$EMU_SERIAL" shell getprop persist.sys.locale | tr -d '\r')" != "$locale" ]]; then
    "$ADB" -s "$EMU_SERIAL" root >/dev/null 2>&1; "$ADB" -s "$EMU_SERIAL" wait-for-device
    "$ADB" -s "$EMU_SERIAL" shell "setprop persist.sys.locale $locale; setprop ctl.restart zygote"
    sleep 5
    for _ in $(seq 1 90); do
      [[ "$("$ADB" -s "$EMU_SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]] && break
      sleep 2
    done
  fi
  "$ADB" -s "$EMU_SERIAL" shell settings put system font_scale "${E2E_ANDROID_FONT_SCALE:-1.3}"
  # Анимации системы не мешают ожиданиям теста.
  for k in window_animation_scale transition_animation_scale animator_duration_scale; do "$ADB" -s "$EMU_SERIAL" shell settings put global "$k" 0; done
  "$ADB" -s "$EMU_SERIAL" reverse "tcp:$E2E_PORT" "tcp:$E2E_PORT" >/dev/null
  # Скриншоты: приложение после `flutter test` удаляется, каталог Мака эмулятор
  # не видит — тест шлёт файлы в приёмник на Маке.
  [[ -n "$SINK_PID" ]] || { node scripts/e2e-shot-sink.mjs "$SHOTS" "$SINK_PORT" >"$RESULTS/shot-sink.log" 2>&1 & SINK_PID=$!; }
  "$ADB" -s "$EMU_SERIAL" reverse "tcp:$SINK_PORT" "tcp:$SINK_PORT" >/dev/null
  "$ADB" -s "$EMU_SERIAL" reverse "tcp:${MINIO_PORT:-9000}" "tcp:${MINIO_PORT:-9000}" >/dev/null 2>&1 || true
  echo "  эмулятор: $avd ($EMU_SERIAL), $("$ADB" -s "$EMU_SERIAL" shell getprop persist.sys.locale | tr -d '\r'), font_scale $("$ADB" -s "$EMU_SERIAL" shell settings get system font_scale | tr -d '\r'), $("$ADB" -s "$EMU_SERIAL" shell wm size | tr -d '\r' | tail -1)"
  IOS_READY=1
}

stop_emulator() {
  [[ -z "$EMU_PID" ]] && return
  "$ADB" -s "$EMU_SERIAL" emu kill >/dev/null 2>&1 || true
  for _ in $(seq 1 20); do kill -0 "$EMU_PID" 2>/dev/null || break; sleep 1; done
  kill_tree "$EMU_PID"; EMU_PID=""
}

# run_ios <имя теста> — один сценарий Flutter на симуляторе или эмуляторе.
run_ios() {
  local name="$1" log="$RESULTS/$DEVICE_SLUG-$1.log"
  if [[ $IOS_ENV_FAILURES -ge 2 || $IOS_READY -eq 0 ]]; then
    row "$name" "⏭ пропущено (окружение)" "симулятор/сборка недоступны — см. выше"
    SKIPPED=$((SKIPPED + 1)); return
  fi
  # Сброс установленного приложения: чистое состояние (Keychain сессии
  # чистит сам тест — iOS не стирает его при uninstall).
  if [[ -n "$IS_ANDROID" ]]; then
    "$ADB" -s "$EMU_SERIAL" uninstall "$APP_ID" >/dev/null 2>&1 || true
  else
    xcrun simctl uninstall "$UDID" kz.darkhan.lubao >/dev/null 2>&1 || true
  fi
  RWT_DIR=apps/lubao_app run_with_timeout 1200 "$log" flutter test "integration_test/${name}.dart" -d "$UDID" \
    --dart-define=API_BASE_URL="$E2E_API_URL" \
    --dart-define=E2E_SHOT_DIR="$SHOTS" \
    --dart-define=E2E_DEVICE="$DEVICE_SLUG" \
    ${IS_ANDROID:+--dart-define=E2E_SHOT_SINK=http://127.0.0.1:$SINK_PORT}
  local code=$?
  # Сценарий оборвался посреди шага «Обновите приложение» (043 п.8) — версия
  # осталась бы поднятой, и все следующие сценарии упёрлись бы в этот экран.
  quick 20 docker exec lubao-postgres-1 psql -U lubao -d lubao_e2e -qc "DELETE FROM app_settings WHERE key = 'minAppVersion'" || true
  if [[ $code -eq 0 ]]; then
    row "$name" "✅" "$(grep -oE '\+[0-9]+: All tests passed' "$log" | tail -1)"
    IOS_ENV_FAILURES=0
  elif [[ $code -eq 124 ]]; then
    row "$name" "❌ TIMEOUT" "лимит 20 мин — процесс убит (см. $(basename "$log"))"
    TIMEOUTS=$((TIMEOUTS + 1)); FAILED=$((FAILED + 1))
    mkdir -p "$SHOTS/$DEVICE_SLUG"
    if [[ -n "$IS_ANDROID" ]]; then
      "$ADB" -s "$EMU_SERIAL" exec-out screencap -p >"$SHOTS/$DEVICE_SLUG/$name-timeout.png" 2>/dev/null || true
      # Что делало приложение, когда встало (Flutter/ANR/память) — для разбора.
      "$ADB" -s "$EMU_SERIAL" logcat -d -t 400 >"$RESULTS/$DEVICE_SLUG-$name-timeout-logcat.txt" 2>/dev/null || true
    else
      xcrun simctl io "$UDID" screenshot "$SHOTS/$DEVICE_SLUG/$name-timeout.png" >/dev/null 2>&1 || true
    fi
    IOS_ENV_FAILURES=$((IOS_ENV_FAILURES + 1))
  elif grep -qE "Failed to load|Unable to start the app|Xcode build failed|Could not build|xcodebuild.*failed|Gradle task assembleDebug failed|BUILD FAILED" "$log"; then
    row "$name" "⏭ пропущено (окружение)" "сборка/запуск на симуляторе не удались (см. $(basename "$log"))"
    IOS_ENV_FAILURES=$((IOS_ENV_FAILURES + 1)); SKIPPED=$((SKIPPED + 1))
  else
    local reason
    reason="$(grep -m1 -E "Expected|TestFailure|Не нашли виджет|Bad state|StateError|Failed assertion" "$log" | cut -c1-160)"
    row "$name" "❌" "${reason:-см. $(basename "$log")} (скриншот падения — из теста, см. шаги)"
    FAILED=$((FAILED + 1)); IOS_ENV_FAILURES=0
  fi
}

PHASE1=(driver_flow_test driver_deal_test logist_drivers_test garage_vehicle_test company_register_test driver_register_iin_test telegram_login_test trade_offers_test feed_filters_test)
PHASE3=(logist_publish_test)
PHASE4=(all_screens_test)
if [[ -n "${E2E_ONLY:-}" ]]; then
  read -r -a PHASE1 <<<"$E2E_ONLY"; PHASE3=(); PHASE4=(); PARTIAL=1
fi

run_admin_ui() {
  if [[ -n "${E2E_SKIP_ADMIN_UI:-}" ]]; then
    row "админка в Chrome (10–14)" "⏭ не запускалась" "E2E_SKIP_ADMIN_UI=${E2E_SKIP_ADMIN_UI}"
    PARTIAL=1; return
  fi
  local log="$RESULTS/$DEVICE_SLUG-admin-ui.log"
  RWT_DIR=scripts/e2e-admin-ui run_with_timeout 900 "$log" env E2E_API_URL="$E2E_API_URL" \
    E2E_ADMIN_URL="http://localhost:${ADMIN_WEB_PORT}" E2E_SHOT_DIR="$SHOTS" E2E_DEVICE="$DEVICE_SLUG" \
    npx playwright test
  local code=$?
  if [[ $code -eq 0 ]]; then
    row "админка в Chrome (10–14, ширина 1280 и 390)" "✅" "$(grep -oE '[0-9]+ passed' "$log" | tail -1)"
  elif [[ $code -eq 124 ]]; then
    row "админка в Chrome" "❌ TIMEOUT" "лимит 15 мин (см. $(basename "$log"))"; TIMEOUTS=$((TIMEOUTS + 1)); FAILED=$((FAILED + 1))
  else
    row "админка в Chrome" "❌" "$(grep -m1 -E "Error|failed" "$log" | cut -c1-160) (см. $(basename "$log"))"; FAILED=$((FAILED + 1))
  fi
}

# --------------------------------------------------------- прогон устройства --

for DEVICE in "${DEVICES[@]}"; do
  IS_ANDROID=""
  [[ "$DEVICE" == android:* ]] && IS_ANDROID=1
  DEVICE_SLUG="$(echo "${DEVICE#android:}" | tr '[:upper:] ' '[:lower:]-')"
  [[ -n "$IS_ANDROID" ]] && DEVICE_SLUG="android-$DEVICE_SLUG"
  echo
  echo "================ $DEVICE ================"
  table_header "$DEVICE"

  echo "== БД + сид + backend =="
  if ! reset_database; then
    row "окружение: БД/сид/backend" "❌" "см. db.log / backend.log"; tail -20 "$RESULTS/db.log" 2>/dev/null; FAILED=$((FAILED + 1)); continue
  fi
  export E2E_API_URL="http://localhost:${E2E_PORT}"

  # Статика админки со своего сервера (CanvasKit и шрифты не из CDN).
  if [[ -z "${E2E_SKIP_ADMIN_UI:-}" ]]; then
    [[ -n "$STATIC_PID" ]] && kill_tree "$STATIC_PID"
    node scripts/e2e-static-server.mjs "$ADMIN_WEB" "$ADMIN_WEB_PORT" >"$RESULTS/static.log" 2>&1 &
    STATIC_PID=$!
    for _ in $(seq 1 20); do curl -sf "http://localhost:${ADMIN_WEB_PORT}/" >/dev/null 2>&1 && break; sleep 1; done
  fi

  echo "== API-смоук админки =="
  if [[ -z "${E2E_ADMIN_UI_ONLY:-}" ]]; then
    if run_with_timeout 180 "$RESULTS/$DEVICE_SLUG-admin-api.log" node scripts/e2e-admin-api.mjs; then
      row "админка: API-смоук (10, 13, 14)" "✅" "$(grep -c '^ok ' "$RESULTS/$DEVICE_SLUG-admin-api.log") проверок"
    else
      row "админка: API-смоук (10, 13, 14)" "❌" "см. $DEVICE_SLUG-admin-api.log"
      tail -15 "$RESULTS/$DEVICE_SLUG-admin-api.log"; FAILED=$((FAILED + 1))
    fi
    # Правило свежести анонса на реальной БД (задача 040, п.4): время подставляется
    # параметром, ждать сутки не нужно; трогает только анонсы водителя D5 и убирает их.
    if DATABASE_URL="$E2E_DB_URL" run_with_timeout 120 "$RESULTS/$DEVICE_SLUG-freshness.log" node scripts/e2e-freshness.mjs; then
      row "правило свежести анонса (040, п.4): день приезда, 12 ч, гашение, геозона" "✅" "$(grep -c '^ok ' "$RESULTS/$DEVICE_SLUG-freshness.log") проверок"
    else
      row "правило свежести анонса (040, п.4)" "❌" "см. $DEVICE_SLUG-freshness.log"
      tail -15 "$RESULTS/$DEVICE_SLUG-freshness.log"; FAILED=$((FAILED + 1))
    fi
    if [[ -z "$WEB_CHECKED" && -n "${APP_WEB+x}" && -z "${E2E_SKIP_ADMIN_UI:-}" && -z "${E2E_ONLY:-}" ]]; then
      WEB_CHECKED=1
      if [[ -z "$APP_WEB" ]]; then
        row "веб логиста без Google (020 А)" "❌" "сборка не прошла, см. app-web-build.log"; FAILED=$((FAILED + 1))
      else
        node scripts/e2e-static-server.mjs "$APP_WEB" "$APP_WEB_PORT" >"$RESULTS/app-static.log" 2>&1 &
        APP_STATIC_PID=$!
        for _ in $(seq 1 20); do curl -sf "http://localhost:${APP_WEB_PORT}/" >/dev/null 2>&1 && break; sleep 1; done
        if RWT_DIR=scripts/e2e-admin-ui run_with_timeout 120 "$RESULTS/app-web-google.log" node web-no-google.mjs "http://localhost:${APP_WEB_PORT}/" "$SHOTS/app-web-zh.png"; then
          row "веб логиста без Google (020 А): CanvasKit и шрифты свои, zh" "✅" "$(grep -o '^ok .*' "$RESULTS/app-web-google.log")"
        else
          row "веб логиста без Google (020 А)" "❌" "$(grep -m1 FAIL "$RESULTS/app-web-google.log" | cut -c1-160)"; FAILED=$((FAILED + 1))
        fi
        kill_tree "$APP_STATIC_PID"
      fi
    fi
    # Смоук меняет данные (регистрирует водителя из ЧС) — для UI админки
    # чистое состояние нужно заново.
    if [[ -z "${E2E_SKIP_ADMIN_UI:-}" ]]; then
      reset_database || { row "окружение: пересоздание БД" "❌" "см. db.log"; FAILED=$((FAILED + 1)); continue; }
    fi
  fi

  if [[ -n "${E2E_SKIP_IOS:-}" ]]; then
    row "iOS-сценарии" "⏭ не запускались" "E2E_SKIP_IOS задан"; PARTIAL=1
    run_admin_ui
    continue
  fi

  if [[ -n "$IS_ANDROID" ]]; then
    echo "== эмулятор ($DEVICE) =="
    # 8 ГБ RAM: перед эмулятором освобождаем память от прошлого устройства —
    # симуляторы, Chromium Playwright, демоны Gradle/Kotlin прошлых сборок.
    xcrun simctl shutdown all >/dev/null 2>&1 || true
    pkill -f ms-playwright >/dev/null 2>&1 || true
    (cd apps/lubao_app/android && ./gradlew --stop >/dev/null 2>&1) || true
    prepare_emulator "${DEVICE#android:}"
  else
    echo "== симулятор ($DEVICE) =="
    prepare_simulator "$DEVICE"
  fi

  echo "== сценарии приложения: часть 1 =="
  for name in "${PHASE1[@]}"; do run_ios "$name"; done

  echo "== админка в Chrome =="
  run_admin_ui

  echo "== сценарии приложения: часть 2 (после решений админа) =="
  for name in "${PHASE3[@]:-}"; do [[ -n "$name" ]] && run_ios "$name"; done
  for name in "${PHASE4[@]:-}"; do [[ -n "$name" ]] && run_ios "$name"; done

  if [[ -n "$IS_ANDROID" ]]; then stop_emulator; else xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true; fi
  append_steps "$DEVICE_SLUG"
done

# --------------------------------------------------------------------- итог --

echo
cat "$REPORT"
if [[ $FAILED -gt 0 ]]; then
  echo "❌ есть упавшие сценарии (TIMEOUT: $TIMEOUTS) — отчёт: $REPORT"
  exit 1
elif [[ $SKIPPED -gt 0 ]]; then
  echo "⏭ iOS-сценарии пропущены из-за окружения ($SKIPPED) — не считается зелёным"
  exit 2
elif [[ $PARTIAL -gt 0 ]]; then
  echo "⚠ неполный прогон (dev-флаги) — не считается зелёным"
  exit 3
fi
echo "✅ все сценарии зелёные — отчёт: $REPORT"
