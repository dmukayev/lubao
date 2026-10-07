# Выпуск: чек-лист первого деплоя и обновлений

Статус документа: рабочий черновик (задача 043). Что подтверждено на этой машине, а что проверяется только на реальном сервере/устройстве, — в разделе «Журнал проверок» внизу.

## 0. Что нужно до начала

| Что | Зачем |
|---|---|
| Сервер в облаке РК (Linux, Docker + Compose v2, 4 ГБ RAM, 40 ГБ диск), домен с A-записью на сервер | персональные данные хранятся в РК; TLS |
| Tailscale на сервере и на устройствах админов | админка доступна только внутри tailnet (030) |
| Mobizon API-ключ | SMS-коды водителям |
| SMTP (хост, логин, пароль, адрес отправителя) | коды и приглашения логистам; для адресов qq.com/163.com нужен провайдер с доставкой в КНР (Alibaba DirectMail и т.п.) |
| (необязательно) Meta WhatsApp Cloud API: токен, phone-id, шаблон authentication | код входа в WhatsApp, фолбэк на SMS |
| (необязательно) DeepSeek API-ключ | автоперевод чата |
| Firebase-проект + APNs-ключ | push (042); без них приложение работает, push нет |
| (необязательно) Sentry DSN | отчёты об ошибках без персональных данных |

## 1. Секреты и окружение

Создайте на сервере `.env.prod` рядом с `docker-compose.prod.yml` (файл в `.gitignore`, не коммитить):

```env
APP_HOST=app.example.kz
APP_PUBLIC_URL=https://app.example.kz
ADMIN_LISTEN=100.64.0.1:8080          # адрес сервера в tailnet : порт админки

POSTGRES_PASSWORD=...                 # openssl rand -base64 24
REDIS_PASSWORD=...
MINIO_ROOT_USER=lubao
MINIO_ROOT_PASSWORD=...               # минимум 16 символов
JWT_ACCESS_SECRET=...                 # openssl rand -base64 48
IDENTIFIER_KEY=...                    # openssl rand -base64 48 — НЕ менять после первого деплоя
IDENTIFIER_PEPPER=...                 # openssl rand -base64 24 — НЕ менять после первого деплоя

SMS_PROVIDER=mobizon
MOBIZON_API_KEY=...
EMAIL_PROVIDER=smtp
SMTP_HOST=...
SMTP_PORT=587
SMTP_USER=...
SMTP_PASS=...
SMTP_FROM="Lubao <no-reply@example.kz>"

CORS_ALLOWED_ORIGINS=https://app.example.kz
MINIO_PUBLIC_URL=https://app.example.kz/files

# Каналы кода входа (042 п.3): включение и порядок — в админке «Настройки → Каналы кода входа»;
# без ключей канал недоступен (в админке серый). SMS (Mobizon) — всегда страховка.
WHATSAPP_TOKEN=
WHATSAPP_PHONE_ID=
WHATSAPP_TEMPLATE=                    # шаблон authentication с кнопкой «Скопировать код»
TELEGRAM_GATEWAY_TOKEN=               # gateway.telegram.org → API token

# Ссылки-приглашения https://APP_HOST/invite/... открывают приложение (042 п.2):
IOS_APP_ID=28Y4B2FLZ7.com.lubao.lubaoApp
ANDROID_PACKAGE=com.lubao.lubao_app
ANDROID_CERT_SHA256=                  # отпечаток релизного ключа: keytool -list -v -keystore … (п. 3.2)

# Push (раздел 5)
PUSH_PROVIDER=real
FCM_SERVICE_ACCOUNT_JSON=             # JSON сервисного аккаунта Firebase одной строкой
APNS_KEY_ID=
APNS_TEAM_ID=28Y4B2FLZ7
APNS_PRIVATE_KEY=                     # содержимое .p8, переводы строк — \n
APNS_BUNDLE_ID=com.lubao.lubaoApp
APNS_PRODUCTION=true                  # App Store и TestFlight — true; сборки с Mac (flutter run) — false

# необязательно
TRANSLATION_PROVIDER=deepseek
DEEPSEEK_API_KEY=
SENTRY_DSN=
BACKUP_REMOTE_CMD=                    # выгрузка копий в ОТДЕЛЬНОЕ хранилище (см. infra/README.md)
ADMIN_BOOTSTRAP_EMAIL=                # первый админ, если админов ещё нет
ADMIN_BOOTSTRAP_PASSWORD_HASH=        # bcrypt-хэш: node -e "console.log(require('bcryptjs').hashSync(process.argv[1],12))" 'пароль'
```

