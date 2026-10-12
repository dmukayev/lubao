# E2E-отчёт

Запуск: 2026-10-13 03:56:07 · устройства: android:lubao_e2e_360


## android:lubao_e2e_360

| Сценарий | Результат | Детали |
|---|---|---|
| админка: API-смоук (10, 13, 14) | ✅ | 180 проверок |
| правило свежести анонса (040, п.4): день приезда, 12 ч, гашение, геозона | ✅ | 20 проверок |
| telegram_login_test | ✅ | +1: All tests passed |
| trade_offers_test | ✅ | +1: All tests passed |
| auth_errors_test | ✅ | +1: All tests passed |
| админка в Chrome (10–14) | ⏭ не запускалась | E2E_SKIP_ADMIN_UI=1 |

### Шаги

| Сценарий | Шаг | Результат | Скриншот / ошибка |
|---|---|---|---|
| telegram_login | 01-кнопка-войти-через-telegram | ✅ | [01-кнопка-войти-через-telegram.png](shots/android-lubao_e2e_360/telegram_login/01-кнопка-войти-через-telegram.png) |
| telegram_login | 02-чужой-контакт-не-принимается | ✅ | [02-чужой-контакт-не-принимается.png](shots/android-lubao_e2e_360/telegram_login/02-чужой-контакт-не-принимается.png) |
| telegram_login | 03-свой-номер-вход-и-регистрация | ✅ | [03-свой-номер-вход-и-регистрация.png](shots/android-lubao_e2e_360/telegram_login/03-свой-номер-вход-и-регистрация.png) |
| trade_offers | 01-логист-публикует-груз-на-2-машины-в-рублях | ✅ | [01-логист-публикует-груз-на-2-машины-в-рублях.png](shots/android-lubao_e2e_360/trade_offers/01-логист-публикует-груз-на-2-машины-в-рублях.png) |
| trade_offers | 02-вход-водителя | ✅ | [02-вход-водителя.png](shots/android-lubao_e2e_360/trade_offers/02-вход-водителя.png) |
| trade_offers | 03-компания-добавила-водителя-принять | ✅ | [03-компания-добавила-водителя-принять.png](shots/android-lubao_e2e_360/trade_offers/03-компания-добавила-водителя-принять.png) |
| trade_offers | 04-лента-аванс-нал-нужно-2-флаги | ✅ | [04-лента-аванс-нал-нужно-2-флаги.png](shots/android-lubao_e2e_360/trade_offers/04-лента-аванс-нал-нужно-2-флаги.png) |
| trade_offers | 05-звезда-в-избранное | ✅ | [05-звезда-в-избранное.png](shots/android-lubao_e2e_360/trade_offers/05-звезда-в-избранное.png) |
| trade_offers | 06-своя-цена | ✅ | [06-своя-цена.png](shots/android-lubao_e2e_360/trade_offers/06-своя-цена.png) |
| trade_offers | 07-встречная-цена-логиста-и-согласен | ✅ | [07-встречная-цена-логиста-и-согласен.png](shots/android-lubao_e2e_360/trade_offers/07-встречная-цена-логиста-и-согласен.png) |
| trade_offers | 08-второй-водитель-груз-ушёл-из-ленты | ✅ | [08-второй-водитель-груз-ушёл-из-ленты.png](shots/android-lubao_e2e_360/trade_offers/08-второй-водитель-груз-ушёл-из-ленты.png) |
| trade_offers | 09-был-в-сети | ✅ | [09-был-в-сети.png](shots/android-lubao_e2e_360/trade_offers/09-был-в-сети.png) |
| trade_offers | 10-создать-водителя-новый-номер-вход-принять | ✅ | [10-создать-водителя-новый-номер-вход-принять.png](shots/android-lubao_e2e_360/trade_offers/10-создать-водителя-новый-номер-вход-принять.png) |
| auth_errors | 01-логист-неверный-пароль | ✅ | [01-логист-неверный-пароль.png](shots/android-lubao_e2e_360/auth_errors/01-логист-неверный-пароль.png) |
| auth_errors | 02-водитель-неверный-код | ✅ | [02-водитель-неверный-код.png](shots/android-lubao_e2e_360/auth_errors/02-водитель-неверный-код.png) |
