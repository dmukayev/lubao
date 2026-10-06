#!/usr/bin/env bash
# Задача 034 — сквозные сценарии одной командой, с защитой от зависаний.
#
# Поднимает изолированную БД `lubao_e2e`, детерминированный сид, backend на
# отдельном порту; прогоняет Flutter integration_test на симуляторе iPhone
# (без GUI Xcode: `simctl boot` + `flutter test -d <udid>`) и API-смоук
# админки. Итог — test-results/e2e/report.md и код возврата:
#   0 — всё зелёное; 1 — есть упавшие/TIMEOUT; 2 — iOS-сценарии пропущены
#   из-за окружения (симулятор/сборка), остальное зелёное.
#
# Правило устойчивости (CLAUDE.md, 034): каждая долгая команда — с лимитом
# времени; по истечении процесс (и его потомки) убивается, в отчёт идёт
# TIMEOUT. На выходе (trap) всё, что запустил скрипт, гасится.
#
# Использование:
#   scripts/e2e.sh                     # iPhone 17
#   scripts/e2e.sh -d "iPhone 16e"     # другой симулятор
#   E2E_ONLY="driver_flow_test" scripts/e2e.sh   # один сценарий
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"

DEVICE_NAME="iPhone 17"
if [[ "${1:-}" == "-d" ]]; then DEVICE_NAME="$2"; fi

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
# CocoaPods (`pod`) нужен для сборки под симулятор — на этой машине он под rbenv.
[[ -d "$HOME/.rbenv/shims" ]] && export PATH="$HOME/.rbenv/shims:$PATH"

E2E_PORT="${E2E_BACKEND_PORT:-3100}"
E2E_DB_URL="postgresql://lubao:lubao@localhost:${POSTGRES_PORT:-5434}/lubao_e2e?schema=public"
RESULTS="$ROOT/test-results/e2e"
REPORT="$RESULTS/report.md"
BACKEND_PID=""
UDID=""
FAILED=0
SKIPPED=0
TIMEOUTS=0

# ---------------------------------------------------------------- утилиты --

kill_tree() {
  local pid="$1" child
  for child in $(pgrep -P "$pid" 2>/dev/null); do kill_tree "$child"; done
  kill -9 "$pid" 2>/dev/null || true
}

# run_with_timeout <секунды> <лог> <команда...>; код 124 — истёк лимит.
run_with_timeout() {
  local limit="$1" log="$2"
  shift 2
  "$@" >"$log" 2>&1 &
  local pid=$!
  (
    sleep "$limit"
    if kill -0 "$pid" 2>/dev/null; then
      echo "[e2e] TIMEOUT ${limit}s — убиваю процесс $pid" >>"$log"
      kill_tree "$pid"
    fi
  ) &
  local watchdog=$!
  wait "$pid" 2>/dev/null
  local code=$?
  kill_tree "$watchdog"
  wait "$watchdog" 2>/dev/null || true
  # Убит сторожем (а не завершился сам) — он оставил маркер в логе.
  grep -q "^\[e2e\] TIMEOUT" "$log" && code=124
  return $code
}

cleanup() {
  [[ -n "$BACKEND_PID" ]] && kill_tree "$BACKEND_PID"
  # Всё, что мог оставить flutter/xcodebuild этого запуска.
  pkill -f "flutter_tools.snapshot test" 2>/dev/null || true
  pkill -f "xcodebuild.*Runner" 2>/dev/null || true
  xcrun simctl shutdown all >/dev/null 2>&1 || true
}
trap cleanup EXIT
trap 'echo "[e2e] прервано"; exit 130' INT TERM

mkdir -p "$RESULTS"
{
  echo "# E2E-отчёт"
  echo
  echo "Запуск: $(date '+%Y-%m-%d %H:%M:%S') · устройство: $DEVICE_NAME"
  echo
  echo "| Сценарий | Результат | Детали |"
  echo "|---|---|---|"
} >"$REPORT"
row() { echo "| $1 | $2 | $3 |" >>"$REPORT"; }