Бэкенд **не стартует** в `NODE_ENV=production`, если: SMS не `mobizon` (иначе код 1111 у всех), почта не `smtp`, пуст `CORS_ALLOWED_ORIGINS`, пароли Postgres/MinIO — значения по умолчанию, `JWT_ACCESS_SECRET`/`IDENTIFIER_KEY` короче 32 символов, `APP_PUBLIC_URL` не https. Причины печатаются списком (`backend/src/config/production-guard.ts`).

## 2. Первый деплой

```bash
git clone <repo> /opt/lubao && cd /opt/lubao

# 2.1 Веб-клиенты: свои CanvasKit и шрифты, без gstatic (--no-web-resources-cdn)
(cd apps/lubao_app   && flutter build web --release --no-web-resources-cdn \
   --dart-define=API_BASE_URL=https://$APP_HOST/api --dart-define=APP_PUBLIC_URL=https://$APP_HOST)
(cd apps/lubao_admin && flutter build web --release --no-web-resources-cdn \
   --dart-define=API_BASE_URL=http://$ADMIN_LISTEN/api)
# (если на сервере нет Flutter — собрать на своей машине и скопировать build/web)

# 2.2 TLS: сначала временный сертификат / certbot — см. infra/README.md
# 2.3 Подъём
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build

# 2.4 Проверка: должно вернуть {"status":"ok","checks":{"postgres":"ok","redis":"ok","minio":"ok"}}
curl -fsS https://$APP_HOST/api/health/ready

# 2.5 Первый администратор (если не задан ADMIN_BOOTSTRAP_*)
docker compose -f docker-compose.prod.yml exec backend \
  node dist/src/cli/create-admin.js --email admin@example.kz --password '<не короче 12 символов>'
# или через env, чтобы пароль не попал в историю shell: ADMIN_EMAIL=… ADMIN_PASSWORD=… node dist/src/cli/create-admin.js

# 2.6 Справочники (регионы, города, точки, типы кузова): сид идемпотентен
docker compose -f docker-compose.prod.yml exec backend npx prisma db seed
```

> `prisma db seed` нужен один раз на пустой базе. `seed-e2e.ts` и `seed-demo.ts` в проде запускать нельзя (e2e-сид сам отказывается при `NODE_ENV=production`).

### 2.7 Чек-лист первого деплоя (по порядку)

- [ ] `https://$APP_HOST/api/health/ready` — всё `ok`;
- [ ] **бэкфилл идентификаторов:** если база не пустая (перенос с тестового стенда) — `docker compose -f docker-compose.prod.yml exec backend npx ts-node prisma/backfill-identifiers.ts`; на пустой базе не нужен;
- [ ] админ создан, вход в админку **из tailnet** работает, **с публичного адреса — нет**;
- [ ] SMS-код приходит на реальный номер; письмо с кодом приходит в gmail, mail.ru, qq.com (проверка доставки);
- [ ] первый бэкап снят вручную: `docker compose -f docker-compose.prod.yml exec backup backup.sh once`, **восстановление проверено** (`infra/README.md` → «Проверка восстановления»), `BACKUP_REMOTE_CMD` настроен;
- [ ] `/legal/terms`, `/legal/privacy` открываются на 4 языках (тексты — заготовки, **юрист правит до первого пользователя**);
- [ ] веб логиста не ходит к gstatic/googleapis (DevTools → Network);
- [ ] `minAppVersion` в «Настройки» админки пуст (обновления пока не требуем).

