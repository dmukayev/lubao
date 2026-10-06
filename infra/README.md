# Инфраструктура

- `../docker-compose.yml` — **dev** (Postgres, Redis, MinIO, OCR, backend с хот-релоадом, nginx без TLS).
- `../docker-compose.prod.yml` — **прод** (см. ниже и `docs/release.md`).
- `nginx/default.conf` — dev; `nginx/prod.conf.template` — прод (TLS, статика веба, админка только на адресе Tailscale).
- `backup/` — ежедневные копии БД и бакетов MinIO.
- `site/` — статические страницы: `/legal/terms`, `/legal/privacy` (тексты-заготовки на 4 языках — правит юрист), `/app` (страница обновления).
- `ocr/` — сервис распознавания документов (внутри сети, без публичного порта).

## Прод: что где живёт

| Сервис | Сеть | Наружу |
|---|---|---|
| nginx | edge + internal | 80, 443 (TLS Let's Encrypt) |
| backend | internal + edge (исходящие: SMS, почта, WhatsApp, курс НБ РК, перевод) | только через nginx (`/api/`, `/socket.io/`) |
| postgres, redis, minio, ocr | **только internal** (`internal: true`, без выхода в интернет) | нет |
| админка | статика за nginx, слушает только `ADMIN_LISTEN` (адрес Tailscale) | нет, только tailnet |

Публикуется только бакет фото грузов (`/files/lubao-uploads/…`). Бакет документов (персональные данные) наружу не отдаётся — файл видит админ через бэкенд, и каждый просмотр пишется в `audit_log` (`DOCUMENT_FILE_VIEWED`).

`/health/ready` проверяет Postgres, Redis и MinIO (503 + какая из зависимостей не отвечает) — на него смотрит healthcheck контейнера и внешний мониторинг. `/health` — просто «процесс жив».

## Бэкапы

`backup` каждый день в `BACKUP_HOUR_UTC` (по умолчанию 22:00 UTC) делает:

1. `pg_dump -Fc` → `/backups/<дата>/db.dump`;
2. зеркало каждого бакета MinIO → `/backups/<дата>/minio/<бакет>/`;
3. удаляет копии старше `BACKUP_KEEP_DAYS` (14);
4. если задан `BACKUP_REMOTE_CMD` — выгружает папку дня в **отдельное** хранилище (пример: `BACKUP_REMOTE_CMD="rclone copy --create-empty-src-dirs"` с настроенным remote; команда получает путь папки последним аргументом). Без него в логе предупреждение: копии лежат только на этом же сервере — это не бэкап от потери сервера.

Копия сейчас: `docker compose -f docker-compose.prod.yml exec backup backup.sh once`.

### Проверка восстановления (делать до первого пользователя и раз в квартал)

На **отдельной** машине/в отдельном проекте compose, не на проде:

```bash
# 1. скопировать папку дня и поднять пустую БД
docker run -d --name restore-pg -e POSTGRES_PASSWORD=restore -p 55432:5432 postgres:16-alpine
docker cp /backups/2026-10-07/db.dump restore-pg:/tmp/db.dump
docker exec restore-pg createdb -U postgres lubao
docker exec restore-pg pg_restore -U postgres -d lubao --no-owner /tmp/db.dump

# 2. проверить, что данные на месте
docker exec restore-pg psql -U postgres -d lubao -c "select count(*) from users; select count(*) from deals;"

# 3. бакеты: файлы лежат в /backups/<дата>/minio/<бакет>/ — поднять MinIO и залить обратно
mc alias set restore http://localhost:9000 <user> <password>
mc mirror /backups/2026-10-07/minio/lubao-documents restore/lubao-documents
```

Восстановление считается проверенным, когда: число записей в `users`/`deals` совпадает с продом на момент копии, backend стартует против восстановленной БД (`prisma migrate deploy` ничего не применяет), документ из восстановленного бакета открывается из админки. Результат проверки — строка в `docs/release.md` → «Журнал проверок».

## TLS

Первый выпуск сертификата (домен должен уже указывать на сервер, порт 80 открыт):

```bash
docker compose -f docker-compose.prod.yml run --rm --entrypoint certbot certbot \
  certonly --webroot -w /var/www/certbot -d "$APP_HOST" --agree-tos -m admin@"$APP_HOST" --no-eff-email
docker compose -f docker-compose.prod.yml restart nginx
```

Продление — контейнер `certbot` проверяет каждые 12 ч. Пока сертификата нет, nginx на 443 не стартует: сначала поднимите только `nginx` с порта 80 (временный конфиг без 443) либо выпустите сертификат `--standalone` до запуска nginx.

## Секреты

Файл `.env.prod` (в `.gitignore`, не коммитить) и переменные compose. Без значений по умолчанию compose не стартует; ключи, которые проверяет предохранитель бэкенда, перечислены в `backend/src/config/production-guard.ts`. Сгенерировать:

```bash
openssl rand -base64 48   # JWT_ACCESS_SECRET, IDENTIFIER_KEY
openssl rand -base64 24   # IDENTIFIER_PEPPER, POSTGRES_PASSWORD, REDIS_PASSWORD, MINIO_ROOT_PASSWORD
```

`IDENTIFIER_KEY` и `IDENTIFIER_PEPPER` менять после первого деплоя нельзя: на них держатся хэши и шифрование ИИН/номеров в чёрном списке.
