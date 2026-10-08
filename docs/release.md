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
IOS_APP_ID=28Y4B2FLZ7.kz.darkhan.lubao
ANDROID_PACKAGE=kz.darkhan.lubao
ANDROID_CERT_SHA256=                  # отпечаток релизного ключа: keytool -list -v -keystore … (п. 3.2)

# Push (раздел 5)
PUSH_PROVIDER=real
FCM_SERVICE_ACCOUNT_JSON=             # JSON сервисного аккаунта Firebase одной строкой
APNS_KEY_ID=
APNS_TEAM_ID=28Y4B2FLZ7
APNS_PRIVATE_KEY=                     # содержимое .p8, переводы строк — \n
APNS_BUNDLE_ID=kz.darkhan.lubao
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

```bash
# 2.6a Карта для расстояний (OSRM, 047/049 п.11). Карту НЕ урезаем: РК, КГ, УЗ, Китай,
# приграничные ФО РФ (Сибирский, Уральский, Приволжский, Южный). Сборка — ОДИН раз (обновление
# раз в полгода) на внешней машине с большой памятью: ~3,5 ГБ pbf, 16–32 ГБ RAM, 1–2 ч, ~10 ГБ диска.
# С Docker или без (бинарники osmium/osrm-extract/osrm-contract в PATH: OSRM_MODE=native).
#   на внешней машине:  OUT_DIR=/data/osrm infra/osrm/prepare.sh
# Сервер/Мак ничего не собирает — получает готовую папку region.osrm* (сервису 2–4 ГБ RAM):
#   rsync -a /data/osrm/region.osrm* <сервер>:/tmp/osrm/
#   docker volume create osrm-data
#   docker run --rm -v osrm-data:/data -v /tmp/osrm:/src alpine sh -c 'cp /src/region.osrm* /data/'
docker compose -f docker-compose.prod.yml restart osrm
# Пока карты нет, сервис osrm ждёт, а в ленте вместо км — «—» (досчитается планировщиком).
# Проверка изнутри сети: Алматы → Астана ≈ 1 200 км (поле "distance" в метрах)
docker compose -f docker-compose.prod.yml exec backend wget -qO- 'http://osrm:5000/route/v1/driving/76.9286,43.2567;71.4704,51.1605?overview=false'
```

> `prisma db seed` нужен один раз на пустой базе. `seed-e2e.ts` и `seed-demo.ts` в проде запускать нельзя (e2e-сид сам отказывается при `NODE_ENV=production`).

### 2.7 Чек-лист первого деплоя (по порядку)

- [ ] `https://$APP_HOST/api/health/ready` — всё `ok`;
- [ ] **бэкфилл идентификаторов:** если база не пустая (перенос с тестового стенда) — `docker compose -f docker-compose.prod.yml exec backend npx ts-node prisma/backfill-identifiers.ts`; на пустой базе не нужен;
- [ ] админ создан, вход в админку **из tailnet** работает, **с публичного адреса — нет**;
- [ ] SMS-код приходит на реальный номер; письмо с кодом приходит в gmail, mail.ru, qq.com (проверка доставки);
- [ ] первый бэкап снят вручную: `docker compose -f docker-compose.prod.yml exec backup backup.sh once`, **восстановление проверено** (`infra/README.md` → «Проверка восстановления»), `BACKUP_REMOTE_CMD` настроен;
- [ ] **обязательно: юрист вычитал и утвердил** `infra/site/legal/terms.html`, `privacy.html`, `offer.html` (сейчас заготовки с пометкой «ТЕКСТ-ЗАГОТОВКА») — без этого в прод не выпускать; изменили смысл текста — поднять версию: согласие на ПДн `PD_CONSENT_VERSION` / `pdConsentVersion`, оферта `OFFER_VERSION` / `offerVersion` (бэкенд `src/auth/legal-consent.ts` и `lubao_core` `auth_repository.dart` — одинаково), пометку «ТЕКСТ-ЗАГОТОВКА» убрать;
- [ ] `/legal/terms`, `/legal/privacy`, `/legal/offer` открываются на 4 языках;
- [ ] веб логиста не ходит к gstatic/googleapis (DevTools → Network);
- [ ] `minAppVersion` в «Настройки» админки пуст (обновления пока не требуем).

## 3. Приложение (мобильные сборки)

### 3.1 Идентификаторы приложения — зафиксированы 2026-10-07, не менять