# --------------------------------------------------------------- окружение --

echo "== 1/6: docker-сервисы =="
if ! run_with_timeout 300 "$RESULTS/docker.log" docker compose up -d postgres redis minio; then
  row "окружение: docker" "❌" "docker compose up не завершился (см. docker.log)"; cat "$RESULTS/docker.log"; exit 1
fi
for svc in postgres redis minio; do
  for _ in $(seq 1 90); do
    [[ "$(docker inspect -f '{{.State.Health.Status}}' "lubao-${svc}-1" 2>/dev/null)" == "healthy" ]] && break
    sleep 1
  done
done

# Ключи идентификаторов нужны сиду (хеш номера в чёрном списке) и backend.
set -a; source .env; set +a

echo "== 2/6: БД lubao_e2e + миграции + сид =="
docker exec lubao-postgres-1 psql -U lubao -d lubao -tc "SELECT 1 FROM pg_database WHERE datname = 'lubao_e2e'" | grep -q 1 || \
  docker exec lubao-postgres-1 createdb -U lubao lubao_e2e
(
  cd backend
  export DATABASE_URL="$E2E_DB_URL"
  run_with_timeout 300 "$RESULTS/db.log" bash -c 'npx prisma migrate deploy && npx ts-node prisma/seed.ts && npx ts-node prisma/seed-e2e.ts'
) || { row "окружение: БД/сид" "❌" "см. db.log"; tail -20 "$RESULTS/db.log"; exit 1; }
# Лимит SMS-кодов (1/мин на номер, 20/ч на IP) живёт в Redis между запусками
# backend — чистим логическую БД /1 перед каждым прогоном.
docker exec lubao-redis-1 redis-cli -n 1 flushdb >/dev/null

echo "== 3/6: backend на порту ${E2E_PORT} =="
set -a; source .env; set +a
(
  cd backend
  run_with_timeout 300 "$RESULTS/build.log" npx nest build
) || { row "окружение: сборка backend" "❌" "см. build.log"; tail -20 "$RESULTS/build.log"; exit 1; }
(
  cd backend
  DATABASE_URL="$E2E_DB_URL" REDIS_URL="redis://localhost:${REDIS_PORT:-6379}/1" PORT="$E2E_PORT" \
    SMS_PROVIDER=console EMAIL_PROVIDER=console TRANSLATION_PROVIDER=noop OCR_SERVICE_URL= NODE_ENV=development \
    exec node dist/src/main.js >"$RESULTS/backend.log" 2>&1
) &
BACKEND_PID=$!
for _ in $(seq 1 60); do
  curl -sf "http://localhost:${E2E_PORT}/reference-data" >/dev/null 2>&1 && break
  sleep 1
done
if ! curl -sf "http://localhost:${E2E_PORT}/reference-data" >/dev/null 2>&1; then
  row "окружение: backend" "❌" "не поднялся (см. backend.log)"; tail -20 "$RESULTS/backend.log"; exit 1
fi
export E2E_API_URL="http://localhost:${E2E_PORT}"

# ------------------------------------------------------------ API-смоук админки --

echo "== 4/6: API-смоук админки (сценарии 10/13/14 на уровне API) =="
if run_with_timeout 180 "$RESULTS/admin-api.log" node scripts/e2e-admin-api.mjs; then
  row "админка: API-смоук (10, 13, 14)" "✅" "$(grep -c '^ok ' "$RESULTS/admin-api.log") проверок"
else
  row "админка: API-смоук (10, 13, 14)" "❌" "см. admin-api.log"
  tail -15 "$RESULTS/admin-api.log"; FAILED=$((FAILED + 1))
fi

# ------------------------------------------------------------ симулятор iOS --

