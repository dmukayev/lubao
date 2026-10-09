# E2E-отчёт

Запуск: 2026-10-09 04:51:45 · устройства: iPhone SE (3rd generation) android:lubao_e2e_360


## iPhone SE (3rd generation)

| Сценарий | Результат | Детали |
|---|---|---|
| админка: API-смоук (10, 13, 14) | ✅ | 158 проверок |
| правило свежести анонса (040, п.4): день приезда, 12 ч, гашение, геозона | ✅ | 20 проверок |
| веб логиста без Google (020 А): CanvasKit и шрифты свои, zh | ✅ | ok ни одного запроса к gstatic/googleapis |
| driver_flow_test | ✅ | +1: All tests passed |
| driver_deal_test | ✅ | +1: All tests passed |
| logist_drivers_test | ✅ | +1: All tests passed |
| garage_vehicle_test | ✅ | +1: All tests passed |
| company_register_test | ✅ | +1: All tests passed |
| driver_register_iin_test | ✅ | +1: All tests passed |
| telegram_login_test | ✅ | +1: All tests passed |
| админка в Chrome (10–14, ширина 1280 и 390) | ✅ | 14 passed |
| logist_publish_test | ✅ | +1: All tests passed |
| all_screens_test | ✅ | +1: All tests passed |

### Шаги