| Платформа | Идентификатор | Где задан |
|---|---|---|
| Android | `kz.darkhan.lubao` | `applicationId` и `namespace` в `apps/lubao_app/android/app/build.gradle.kts`, пакет `MainActivity` — `android/app/src/main/kotlin/kz/darkhan/lubao/` |
| iOS | `kz.darkhan.lubao` (тесты — `kz.darkhan.lubao.RunnerTests`) | `PRODUCT_BUNDLE_IDENTIFIER` во всех конфигурациях `apps/lubao_app/ios/Runner.xcodeproj/project.pbxproj` |
| Связанное | `APNS_BUNDLE_ID=kz.darkhan.lubao`, `IOS_APP_ID=28Y4B2FLZ7.kz.darkhan.lubao`, `ANDROID_PACKAGE=kz.darkhan.lubao` | `.env.example`, `docker-compose.prod.yml`, раздел 1 |

После публикации в Google Play / App Store идентификатор сменить нельзя (это будет другое приложение): push-ключи, Firebase-приложения, App ID в Apple Developer, `assetlinks.json` и `apple-app-site-association` заводятся на эти значения. Название на устройстве — «Lubao» (`android:label` / `CFBundleDisplayName`), иконка — фирменный знак (043 п.7, `design/brand/`).

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

1. Apple Developer аккаунт, App ID `kz.darkhan.lubao`, в Capabilities включить **Push Notifications** (и в Xcode → Runner → Signing & Capabilities добавить Push Notifications и Background Modes → Remote notifications).
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

Приложение собирается и работает без Firebase: push включается флагом сборки `--dart-define=PUSH_ENABLED=true` (без флага `PushService` ничего не делает) и файлами, которые не кладутся в репозиторий (они в `.gitignore`):

1. Firebase Console → проект → добавить приложения:
   - Android `kz.darkhan.lubao` → `google-services.json` в `apps/lubao_app/android/app/` (Gradle-плагин `com.google.gms.google-services` применяется сам, только если файл есть);
   - iOS `kz.darkhan.lubao` → `GoogleService-Info.plist` в `apps/lubao_app/ios/Runner/` и добавить в target Runner (Copy Bundle Resources).
2. Apple Developer → Keys → ключ APNs (`.p8`) → загрузить в Firebase Console (Project settings → Cloud Messaging → APNs auth key). Обе платформы получают push через FCM; токен регистрируется как `FCM`.
3. iOS: права `aps-environment` уже в `Runner.entitlements`, фоновый режим `remote-notification` — в Info.plist; при экспорте в App Store/TestFlight Xcode ставит production.
4. Сервер: `PUSH_PROVIDER=real`, `FCM_SERVICE_ACCOUNT_JSON` (раздел 1). APNs-переменные нужны только для прямой отправки в обход FCM (сейчас не используется).
5. Сборки: `flutter build apk --release --dart-define=PUSH_ENABLED=true …`, `flutter build ipa --dart-define=PUSH_ENABLED=true …`.

Поведение (042 п.1): разрешение спрашивается после первого анонса / отклика / публикации груза; токен — при входе и смене, снимается при выходе; тап открывает экран из `deepLink`; «Ещё ищете груз?» — кнопки «Да / Уехал», «Договорились?» — «Да / Нет» (Android — уведомление рисует приложение из data-сообщения, iOS — категории регистрирует приложение, нажатие передаёт AppDelegate).

Сборка для КНР — без флага `PUSH_ENABLED` (Firebase не инициализируется); JPush — после пилота.

## Журнал проверок

| Дата | Что проверено | Где | Результат |
|---|---|---|---|
| _заполняется при деплое_ | | | |

## Идентификаторы приложения — зафиксированы 2026-10-07, не менять
- Android `applicationId` и `namespace`: `kz.darkhan.lubao`
- iOS `PRODUCT_BUNDLE_IDENTIFIER`: `kz.darkhan.lubao`
(были шаблонные `com.lubao.lubao_app` / `com.lubao.lubaoApp` — переименовать до первой внешней сборки: Android `build.gradle`, папка пакета `MainActivity`, `AndroidManifest`; iOS все три конфигурации в `project.pbxproj`, `APNS_BUNDLE_ID` в `.env.example`; `google-services.json`/`GoogleService-Info.plist` пользователь заводит уже под новые.)
Под них заведены Firebase (FCM/APNs) и будут заведены Google Play и App Store. Смена идентификатора = другое приложение для магазинов и телефонов (обновления не придут). Название на иконке и в магазине меняется свободно, идентификаторы — нет.
