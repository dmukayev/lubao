# Демо-доступы (seed-demo.ts)

Все аккаунты создаются командой `pnpm --filter backend prisma:seed:demo`.
Авторизация сейчас — временный dev-режим (без реальных SMS/JWT), см. `backend/src/common/dev-auth.guard.ts`.

## Админ (lubao_admin, http://localhost:5566)

| Email | Пароль |
|---|---|
| admin@lubao.kz | Demo12345! |

## Компании (lubao_app → «Логистическая компания»)

Единый пароль для всех: **Demo12345!**

| Компания | Email (владелец) | Email (логист) |
|---|---|---|
| Xinjiang Yidao Logistics 新疆一道物流 | owner@yidao-logistics.cn | logist@yidao-logistics.cn |
| Horgos Silk Bridge Trading 霍尔果斯丝路桥贸易 | owner@silkbridge-trade.cn | — |
| Beijing Trans-Eurasia Cargo 北京欧亚货运 | owner@transeurasia-cargo.cn | — |
| Nurly Zhol Terminal Logistics | owner@nurlyzhol-terminal.kz | — |

## Водители (lubao_app → «Водитель»)

Вход по телефону, без пароля/SMS-кода (dev-логин).

| Телефон | Ф.И.О. |
|---|---|
| +77011234501 | Ерлан Тохтаров |
| +77011234502 | Асхат Ниязов |
| +77011234503 | Данияр Сагынов |
| +77011234504 | Владимир Ким |
| +77011234505 | Нурлан Жаркентов |
| +77011234506 | Бахтияр Оспанов |

## Как пересоздать

```bash
cd backend
pnpm exec ts-node prisma/seed-demo.ts
```

Скрипт идемпотентный — повторный запуск не плодит дубли.
