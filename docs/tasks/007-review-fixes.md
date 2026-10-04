# 007 — Доработки по ревью: бизнес-правила и строки

Статус: не начато

Найдено при ревью кода 2026-10-04. Мелкие расхождения кода с `docs/decisions.md`.

## Что сделать
1. **Подтверждение сделки без верификации — проверка на бэкенде.**
   Сейчас клиент обрабатывает ошибку «водитель не проверен» (`deal_detail_screen.dart`), но бэкенд такую ошибку не выбрасывает — в `deals`/`responses` нет проверки `driver.isVerified`.
   Добавить: переход сделки в «подтверждён водителем» → 403 с кодом `DRIVER_NOT_VERIFIED`, если `isVerified = false`. Тест.
2. **Селфи — только камера.** В `driver_verification_screen.dart` для документа SELFIE скрыть кнопку «Из галереи». Для остальных документов галерея разрешена.
3. **`isVerified` пересчитывать, а не только ставить true.** В `admin.service.ts` при approve ставится `isVerified: true`. Нужно: `isVerified` = все 4 документа водителя (SELFIE, VEHICLE_PASSPORT, TRAILER_PASSPORT, DRIVER_LICENSE) в APPROVED; при reject любого — `false`.
4. **Захардкоженные строки → ARB** (kk/ru/zh/en):
   - `apps/lubao_admin/lib/features/complaints/complaints_screen.dart`
   - `apps/lubao_admin/lib/features/drivers/admin_drivers_screen.dart`
   - `apps/lubao_app/lib/features/company/drivers/drivers_at_point_screen.dart`
   - `apps/lubao_app/lib/features/company/profile/company_profile_screen.dart`
   - `apps/lubao_app/lib/features/driver/feed/cargo_detail_screen.dart`
   - `apps/lubao_app/lib/features/driver/profile/driver_profile_screen.dart`
   - `packages/lubao_core/lib/src/widgets/loading_view.dart`
   Плюс сообщения ошибок бэкенда (например, лимиты SMS) — отдавать код ошибки, текст переводить на клиенте.
5. **Выбор языка до входа** (решение 2026-10-04 «Смена языка»): сейчас на `role_select_screen.dart` и `company_login_screen.dart` языка нет. Добавить: при первом запуске — экран выбора Қазақша / Русский / 中文 / English (выбран язык телефона); на экранах выбора роли и входа — плашка языка в правом верхнем углу. После входа сохранить выбор в `users.language` на сервере; при входе на новом устройстве — брать язык с сервера.
6. **Убрать «Хоргос» из текстов** (решение 2026-10-04): в `app_*.arb` — `feedTitle` («Грузы в Хоргосе»), `driverHomeCheckInEmpty` («…в Хоргосе…»), `driversAtPointTitle` («Кто будет на Хоргосе») и все подобные: общий текст («Грузы», «Кто будет на точке») или подстановка названия точки из справочника через плейсхолдер (`{point}`), на всех 4 языках.
7. Удалить лишний `backend/prisma/migrations/20261004012125_driver_registration_docs/migration_lock.toml` (lock-файл должен быть один, в корне `migrations/`).

## Готово, когда
- Неверифицированный водитель не может подтвердить сделку даже прямым запросом к API.
- `git grep -P "Text\(\s*'[^']*[А-Яа-я]" -- apps packages` ничего не находит.
- `git grep -i -E "хоргос|қорғас|霍尔果斯|khorgos" -- packages/lubao_core/lib/l10n apps` ничего не находит.
