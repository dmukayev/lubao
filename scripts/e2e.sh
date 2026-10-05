#!/usr/bin/env bash
# Задача 034 — сквозные сценарии одной командой.
#
# Поднимает изолированную БД `lubao_e2e` (в том же Postgres-контейнере, что
# и дев-база — не трогая её), засевает детерминированные синтетические
# данные (prisma/seed-e2e.ts), запускает backend на отдельном порту и
# прогоняет Flutter integration_test. Код возврата — как у `flutter test`:
# 0 — зелёный прогон, не 0 — есть провалившиеся сценарии.
#
# Использование:
#   scripts/e2e.sh                       # Chrome (headless)
#   scripts/e2e.sh -d "iPhone 17"         # симулятор (должен быть booted)
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="iPhone 17"
if [[ "${1:-}" == "-d" ]]; then
  DEVICE="$2"
fi

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
# CocoaPods (`pod`) нужен для сборки симулятора (п.0 задачи 034) — на этой
# машине он под rbenv, а не в системном PATH.
[[ -d "$HOME/.rbenv/shims" ]] && export PATH="$HOME/.rbenv/shims:$PATH"

E2E_PORT="${E2E_BACKEND_PORT:-3100}"
E2E_DB_URL="postgresql://lubao:lubao@localhost:${POSTGRES_PORT:-5434}/lubao_e2e?schema=public"
BACKEND_PID=""

cleanup() {
  if [[ -n "$BACKEND_PID" ]]; then
    kill "$BACKEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "== 1/5: docker-сервисы (postgres, redis, minio) =="
docker compose up -d postgres redis minio
for svc in postgres redis minio; do
  until [[ "$(docker inspect -f '{{.State.Health.Status}}' "lubao-${svc}-1" 2>/dev/null)" == "healthy" ]]; do
    sleep 1
  done
done

echo "== 2/5: БД lubao_e2e + миграции + сид =="
docker exec lubao-postgres-1 psql -U lubao -d lubao -tc \
  "SELECT 1 FROM pg_database WHERE datname = 'lubao_e2e'" | grep -q 1 || \
  docker exec lubao-postgres-1 createdb -U lubao lubao_e2e

pushd backend >/dev/null
DATABASE_URL="$E2E_DB_URL" npx prisma migrate deploy
DATABASE_URL="$E2E_DB_URL" npx ts-node prisma/seed.ts
DATABASE_URL="$E2E_DB_URL" npx ts-node prisma/seed-e2e.ts
popd >/dev/null

# Redis (отдельная логическая БД /1, см. REDIS_URL ниже) хранит лимит SMS-
# кодов (1 код/минуту на номер) МЕЖДУ запусками backend — повторный прогон
# `e2e.sh` раньше чем через минуту после предыдущего иначе падает на
# «Слишком частые запросы кода». Чистим перед каждым прогоном.
docker exec lubao-redis-1 redis-cli -n 1 flushdb >/dev/null

echo "== 3/5: backend на порту ${E2E_PORT} =="
set -a
source .env
set +a
pushd backend >/dev/null
npx nest build
DATABASE_URL="$E2E_DB_URL" \
  REDIS_URL="redis://localhost:${REDIS_PORT:-6379}/1" \
  PORT="$E2E_PORT" \
  SMS_PROVIDER=console \
  EMAIL_PROVIDER=console \
  TRANSLATION_PROVIDER=noop \
  OCR_SERVICE_URL= \
  NODE_ENV=development \
  node dist/src/main.js > /tmp/lubao-e2e-backend.log 2>&1 &
BACKEND_PID=$!
popd >/dev/null

echo "   ждём готовности..."
for _ in $(seq 1 60); do
  if curl -sf "http://localhost:${E2E_PORT}/reference-data" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
if ! curl -sf "http://localhost:${E2E_PORT}/reference-data" >/dev/null 2>&1; then
  echo "backend не поднялся, лог:"
  cat /tmp/lubao-e2e-backend.log
  exit 1
fi

echo "== 4/5: Flutter integration_test ($DEVICE) =="
mkdir -p test-results/e2e
# На всякий случай сбрасываем установку — сама сессия (Keychain) всё равно
# переживает uninstall на iOS, поэтому главный сброс сессии — внутри теста
# (`_clearPersistedSession`), это только на случай другого локального state.
if [[ "$DEVICE" != "chrome" && "$DEVICE" != web-server* ]]; then
  xcrun simctl uninstall "$DEVICE" com.lubao.lubaoApp 2>/dev/null || true
fi
pushd apps/lubao_app >/dev/null
set +e
if [[ "$DEVICE" == "chrome" || "$DEVICE" == web-server* ]]; then
  # `flutter test` не поддерживает web для integration_test — только `drive`.
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/driver_flow_test.dart \
    -d "$DEVICE" \
    --dart-define=API_BASE_URL="http://localhost:${E2E_PORT}"
else
  flutter test integration_test/driver_flow_test.dart \
    -d "$DEVICE" \
    --dart-define=API_BASE_URL="http://localhost:${E2E_PORT}"
fi
RESULT=$?
set -e
popd >/dev/null

echo "== 5/5: итог =="
if [[ $RESULT -eq 0 ]]; then
  echo "✅ сценарии зелёные"
else
  echo "❌ сценарии провалились (код $RESULT), backend-лог:"
  tail -n 60 /tmp/lubao-e2e-backend.log
fi
exit $RESULT
