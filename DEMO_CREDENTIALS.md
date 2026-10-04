# Демо-доступы (seed-demo.ts)

Все аккаунты создаются командой `pnpm --filter backend prisma:seed:demo`.
Скрипт отказывается запускаться при `NODE_ENV=production`.

Авторизация — JWT (access-токен 15 мин + refresh-токен, ротация при
обновлении, несколько устройств одновременно), см. `backend/src/token/`
и `backend/src/auth/`. Код SMS в деве (`SMS_PROVIDER=console`) всегда `1111`,
код email (`EMAIL_PROVIDER=console`) всегда `111111`.

## Админ (lubao_admin, http://localhost:5566)

Единственный вход с паролем — остаётся так по решению 2026-10-04 (2FA пока
не делаем, но пароль нужен).

| Email | Пароль |
|---|---|
| admin@lubao.kz | DemoLubao2026! |

## Компании (lubao_app → «Логистическая компания»)

Вход по email + паролю (задача 025, заменяет вход по коду из 006/022).
Пароль у всех демо-компаний один — `DemoLubao2026!` (тот же, что у админа).

| Компания | Email (владелец) | Email (логист) |
|---|---|---|
| Xinjiang Yidao Logistics 新疆一道物流 | owner@yidao-logistics.cn | logist@yidao-logistics.cn |
| Horgos Silk Bridge Trading 霍尔果斯丝路桥贸易 | owner@silkbridge-trade.cn | — |
| Beijing Trans-Eurasia Cargo 北京欧亚货运 | owner@transeurasia-cargo.cn | — |
| Nurly Zhol Terminal Logistics | owner@nurlyzhol-terminal.kz | — |

## Водители (lubao_app → «Водитель»)

Вход по телефону + SMS-код (в деве всегда `1111`).

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