## 3. Приложение (мобильные сборки)

### 3.1 Идентификаторы и название

Текущие значения (заменить до первого релиза, менять после публикации нельзя): Android `applicationId = com.lubao.lubao_app`, iOS `PRODUCT_BUNDLE_IDENTIFIER = com.lubao.lubaoApp`, название на устройстве — «Lubao» (`android:label` / `CFBundleDisplayName`), иконка — `apps/lubao_app/ios/Runner/Assets.xcassets/AppIcon.appiconset` и `android/app/src/main/res/mipmap-*` (заменить на финальную).

### 3.2 Android: подпись релизным ключом

```bash
keytool -genkey -v -keystore ~/lubao-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias lubao
```

Keystore и пароли **хранить вне репозитория** (менеджер паролей + офлайн-копия: потеряли ключ — Google Play не даст обновлять приложение). В `apps/lubao_app/android/key.properties` (в `.gitignore`):

```properties
storePassword=...
keyPassword=...
keyAlias=lubao
storeFile=/absolute/path/to/lubao-release.jks
```

Сборка: `flutter build appbundle --release --dart-define=API_BASE_URL=https://$APP_HOST/api --dart-define=APP_PUBLIC_URL=https://$APP_HOST` → `build/app/outputs/bundle/release/app-release.aab` → Google Play Console (внутреннее тестирование → закрытое → продакшен).

### 3.3 iOS: TestFlight

1. Apple Developer аккаунт, App ID `com.lubao.lubaoApp` (или финальный), в Capabilities включить **Push Notifications** (и в Xcode → Runner → Signing & Capabilities добавить Push Notifications и Background Modes → Remote notifications).
2. `flutter build ipa --release --dart-define=...` (те же `--dart-define`, что для Android; для push добавить `--dart-define=PUSH_ENABLED=true`).
3. Xcode → Organizer → Distribute App → App Store Connect → TestFlight; тестеров добавить по email.

### 3.4 Принудительное обновление (force-update)

В админке «Настройки» → `minAppVersion` (например `1.2.0`). Версия приложения ниже — при старте экран «Обновите приложение» с кнопкой на `https://$APP_HOST/app` (ссылки на Google Play / TestFlight прописать в `infra/site/app.html`). Пустое значение — выключено. Поднимайте только когда новая сборка уже опубликована в магазинах.

## 4. Обновление версии

```bash
git pull
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build backend   # миграции применяются при старте контейнера
# веб: пересобрать apps/lubao_app и apps/lubao_admin (п. 2.1); nginx отдаёт статику с диска, перезапуск не нужен
```

Откат: предыдущий образ (`docker compose ... up -d --no-build` после `git checkout <тег>` и пересборки) + восстановление БД из бэкапа, если миграция была несовместимой. Миграции в проекте аддитивные (новые колонки/значения enum), поэтому откат кода без отката БД обычно безопасен.

## 5. Push (Firebase / APNs)

Приложение собирается и работает без Firebase; push включается флагом `--dart-define=PUSH_ENABLED=true` и файлами, которые нельзя класть в репозиторий:

- Android: `apps/lubao_app/android/app/google-services.json` + Gradle-плагин `com.google.gms.google-services` (подключается автоматически, если файл есть);
- iOS: `apps/lubao_app/ios/Runner/GoogleService-Info.plist` + APNs-ключ в Firebase Console;
- на сервере: `PUSH_PROVIDER=real`, учётные данные FCM/APNs (см. `backend/src/notifications/push/*`).

Сборка для КНР без Firebase — отдельный flavor `cn` (заглушка не реализована, JPush — после пилота).

## Журнал проверок

| Дата | Что проверено | Где | Результат |
|---|---|---|---|
| _заполняется при деплое_ | | | |