| Сценарий | Шаг | Результат | Скриншот / ошибка |
|---|---|---|---|
| driver_flow | 01-обновите-приложение | ✅ | [01-обновите-приложение.png](shots/iphone-se-(3rd-generation)/driver_flow/01-обновите-приложение.png) |
| driver_flow | 02-вход-выбор-канала-кода | ✅ | [02-вход-выбор-канала-кода.png](shots/iphone-se-(3rd-generation)/driver_flow/02-вход-выбор-канала-кода.png) |
| driver_flow | 03-вход | ✅ | [03-вход.png](shots/iphone-se-(3rd-generation)/driver_flow/03-вход.png) |
| driver_flow | 04-анонс-свободен-в-алматы | ✅ | [04-анонс-свободен-в-алматы.png](shots/iphone-se-(3rd-generation)/driver_flow/04-анонс-свободен-в-алматы.png) |
| driver_flow | 05-смена-города-анонса-на-астану | ✅ | [05-смена-города-анонса-на-астану.png](shots/iphone-se-(3rd-generation)/driver_flow/05-смена-города-анонса-на-астану.png) |
| driver_flow | 06-лента-карточка-груза | ✅ | [06-лента-карточка-груза.png](shots/iphone-se-(3rd-generation)/driver_flow/06-лента-карточка-груза.png) |
| driver_flow | 07-whatsapp-значок-у-казахстанской-компании | ✅ | [07-whatsapp-значок-у-казахстанской-компании.png](shots/iphone-se-(3rd-generation)/driver_flow/07-whatsapp-значок-у-казахстанской-компании.png) |
| driver_flow | 08-whatsapp-переход-и-событие | ✅ | [08-whatsapp-переход-и-событие.png](shots/iphone-se-(3rd-generation)/driver_flow/08-whatsapp-переход-и-событие.png) |
| driver_flow | 09-чат-сообщение | ✅ | [09-чат-сообщение.png](shots/iphone-se-(3rd-generation)/driver_flow/09-чат-сообщение.png) |
| driver_flow | 10-список-чатов | ✅ | [10-список-чатов.png](shots/iphone-se-(3rd-generation)/driver_flow/10-список-чатов.png) |
| driver_deal | 01-вход | ✅ | [01-вход.png](shots/iphone-se-(3rd-generation)/driver_deal/01-вход.png) |
| driver_deal | 02-отклики-на-три-груза | ✅ | [02-отклики-на-три-груза.png](shots/iphone-se-(3rd-generation)/driver_deal/02-отклики-на-три-груза.png) |
| driver_deal | 03-логист-выбирает-через-API | ✅ | [03-логист-выбирает-через-API.png](shots/iphone-se-(3rd-generation)/driver_deal/03-логист-выбирает-через-API.png) |
| driver_deal | 04-груз-со-сделкой-исчез-из-ленты | ✅ | [04-груз-со-сделкой-исчез-из-ленты.png](shots/iphone-se-(3rd-generation)/driver_deal/04-груз-со-сделкой-исчез-из-ленты.png) |
| driver_deal | 05-сделка1-загружен-без-согласия-на-трекинг | ✅ | [05-сделка1-загружен-без-согласия-на-трекинг.png](shots/iphone-se-(3rd-generation)/driver_deal/05-сделка1-загружен-без-согласия-на-трекинг.png) |
| driver_deal | 06-логист-открыл-документы-водитель-видит | ✅ | [06-логист-открыл-документы-водитель-видит.png](shots/iphone-se-(3rd-generation)/driver_deal/06-логист-открыл-документы-водитель-видит.png) |
| driver_deal | 07-сделка2-одна-перевозка-за-раз | ✅ | [07-сделка2-одна-перевозка-за-раз.png](shots/iphone-se-(3rd-generation)/driver_deal/07-сделка2-одна-перевозка-за-раз.png) |
| driver_deal | 08-доставлено-ищете-груз-отсюда | ✅ | [08-доставлено-ищете-груз-отсюда.png](shots/iphone-se-(3rd-generation)/driver_deal/08-доставлено-ищете-груз-отсюда.png) |
| driver_deal | 09-сделка2-согласие-на-трекинг-и-пауза | ✅ | [09-сделка2-согласие-на-трекинг-и-пауза.png](shots/iphone-se-(3rd-generation)/driver_deal/09-сделка2-согласие-на-трекинг-и-пауза.png) |
| driver_deal | 10-сделка3-одна-перевозка-за-раз | ✅ | [10-сделка3-одна-перевозка-за-раз.png](shots/iphone-se-(3rd-generation)/driver_deal/10-сделка3-одна-перевозка-за-раз.png) |
| driver_deal | 11-отмена-причина-из-списка | ✅ | [11-отмена-причина-из-списка.png](shots/iphone-se-(3rd-generation)/driver_deal/11-отмена-причина-из-списка.png) |
| driver_deal | 12-отмена-после-загрузки-и-жалоба | ✅ | [12-отмена-после-загрузки-и-жалоба.png](shots/iphone-se-(3rd-generation)/driver_deal/12-отмена-после-загрузки-и-жалоба.png) |
| logist_drivers | 01-вход-логиста | ✅ | [01-вход-логиста.png](shots/iphone-se-(3rd-generation)/logist_drivers/01-вход-логиста.png) |
| logist_drivers | 02-водители-экран | ✅ | [02-водители-экран.png](shots/iphone-se-(3rd-generation)/logist_drivers/02-водители-экран.png) |
| logist_drivers | 03-кто-свободен-выбор-города-алматы | ✅ | [03-кто-свободен-выбор-города-алматы.png](shots/iphone-se-(3rd-generation)/logist_drivers/03-кто-свободен-выбор-города-алматы.png) |
| logist_drivers | 04-кто-свободен-обратно-хоргос | ✅ | [04-кто-свободен-обратно-хоргос.png](shots/iphone-se-(3rd-generation)/logist_drivers/04-кто-свободен-обратно-хоргос.png) |
| logist_drivers | 05-фильтр-проверенные | ✅ | [05-фильтр-проверенные.png](shots/iphone-se-(3rd-generation)/logist_drivers/05-фильтр-проверенные.png) |
| logist_drivers | 06-чат-с-водителем | ✅ | [06-чат-с-водителем.png](shots/iphone-se-(3rd-generation)/logist_drivers/06-чат-с-водителем.png) |
| logist_drivers | 07-предложить-груз | ✅ | [07-предложить-груз.png](shots/iphone-se-(3rd-generation)/logist_drivers/07-предложить-груз.png) |
| logist_drivers | 08-пригласить-ждём-согласия | ✅ | [08-пригласить-ждём-согласия.png](shots/iphone-se-(3rd-generation)/logist_drivers/08-пригласить-ждём-согласия.png) |
| logist_drivers | 09-выход-логиста | ✅ | [09-выход-логиста.png](shots/iphone-se-(3rd-generation)/logist_drivers/09-выход-логиста.png) |
| logist_drivers | 10-вход-водителя-D3 | ✅ | [10-вход-водителя-D3.png](shots/iphone-se-(3rd-generation)/logist_drivers/10-вход-водителя-D3.png) |
| logist_drivers | 11-водитель-видит-приглашение-и-соглашается | ✅ | [11-водитель-видит-приглашение-и-соглашается.png](shots/iphone-se-(3rd-generation)/logist_drivers/11-водитель-видит-приглашение-и-соглашается.png) |
| logist_drivers | 12-фото-профиля-из-селфи | ✅ | [12-фото-профиля-из-селфи.png](shots/iphone-se-(3rd-generation)/logist_drivers/12-фото-профиля-из-селфи.png) |
| logist_drivers | 13-выход-водителя | ✅ | [13-выход-водителя.png](shots/iphone-se-(3rd-generation)/logist_drivers/13-выход-водителя.png) |
| logist_drivers | 14-логист-видит-фото-водителя | ✅ | [14-логист-видит-фото-водителя.png](shots/iphone-se-(3rd-generation)/logist_drivers/14-логист-видит-фото-водителя.png) |
| logist_drivers | 15-логист-выбирает-согласившегося | ✅ | [15-логист-выбирает-согласившегося.png](shots/iphone-se-(3rd-generation)/logist_drivers/15-логист-выбирает-согласившегося.png) |
| logist_drivers | 16-выход-логиста-2 | ✅ | [16-выход-логиста-2.png](shots/iphone-se-(3rd-generation)/logist_drivers/16-выход-логиста-2.png) |
| logist_drivers | 17-вход-водителя-D3-снова | ✅ | [17-вход-водителя-D3-снова.png](shots/iphone-se-(3rd-generation)/logist_drivers/17-вход-водителя-D3-снова.png) |
| logist_drivers | 18-чат-водителя-подтверждение | ✅ | [18-чат-водителя-подтверждение.png](shots/iphone-se-(3rd-generation)/logist_drivers/18-чат-водителя-подтверждение.png) |
| logist_drivers | 19-загружен-в-карточке-чата | ✅ | [19-загружен-в-карточке-чата.png](shots/iphone-se-(3rd-generation)/logist_drivers/19-загружен-в-карточке-чата.png) |
| logist_drivers | 20-анонс-погас-после-подтверждения | ✅ | [20-анонс-погас-после-подтверждения.png](shots/iphone-se-(3rd-generation)/logist_drivers/20-анонс-погас-после-подтверждения.png) |
| garage_vehicle | 01-вход-водителя | ✅ | [01-вход-водителя.png](shots/iphone-se-(3rd-generation)/garage_vehicle/01-вход-водителя.png) |
| garage_vehicle | 02-гараж | ✅ | [02-гараж.png](shots/iphone-se-(3rd-generation)/garage_vehicle/02-гараж.png) |
| garage_vehicle | 03-шторка-добавления | ✅ | [03-шторка-добавления.png](shots/iphone-se-(3rd-generation)/garage_vehicle/03-шторка-добавления.png) |
| garage_vehicle | 04-форма-цистерны-без-паллет | ✅ | [04-форма-цистерны-без-паллет.png](shots/iphone-se-(3rd-generation)/garage_vehicle/04-форма-цистерны-без-паллет.png) |
| garage_vehicle | 05-поля-прицепа | ✅ | [05-поля-прицепа.png](shots/iphone-se-(3rd-generation)/garage_vehicle/05-поля-прицепа.png) |
| garage_vehicle | 06-фото-техпаспорта | ✅ | [06-фото-техпаспорта.png](shots/iphone-se-(3rd-generation)/garage_vehicle/06-фото-техпаспорта.png) |
| garage_vehicle | 07-отправка-на-проверку | ✅ | [07-отправка-на-проверку.png](shots/iphone-se-(3rd-generation)/garage_vehicle/07-отправка-на-проверку.png) |
| garage_vehicle | 08-документ-распознан-OCR | ✅ | [08-документ-распознан-OCR.png](shots/iphone-se-(3rd-generation)/garage_vehicle/08-документ-распознан-OCR.png) |
| company_register | 01-форма-регистрации | ✅ | [01-форма-регистрации.png](shots/iphone-se-(3rd-generation)/company_register/01-форма-регистрации.png) |
| company_register | 02-оферта-галочка | ✅ | [02-оферта-галочка.png](shots/iphone-se-(3rd-generation)/company_register/02-оферта-галочка.png) |
| company_register | 03-отправка-регистрации | ✅ | [03-отправка-регистрации.png](shots/iphone-se-(3rd-generation)/company_register/03-отправка-регистрации.png) |
| company_register | 04-баннер-в-профиле | ✅ | [04-баннер-в-профиле.png](shots/iphone-se-(3rd-generation)/company_register/04-баннер-в-профиле.png) |
| company_register | 05-загрузка-свидетельства | ✅ | [05-загрузка-свидетельства.png](shots/iphone-se-(3rd-generation)/company_register/05-загрузка-свидетельства.png) |
| company_register | 06-публикация-заблокирована | ✅ | [06-публикация-заблокирована.png](shots/iphone-se-(3rd-generation)/company_register/06-публикация-заблокирована.png) |
| driver_register_iin | 01-A-вход-нового-номера | ✅ | [01-A-вход-нового-номера.png](shots/iphone-se-(3rd-generation)/driver_register_iin/01-A-вход-нового-номера.png) |
| driver_register_iin | 02-A-мастер-шаг1-имя-город | ✅ | [02-A-мастер-шаг1-имя-город.png](shots/iphone-se-(3rd-generation)/driver_register_iin/02-A-мастер-шаг1-имя-город.png) |
| driver_register_iin | 03-A-мастер-шаг2-кузов | ✅ | [03-A-мастер-шаг2-кузов.png](shots/iphone-se-(3rd-generation)/driver_register_iin/03-A-мастер-шаг2-кузов.png) |
| driver_register_iin | 04-A-мастер-шаг3-готово | ✅ | [04-A-мастер-шаг3-готово.png](shots/iphone-se-(3rd-generation)/driver_register_iin/04-A-мастер-шаг3-готово.png) |
| driver_register_iin | 05-A-где-вы-сейчас | ✅ | [05-A-где-вы-сейчас.png](shots/iphone-se-(3rd-generation)/driver_register_iin/05-A-где-вы-сейчас.png) |
| driver_register_iin | 06-A-плашка-добавьте-машину | ✅ | [06-A-плашка-добавьте-машину.png](shots/iphone-se-(3rd-generation)/driver_register_iin/06-A-плашка-добавьте-машину.png) |
| driver_register_iin | 07-A-гараж-пуст-после-регистрации | ✅ | [07-A-гараж-пуст-после-регистрации.png](shots/iphone-se-(3rd-generation)/driver_register_iin/07-A-гараж-пуст-после-регистрации.png) |
| driver_register_iin | 08-A-новичок-откликается-без-проверки | ✅ | [08-A-новичок-откликается-без-проверки.png](shots/iphone-se-(3rd-generation)/driver_register_iin/08-A-новичок-откликается-без-проверки.png) |
| driver_register_iin | 09-A-телефон-после-отклика | ✅ | [09-A-телефон-после-отклика.png](shots/iphone-se-(3rd-generation)/driver_register_iin/09-A-телефон-после-отклика.png) |
| driver_register_iin | 10-A-селфи-и-права | ✅ | [10-A-селфи-и-права.png](shots/iphone-se-(3rd-generation)/driver_register_iin/10-A-селфи-и-права.png) |
| driver_register_iin | 11-A-ИИН-распознан | ✅ | [11-A-ИИН-распознан.png](shots/iphone-se-(3rd-generation)/driver_register_iin/11-A-ИИН-распознан.png) |
| driver_register_iin | 12-выход-A | ✅ | [12-выход-A.png](shots/iphone-se-(3rd-generation)/driver_register_iin/12-выход-A.png) |
| driver_register_iin | 13-B-вход-нового-номера | ✅ | [13-B-вход-нового-номера.png](shots/iphone-se-(3rd-generation)/driver_register_iin/13-B-вход-нового-номера.png) |
| driver_register_iin | 14-B-мастер-шаг1-имя-город | ✅ | [14-B-мастер-шаг1-имя-город.png](shots/iphone-se-(3rd-generation)/driver_register_iin/14-B-мастер-шаг1-имя-город.png) |
| driver_register_iin | 15-B-мастер-шаг2-кузов | ✅ | [15-B-мастер-шаг2-кузов.png](shots/iphone-se-(3rd-generation)/driver_register_iin/15-B-мастер-шаг2-кузов.png) |
| driver_register_iin | 16-B-мастер-шаг3-готово | ✅ | [16-B-мастер-шаг3-готово.png](shots/iphone-se-(3rd-generation)/driver_register_iin/16-B-мастер-шаг3-готово.png) |
| driver_register_iin | 17-B-где-вы-сейчас | ✅ | [17-B-где-вы-сейчас.png](shots/iphone-se-(3rd-generation)/driver_register_iin/17-B-где-вы-сейчас.png) |
| driver_register_iin | 18-B-селфи-и-права | ✅ | [18-B-селфи-и-права.png](shots/iphone-se-(3rd-generation)/driver_register_iin/18-B-селфи-и-права.png) |
| driver_register_iin | 19-B-ИИН-распознан | ✅ | [19-B-ИИН-распознан.png](shots/iphone-se-(3rd-generation)/driver_register_iin/19-B-ИИН-распознан.png) |
| telegram_login | 01-кнопка-войти-через-telegram | ✅ | [01-кнопка-войти-через-telegram.png](shots/iphone-se-(3rd-generation)/telegram_login/01-кнопка-войти-через-telegram.png) |
| telegram_login | 02-чужой-контакт-не-принимается | ✅ | [02-чужой-контакт-не-принимается.png](shots/iphone-se-(3rd-generation)/telegram_login/02-чужой-контакт-не-принимается.png) |
| telegram_login | 03-свой-номер-вход-и-регистрация | ✅ | [03-свой-номер-вход-и-регистрация.png](shots/iphone-se-(3rd-generation)/telegram_login/03-свой-номер-вход-и-регистрация.png) |
| admin_summary_desktop-1280 | 01-вход-и-сводка | ✅ | [01-вход-и-сводка.png](shots/iphone-se-(3rd-generation)/admin_summary_desktop-1280/01-вход-и-сводка.png) |
| admin_summary_desktop-1280 | 02-плитка-водители | ✅ | [02-плитка-водители.png](shots/iphone-se-(3rd-generation)/admin_summary_desktop-1280/02-плитка-водители.png) |
| admin_summary_desktop-1280 | 03-плитка-компании | ✅ | [03-плитка-компании.png](shots/iphone-se-(3rd-generation)/admin_summary_desktop-1280/03-плитка-компании.png) |
| admin_summary_desktop-1280 | 04-плитка-активные-грузы | ✅ | [04-плитка-активные-грузы.png](shots/iphone-se-(3rd-generation)/admin_summary_desktop-1280/04-плитка-активные-грузы.png) |
| admin_summary_desktop-1280 | 05-плитка-документы-на-проверке | ✅ | [05-плитка-документы-на-проверке.png](shots/iphone-se-(3rd-generation)/admin_summary_desktop-1280/05-плитка-документы-на-проверке.png) |
| admin_summary_desktop-1280 | 06-плитка-открытые-жалобы | ✅ | [06-плитка-открытые-жалобы.png](shots/iphone-se-(3rd-generation)/admin_summary_desktop-1280/06-плитка-открытые-жалобы.png) |
| admin_summary_desktop-1280 | 07-требует-внимания-ведёт-в-списки | ✅ | [07-требует-внимания-ведёт-в-списки.png](shots/iphone-se-(3rd-generation)/admin_summary_desktop-1280/07-требует-внимания-ведёт-в-списки.png) |
| admin_summary_desktop-1280 | 08-сводка-по-городам | ✅ | [08-сводка-по-городам.png](shots/iphone-se-(3rd-generation)/admin_summary_desktop-1280/08-сводка-по-городам.png) |
| admin_verification | 01-вход-и-очередь | ✅ | [01-вход-и-очередь.png](shots/iphone-se-(3rd-generation)/admin_verification/01-вход-и-очередь.png) |
| admin_verification | 02-водитель-распознано | ✅ | [02-водитель-распознано.png](shots/iphone-se-(3rd-generation)/admin_verification/02-водитель-распознано.png) |
| admin_verification | 03-одобрить-права-и-селфи | ✅ | [03-одобрить-права-и-селфи.png](shots/iphone-se-(3rd-generation)/admin_verification/03-одобрить-права-и-селфи.png) |
| admin_verification | 04-подтвердить-водителя | ✅ | [04-подтвердить-водителя.png](shots/iphone-se-(3rd-generation)/admin_verification/04-подтвердить-водителя.png) |
| admin_verification | 05-водитель-проверен-в-списке | ✅ | [05-водитель-проверен-в-списке.png](shots/iphone-se-(3rd-generation)/admin_verification/05-водитель-проверен-в-списке.png) |
| admin_verification | 06-машина-техпаспорт-одобряется | ✅ | [06-машина-техпаспорт-одобряется.png](shots/iphone-se-(3rd-generation)/admin_verification/06-машина-техпаспорт-одобряется.png) |
| admin_verification | 07-компания-подтверждается | ✅ | [07-компания-подтверждается.png](shots/iphone-se-(3rd-generation)/admin_verification/07-компания-подтверждается.png) |
| admin_blacklist_desktop-1280 | 01-вход | ✅ | [01-вход.png](shots/iphone-se-(3rd-generation)/admin_blacklist_desktop-1280/01-вход.png) |
| admin_blacklist_desktop-1280 | 02-блокировка-водителя-с-идентификаторами | ✅ | [02-блокировка-водителя-с-идентификаторами.png](shots/iphone-se-(3rd-generation)/admin_blacklist_desktop-1280/02-блокировка-водителя-с-идентификаторами.png) |
| admin_blacklist_desktop-1280 | 03-новый-водитель-в-проверке-⛔ | ✅ | [03-новый-водитель-в-проверке-⛔.png](shots/iphone-se-(3rd-generation)/admin_blacklist_desktop-1280/03-новый-водитель-в-проверке-⛔.png) |
| admin_blacklist_desktop-1280 | 04-чёрный-список-ручная-блокировка | ✅ | [04-чёрный-список-ручная-блокировка.png](shots/iphone-se-(3rd-generation)/admin_blacklist_desktop-1280/04-чёрный-список-ручная-блокировка.png) |
| admin_blacklist_desktop-1280 | 05-чёрный-список-снятие | ✅ | [05-чёрный-список-снятие.png](shots/iphone-se-(3rd-generation)/admin_blacklist_desktop-1280/05-чёрный-список-снятие.png) |
| admin_complaint_desktop-1280 | 01-вход-и-список | ✅ | [01-вход-и-список.png](shots/iphone-se-(3rd-generation)/admin_complaint_desktop-1280/01-вход-и-список.png) |
| admin_complaint_desktop-1280 | 02-жалоба-в-новых | ✅ | [02-жалоба-в-новых.png](shots/iphone-se-(3rd-generation)/admin_complaint_desktop-1280/02-жалоба-в-новых.png) |
| admin_complaint_desktop-1280 | 03-взять-в-работу | ✅ | [03-взять-в-работу.png](shots/iphone-se-(3rd-generation)/admin_complaint_desktop-1280/03-взять-в-работу.png) |
| admin_complaint_desktop-1280 | 04-решение-без-ответа-недоступно | ✅ | [04-решение-без-ответа-недоступно.png](shots/iphone-se-(3rd-generation)/admin_complaint_desktop-1280/04-решение-без-ответа-недоступно.png) |
| admin_complaint_desktop-1280 | 05-решение-с-ответом | ✅ | [05-решение-с-ответом.png](shots/iphone-se-(3rd-generation)/admin_complaint_desktop-1280/05-решение-с-ответом.png) |
| admin_cards_desktop-1280 | 01-вход | ✅ | [01-вход.png](shots/iphone-se-(3rd-generation)/admin_cards_desktop-1280/01-вход.png) |
| admin_cards_desktop-1280 | 02-карточка-водителя | ✅ | [02-карточка-водителя.png](shots/iphone-se-(3rd-generation)/admin_cards_desktop-1280/02-карточка-водителя.png) |
| admin_cards_desktop-1280 | 03-карточка-компании | ✅ | [03-карточка-компании.png](shots/iphone-se-(3rd-generation)/admin_cards_desktop-1280/03-карточка-компании.png) |
| admin_cards_desktop-1280 | 04-карточка-груза | ✅ | [04-карточка-груза.png](shots/iphone-se-(3rd-generation)/admin_cards_desktop-1280/04-карточка-груза.png) |
| admin_cards_desktop-1280 | 05-карточка-сделки | ✅ | [05-карточка-сделки.png](shots/iphone-se-(3rd-generation)/admin_cards_desktop-1280/05-карточка-сделки.png) |
| admin_cards_desktop-1280 | 06-правка-имени-не-меняет-госномер | ✅ | [06-правка-имени-не-меняет-госномер.png](shots/iphone-se-(3rd-generation)/admin_cards_desktop-1280/06-правка-имени-не-меняет-госномер.png) |
| admin_screens_desktop-1280 | 01-вход | ✅ | [01-вход.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/01-вход.png) |
| admin_screens_desktop-1280 | 02-dashboard | ✅ | [02-dashboard.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/02-dashboard.png) |
| admin_screens_desktop-1280 | 03-verification | ✅ | [03-verification.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/03-verification.png) |
| admin_screens_desktop-1280 | 04-complaints | ✅ | [04-complaints.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/04-complaints.png) |
| admin_screens_desktop-1280 | 05-drivers | ✅ | [05-drivers.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/05-drivers.png) |
| admin_screens_desktop-1280 | 06-companies | ✅ | [06-companies.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/06-companies.png) |
| admin_screens_desktop-1280 | 07-cargos | ✅ | [07-cargos.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/07-cargos.png) |
| admin_screens_desktop-1280 | 08-deals | ✅ | [08-deals.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/08-deals.png) |
| admin_screens_desktop-1280 | 09-search | ✅ | [09-search.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/09-search.png) |
| admin_screens_desktop-1280 | 10-more | ✅ | [10-more.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/10-more.png) |
| admin_screens_desktop-1280 | 11-audit | ✅ | [11-audit.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/11-audit.png) |
| admin_screens_desktop-1280 | 12-settings | ✅ | [12-settings.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/12-settings.png) |
| admin_screens_desktop-1280 | 13-reference | ✅ | [13-reference.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/13-reference.png) |
| admin_screens_desktop-1280 | 14-route-prices | ✅ | [14-route-prices.png](shots/iphone-se-(3rd-generation)/admin_screens_desktop-1280/14-route-prices.png) |
| admin_dispute_desktop-1280 | 01-спор-через-API | ✅ | [01-спор-через-API.png](shots/iphone-se-(3rd-generation)/admin_dispute_desktop-1280/01-спор-через-API.png) |
| admin_dispute_desktop-1280 | 02-вход | ✅ | [02-вход.png](shots/iphone-se-(3rd-generation)/admin_dispute_desktop-1280/02-вход.png) |
| admin_dispute_desktop-1280 | 03-спор-в-требует-внимания | ✅ | [03-спор-в-требует-внимания.png](shots/iphone-se-(3rd-generation)/admin_dispute_desktop-1280/03-спор-в-требует-внимания.png) |
| admin_dispute_desktop-1280 | 04-карточка-сделки-вернуть-в-путь | ✅ | [04-карточка-сделки-вернуть-в-путь.png](shots/iphone-se-(3rd-generation)/admin_dispute_desktop-1280/04-карточка-сделки-вернуть-в-путь.png) |
| admin_summary_mobile-390 | 01-вход-и-сводка | ✅ | [01-вход-и-сводка.png](shots/iphone-se-(3rd-generation)/admin_summary_mobile-390/01-вход-и-сводка.png) |
| admin_summary_mobile-390 | 02-плитка-водители | ✅ | [02-плитка-водители.png](shots/iphone-se-(3rd-generation)/admin_summary_mobile-390/02-плитка-водители.png) |
| admin_summary_mobile-390 | 03-плитка-компании | ✅ | [03-плитка-компании.png](shots/iphone-se-(3rd-generation)/admin_summary_mobile-390/03-плитка-компании.png) |
| admin_summary_mobile-390 | 04-плитка-активные-грузы | ✅ | [04-плитка-активные-грузы.png](shots/iphone-se-(3rd-generation)/admin_summary_mobile-390/04-плитка-активные-грузы.png) |
| admin_summary_mobile-390 | 05-плитка-документы-на-проверке | ✅ | [05-плитка-документы-на-проверке.png](shots/iphone-se-(3rd-generation)/admin_summary_mobile-390/05-плитка-документы-на-проверке.png) |
| admin_summary_mobile-390 | 06-плитка-открытые-жалобы | ✅ | [06-плитка-открытые-жалобы.png](shots/iphone-se-(3rd-generation)/admin_summary_mobile-390/06-плитка-открытые-жалобы.png) |
| admin_summary_mobile-390 | 07-требует-внимания-ведёт-в-списки | ✅ | [07-требует-внимания-ведёт-в-списки.png](shots/iphone-se-(3rd-generation)/admin_summary_mobile-390/07-требует-внимания-ведёт-в-списки.png) |
| admin_summary_mobile-390 | 08-сводка-по-городам | ✅ | [08-сводка-по-городам.png](shots/iphone-se-(3rd-generation)/admin_summary_mobile-390/08-сводка-по-городам.png) |
| admin_verification_mobile | 01-очередь | ✅ | [01-очередь.png](shots/iphone-se-(3rd-generation)/admin_verification_mobile/01-очередь.png) |
| admin_blacklist_mobile-390 | 01-вход | ✅ | [01-вход.png](shots/iphone-se-(3rd-generation)/admin_blacklist_mobile-390/01-вход.png) |
| admin_blacklist_mobile-390 | 02-новый-водитель-в-проверке-⛔ | ✅ | [02-новый-водитель-в-проверке-⛔.png](shots/iphone-se-(3rd-generation)/admin_blacklist_mobile-390/02-новый-водитель-в-проверке-⛔.png) |
| admin_blacklist_mobile-390 | 03-чёрный-список-ручная-блокировка | ✅ | [03-чёрный-список-ручная-блокировка.png](shots/iphone-se-(3rd-generation)/admin_blacklist_mobile-390/03-чёрный-список-ручная-блокировка.png) |
| admin_blacklist_mobile-390 | 04-чёрный-список-снятие | ✅ | [04-чёрный-список-снятие.png](shots/iphone-se-(3rd-generation)/admin_blacklist_mobile-390/04-чёрный-список-снятие.png) |
| admin_complaint_mobile-390 | 01-вход-и-список | ✅ | [01-вход-и-список.png](shots/iphone-se-(3rd-generation)/admin_complaint_mobile-390/01-вход-и-список.png) |
| admin_complaint_mobile-390 | 02-закрытые-на-телефоне | ✅ | [02-закрытые-на-телефоне.png](shots/iphone-se-(3rd-generation)/admin_complaint_mobile-390/02-закрытые-на-телефоне.png) |
| admin_cards_mobile-390 | 01-вход | ✅ | [01-вход.png](shots/iphone-se-(3rd-generation)/admin_cards_mobile-390/01-вход.png) |
| admin_cards_mobile-390 | 02-карточка-водителя | ✅ | [02-карточка-водителя.png](shots/iphone-se-(3rd-generation)/admin_cards_mobile-390/02-карточка-водителя.png) |
| admin_cards_mobile-390 | 03-карточка-компании | ✅ | [03-карточка-компании.png](shots/iphone-se-(3rd-generation)/admin_cards_mobile-390/03-карточка-компании.png) |
| admin_cards_mobile-390 | 04-карточка-груза | ✅ | [04-карточка-груза.png](shots/iphone-se-(3rd-generation)/admin_cards_mobile-390/04-карточка-груза.png) |
| admin_cards_mobile-390 | 05-карточка-сделки | ✅ | [05-карточка-сделки.png](shots/iphone-se-(3rd-generation)/admin_cards_mobile-390/05-карточка-сделки.png) |
| admin_screens_mobile-390 | 01-вход | ✅ | [01-вход.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/01-вход.png) |
| admin_screens_mobile-390 | 02-dashboard | ✅ | [02-dashboard.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/02-dashboard.png) |
| admin_screens_mobile-390 | 03-verification | ✅ | [03-verification.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/03-verification.png) |
| admin_screens_mobile-390 | 04-complaints | ✅ | [04-complaints.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/04-complaints.png) |
| admin_screens_mobile-390 | 05-drivers | ✅ | [05-drivers.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/05-drivers.png) |
| admin_screens_mobile-390 | 06-companies | ✅ | [06-companies.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/06-companies.png) |
| admin_screens_mobile-390 | 07-cargos | ✅ | [07-cargos.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/07-cargos.png) |
| admin_screens_mobile-390 | 08-deals | ✅ | [08-deals.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/08-deals.png) |
| admin_screens_mobile-390 | 09-search | ✅ | [09-search.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/09-search.png) |
| admin_screens_mobile-390 | 10-more | ✅ | [10-more.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/10-more.png) |
| admin_screens_mobile-390 | 11-audit | ✅ | [11-audit.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/11-audit.png) |
| admin_screens_mobile-390 | 12-settings | ✅ | [12-settings.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/12-settings.png) |
| admin_screens_mobile-390 | 13-reference | ✅ | [13-reference.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/13-reference.png) |
| admin_screens_mobile-390 | 14-route-prices | ✅ | [14-route-prices.png](shots/iphone-se-(3rd-generation)/admin_screens_mobile-390/14-route-prices.png) |
| admin_dispute_mobile-390 | 01-спор-через-API | ✅ | [01-спор-через-API.png](shots/iphone-se-(3rd-generation)/admin_dispute_mobile-390/01-спор-через-API.png) |
| admin_dispute_mobile-390 | 02-вход | ✅ | [02-вход.png](shots/iphone-se-(3rd-generation)/admin_dispute_mobile-390/02-вход.png) |
| admin_dispute_mobile-390 | 03-спор-в-требует-внимания | ✅ | [03-спор-в-требует-внимания.png](shots/iphone-se-(3rd-generation)/admin_dispute_mobile-390/03-спор-в-требует-внимания.png) |
| admin_dispute_mobile-390 | 04-карточка-сделки-вернуть-в-путь | ✅ | [04-карточка-сделки-вернуть-в-путь.png](shots/iphone-se-(3rd-generation)/admin_dispute_mobile-390/04-карточка-сделки-вернуть-в-путь.png) |
| logist_publish | 01-вход-одобренной-компании | ✅ | [01-вход-одобренной-компании.png](shots/iphone-se-(3rd-generation)/logist_publish/01-вход-одобренной-компании.png) |
| logist_publish | 02-форма-груза | ✅ | [02-форма-груза.png](shots/iphone-se-(3rd-generation)/logist_publish/02-форма-груза.png) |
| logist_publish | 03-город-погрузки-обязателен | ✅ | [03-город-погрузки-обязателен.png](shots/iphone-se-(3rd-generation)/logist_publish/03-город-погрузки-обязателен.png) |
| logist_publish | 04-выбор-города-погрузки-и-категории | ✅ | [04-выбор-города-погрузки-и-категории.png](shots/iphone-se-(3rd-generation)/logist_publish/04-выбор-города-погрузки-и-категории.png) |
| logist_publish | 05-публикация | ✅ | [05-публикация.png](shots/iphone-se-(3rd-generation)/logist_publish/05-публикация.png) |
| logist_publish | 06-водитель-откликается | ✅ | [06-водитель-откликается.png](shots/iphone-se-(3rd-generation)/logist_publish/06-водитель-откликается.png) |
| logist_publish | 07-выбор-водителя-в-откликах | ✅ | [07-выбор-водителя-в-откликах.png](shots/iphone-se-(3rd-generation)/logist_publish/07-выбор-водителя-в-откликах.png) |
| logist_publish | 08-отклик-ведёт-в-сделку | ✅ | [08-отклик-ведёт-в-сделку.png](shots/iphone-se-(3rd-generation)/logist_publish/08-отклик-ведёт-в-сделку.png) |
| logist_publish | 09-сделка-в-списке | ✅ | [09-сделка-в-списке.png](shots/iphone-se-(3rd-generation)/logist_publish/09-сделка-в-списке.png) |
| all_screens | 01-role-select | ✅ | [01-role-select.png](shots/iphone-se-(3rd-generation)/all_screens/01-role-select.png) |
| all_screens | 02-login-driver | ✅ | [02-login-driver.png](shots/iphone-se-(3rd-generation)/all_screens/02-login-driver.png) |
| all_screens | 03-login-company | ✅ | [03-login-company.png](shots/iphone-se-(3rd-generation)/all_screens/03-login-company.png) |
| all_screens | 04-login-company-register | ✅ | [04-login-company-register.png](shots/iphone-se-(3rd-generation)/all_screens/04-login-company-register.png) |
| all_screens | 05-login-company-forgot | ✅ | [05-login-company-forgot.png](shots/iphone-se-(3rd-generation)/all_screens/05-login-company-forgot.png) |
| all_screens | 06-invite | ✅ | [06-invite.png](shots/iphone-se-(3rd-generation)/all_screens/06-invite.png) |
| all_screens | 07-role-select-2 | ✅ | [07-role-select-2.png](shots/iphone-se-(3rd-generation)/all_screens/07-role-select-2.png) |
| all_screens | 08-вход-водителя | ✅ | [08-вход-водителя.png](shots/iphone-se-(3rd-generation)/all_screens/08-вход-водителя.png) |
| all_screens | 09-driver-feed | ✅ | [09-driver-feed.png](shots/iphone-se-(3rd-generation)/all_screens/09-driver-feed.png) |
| all_screens | 10-driver-chats | ✅ | [10-driver-chats.png](shots/iphone-se-(3rd-generation)/all_screens/10-driver-chats.png) |
| all_screens | 11-driver-deals | ✅ | [11-driver-deals.png](shots/iphone-se-(3rd-generation)/all_screens/11-driver-deals.png) |
| all_screens | 12-driver-profile | ✅ | [12-driver-profile.png](shots/iphone-se-(3rd-generation)/all_screens/12-driver-profile.png) |
| all_screens | 13-driver-cargo | ✅ | [13-driver-cargo.png](shots/iphone-se-(3rd-generation)/all_screens/13-driver-cargo.png) |
| all_screens | 14-driver-setup | ✅ | [14-driver-setup.png](shots/iphone-se-(3rd-generation)/all_screens/14-driver-setup.png) |
| all_screens | 15-driver-register | ✅ | [15-driver-register.png](shots/iphone-se-(3rd-generation)/all_screens/15-driver-register.png) |
| all_screens | 16-driver-verification | ✅ | [16-driver-verification.png](shots/iphone-se-(3rd-generation)/all_screens/16-driver-verification.png) |
| all_screens | 17-driver-garage | ✅ | [17-driver-garage.png](shots/iphone-se-(3rd-generation)/all_screens/17-driver-garage.png) |
| all_screens | 18-driver-responses | ✅ | [18-driver-responses.png](shots/iphone-se-(3rd-generation)/all_screens/18-driver-responses.png) |
| all_screens | 19-devices | ✅ | [19-devices.png](shots/iphone-se-(3rd-generation)/all_screens/19-devices.png) |
| all_screens | 20-notification-settings | ✅ | [20-notification-settings.png](shots/iphone-se-(3rd-generation)/all_screens/20-notification-settings.png) |
| all_screens | 21-about | ✅ | [21-about.png](shots/iphone-se-(3rd-generation)/all_screens/21-about.png) |
| all_screens | 22-deal-detail | ✅ | [22-deal-detail.png](shots/iphone-se-(3rd-generation)/all_screens/22-deal-detail.png) |
| all_screens | 23-выход-водителя | ✅ | [23-выход-водителя.png](shots/iphone-se-(3rd-generation)/all_screens/23-выход-водителя.png) |
| all_screens | 24-вход-логиста | ✅ | [24-вход-логиста.png](shots/iphone-se-(3rd-generation)/all_screens/24-вход-логиста.png) |
| all_screens | 25-company-cargos | ✅ | [25-company-cargos.png](shots/iphone-se-(3rd-generation)/all_screens/25-company-cargos.png) |
| all_screens | 26-company-drivers | ✅ | [26-company-drivers.png](shots/iphone-se-(3rd-generation)/all_screens/26-company-drivers.png) |
| all_screens | 27-company-chats | ✅ | [27-company-chats.png](shots/iphone-se-(3rd-generation)/all_screens/27-company-chats.png) |
| all_screens | 28-company-deals | ✅ | [28-company-deals.png](shots/iphone-se-(3rd-generation)/all_screens/28-company-deals.png) |
| all_screens | 29-company-profile | ✅ | [29-company-profile.png](shots/iphone-se-(3rd-generation)/all_screens/29-company-profile.png) |
| all_screens | 30-company-cargo-new | ✅ | [30-company-cargo-new.png](shots/iphone-se-(3rd-generation)/all_screens/30-company-cargo-new.png) |
| all_screens | 31-company-cargo-responses | ✅ | [31-company-cargo-responses.png](shots/iphone-se-(3rd-generation)/all_screens/31-company-cargo-responses.png) |
| all_screens | 32-company-deal-detail | ✅ | [32-company-deal-detail.png](shots/iphone-se-(3rd-generation)/all_screens/32-company-deal-detail.png) |
| all_screens | 33-company-chat | ✅ | [33-company-chat.png](shots/iphone-se-(3rd-generation)/all_screens/33-company-chat.png) |
| all_screens | 34-company-devices | ✅ | [34-company-devices.png](shots/iphone-se-(3rd-generation)/all_screens/34-company-devices.png) |
| all_screens | 35-company-notification-settings | ✅ | [35-company-notification-settings.png](shots/iphone-se-(3rd-generation)/all_screens/35-company-notification-settings.png) |
| all_screens | 36-company-about | ✅ | [36-company-about.png](shots/iphone-se-(3rd-generation)/all_screens/36-company-about.png) |

