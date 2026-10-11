#!/usr/bin/env bash
# 059 / 064 п.11: время ответа ленты при N грузах (по умолчанию 1200, разные города, кузова, компании) — свой сервер на
# e2e-базе (dev не трогается). Печатает медиану и худшее из 10 запросов.
set -uo pipefail
cd "$(dirname "$0")/.."
N="${1:-1200}"; PORT=3101
DB_URL="postgresql://lubao:lubao@localhost:${POSTGRES_PORT:-5434}/lubao_e2e?schema=public"
OUT=test-results/bench; mkdir -p "$OUT"
docker exec lubao-postgres-1 psql -U lubao -d lubao -c "DROP DATABASE IF EXISTS lubao_e2e WITH (FORCE)" >/dev/null
docker exec lubao-postgres-1 createdb -U lubao lubao_e2e
(cd backend && DATABASE_URL="$DB_URL" bash -c 'npx prisma migrate deploy && npx ts-node prisma/seed.ts && npx ts-node prisma/seed-e2e.ts') >"$OUT/db.log" 2>&1 || { echo "сид не удался"; exit 1; }
# 064 п.11: реалистичные данные — разные города погрузки и выгрузки, кузова
# (и specs по профилю), компании, валюты, вес/объём/паллеты, даты, аванс.
docker exec lubao-postgres-1 psql -U lubao -d lubao_e2e -c "
  INSERT INTO cargos (id, \"companyId\", \"publishedByUserId\", \"pointId\", \"destinationCountryId\", \"destinationCityId\", \"bodyTypeId\", \"weightKg\", \"volumeM3\", \"palletCount\", specs, \"categoryId\", price, currency, \"advanceAmount\", \"paymentForm\", \"paymentDelayDays\", \"readyDate\", status, \"publishedAt\", \"expiresAt\", \"createdAt\", \"updatedAt\", \"distanceKm\", \"pricePerKm\")
  SELECT gen_random_uuid()::text, split_part(m.cu, '|', 1), split_part(m.cu, '|', 2), p.id, split_part(d.cc, '|', 2), split_part(d.cc, '|', 1), b.id,
         w.kg, CASE WHEN b.profile = 'VOLUME' THEN round((w.kg / 250.0)::numeric, 1) END, CASE WHEN b.profile = 'VOLUME' AND g % 3 = 0 THEN 10 + g % 23 END,
         CASE b.profile WHEN 'TANK' THEN jsonb_build_object('cargoLiters', 10000 + (g % 20) * 1000, 'cargoProduct', 'FOOD') WHEN 'CAR_CARRIER' THEN jsonb_build_object('carCount', 1 + g % 8) WHEN 'CONTAINER' THEN jsonb_build_object('containerType', CASE WHEN g % 2 = 0 THEN 'C40' ELSE 'C20' END) END,
         cat.id, pr.amount, pr.cur, CASE WHEN g % 4 = 0 THEN round(pr.amount * 0.3) END, (ARRAY['CASH','CARD','CASHLESS'])[1 + g % 3]::\"PaymentForm\", CASE WHEN g % 2 = 0 THEN 1 + g % 10 END,
         current_date + (g % 8), 'PUBLISHED', now() - (g || ' minutes')::interval, current_date + (g % 8) + 3, now(), now(), km.v, round(pr.amount / km.v, 2)
  FROM generate_series(1, $N) g
  CROSS JOIN LATERAL (SELECT cm.\"companyId\" || '|' || cm.\"userId\" AS cu FROM company_members cm JOIN companies co ON co.id = cm.\"companyId\" WHERE co.\"isVerified\" ORDER BY random() + g * 0 LIMIT 1) m
  CROSS JOIN LATERAL (SELECT id FROM points WHERE \"isActive\" ORDER BY random() + g * 0 LIMIT 1) p
  CROSS JOIN LATERAL (SELECT id || '|' || \"countryId\" AS cc FROM cities ORDER BY random() + g * 0 LIMIT 1) d
  CROSS JOIN LATERAL (SELECT id, profile FROM body_types ORDER BY random() + g * 0 LIMIT 1) b
  CROSS JOIN LATERAL (SELECT id FROM cargo_categories ORDER BY random() + g * 0 LIMIT 1) cat
  CROSS JOIN LATERAL (SELECT (500 + (g * 37) % 24500)::numeric AS kg) w
  CROSS JOIN LATERAL (SELECT 200 + (g * 53) % 4800 AS v) km
  CROSS JOIN LATERAL (SELECT (ARRAY['USD','KZT','CNY','RUB','UZS'])[1 + g % 5] AS cur, (ARRAY[1500, 750000, 10000, 120000, 18000000])[1 + g % 5] * (1 + (g % 7) / 10.0) AS amount) pr;" >/dev/null
echo "компаний: $(docker exec lubao-postgres-1 psql -U lubao -d lubao_e2e -tAc "select count(distinct \"companyId\") from cargos where status='PUBLISHED'"), городов погрузки: $(docker exec lubao-postgres-1 psql -U lubao -d lubao_e2e -tAc "select count(distinct \"pointId\") from cargos where status='PUBLISHED'"), кузовов: $(docker exec lubao-postgres-1 psql -U lubao -d lubao_e2e -tAc "select count(distinct \"bodyTypeId\") from cargos where status='PUBLISHED'")"
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
bench "кузов (профиль) + цена в USD от 1000" "limit=30&showOtherCities=true&bodyTypeIds=$(docker exec lubao-postgres-1 psql -U lubao -d lubao_e2e -tAc "select id from body_types where code='TENT'")&priceMin=1000&priceCurrency=USD"
bench "ближе погрузка" "limit=30&showOtherCities=true&sort=ready"