if [[ -n "${E2E_SKIP_IOS:-}" ]]; then
  row "iOS-сценарии" "⏭ не запускались" "E2E_SKIP_IOS задан"
  cat "$REPORT"
  [[ $FAILED -gt 0 ]] && exit 1
  exit 0
fi

echo "== 5/6: симулятор ($DEVICE_NAME) =="
UDID="$(xcrun simctl list devices available | grep -F "$DEVICE_NAME (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
IOS_ENV_FAILURES=0
IOS_READY=0
if [[ -z "$UDID" ]]; then
  row "окружение: симулятор" "⏭ пропущено (окружение)" "устройство «$DEVICE_NAME» не найдено"
  IOS_ENV_FAILURES=2
else
  xcrun simctl shutdown all >/dev/null 2>&1 || true
  if run_with_timeout 300 "$RESULTS/simctl-boot.log" xcrun simctl boot "$UDID" \
     && run_with_timeout 300 "$RESULTS/simctl-bootstatus.log" xcrun simctl bootstatus "$UDID" -b; then
    IOS_READY=1
  else
    row "окружение: симулятор" "⏭ пропущено (окружение)" "simctl boot/bootstatus не завершились за 5 мин"
    IOS_ENV_FAILURES=2
  fi
fi

echo "== 6/6: сценарии Flutter (iOS) =="
SCENARIOS=(driver_flow_test driver_deal_test logist_drivers_test)
[[ -n "${E2E_ONLY:-}" ]] && read -r -a SCENARIOS <<<"$E2E_ONLY"

for name in "${SCENARIOS[@]}"; do
  log="$RESULTS/$name.log"
  if [[ $IOS_ENV_FAILURES -ge 2 || $IOS_READY -eq 0 ]]; then
    row "$name" "⏭ пропущено (окружение)" "симулятор/сборка недоступны — см. выше"
    SKIPPED=$((SKIPPED + 1)); continue
  fi
  # Сброс установленного приложения: чистое состояние (Keychain сессии
  # чистит сам тест — iOS не стирает его при uninstall).
  xcrun simctl uninstall "$UDID" com.lubao.lubaoApp >/dev/null 2>&1 || true
  (
    cd apps/lubao_app
    run_with_timeout 1200 "$log" flutter test "integration_test/${name}.dart" -d "$UDID" \
      --dart-define=API_BASE_URL="$E2E_API_URL"
  )
  code=$?
  if [[ $code -eq 0 ]]; then
    row "$name" "✅" "$(grep -oE '\+[0-9]+: All tests passed' "$log" | tail -1)"
    IOS_ENV_FAILURES=0
  elif [[ $code -eq 124 ]]; then
    row "$name" "❌ TIMEOUT" "лимит 20 мин — процесс убит (см. $name.log)"
    TIMEOUTS=$((TIMEOUTS + 1)); FAILED=$((FAILED + 1))
    xcrun simctl io "$UDID" screenshot "$RESULTS/$name-timeout.png" >/dev/null 2>&1 || true
    IOS_ENV_FAILURES=$((IOS_ENV_FAILURES + 1))
  elif grep -qE "Failed to load|Unable to start the app|Xcode build failed|Could not build|xcodebuild.*failed" "$log"; then
    row "$name" "⏭ пропущено (окружение)" "сборка/запуск на симуляторе не удались (см. $name.log)"
    IOS_ENV_FAILURES=$((IOS_ENV_FAILURES + 1)); SKIPPED=$((SKIPPED + 1))
  else
    reason="$(grep -m1 -E "Expected|TestFailure|Не нашли виджет|Bad state|StateError" "$log" | cut -c1-160)"
    row "$name" "❌" "${reason:-см. $name.log}"
    xcrun simctl io "$UDID" screenshot "$RESULTS/$name-fail.png" >/dev/null 2>&1 || true
    FAILED=$((FAILED + 1)); IOS_ENV_FAILURES=0
  fi
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
fi
echo "✅ все сценарии зелёные — отчёт: $REPORT"
