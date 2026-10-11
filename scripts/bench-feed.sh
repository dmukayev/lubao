#!/usr/bin/env bash
# 059: время ответа ленты при N грузах (по умолчанию 1200) — свой сервер на
# e2e-базе (dev не трогается). Печатает медиану и худшее из 10 запросов.
set -uo pipefail
cd "$(dirname "$0")/.."
N="${1:-1200}"; PORT=3101
DB_URL="postgresql://lubao:lubao@localhost:${POSTGRES_PORT:-5434}/lubao_e2e?schema=public"
OUT=test-results/bench; mkdir -p "$OUT"
docker exec lubao-postgres-1 psql -U lubao -d lubao -c "DROP DATABASE IF EXISTS lubao_e2e WITH (FORCE)" >/dev/null
docker exec lubao-postgres-1 createdb -U lubao lubao_e2e
(cd backend && DATABASE_URL="$DB_URL" bash -c 'npx prisma migrate deploy && npx ts-node prisma/seed.ts && npx ts-node prisma/seed-e2e.ts') >"$OUT/db.log" 2>&1 || { echo "сид не удался"; exit 1; }
docker exec lubao-postgres-1 psql -U lubao -d lubao_e2e -c "
  INSERT INTO cargos (id, \"companyId\", \"publishedByUserId\", \"pointId\", \"destinationCountryId\", \"destinationCityId\", \"bodyTypeId\", \"weightKg\", \"categoryId\", price, currency, \"readyDate\", status, \"publishedAt\", \"expiresAt\", \"createdAt\", \"updatedAt\", \"distanceKm\", \"pricePerKm\")
  SELECT gen_random_uuid()::text, c.\"companyId\", c.\"publishedByUserId\", c.\"pointId\", c.\"destinationCountryId\", c.\"destinationCityId\", c.\"bodyTypeId\", c.\"weightKg\", c.\"categoryId\", c.price + g, c.currency, c.\"readyDate\", 'PUBLISHED', now() - (g || ' minutes')::interval, now() + interval '3 days', now(), now(), c.\"distanceKm\" + g % 500, c.\"pricePerKm\"
  FROM cargos c, generate_series(1, $N) g WHERE c.id = '11111111-1111-4111-8111-111111111001';" >/dev/null
docker exec lubao-redis-1 redis-cli -n 1 flushdb >/dev/null
rm -rf backend/dist-bench && cp -R backend/dist backend/dist-bench
(cd backend && DATABASE_URL="$DB_URL" REDIS_URL="redis://localhost:${REDIS_PORT:-6379}/1" PORT="$PORT" SMS_PROVIDER=console EMAIL_PROVIDER=console \
  TRANSLATION_PROVIDER=noop PUSH_PROVIDER=console NODE_ENV=development JOBS_DISABLED=true SMS_MINUTE_LOCK_SECONDS=0 THROTTLE_USER_LIMIT=6000 \
  exec node dist-bench/src/main.js >"../$OUT/backend.log" 2>&1) &
PID=$!; trap 'kill $PID 2>/dev/null; rm -rf backend/dist-bench' EXIT
for _ in $(seq 1 60); do curl -sf "http://localhost:$PORT/reference-data" >/dev/null && break; sleep 1; done
curl -s -X POST "http://localhost:$PORT/auth/phone/request-code" -H 'content-type: application/json' -d '{"phone":"+77010000002"}' >/dev/null
TOKEN=$(curl -s -X POST "http://localhost:$PORT/auth/phone/verify" -H 'content-type: application/json' -d '{"phone":"+77010000002","code":"1111","deviceName":"bench","platform":"ios"}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["accessToken"])')
bench() {
  local label="$1" q="$2"; local times=()
  for _ in $(seq 1 10); do times+=("$(curl -s -o /dev/null -w '%{time_total}' -H "Authorization: Bearer $TOKEN" "http://localhost:$PORT/cargos?$q")"); done
  printf '%s\n' "${times[@]}" | sort -n | awk -v l="$label" '{a[NR]=$1} END {printf "%-40s медиана %.0f мс, худшее %.0f мс\n", l, a[int((NR+1)/2)]*1000, a[NR]*1000}'
}
echo "грузов в ленте: $(docker exec lubao-postgres-1 psql -U lubao -d lubao_e2e -tAc "select count(*) from cargos where status='PUBLISHED'")"
bench "по умолчанию (страница 30)" "limit=30"
bench "все города, сортировка ₸/км" "limit=30&showOtherCities=true&sort=per_km"
bench "фильтр вес 10–20 т + новые" "limit=30&weightMinT=10&weightMaxT=20&sort=new&showOtherCities=true"
bench "счётчик шторки (limit=0)" "limit=0&showOtherCities=true"
bench "третья страница" "limit=30&offset=60&showOtherCities=true"