## android:lubao_e2e_360

| Сценарий | Результат | Детали |
|---|---|---|
| админка: API-смоук (10, 13, 14) | ✅ | 158 проверок |
| правило свежести анонса (040, п.4): день приезда, 12 ч, гашение, геозона | ✅ | 20 проверок |
| driver_flow_test | ❌ TIMEOUT | лимит 20 мин — процесс убит (см. android-lubao_e2e_360-driver_flow_test.log) |
| driver_deal_test | ✅ | +1: All tests passed |
| logist_drivers_test | ✅ | +1: All tests passed |
| garage_vehicle_test | ✅ | +1: All tests passed |
| company_register_test | ✅ | +1: All tests passed |
| driver_register_iin_test | ✅ | +1: All tests passed |
| telegram_login_test | ✅ | +1: All tests passed |
| админка в Chrome (10–14, ширина 1280 и 390) | ✅ | 14 passed |
| logist_publish_test | ✅ | +1: All tests passed |
| all_screens_test | ✅ | +1: All tests passed |

### Шаги

| Сценарий | Шаг | Результат | Скриншот / ошибка |
|---|---|---|---|
| driver_deal | 01-вход | ✅ | [01-вход.png](shots/android-lubao_e2e_360/driver_deal/01-вход.png) |
| driver_deal | 02-отклики-на-три-груза | ✅ | [02-отклики-на-три-груза.png](shots/android-lubao_e2e_360/driver_deal/02-отклики-на-три-груза.png) |
| driver_deal | 03-логист-выбирает-через-API | ✅ | [03-логист-выбирает-через-API.png](shots/android-lubao_e2e_360/driver_deal/03-логист-выбирает-через-API.png) |
| driver_deal | 04-груз-со-сделкой-исчез-из-ленты | ✅ | [04-груз-со-сделкой-исчез-из-ленты.png](shots/android-lubao_e2e_360/driver_deal/04-груз-со-сделкой-исчез-из-ленты.png) |
| driver_deal | 05-сделка1-загружен-без-согласия-на-трекинг | ✅ | [05-сделка1-загружен-без-согласия-на-трекинг.png](shots/android-lubao_e2e_360/driver_deal/05-сделка1-загружен-без-согласия-на-трекинг.png) |
| driver_deal | 06-логист-открыл-документы-водитель-видит | ✅ | [06-логист-открыл-документы-водитель-видит.png](shots/android-lubao_e2e_360/driver_deal/06-логист-открыл-документы-водитель-видит.png) |
| driver_deal | 07-сделка2-одна-перевозка-за-раз | ✅ | [07-сделка2-одна-перевозка-за-раз.png](shots/android-lubao_e2e_360/driver_deal/07-сделка2-одна-перевозка-за-раз.png) |
| driver_deal | 08-доставлено-ищете-груз-отсюда | ✅ | [08-доставлено-ищете-груз-отсюда.png](shots/android-lubao_e2e_360/driver_deal/08-доставлено-ищете-груз-отсюда.png) |
| driver_deal | 09-сделка2-согласие-на-трекинг-и-пауза | ✅ | [09-сделка2-согласие-на-трекинг-и-пауза.png](shots/android-lubao_e2e_360/driver_deal/09-сделка2-согласие-на-трекинг-и-пауза.png) |
| driver_deal | 10-сделка3-одна-перевозка-за-раз | ✅ | [10-сделка3-одна-перевозка-за-раз.png](shots/android-lubao_e2e_360/driver_deal/10-сделка3-одна-перевозка-за-раз.png) |
| driver_deal | 11-отмена-причина-из-списка | ✅ | [11-отмена-причина-из-списка.png](shots/android-lubao_e2e_360/driver_deal/11-отмена-причина-из-списка.png) |
| driver_deal | 12-отмена-после-загрузки-и-жалоба | ✅ | [12-отмена-после-загрузки-и-жалоба.png](shots/android-lubao_e2e_360/driver_deal/12-отмена-после-загрузки-и-жалоба.png) |
| logist_drivers | 01-вход-логиста | ✅ | [01-вход-логиста.png](shots/android-lubao_e2e_360/logist_drivers/01-вход-логиста.png) |
| logist_drivers | 02-водители-экран | ✅ | [02-водители-экран.png](shots/android-lubao_e2e_360/logist_drivers/02-водители-экран.png) |
| logist_drivers | 03-кто-свободен-выбор-города-алматы | ✅ | [03-кто-свободен-выбор-города-алматы.png](shots/android-lubao_e2e_360/logist_drivers/03-кто-свободен-выбор-города-алматы.png) |
| logist_drivers | 04-кто-свободен-обратно-хоргос | ✅ | [04-кто-свободен-обратно-хоргос.png](shots/android-lubao_e2e_360/logist_drivers/04-кто-свободен-обратно-хоргос.png) |
| logist_drivers | 05-фильтр-проверенные | ✅ | [05-фильтр-проверенные.png](shots/android-lubao_e2e_360/logist_drivers/05-фильтр-проверенные.png) |
| logist_drivers | 06-чат-с-водителем | ✅ | [06-чат-с-водителем.png](shots/android-lubao_e2e_360/logist_drivers/06-чат-с-водителем.png) |
| logist_drivers | 07-предложить-груз | ✅ | [07-предложить-груз.png](shots/android-lubao_e2e_360/logist_drivers/07-предложить-груз.png) |
| logist_drivers | 08-пригласить-ждём-согласия | ✅ | [08-пригласить-ждём-согласия.png](shots/android-lubao_e2e_360/logist_drivers/08-пригласить-ждём-согласия.png) |
| logist_drivers | 09-выход-логиста | ✅ | [09-выход-логиста.png](shots/android-lubao_e2e_360/logist_drivers/09-выход-логиста.png) |
| logist_drivers | 10-вход-водителя-D3 | ✅ | [10-вход-водителя-D3.png](shots/android-lubao_e2e_360/logist_drivers/10-вход-водителя-D3.png) |
| logist_drivers | 11-водитель-видит-приглашение-и-соглашается | ✅ | [11-водитель-видит-приглашение-и-соглашается.png](shots/android-lubao_e2e_360/logist_drivers/11-водитель-видит-приглашение-и-соглашается.png) |
| logist_drivers | 12-фото-профиля-из-селфи | ✅ | [12-фото-профиля-из-селфи.png](shots/android-lubao_e2e_360/logist_drivers/12-фото-профиля-из-селфи.png) |
| logist_drivers | 13-выход-водителя | ✅ | [13-выход-водителя.png](shots/android-lubao_e2e_360/logist_drivers/13-выход-водителя.png) |
| logist_drivers | 14-логист-видит-фото-водителя | ✅ | [14-логист-видит-фото-водителя.png](shots/android-lubao_e2e_360/logist_drivers/14-логист-видит-фото-водителя.png) |
| logist_drivers | 15-логист-выбирает-согласившегося | ✅ | [15-логист-выбирает-согласившегося.png](shots/android-lubao_e2e_360/logist_drivers/15-логист-выбирает-согласившегося.png) |
| logist_drivers | 16-выход-логиста-2 | ✅ | [16-выход-логиста-2.png](shots/android-lubao_e2e_360/logist_drivers/16-выход-логиста-2.png) |
| logist_drivers | 17-вход-водителя-D3-снова | ✅ | [17-вход-водителя-D3-снова.png](shots/android-lubao_e2e_360/logist_drivers/17-вход-водителя-D3-снова.png) |
| logist_drivers | 18-чат-водителя-подтверждение | ✅ | [18-чат-водителя-подтверждение.png](shots/android-lubao_e2e_360/logist_drivers/18-чат-водителя-подтверждение.png) |
| logist_drivers | 19-загружен-в-карточке-чата | ✅ | [19-загружен-в-карточке-чата.png](shots/android-lubao_e2e_360/logist_drivers/19-загружен-в-карточке-чата.png) |
| logist_drivers | 20-анонс-погас-после-подтверждения | ✅ | [20-анонс-погас-после-подтверждения.png](shots/android-lubao_e2e_360/logist_drivers/20-анонс-погас-после-подтверждения.png) |
| garage_vehicle | 01-вход-водителя | ✅ | [01-вход-водителя.png](shots/android-lubao_e2e_360/garage_vehicle/01-вход-водителя.png) |
| garage_vehicle | 02-гараж | ✅ | [02-гараж.png](shots/android-lubao_e2e_360/garage_vehicle/02-гараж.png) |
| garage_vehicle | 03-шторка-добавления | ✅ | [03-шторка-добавления.png](shots/android-lubao_e2e_360/garage_vehicle/03-шторка-добавления.png) |
| garage_vehicle | 04-форма-цистерны-без-паллет | ✅ | [04-форма-цистерны-без-паллет.png](shots/android-lubao_e2e_360/garage_vehicle/04-форма-цистерны-без-паллет.png) |
| garage_vehicle | 05-поля-прицепа | ✅ | [05-поля-прицепа.png](shots/android-lubao_e2e_360/garage_vehicle/05-поля-прицепа.png) |
| garage_vehicle | 06-фото-техпаспорта | ✅ | [06-фото-техпаспорта.png](shots/android-lubao_e2e_360/garage_vehicle/06-фото-техпаспорта.png) |
| garage_vehicle | 07-отправка-на-проверку | ✅ | [07-отправка-на-проверку.png](shots/android-lubao_e2e_360/garage_vehicle/07-отправка-на-проверку.png) |
| garage_vehicle | 08-документ-распознан-OCR | ✅ | [08-документ-распознан-OCR.png](shots/android-lubao_e2e_360/garage_vehicle/08-документ-распознан-OCR.png) |
| company_register | 01-форма-регистрации | ✅ | [01-форма-регистрации.png](shots/android-lubao_e2e_360/company_register/01-форма-регистрации.png) |
| company_register | 02-оферта-галочка | ✅ | [02-оферта-галочка.png](shots/android-lubao_e2e_360/company_register/02-оферта-галочка.png) |
| company_register | 03-отправка-регистрации | ✅ | [03-отправка-регистрации.png](shots/android-lubao_e2e_360/company_register/03-отправка-регистрации.png) |
| company_register | 04-баннер-в-профиле | ✅ | [04-баннер-в-профиле.png](shots/android-lubao_e2e_360/company_register/04-баннер-в-профиле.png) |
| company_register | 05-загрузка-свидетельства | ✅ | [05-загрузка-свидетельства.png](shots/android-lubao_e2e_360/company_register/05-загрузка-свидетельства.png) |
| company_register | 06-публикация-заблокирована | ✅ | [06-публикация-заблокирована.png](shots/android-lubao_e2e_360/company_register/06-публикация-заблокирована.png) |
| driver_register_iin | 01-A-вход-нового-номера | ✅ | [01-A-вход-нового-номера.png](shots/android-lubao_e2e_360/driver_register_iin/01-A-вход-нового-номера.png) |
| driver_register_iin | 02-A-мастер-шаг1-имя-город | ✅ | [02-A-мастер-шаг1-имя-город.png](shots/android-lubao_e2e_360/driver_register_iin/02-A-мастер-шаг1-имя-город.png) |
| driver_register_iin | 03-A-мастер-шаг2-кузов | ✅ | [03-A-мастер-шаг2-кузов.png](shots/android-lubao_e2e_360/driver_register_iin/03-A-мастер-шаг2-кузов.png) |
| driver_register_iin | 04-A-мастер-шаг3-готово | ✅ | [04-A-мастер-шаг3-готово.png](shots/android-lubao_e2e_360/driver_register_iin/04-A-мастер-шаг3-готово.png) |
| driver_register_iin | 05-A-где-вы-сейчас | ✅ | [05-A-где-вы-сейчас.png](shots/android-lubao_e2e_360/driver_register_iin/05-A-где-вы-сейчас.png) |
| driver_register_iin | 06-A-плашка-добавьте-машину | ✅ | [06-A-плашка-добавьте-машину.png](shots/android-lubao_e2e_360/driver_register_iin/06-A-плашка-добавьте-машину.png) |
| driver_register_iin | 07-A-гараж-пуст-после-регистрации | ✅ | [07-A-гараж-пуст-после-регистрации.png](shots/android-lubao_e2e_360/driver_register_iin/07-A-гараж-пуст-после-регистрации.png) |
| driver_register_iin | 08-A-новичок-откликается-без-проверки | ✅ | [08-A-новичок-откликается-без-проверки.png](shots/android-lubao_e2e_360/driver_register_iin/08-A-новичок-откликается-без-проверки.png) |
| driver_register_iin | 09-A-телефон-после-отклика | ✅ | [09-A-телефон-после-отклика.png](shots/android-lubao_e2e_360/driver_register_iin/09-A-телефон-после-отклика.png) |
| driver_register_iin | 10-A-селфи-и-права | ✅ | [10-A-селфи-и-права.png](shots/android-lubao_e2e_360/driver_register_iin/10-A-селфи-и-права.png) |
| driver_register_iin | 11-A-ИИН-распознан | ✅ | [11-A-ИИН-распознан.png](shots/android-lubao_e2e_360/driver_register_iin/11-A-ИИН-распознан.png) |
| driver_register_iin | 12-выход-A | ✅ | [12-выход-A.png](shots/android-lubao_e2e_360/driver_register_iin/12-выход-A.png) |
| driver_register_iin | 13-B-вход-нового-номера | ✅ | [13-B-вход-нового-номера.png](shots/android-lubao_e2e_360/driver_register_iin/13-B-вход-нового-номера.png) |
| driver_register_iin | 14-B-мастер-шаг1-имя-город | ✅ | [14-B-мастер-шаг1-имя-город.png](shots/android-lubao_e2e_360/driver_register_iin/14-B-мастер-шаг1-имя-город.png) |
| driver_register_iin | 15-B-мастер-шаг2-кузов | ✅ | [15-B-мастер-шаг2-кузов.png](shots/android-lubao_e2e_360/driver_register_iin/15-B-мастер-шаг2-кузов.png) |
| driver_register_iin | 16-B-мастер-шаг3-готово | ✅ | [16-B-мастер-шаг3-готово.png](shots/android-lubao_e2e_360/driver_register_iin/16-B-мастер-шаг3-готово.png) |
| driver_register_iin | 17-B-где-вы-сейчас | ✅ | [17-B-где-вы-сейчас.png](shots/android-lubao_e2e_360/driver_register_iin/17-B-где-вы-сейчас.png) |
| driver_register_iin | 18-B-селфи-и-права | ✅ | [18-B-селфи-и-права.png](shots/android-lubao_e2e_360/driver_register_iin/18-B-селфи-и-права.png) |
| driver_register_iin | 19-B-ИИН-распознан | ✅ | [19-B-ИИН-распознан.png](shots/android-lubao_e2e_360/driver_register_iin/19-B-ИИН-распознан.png) |
| telegram_login | 01-кнопка-войти-через-telegram | ✅ | [01-кнопка-войти-через-telegram.png](shots/android-lubao_e2e_360/telegram_login/01-кнопка-войти-через-telegram.png) |
| telegram_login | 02-чужой-контакт-не-принимается | ✅ | [02-чужой-контакт-не-принимается.png](shots/android-lubao_e2e_360/telegram_login/02-чужой-контакт-не-принимается.png) |
| telegram_login | 03-свой-номер-вход-и-регистрация | ✅ | [03-свой-номер-вход-и-регистрация.png](shots/android-lubao_e2e_360/telegram_login/03-свой-номер-вход-и-регистрация.png) |
| admin_summary_desktop-1280 | 01-вход-и-сводка | ✅ | [01-вход-и-сводка.png](shots/android-lubao_e2e_360/admin_summary_desktop-1280/01-вход-и-сводка.png) |
| admin_summary_desktop-1280 | 02-плитка-водители | ✅ | [02-плитка-водители.png](shots/android-lubao_e2e_360/admin_summary_desktop-1280/02-плитка-водители.png) |
| admin_summary_desktop-1280 | 03-плитка-компании | ✅ | [03-плитка-компании.png](shots/android-lubao_e2e_360/admin_summary_desktop-1280/03-плитка-компании.png) |
| admin_summary_desktop-1280 | 04-плитка-активные-грузы | ✅ | [04-плитка-активные-грузы.png](shots/android-lubao_e2e_360/admin_summary_desktop-1280/04-плитка-активные-грузы.png) |
| admin_summary_desktop-1280 | 05-плитка-документы-на-проверке | ✅ | [05-плитка-документы-на-проверке.png](shots/android-lubao_e2e_360/admin_summary_desktop-1280/05-плитка-документы-на-проверке.png) |
| admin_summary_desktop-1280 | 06-плитка-открытые-жалобы | ✅ | [06-плитка-открытые-жалобы.png](shots/android-lubao_e2e_360/admin_summary_desktop-1280/06-плитка-открытые-жалобы.png) |
| admin_summary_desktop-1280 | 07-требует-внимания-ведёт-в-списки | ✅ | [07-требует-внимания-ведёт-в-списки.png](shots/android-lubao_e2e_360/admin_summary_desktop-1280/07-требует-внимания-ведёт-в-списки.png) |
| admin_summary_desktop-1280 | 08-сводка-по-городам | ✅ | [08-сводка-по-городам.png](shots/android-lubao_e2e_360/admin_summary_desktop-1280/08-сводка-по-городам.png) |
| admin_verification | 01-вход-и-очередь | ✅ | [01-вход-и-очередь.png](shots/android-lubao_e2e_360/admin_verification/01-вход-и-очередь.png) |
| admin_verification | 02-водитель-распознано | ✅ | [02-водитель-распознано.png](shots/android-lubao_e2e_360/admin_verification/02-водитель-распознано.png) |
| admin_verification | 03-одобрить-права-и-селфи | ✅ | [03-одобрить-права-и-селфи.png](shots/android-lubao_e2e_360/admin_verification/03-одобрить-права-и-селфи.png) |
| admin_verification | 04-подтвердить-водителя | ✅ | [04-подтвердить-водителя.png](shots/android-lubao_e2e_360/admin_verification/04-подтвердить-водителя.png) |
| admin_verification | 05-водитель-проверен-в-списке | ✅ | [05-водитель-проверен-в-списке.png](shots/android-lubao_e2e_360/admin_verification/05-водитель-проверен-в-списке.png) |
| admin_verification | 06-машина-техпаспорт-одобряется | ✅ | [06-машина-техпаспорт-одобряется.png](shots/android-lubao_e2e_360/admin_verification/06-машина-техпаспорт-одобряется.png) |
| admin_verification | 07-компания-подтверждается | ✅ | [07-компания-подтверждается.png](shots/android-lubao_e2e_360/admin_verification/07-компания-подтверждается.png) |
| admin_blacklist_desktop-1280 | 01-вход | ✅ | [01-вход.png](shots/android-lubao_e2e_360/admin_blacklist_desktop-1280/01-вход.png) |
| admin_blacklist_desktop-1280 | 02-блокировка-водителя-с-идентификаторами | ✅ | [02-блокировка-водителя-с-идентификаторами.png](shots/android-lubao_e2e_360/admin_blacklist_desktop-1280/02-блокировка-водителя-с-идентификаторами.png) |
| admin_blacklist_desktop-1280 | 03-новый-водитель-в-проверке-⛔ | ✅ | [03-новый-водитель-в-проверке-⛔.png](shots/android-lubao_e2e_360/admin_blacklist_desktop-1280/03-новый-водитель-в-проверке-⛔.png) |
| admin_blacklist_desktop-1280 | 04-чёрный-список-ручная-блокировка | ✅ | [04-чёрный-список-ручная-блокировка.png](shots/android-lubao_e2e_360/admin_blacklist_desktop-1280/04-чёрный-список-ручная-блокировка.png) |
| admin_blacklist_desktop-1280 | 05-чёрный-список-снятие | ✅ | [05-чёрный-список-снятие.png](shots/android-lubao_e2e_360/admin_blacklist_desktop-1280/05-чёрный-список-снятие.png) |
| admin_complaint_desktop-1280 | 01-вход-и-список | ✅ | [01-вход-и-список.png](shots/android-lubao_e2e_360/admin_complaint_desktop-1280/01-вход-и-список.png) |
| admin_complaint_desktop-1280 | 02-жалоба-в-новых | ✅ | [02-жалоба-в-новых.png](shots/android-lubao_e2e_360/admin_complaint_desktop-1280/02-жалоба-в-новых.png) |
| admin_complaint_desktop-1280 | 03-взять-в-работу | ✅ | [03-взять-в-работу.png](shots/android-lubao_e2e_360/admin_complaint_desktop-1280/03-взять-в-работу.png) |
| admin_complaint_desktop-1280 | 04-решение-без-ответа-недоступно | ✅ | [04-решение-без-ответа-недоступно.png](shots/android-lubao_e2e_360/admin_complaint_desktop-1280/04-решение-без-ответа-недоступно.png) |
| admin_complaint_desktop-1280 | 05-решение-с-ответом | ✅ | [05-решение-с-ответом.png](shots/android-lubao_e2e_360/admin_complaint_desktop-1280/05-решение-с-ответом.png) |
| admin_cards_desktop-1280 | 01-вход | ✅ | [01-вход.png](shots/android-lubao_e2e_360/admin_cards_desktop-1280/01-вход.png) |
| admin_cards_desktop-1280 | 02-карточка-водителя | ✅ | [02-карточка-водителя.png](shots/android-lubao_e2e_360/admin_cards_desktop-1280/02-карточка-водителя.png) |
| admin_cards_desktop-1280 | 03-карточка-компании | ✅ | [03-карточка-компании.png](shots/android-lubao_e2e_360/admin_cards_desktop-1280/03-карточка-компании.png) |
| admin_cards_desktop-1280 | 04-карточка-груза | ✅ | [04-карточка-груза.png](shots/android-lubao_e2e_360/admin_cards_desktop-1280/04-карточка-груза.png) |
| admin_cards_desktop-1280 | 05-карточка-сделки | ✅ | [05-карточка-сделки.png](shots/android-lubao_e2e_360/admin_cards_desktop-1280/05-карточка-сделки.png) |
| admin_cards_desktop-1280 | 06-правка-имени-не-меняет-госномер | ✅ | [06-правка-имени-не-меняет-госномер.png](shots/android-lubao_e2e_360/admin_cards_desktop-1280/06-правка-имени-не-меняет-госномер.png) |
| admin_screens_desktop-1280 | 01-вход | ✅ | [01-вход.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/01-вход.png) |
| admin_screens_desktop-1280 | 02-dashboard | ✅ | [02-dashboard.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/02-dashboard.png) |
| admin_screens_desktop-1280 | 03-verification | ✅ | [03-verification.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/03-verification.png) |
| admin_screens_desktop-1280 | 04-complaints | ✅ | [04-complaints.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/04-complaints.png) |
| admin_screens_desktop-1280 | 05-drivers | ✅ | [05-drivers.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/05-drivers.png) |
| admin_screens_desktop-1280 | 06-companies | ✅ | [06-companies.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/06-companies.png) |
| admin_screens_desktop-1280 | 07-cargos | ✅ | [07-cargos.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/07-cargos.png) |
| admin_screens_desktop-1280 | 08-deals | ✅ | [08-deals.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/08-deals.png) |
| admin_screens_desktop-1280 | 09-search | ✅ | [09-search.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/09-search.png) |
| admin_screens_desktop-1280 | 10-more | ✅ | [10-more.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/10-more.png) |
| admin_screens_desktop-1280 | 11-audit | ✅ | [11-audit.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/11-audit.png) |
| admin_screens_desktop-1280 | 12-settings | ✅ | [12-settings.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/12-settings.png) |
| admin_screens_desktop-1280 | 13-reference | ✅ | [13-reference.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/13-reference.png) |
| admin_screens_desktop-1280 | 14-route-prices | ✅ | [14-route-prices.png](shots/android-lubao_e2e_360/admin_screens_desktop-1280/14-route-prices.png) |
| admin_dispute_desktop-1280 | 01-спор-через-API | ✅ | [01-спор-через-API.png](shots/android-lubao_e2e_360/admin_dispute_desktop-1280/01-спор-через-API.png) |
| admin_dispute_desktop-1280 | 02-вход | ✅ | [02-вход.png](shots/android-lubao_e2e_360/admin_dispute_desktop-1280/02-вход.png) |
| admin_dispute_desktop-1280 | 03-спор-в-требует-внимания | ✅ | [03-спор-в-требует-внимания.png](shots/android-lubao_e2e_360/admin_dispute_desktop-1280/03-спор-в-требует-внимания.png) |
| admin_dispute_desktop-1280 | 04-карточка-сделки-вернуть-в-путь | ✅ | [04-карточка-сделки-вернуть-в-путь.png](shots/android-lubao_e2e_360/admin_dispute_desktop-1280/04-карточка-сделки-вернуть-в-путь.png) |
| admin_summary_mobile-390 | 01-вход-и-сводка | ✅ | [01-вход-и-сводка.png](shots/android-lubao_e2e_360/admin_summary_mobile-390/01-вход-и-сводка.png) |
| admin_summary_mobile-390 | 02-плитка-водители | ✅ | [02-плитка-водители.png](shots/android-lubao_e2e_360/admin_summary_mobile-390/02-плитка-водители.png) |
| admin_summary_mobile-390 | 03-плитка-компании | ✅ | [03-плитка-компании.png](shots/android-lubao_e2e_360/admin_summary_mobile-390/03-плитка-компании.png) |
| admin_summary_mobile-390 | 04-плитка-активные-грузы | ✅ | [04-плитка-активные-грузы.png](shots/android-lubao_e2e_360/admin_summary_mobile-390/04-плитка-активные-грузы.png) |
| admin_summary_mobile-390 | 05-плитка-документы-на-проверке | ✅ | [05-плитка-документы-на-проверке.png](shots/android-lubao_e2e_360/admin_summary_mobile-390/05-плитка-документы-на-проверке.png) |
| admin_summary_mobile-390 | 06-плитка-открытые-жалобы | ✅ | [06-плитка-открытые-жалобы.png](shots/android-lubao_e2e_360/admin_summary_mobile-390/06-плитка-открытые-жалобы.png) |
| admin_summary_mobile-390 | 07-требует-внимания-ведёт-в-списки | ✅ | [07-требует-внимания-ведёт-в-списки.png](shots/android-lubao_e2e_360/admin_summary_mobile-390/07-требует-внимания-ведёт-в-списки.png) |
| admin_summary_mobile-390 | 08-сводка-по-городам | ✅ | [08-сводка-по-городам.png](shots/android-lubao_e2e_360/admin_summary_mobile-390/08-сводка-по-городам.png) |
| admin_verification_mobile | 01-очередь | ✅ | [01-очередь.png](shots/android-lubao_e2e_360/admin_verification_mobile/01-очередь.png) |
| admin_blacklist_mobile-390 | 01-вход | ✅ | [01-вход.png](shots/android-lubao_e2e_360/admin_blacklist_mobile-390/01-вход.png) |
| admin_blacklist_mobile-390 | 02-новый-водитель-в-проверке-⛔ | ✅ | [02-новый-водитель-в-проверке-⛔.png](shots/android-lubao_e2e_360/admin_blacklist_mobile-390/02-новый-водитель-в-проверке-⛔.png) |
| admin_blacklist_mobile-390 | 03-чёрный-список-ручная-блокировка | ✅ | [03-чёрный-список-ручная-блокировка.png](shots/android-lubao_e2e_360/admin_blacklist_mobile-390/03-чёрный-список-ручная-блокировка.png) |
| admin_blacklist_mobile-390 | 04-чёрный-список-снятие | ✅ | [04-чёрный-список-снятие.png](shots/android-lubao_e2e_360/admin_blacklist_mobile-390/04-чёрный-список-снятие.png) |
| admin_complaint_mobile-390 | 01-вход-и-список | ✅ | [01-вход-и-список.png](shots/android-lubao_e2e_360/admin_complaint_mobile-390/01-вход-и-список.png) |
| admin_complaint_mobile-390 | 02-закрытые-на-телефоне | ✅ | [02-закрытые-на-телефоне.png](shots/android-lubao_e2e_360/admin_complaint_mobile-390/02-закрытые-на-телефоне.png) |
| admin_cards_mobile-390 | 01-вход | ✅ | [01-вход.png](shots/android-lubao_e2e_360/admin_cards_mobile-390/01-вход.png) |
| admin_cards_mobile-390 | 02-карточка-водителя | ✅ | [02-карточка-водителя.png](shots/android-lubao_e2e_360/admin_cards_mobile-390/02-карточка-водителя.png) |
| admin_cards_mobile-390 | 03-карточка-компании | ✅ | [03-карточка-компании.png](shots/android-lubao_e2e_360/admin_cards_mobile-390/03-карточка-компании.png) |
| admin_cards_mobile-390 | 04-карточка-груза | ✅ | [04-карточка-груза.png](shots/android-lubao_e2e_360/admin_cards_mobile-390/04-карточка-груза.png) |
| admin_cards_mobile-390 | 05-карточка-сделки | ✅ | [05-карточка-сделки.png](shots/android-lubao_e2e_360/admin_cards_mobile-390/05-карточка-сделки.png) |
| admin_screens_mobile-390 | 01-вход | ✅ | [01-вход.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/01-вход.png) |
| admin_screens_mobile-390 | 02-dashboard | ✅ | [02-dashboard.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/02-dashboard.png) |
| admin_screens_mobile-390 | 03-verification | ✅ | [03-verification.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/03-verification.png) |
| admin_screens_mobile-390 | 04-complaints | ✅ | [04-complaints.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/04-complaints.png) |
| admin_screens_mobile-390 | 05-drivers | ✅ | [05-drivers.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/05-drivers.png) |
| admin_screens_mobile-390 | 06-companies | ✅ | [06-companies.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/06-companies.png) |
| admin_screens_mobile-390 | 07-cargos | ✅ | [07-cargos.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/07-cargos.png) |
| admin_screens_mobile-390 | 08-deals | ✅ | [08-deals.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/08-deals.png) |
| admin_screens_mobile-390 | 09-search | ✅ | [09-search.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/09-search.png) |
| admin_screens_mobile-390 | 10-more | ✅ | [10-more.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/10-more.png) |
| admin_screens_mobile-390 | 11-audit | ✅ | [11-audit.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/11-audit.png) |
| admin_screens_mobile-390 | 12-settings | ✅ | [12-settings.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/12-settings.png) |
| admin_screens_mobile-390 | 13-reference | ✅ | [13-reference.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/13-reference.png) |
| admin_screens_mobile-390 | 14-route-prices | ✅ | [14-route-prices.png](shots/android-lubao_e2e_360/admin_screens_mobile-390/14-route-prices.png) |
| admin_dispute_mobile-390 | 01-спор-через-API | ✅ | [01-спор-через-API.png](shots/android-lubao_e2e_360/admin_dispute_mobile-390/01-спор-через-API.png) |
| admin_dispute_mobile-390 | 02-вход | ✅ | [02-вход.png](shots/android-lubao_e2e_360/admin_dispute_mobile-390/02-вход.png) |
| admin_dispute_mobile-390 | 03-спор-в-требует-внимания | ✅ | [03-спор-в-требует-внимания.png](shots/android-lubao_e2e_360/admin_dispute_mobile-390/03-спор-в-требует-внимания.png) |
| admin_dispute_mobile-390 | 04-карточка-сделки-вернуть-в-путь | ✅ | [04-карточка-сделки-вернуть-в-путь.png](shots/android-lubao_e2e_360/admin_dispute_mobile-390/04-карточка-сделки-вернуть-в-путь.png) |
| logist_publish | 01-вход-одобренной-компании | ✅ | [01-вход-одобренной-компании.png](shots/android-lubao_e2e_360/logist_publish/01-вход-одобренной-компании.png) |
| logist_publish | 02-форма-груза | ✅ | [02-форма-груза.png](shots/android-lubao_e2e_360/logist_publish/02-форма-груза.png) |
| logist_publish | 03-город-погрузки-обязателен | ✅ | [03-город-погрузки-обязателен.png](shots/android-lubao_e2e_360/logist_publish/03-город-погрузки-обязателен.png) |
| logist_publish | 04-выбор-города-погрузки-и-категории | ✅ | [04-выбор-города-погрузки-и-категории.png](shots/android-lubao_e2e_360/logist_publish/04-выбор-города-погрузки-и-категории.png) |
| logist_publish | 05-публикация | ✅ | [05-публикация.png](shots/android-lubao_e2e_360/logist_publish/05-публикация.png) |
| logist_publish | 06-водитель-откликается | ✅ | [06-водитель-откликается.png](shots/android-lubao_e2e_360/logist_publish/06-водитель-откликается.png) |
| logist_publish | 07-выбор-водителя-в-откликах | ✅ | [07-выбор-водителя-в-откликах.png](shots/android-lubao_e2e_360/logist_publish/07-выбор-водителя-в-откликах.png) |
| logist_publish | 08-отклик-ведёт-в-сделку | ✅ | [08-отклик-ведёт-в-сделку.png](shots/android-lubao_e2e_360/logist_publish/08-отклик-ведёт-в-сделку.png) |
| logist_publish | 09-сделка-в-списке | ✅ | [09-сделка-в-списке.png](shots/android-lubao_e2e_360/logist_publish/09-сделка-в-списке.png) |
| all_screens | 01-role-select | ✅ | [01-role-select.png](shots/android-lubao_e2e_360/all_screens/01-role-select.png) |
| all_screens | 02-login-driver | ✅ | [02-login-driver.png](shots/android-lubao_e2e_360/all_screens/02-login-driver.png) |
| all_screens | 03-login-company | ✅ | [03-login-company.png](shots/android-lubao_e2e_360/all_screens/03-login-company.png) |
| all_screens | 04-login-company-register | ✅ | [04-login-company-register.png](shots/android-lubao_e2e_360/all_screens/04-login-company-register.png) |
| all_screens | 05-login-company-forgot | ✅ | [05-login-company-forgot.png](shots/android-lubao_e2e_360/all_screens/05-login-company-forgot.png) |
| all_screens | 06-invite | ✅ | [06-invite.png](shots/android-lubao_e2e_360/all_screens/06-invite.png) |
| all_screens | 07-role-select-2 | ✅ | [07-role-select-2.png](shots/android-lubao_e2e_360/all_screens/07-role-select-2.png) |
| all_screens | 08-вход-водителя | ✅ | [08-вход-водителя.png](shots/android-lubao_e2e_360/all_screens/08-вход-водителя.png) |
| all_screens | 09-driver-feed | ✅ | [09-driver-feed.png](shots/android-lubao_e2e_360/all_screens/09-driver-feed.png) |
| all_screens | 10-driver-chats | ✅ | [10-driver-chats.png](shots/android-lubao_e2e_360/all_screens/10-driver-chats.png) |
| all_screens | 11-driver-deals | ✅ | [11-driver-deals.png](shots/android-lubao_e2e_360/all_screens/11-driver-deals.png) |
| all_screens | 12-driver-profile | ✅ | [12-driver-profile.png](shots/android-lubao_e2e_360/all_screens/12-driver-profile.png) |
| all_screens | 13-driver-cargo | ✅ | [13-driver-cargo.png](shots/android-lubao_e2e_360/all_screens/13-driver-cargo.png) |
| all_screens | 14-driver-setup | ✅ | [14-driver-setup.png](shots/android-lubao_e2e_360/all_screens/14-driver-setup.png) |
| all_screens | 15-driver-register | ✅ | [15-driver-register.png](shots/android-lubao_e2e_360/all_screens/15-driver-register.png) |
| all_screens | 16-driver-verification | ✅ | [16-driver-verification.png](shots/android-lubao_e2e_360/all_screens/16-driver-verification.png) |
| all_screens | 17-driver-garage | ✅ | [17-driver-garage.png](shots/android-lubao_e2e_360/all_screens/17-driver-garage.png) |
| all_screens | 18-driver-responses | ✅ | [18-driver-responses.png](shots/android-lubao_e2e_360/all_screens/18-driver-responses.png) |
| all_screens | 19-devices | ✅ | [19-devices.png](shots/android-lubao_e2e_360/all_screens/19-devices.png) |
| all_screens | 20-notification-settings | ✅ | [20-notification-settings.png](shots/android-lubao_e2e_360/all_screens/20-notification-settings.png) |
| all_screens | 21-about | ✅ | [21-about.png](shots/android-lubao_e2e_360/all_screens/21-about.png) |
| all_screens | 22-deal-detail | ✅ | [22-deal-detail.png](shots/android-lubao_e2e_360/all_screens/22-deal-detail.png) |
| all_screens | 23-выход-водителя | ✅ | [23-выход-водителя.png](shots/android-lubao_e2e_360/all_screens/23-выход-водителя.png) |
| all_screens | 24-вход-логиста | ✅ | [24-вход-логиста.png](shots/android-lubao_e2e_360/all_screens/24-вход-логиста.png) |
| all_screens | 25-company-cargos | ✅ | [25-company-cargos.png](shots/android-lubao_e2e_360/all_screens/25-company-cargos.png) |
| all_screens | 26-company-drivers | ✅ | [26-company-drivers.png](shots/android-lubao_e2e_360/all_screens/26-company-drivers.png) |
| all_screens | 27-company-chats | ✅ | [27-company-chats.png](shots/android-lubao_e2e_360/all_screens/27-company-chats.png) |
| all_screens | 28-company-deals | ✅ | [28-company-deals.png](shots/android-lubao_e2e_360/all_screens/28-company-deals.png) |
| all_screens | 29-company-profile | ✅ | [29-company-profile.png](shots/android-lubao_e2e_360/all_screens/29-company-profile.png) |
| all_screens | 30-company-cargo-new | ✅ | [30-company-cargo-new.png](shots/android-lubao_e2e_360/all_screens/30-company-cargo-new.png) |
| all_screens | 31-company-cargo-responses | ✅ | [31-company-cargo-responses.png](shots/android-lubao_e2e_360/all_screens/31-company-cargo-responses.png) |
| all_screens | 32-company-deal-detail | ✅ | [32-company-deal-detail.png](shots/android-lubao_e2e_360/all_screens/32-company-deal-detail.png) |
| all_screens | 33-company-chat | ✅ | [33-company-chat.png](shots/android-lubao_e2e_360/all_screens/33-company-chat.png) |
| all_screens | 34-company-devices | ✅ | [34-company-devices.png](shots/android-lubao_e2e_360/all_screens/34-company-devices.png) |
| all_screens | 35-company-notification-settings | ✅ | [35-company-notification-settings.png](shots/android-lubao_e2e_360/all_screens/35-company-notification-settings.png) |
| all_screens | 36-company-about | ✅ | [36-company-about.png](shots/android-lubao_e2e_360/all_screens/36-company-about.png) |
