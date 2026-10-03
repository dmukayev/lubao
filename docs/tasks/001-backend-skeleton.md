# 001 — Монорепозиторий и каркас бэкенда

Статус: не начато

## Цель
Проект запускается одной командой, база создана со всеми таблицами и справочниками.

## Что сделать
1. Структура: `apps/`, `packages/lubao_core`, `backend/`, `infra/` (см. CLAUDE.md).
2. `infra/docker-compose.yml`: PostgreSQL, Redis, MinIO. `.env.example` со всеми переменными.
3. `backend`: NestJS + Prisma. Prisma-схема всех таблиц из раздела «Доменная модель» CLAUDE.md, включая `verification_documents` (type, status, reject_reason, file_key, reviewed_by, reviewed_at).
4. Seed: точка «Хоргос» (МЦПС, СЭЗ «Восточные ворота»), страны СНГ и соседние, регионы и крупные города Казахстана, типы кузовов (тент, реф, площадка, контейнеровоз, изотерм), допуски (TIR, CMR, ADR, разрешение РФ), шаблоны сообщений чата. Все названия — {kk, ru, zh}.
5. Модули-заглушки: auth, users, drivers, vehicles, companies, dictionaries, arrivals, cargos, responses, deals, chat, translation, notifications, reviews, moderation, billing (выключен), admin.
6. CRUD + GET-эндпоинты справочников, Swagger на `/docs`.

## Готово, когда
- `docker compose up` + `npm run start:dev` поднимают всё без ошибок.
- `npx prisma migrate dev` и seed проходят на чистой базе.
- `GET /dictionaries/countries` возвращает страны на трёх языках.
- README в корне описывает запуск.
