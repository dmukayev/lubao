// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'lubao_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class LubaoLocalizationsRu extends LubaoLocalizations {
  LubaoLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Lubao';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonNext => 'Далее';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonDone => 'Готово';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonLoading => 'Загрузка...';

  @override
  String get commonError => 'Что-то пошло не так';

  @override
  String get commonSeeAll => 'Смотреть все';

  @override
  String get commonCall => 'Позвонить';

  @override
  String get commonWhatsApp => 'WhatsApp';

  @override
  String get commonChat => 'Чат';

  @override
  String get commonSend => 'Отправить';

  @override
  String get commonSearch => 'Поиск';

  @override
  String get commonYes => 'Да';

  @override
  String get commonNo => 'Нет';

  @override
  String get roleSelectTitle => 'Кто вы?';

  @override
  String get roleSelectSubtitle => 'Выберите, как вы будете пользоваться Lubao';

  @override
  String get roleDriver => 'Водитель';

  @override
  String get roleCompany => 'Логистическая компания';

  @override
  String get driverLoginTitle => 'Вход для водителя';

  @override
  String get driverLoginPhoneLabel => 'Номер телефона';

  @override
  String get driverLoginPhoneHint => '+7 700 000 00 00';

  @override
  String get driverLoginSendCode => 'Получить код';

  @override
  String get driverLoginCodeLabel => 'Код из SMS';

  @override
  String get driverLoginVerify => 'Войти';

  @override
  String get driverLoginCountryLabel => 'Страна';

  @override
  String driverOtpSubtitle(String phone) {
    return 'Код отправлен на $phone';
  }

  @override
  String get driverOtpResend => 'Отправить код ещё раз';

  @override
  String get driverOtpInvalidCode => 'Неверный код';

  @override
  String get driverOtpTooManyAttempts =>
      'Слишком много попыток — запросите новый код';

  @override
  String get companyRegisterTitle => 'Новая компания';

  @override
  String get companyRegisterOwnerName => 'Ваше имя';

  @override
  String get companyRegisterCompanyName => 'Название компании';

  @override
  String get companyRegisterCompanyNameRu => 'Название по-русски';

  @override
  String get companyRegisterNameError => 'Введите название, минимум 2 символа';

  @override
  String get companyRegisterCountry => 'Страна';

  @override
  String get companyRegisterCountryError => 'Выберите страну';

  @override
  String get companyRegisterOtherCountry => 'Другая';

  @override
  String get companyRegisterSubmit => 'Создать компанию';

  @override
  String get companyRegisterEmailError => 'Введите email';

  @override
  String get companyRegisterPasswordError => 'Минимум 8 символов';

  @override
  String get companyRegisterEmailTaken =>
      'Этот email уже зарегистрирован. Войти?';

  @override
  String get companyLoginTitle => 'Вход для компании';

  @override
  String get companyLoginEmailLabel => 'Email';

  @override
  String get companyLoginVerify => 'Войти';

  @override
  String get companyLoginLockedOut =>
      'Слишком много попыток. Попробуйте через 15 минут';

  @override
  String get companyLoginShowPassword => 'Показать пароль';

  @override
  String get companyLoginHidePassword => 'Скрыть пароль';

  @override
  String get companyLoginRegisterLink => 'Регистрация';

  @override
  String get companyLoginForgotPasswordLink => 'Забыли пароль?';

  @override
  String get forgotPasswordTitle => 'Восстановление пароля';

  @override
  String get forgotPasswordSendCode => 'Отправить код';

  @override
  String get forgotPasswordCodeLabel => 'Код из письма';

  @override
  String get forgotPasswordNewPasswordLabel => 'Новый пароль';

  @override
  String get forgotPasswordSubmit => 'Сменить пароль';

  @override
  String get forgotPasswordSuccess => 'Пароль изменён, войдите с новым паролем';

  @override
  String get forgotPasswordResend => 'Отправить код ещё раз';

  @override
  String get forgotPasswordInvalidCode => 'Неверный или истёкший код';

  @override
  String get forgotPasswordNoEmailLink => 'Письмо не приходит?';

  @override
  String get supportContactTitle => 'Связаться с поддержкой';

  @override
  String get supportContactBody =>
      'Если письмо не приходит, напишите нам любым удобным способом';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportContactWechat => 'WeChat';

  @override
  String get supportContactEmail => 'Email';

  @override
  String get supportContactNone => 'Контакты поддержки скоро появятся здесь';

  @override
  String get acceptInviteTitle => 'Приглашение в компанию';

  @override
  String acceptInviteSubtitle(String companyName, String role) {
    return 'Вас пригласили в «$companyName» — роль: $role';
  }

  @override
  String get acceptInviteNameLabel => 'Ваше имя';

  @override
  String get acceptInvitePhoneLabel => 'Телефон (для водителей)';

  @override
  String get acceptInviteWechatLabel => 'WeChat (необязательно)';

  @override
  String get acceptInviteSubmit => 'Войти в компанию';

  @override
  String get acceptInviteInvalidToken =>
      'Приглашение недействительно или уже использовано';

  @override
  String get emailVerifyBannerText => 'Email не подтверждён';

  @override
  String get emailVerifyBannerAction => 'Подтвердить';

  @override
  String get emailVerifyDialogTitle => 'Подтверждение email';

  @override
  String get emailVerifyDialogCodeLabel => 'Код из письма';

  @override
  String get emailVerifyDialogSubmit => 'Подтвердить';

  @override
  String get employeesInviteButton => 'Пригласить сотрудника';

  @override
  String get employeesInviteEmailLabel => 'Email сотрудника';

  @override
  String get employeesInviteRoleOwner => 'Владелец';

  @override
  String get employeesInviteRoleLogist => 'Логист';

  @override
  String get employeesInviteSubmit => 'Создать ссылку';

  @override
  String get employeesInviteLinkReady =>
      'Ссылка-приглашение действует 7 дней. Скопируйте и отправьте в WeChat/WhatsApp:';

  @override
  String get employeesInviteCopyLink => 'Скопировать';

  @override
  String get employeesInviteCopied => 'Ссылка скопирована';

  @override
  String get driverSetupTitle => 'Настройка профиля';

  @override
  String get driverRegisterTitle => 'Регистрация';

  @override
  String get driverVerificationTitle => 'Верификация';

  @override
  String get driverVerificationIntro =>
      'Чтобы откликаться на грузы и подтверждать сделки, подтвердите личность — это займёт около 2 минут';

  @override
  String get driverVerificationSelfie => 'Селфи';

  @override
  String get driverVerificationVehiclePassport => 'Техпаспорт тягача';

  @override
  String get driverVerificationTrailerPassport => 'Техпаспорт прицепа';

  @override
  String get driverVerificationLicense => 'Права';

  @override
  String get driverVerificationStatusNone => 'Не загружено';

  @override
  String get driverVerificationStatusPending => 'На проверке';

  @override
  String get driverVerificationStatusApproved => 'Подтверждено';

  @override
  String get driverVerificationStatusRejected => 'Отклонено';

  @override
  String get driverVerificationUploadFailed => 'Не удалось загрузить фото';

  @override
  String get driverVerificationRequiredPrompt =>
      'Чтобы откликнуться, подтвердите личность — 2 минуты';

  @override
  String get driverVerificationRequiredAction => 'Пройти верификацию';

  @override
  String profileCompleteness(int percent) {
    return 'Профиль заполнен на $percent% — проверенные водители получают в 3 раза больше приглашений';
  }

  @override
  String driverSetupStepOf(int step, int total) {
    return 'Шаг $step из $total';
  }

  @override
  String get driverSetupFullName => 'Ф.И.О.';

  @override
  String get driverSetupFullNameError => 'Введите имя: 2-80 букв, без цифр';

  @override
  String get driverSetupHomeCityError => 'Выберите город';

  @override
  String get driverSetupBodyTypeError => 'Выберите тип кузова';

  @override
  String get cityNotListed => 'Нет моего города';

  @override
  String get addCitySettlementLabel => 'Населённый пункт';

  @override
  String get addCitySettlementError => 'Введите название населённого пункта';

  @override
  String get addCityRegionLabel => 'Область/регион';

  @override
  String get addCityRegionError => 'Выберите область';

  @override
  String get addCitySubmit => 'Продолжить';

  @override
  String get driverSetupHomeCity => 'Домашний город';

  @override
  String get driverSetupCountries => 'Направления';

  @override
  String get driverSetupAnyCountry => 'Любая страна';

  @override
  String get driverSetupPermits => 'Допуски';

  @override
  String get driverSetupVehicleBodyType => 'Тип кузова';

  @override
  String get driverSetupVehiclePlate => 'Гос. номер';

  @override
  String get driverSetupVehicleTitle => 'Какая у вас машина?';

  @override
  String get driverSetupVehicleSubtitle =>
      'Заполните один раз — мы будем подбирать грузы под неё';

  @override
  String get driverSetupCapacity => 'Грузоподъёмность';

  @override
  String get driverSetupDocuments => 'Документы на машину';

  @override
  String get driverSetupDirectionsTitle => 'Куда готовы ехать?';

  @override
  String get driverSetupDirectionsSubtitle =>
      'Покажем грузы в эти страны первыми. Можно поменять в любой момент';

  @override
  String driverSetupCountriesSelected(int count) {
    return 'Выбрано стран: $count';
  }

  @override
  String get driverSetupSubmit => 'Сохранить и продолжить';

  @override
  String get feedTitle => 'Грузы в Хоргосе';

  @override
  String get driverHomeGreeting => 'Сәлем,';

  @override
  String get driverHomeAnonsTitle => 'Мой анонс';

  @override
  String driverHomeLogistsCount(int count) {
    return 'Логистов рядом: $count';
  }

  @override
  String driverHomeSince(String date) {
    return 'На месте с $date';
  }

  @override
  String get driverHomeCheckInEmpty =>
      'Заявите о прибытии — логисты увидят вас заранее';

  @override
  String get driverHomeCheckInButton => 'Я уже на месте';

  @override
  String get driverHomeLeaveButton => 'Я уехал';

  @override
  String get driverHomeCancelButton => 'Отменить';

  @override
  String get driverHomeAnnounceButton => 'Буду на точке';

  @override
  String get driverHomeRepeatButton => 'Повторить прошлый анонс';

  @override
  String get driverHomeEditButton => 'Изменить';

  @override
  String driverHomePlannedFor(String date) {
    return 'Будет $date';
  }

  @override
  String get announceArrivalTitle => 'Буду на точке';

  @override
  String get announceArrivalWhen => 'Когда';

  @override
  String get announceArrivalToday => 'Сегодня';

  @override
  String get announceArrivalTomorrow => 'Завтра';

  @override
  String get announceArrivalDayAfter => 'Послезавтра';

  @override
  String get announceArrivalPickDate => 'Выбрать дату';

  @override
  String get announceArrivalWhere => 'Где';

  @override
  String get announceArrivalCountries => 'Куда готов';

  @override
  String get announceArrivalWaitDays => 'Сколько готовы ждать';

  @override
  String announceArrivalWaitDaysValue(int days) {
    return '$days дн.';
  }

  @override
  String get announceArrivalSubmit => 'Опубликовать';

  @override
  String driverHomeFeedCount(int count) {
    return 'Подходящие грузы $count';
  }

  @override
  String get feedEmpty => 'Пока нет подходящих грузов';

  @override
  String get feedSectionHome => 'Близко к дому';

  @override
  String get feedSectionSelected => 'Ваши направления';

  @override
  String get feedSectionOther => 'Остальные направления';

  @override
  String get cargoPrice => 'Цена';

  @override
  String get cargoWeight => 'Вес';

  @override
  String get cargoVolume => 'Объём';

  @override
  String get cargoPhotos => 'Фотографии';

  @override
  String get unitKg => 'кг';

  @override
  String get unitM3 => 'м³';

  @override
  String get unitTon => 'т';

  @override
  String get cargoReadyDate => 'Дата готовности';

  @override
  String get cargoDestination => 'Направление';

  @override
  String get cargoBodyType => 'Кузов';

  @override
  String get cargoRespond => 'Откликнуться';

  @override
  String get cargoAlreadyResponded => 'Вы откликнулись';

  @override
  String get cargoDetailTitle => 'Груз';

  @override
  String get cargoDetailDescription => 'Описание';

  @override
  String get cargoDetailCompany => 'Компания';

  @override
  String get cargoDetailPriceLabel => 'Цена за рейс';

  @override
  String cargoDetailCompanyDeals(int count) {
    return '$count сделок в Lubao';
  }

  @override
  String get cargoDetailNoReviews => 'Пока нет отзывов';

  @override
  String get cargoStatusPublished => 'Опубликован';

  @override
  String get cargoStatusArchived => 'В архиве';

  @override
  String get cargoStatusExpired => 'Истёк';

  @override
  String get cargoStatusCancelled => 'Отменён';

  @override
  String get dealsTitle => 'Мои сделки';

  @override
  String get dealsEmpty => 'Сделок пока нет';

  @override
  String get dealStatusSelected => 'Выбран';

  @override
  String get dealStatusConfirmed => 'Подтверждён водителем';

  @override
  String get dealStatusLoaded => 'Загружен';

  @override
  String get dealStatusInTransit => 'В пути';

  @override
  String get dealStatusDelivered => 'Доставлено';

  @override
  String get dealStatusCancelled => 'Отменена';

  @override
  String get dealDetailTitle => 'Сделка';

  @override
  String get dealTimelineTitle => 'Статус сделки';

  @override
  String get dealDriverLocationTitle => 'Местоположение водителя';

  @override
  String get dealLocationUpdatedAt => 'Обновлено';

  @override
  String get dealLocationNoData => 'Координаты ещё не получены';

  @override
  String get dealConfirm => 'Подтвердить';

  @override
  String get dealMarkLoaded => 'Груз загружен';

  @override
  String get dealMarkInTransit => 'В пути';

  @override
  String get dealMarkDelivered => 'Доставлено';

  @override
  String get dealCancel => 'Отменить сделку';

  @override
  String get dealCancelReasonLabel => 'Причина отмены';

  @override
  String get dealCancelledBy => 'Отменил(а)';

  @override
  String get reviewTitle => 'Оставить отзыв';

  @override
  String get reviewRatingLabel => 'Оценка';

  @override
  String get reviewCommentLabel => 'Комментарий';

  @override
  String get reviewSubmit => 'Отправить отзыв';

  @override
  String get reviewsReceivedTitle => 'Отзывы';

  @override
  String get responsesTitle => 'Отклики';

  @override
  String get responsesEmpty => 'Пока нет откликов';

  @override
  String get responseSelect => 'Выбрать водителя';

  @override
  String get responseReject => 'Отклонить';

  @override
  String get responseStatusPending => 'Ожидает';

  @override
  String get responseStatusSelected => 'Выбран';

  @override
  String get responseStatusRejected => 'Отклонён';

  @override
  String get responseStatusCancelled => 'Отменён';

  @override
  String get myCargosTitle => 'Мои грузы';

  @override
  String get myCargosEmpty => 'Вы ещё не публиковали грузы';

  @override
  String get postCargoTitle => 'Новый груз';

  @override
  String get postCargoDestinationCountry => 'Страна назначения';

  @override
  String get postCargoDestinationCity => 'Город назначения';

  @override
  String get postCargoBodyType => 'Тип кузова';

  @override
  String get postCargoVolume => 'Объём, м³';

  @override
  String get postCargoWeight => 'Вес, кг';

  @override
  String get postCargoPhotos => 'Фотографии';

  @override
  String get postCargoAddPhotoCamera => 'Камера';

  @override
  String get postCargoAddPhotoGallery => 'Галерея';

  @override
  String get postCargoRemovePhoto => 'Удалить фото';

  @override
  String get postCargoPhotoUploadFailed => 'Не удалось загрузить фото';

  @override
  String get postCargoPrice => 'Цена';

  @override
  String get postCargoCurrency => 'Валюта';

  @override
  String get postCargoReadyDate => 'Дата готовности';

  @override
  String get postCargoDescription => 'Описание груза';

  @override
  String get postCargoSubmit => 'Опубликовать';

  @override
  String get editCargoTitle => 'Редактировать груз';

  @override
  String get cargoEdit => 'Редактировать';

  @override
  String get cargoDelete => 'Удалить';

  @override
  String get cargoDeleteConfirmTitle => 'Удалить груз?';

  @override
  String get cargoDeleteConfirmMessage =>
      'Груз будет снят с публикации. История откликов и сделок сохранится.';

  @override
  String get cargoDeleted => 'Груз удалён';

  @override
  String get chatTitle => 'Чат';

  @override
  String get chatInputHint => 'Сообщение';

  @override
  String get chatEmpty => 'Начните переписку';

  @override
  String get chatAttachLocation => 'Прикрепить точку';

  @override
  String get chatLocationMessagePrefix => 'Точка на карте';

  @override
  String get chatLocationError => 'Не удалось определить местоположение';

  @override
  String get chatTranslatedBadge => 'Переведено';

  @override
  String get chatShowOriginal => 'оригинал';

  @override
  String chatWritesIn(String language) {
    return 'Пишет на $language';
  }

  @override
  String get chatToday => 'Сегодня';

  @override
  String get chatYesterday => 'Вчера';

  @override
  String get chatConfirmTitle => 'Логист выбрал вас на этот груз';

  @override
  String get chatConfirmSubtitle =>
      'Подтвердите — сделка зафиксируется, и вы получите отзыв и рейтинг';

  @override
  String get chatConfirmButton => 'Подтверждаю перевозку';

  @override
  String get chatQuickReplyAtPlace => 'Я на месте';

  @override
  String get chatQuickReplyLoaded => 'Загрузился';

  @override
  String get chatQuickReplyLate1h => 'Опаздываю на 1 час';

  @override
  String get wholeCountrySuffix => 'вся страна';

  @override
  String get searchCityCountryHint => 'Начните вводить город или страну';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileLogout => 'Выйти';

  @override
  String get profileRatingLabel => 'Рейтинг';

  @override
  String get profileVerified => 'Проверен';

  @override
  String get profileNotVerified => 'Не проверен';

  @override
  String get profileLanguage => 'Язык · Тіл · 语言 · Language';

  @override
  String get profilePhone => 'Телефон';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileCompanyName => 'Компания';

  @override
  String get profileMembers => 'Сотрудники';

  @override
  String get profileMyDevices => 'Мои устройства';

  @override
  String get companySetPasswordTitle => 'Пароль для входа';

  @override
  String get companySetPasswordHint => 'Сменить пароль для входа';

  @override
  String get companySetPasswordTooShort => 'Минимум 8 символов';

  @override
  String get devicesTitle => 'Мои устройства';

  @override
  String get devicesCurrentBadge => 'Текущее устройство';

  @override
  String get devicesLogoutThis => 'Выйти на этом устройстве';

  @override
  String get devicesLogoutAllOthers => 'Выйти на всех остальных';

  @override
  String get devicesLogoutAllOthersConfirm =>
      'Все остальные устройства будут разлогинены. Продолжить?';

  @override
  String get devicesEmpty => 'Нет активных устройств';

  @override
  String get adminLoginLockedOut =>
      'Слишком много неверных попыток, попробуйте через 15 минут';

  @override
  String get languageKk => 'Қазақша';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageZh => '中文';

  @override
  String get navFeed => 'Грузы';

  @override
  String get navDeals => 'Сделки';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navCargos => 'Грузы';

  @override
  String get navResponses => 'Отклики';

  @override
  String get navDrivers => 'Водители';

  @override
  String driversAtPointTitle(String point) {
    return 'Кто будет на $point';
  }

  @override
  String get driversAtPointSubtitle =>
      'Водители, которые заранее сообщили о прибытии';

  @override
  String driversAtPointDispatchFrom(String point) {
    return 'Пункт отправки груза: $point';
  }

  @override
  String get driversAtPointPickDate => 'Выбрать дату';

  @override
  String driversAtPointCountAtPlace(int count) {
    return 'Сейчас на месте: $count';
  }

  @override
  String get driversAtPointEmpty => 'Пока никого нет на месте';

  @override
  String get driversAtPointFilterCountry => 'Страна';

  @override
  String get driversAtPointFilterBodyType => 'Кузов';

  @override
  String get driversAtPointFilterMinCapacity => 'От 20 т';

  @override
  String get driversAtPointFilterVerifiedOnly => 'Только проверенные';

  @override
  String get driversAtPointInvite => 'Пригласить к грузу';

  @override
  String get driversAtPointPickCargo => 'Выберите груз';

  @override
  String get driversAtPointNoCargos => 'Сначала опубликуйте груз';

  @override
  String get driversAtPointInviteSent => 'Приглашение отправлено';

  @override
  String driversAtPointArrivedAt(String time) {
    return 'На месте с $time';
  }

  @override
  String driversAtPointPlannedAt(String time) {
    return 'Будет $time';
  }

  @override
  String get driversAtPointToday => 'Сегодня';

  @override
  String get adminLoginTitle => 'Вход в админ-панель';

  @override
  String get adminLoginEmailLabel => 'Email';

  @override
  String get adminLoginPasswordLabel => 'Пароль';

  @override
  String get adminLoginSubmit => 'Войти';

  @override
  String get adminDashboardTitle => 'Обзор';

  @override
  String get adminStatDrivers => 'Водители';

  @override
  String get adminStatCompanies => 'Компании';

  @override
  String get adminStatCargosPublished => 'Активные грузы';

  @override
  String get adminStatDealsActive => 'Сделки в работе';

  @override
  String get adminStatDealsDelivered => 'Доставлено сделок';

  @override
  String get adminStatPendingDocs => 'Документы на проверке';

  @override
  String get adminStatOpenComplaints => 'Открытые жалобы';

  @override
  String get adminNavDashboard => 'Обзор';

  @override
  String get adminNavVerification => 'Верификация';

  @override
  String get adminNavComplaints => 'Жалобы';

  @override
  String get adminNavCompanies => 'Компании';

  @override
  String get adminNavDrivers => 'Водители';

  @override
  String get adminNavReference => 'Справочники';

  @override
  String get adminVerificationTitle => 'Документы на проверку';

  @override
  String get adminVerificationEmpty => 'Все проверены 👍';

  @override
  String get adminApprove => 'Одобрить';

  @override
  String get adminReject => 'Отклонить';

  @override
  String get adminRejectReasonLabel => 'Причина отклонения';

  @override
  String get adminComplaintsTitle => 'Жалобы';

  @override
  String get adminComplaintsEmpty => 'Жалоб нет';

  @override
  String get adminResolve => 'Решено';

  @override
  String get adminMarkInReview => 'В работе';

  @override
  String get adminCompaniesTitle => 'Компании';

  @override
  String get adminDriversTitle => 'Водители';

  @override
  String get adminVerified => 'Проверен';

  @override
  String get adminNotVerified => 'Не проверен';

  @override
  String get adminReferenceTitle => 'Справочники';

  @override
  String get adminPendingCitiesTab => 'Новые города';

  @override
  String get adminPendingCitiesEmpty => 'Нет новых городов от пользователей';

  @override
  String get adminMergeCity => 'Объединить';

  @override
  String get adminMergeCityTarget => 'Город для объединения';

  @override
  String get adminCitySubmittedBy => 'Добавил';

  @override
  String get adminCityRegion => 'Область';

  @override
  String get adminAddBodyType => 'Добавить тип кузова';

  @override
  String get adminAddPermit => 'Добавить допуск';

  @override
  String get adminAddPoint => 'Добавить точку загрузки';

  @override
  String get adminPointCity => 'Город';

  @override
  String get adminNameKk => 'Название (kk)';

  @override
  String get adminNameRu => 'Название (ru)';

  @override
  String get adminNameZh => 'Название (zh)';

  @override
  String get adminCode => 'Код';

  @override
  String get adminActive => 'Активна';

  @override
  String get adminInactive => 'Неактивна';

  @override
  String get accountBlockedMessage =>
      'Аккаунт заблокирован. Обратитесь в поддержку';

  @override
  String get adminSearchCompanyHint => 'Название, email, рег. номер';

  @override
  String get adminSearchDriverHint => 'Имя, телефон, гос. номер';

  @override
  String get adminFilterAll => 'Все';

  @override
  String get adminFilterPending => 'На проверке';

  @override
  String get adminFilterVerified => 'Проверенные';

  @override
  String get adminFilterBlocked => 'Блокированные';

  @override
  String get adminCompaniesEmpty => 'Компании не найдены';

  @override
  String get adminDriversEmpty => 'Водители не найдены';

  @override
  String get adminColName => 'Имя';

  @override
  String get adminColOwner => 'Владелец';

  @override
  String get adminColEmployees => 'Сотрудники';

  @override
  String get adminColCargos => 'Активные грузы';

  @override
  String get adminColStatus => 'Статус';

  @override
  String get adminColRating => 'Рейтинг';

  @override
  String get adminColDeals => 'Сделки';

  @override
  String get adminColPhone => 'Телефон';

  @override
  String get adminColCity => 'Город';

  @override
  String get adminColVehicle => 'Машина';

  @override
  String get adminBlockedBadge => 'Блокирован';

  @override
  String adminPageOf(int page, int total) {
    return 'Страница $page из $total';
  }

  @override
  String get adminBlockConfirmTitle => 'Блокировать водителя?';

  @override
  String get adminBlockCompanyConfirmTitle => 'Блокировать компанию?';

  @override
  String get adminBlock => 'Блокировать';

  @override
  String get adminBlockCompany => 'Блокировать компанию';

  @override
  String get adminUnblockConfirmTitle => 'Разблокировать?';

  @override
  String get adminUnblock => 'Разблокировать';

  @override
  String get adminVerifyMissingDocsError =>
      'Не все обязательные документы одобрены — поставьте галочку «проверил лично» и повторите';

  @override
  String get adminResetPasswordConfirmTitle => 'Сбросить пароль владельца?';

  @override
  String get adminResetPasswordDialogTitle => 'Временный пароль';

  @override
  String get adminResetPassword => 'Сбросить пароль';

  @override
  String get adminCopied => 'Скопировано';

  @override
  String get adminToggleVerification => 'Изменить статус проверки';

  @override
  String get adminStatComplaints => 'Жалобы';

  @override
  String get adminStatCancellations => 'Отмены';

  @override
  String get adminStatCalls => 'Звонки';

  @override
  String get adminDocuments => 'Документы';

  @override
  String get adminNoDocuments => 'Документов нет';

  @override
  String get adminLegalDetails => 'Юридические данные';

  @override
  String get adminInvites => 'Приглашения';

  @override
  String get adminInviteUsed => 'Использовано';

  @override
  String get adminTabCargos => 'Грузы';

  @override
  String get adminTabDeals => 'Сделки';

  @override
  String get adminTabReviews => 'Отзывы';

  @override
  String get adminTabLog => 'Журнал';

  @override
  String get adminNoCargos => 'Грузов нет';

  @override
  String get adminNoDeals => 'Сделок нет';

  @override
  String get adminNoReviews => 'Отзывов нет';

  @override
  String get adminNoLog => 'Записей нет';

  @override
  String get adminEndSessionsConfirmTitle => 'Завершить все сессии?';

  @override
  String get adminEndSessions => 'Завершить сессии';

  @override
  String adminWithUsSince(String date) {
    return 'С нами с $date';
  }

  @override
  String adminLastLogin(String date) {
    return 'Последний вход: $date';
  }

  @override
  String get adminReasonLabel => 'Причина';

  @override
  String get adminVerifyDialogTitle => 'Поставить «Проверен»';

  @override
  String get adminUnverifyDialogTitle => 'Снять «Проверен»';

  @override
  String get adminForceVerifyCheckbox => 'Я проверил документы лично';

  @override
  String get adminRejectPresetUnreadable => 'Нечитаемое фото';

  @override
  String get adminRejectPresetExpired => 'Документ просрочен';

  @override
  String get adminRejectPresetMismatch => 'Имя не совпадает';

  @override
  String get adminRejectPresetOther => 'Другое / причина';

  @override
  String get adminDocTypeCompanyRegistration => 'Свидетельство о регистрации';

  @override
  String get adminDocTypeIdentity => 'Удостоверение личности';

  @override
  String get adminDocTypeOther => 'Другой документ';

  @override
  String get adminRotate => 'Повернуть';

  @override
  String get adminComplaintReporter => 'Заявитель';

  @override
  String get adminComplaintTarget => 'Объект жалобы';

  @override
  String get adminAttentionTitle => 'Требует внимания';

  @override
  String get adminAttentionEmpty => 'Всё в порядке — внимания не требуется';

  @override
  String adminAttentionPendingVerification(int count) {
    return 'На проверке: $count человек';
  }

  @override
  String adminAttentionOpenComplaints(int count) {
    return 'Открытых жалоб: $count';
  }

  @override
  String adminAttentionStaleDeals(int count) {
    return 'Сделок без движения > 3 дней: $count';
  }

  @override
  String adminAttentionUnverifiedCompanies(int count) {
    return 'Непроверенных компаний: $count';
  }

  @override
  String adminAttentionPendingCities(int count) {
    return 'Новых городов: $count';
  }

  @override
  String get adminRecentEventsTitle => 'Последние события';

  @override
  String get adminAuditLogLink => 'Журнал →';

  @override
  String get adminAuditLogTitle => 'Журнал действий';

  @override
  String get adminNoEvents => 'Событий нет';

  @override
  String get adminPeriodLabel => 'Период:';

  @override
  String get adminPeriodToday => 'Сегодня';

  @override
  String get adminPeriod7d => '7 дней';

  @override
  String get adminPeriod30d => '30 дней';

  @override
  String get adminStatOnSiteToday => 'На точке сегодня';

  @override
  String adminStatOnSiteWeek(int count) {
    return 'На неделе: $count';
  }

  @override
  String get adminGlobalSearchHint =>
      'Поиск: имя, телефон, email, госномер, № груза/сделки';

  @override
  String get adminSearchNoResults => 'Ничего не найдено';

  @override
  String get adminNavCargos => 'Грузы';

  @override
  String get adminNavDeals => 'Сделки';

  @override
  String get adminNavSettings => 'Настройки';

  @override
  String get adminCargosTitle => 'Грузы';

  @override
  String get adminCargosEmpty => 'Грузы не найдены';

  @override
  String get adminDealsTitle => 'Сделки';

  @override
  String get adminDealsEmpty => 'Сделки не найдены';

  @override
  String get adminFilterActive => 'В работе';

  @override
  String get adminFilterStale => 'Без движения > 3 дней';

  @override
  String get adminFilterOnSite => 'На точке';

  @override
  String get adminColRoute => 'Маршрут';

  @override
  String get adminColBodyType => 'Кузов';

  @override
  String get adminColPrice => 'Цена';

  @override
  String get adminColCompany => 'Компания';

  @override
  String get adminColDriver => 'Водитель';

  @override
  String get adminColResponses => 'Откликов';

  @override
  String get adminColPublished => 'Опубликован';

  @override
  String get adminColCreated => 'Создана';

  @override
  String get adminColStale => 'Без движения';

  @override
  String adminStaleDays(int days) {
    return '$days дн.';
  }

  @override
  String get adminSettingsEmpty => 'Настроек пока нет';

  @override
  String get adminVerificationTabDrivers => 'Водители';

  @override
  String get adminVerificationTabCompanies => 'Компании';

  @override
  String get adminVerificationNoSelection =>
      'Выберите человека или компанию из очереди слева';

  @override
  String adminVerificationReasonNew(int count) {
    return 'Новый · $count документов';
  }

  @override
  String adminVerificationReasonResubmitted(String type) {
    return 'Повторно: $type';
  }

  @override
  String get adminVerificationReasonVehicleChanged => 'Сменил машину';

  @override
  String get adminVerificationOpenCard => 'Карточка →';

  @override
  String get adminVerificationCrossCheckTitle => 'Сверка с профилем';

  @override
  String get adminCrossCheckName => 'Имя ↔ права';

  @override
  String get adminCrossCheckPhoto => 'Лицо на селфи ↔ фото в правах';

  @override
  String get adminCrossCheckPlate => 'Госномер ↔ техпаспорт тягача';

  @override
  String get adminCrossCheckTrailerPlate => 'Прицеп ↔ техпаспорт прицепа';

  @override
  String get adminCrossCheckCompanyName => 'Название ↔ лицензия';

  @override
  String get adminCrossCheckCompanyTaxId => 'Рег. номер ↔ лицензия';

  @override
  String get adminCrossCheckMatch => 'Совпадает';

  @override
  String get adminCrossCheckMismatch => 'Не совпадает';

  @override
  String get adminConfirmDriverButton => 'Подтвердить водителя';

  @override
  String get adminConfirmCompanyButton => 'Подтвердить компанию';

  @override
  String get adminReturnForReworkButton => 'Вернуть на доработку';

  @override
  String get adminReturnForReworkDialogTitle => 'Вернуть на доработку';

  @override
  String get adminReturnForReworkNoteLabel => 'Комментарий (что переснять)';

  @override
  String get adminVerificationMissingDocsHint =>
      'Отметьте все обязательные документы как «в порядке», чтобы подтвердить';

  @override
  String get adminVerificationCompareWithSelfie => 'Рядом с селфи';

  @override
  String get adminRejectPresetPlateMismatch => 'Госномер не совпадает';

  @override
  String get adminCargoUnpublish => 'Снять с публикации';

  @override
  String get adminCargoUnpublishDialogTitle => 'Снять груз с публикации';

  @override
  String get adminCargoEdit => 'Исправить';

  @override
  String get adminCargoEditDialogTitle => 'Исправить груз';

  @override
  String get adminCargoPublishedAt => 'Опубликован';

  @override
  String get adminCargoExpiresAt => 'Истекает';

  @override
  String get adminCargoArchivedAt => 'Снят с публикации';

  @override
  String get adminCargoTabResponses => 'Отклики';

  @override
  String get adminNoResponses => 'Пока нет откликов';

  @override
  String get adminDealCancel => 'Отменить сделку';

  @override
  String get adminDealCancelDialogTitle => 'Отменить сделку';

  @override
  String get adminDealFixStatus => 'Исправить статус';

  @override
  String get adminDealFixStatusDialogTitle => 'Исправить статус сделки';

  @override
  String get adminDealOpenCargo => 'Груз →';

  @override
  String adminDealCancelledBy(String role) {
    return 'Отменено ($role)';
  }

  @override
  String get adminDealStatusHistoryTitle => 'История статусов';

  @override
  String get adminDealTabChat => 'Переписка';

  @override
  String get adminDealTabCalls => 'Звонки';

  @override
  String get adminDealShowChat => 'Показать переписку';

  @override
  String get adminNoChat => 'Сообщений нет';

  @override
  String get adminNoCalls => 'Звонков не было';

  @override
  String get adminContactEventCall => 'Звонок';

  @override
  String get adminContactEventWhatsapp => 'WhatsApp';

  @override
  String get roleAdmin => 'Админ';

  @override
  String get adminEdit => 'Редактировать';

  @override
  String get adminTransferOwnershipTitle => 'Передать владение';

  @override
  String get adminDemoteToLogistTitle => 'Понизить до логиста';

  @override
  String get adminLastOwnerError => 'Нельзя — это последний владелец компании';

  @override
  String get adminRemoveMemberTitle => 'Удалить сотрудника';

  @override
  String get adminRemoveMember => 'Удалить';

  @override
  String get adminChangeMemberEmailTitle => 'Сменить email сотрудника';

  @override
  String get adminEmailTakenError => 'Этот email уже используется';

  @override
  String get adminCompanyCity => 'Город';

  @override
  String get adminLegalAddress => 'Юридический адрес';

  @override
  String get adminTaxId => 'Рег. номер (БИН)';

  @override
  String get adminPhoneChangeWarning =>
      'При сохранении все сессии водителя будут завершены';

  @override
  String get adminVehicleBrand => 'Марка';

  @override
  String get adminVehicleLengthM => 'Длина, м';

  @override
  String get adminNameEn => 'Название (en)';

  @override
  String get adminSortOrder => 'Порядок';

  @override
  String get adminLat => 'Широта';

  @override
  String get adminLng => 'Долгота';

  @override
  String get adminCitiesTab => 'Города';

  @override
  String get adminSettingDefaultCity => 'Точка по умолчанию';

  @override
  String get adminSettingNotSet => 'Не задано';

  @override
  String get adminSettingHomeRadius => 'Радиус «Близко к дому», км';

  @override
  String get adminUnitKm => 'км';

  @override
  String get adminSettingCargoArchiveDays => 'Срок архива груза без откликов';

  @override
  String get adminComplaintResolutionTitle => 'Решение';

  @override
  String get adminComplaintResolutionNoteLabel => 'Ответ автору жалобы';

  @override
  String get adminComplaintSelectHint => 'Выберите жалобу из очереди слева';

  @override
  String get adminComplaintTabNew => 'Новые';

  @override
  String get adminComplaintTabInReview => 'В работе';

  @override
  String get adminComplaintTabClosed => 'Закрытые';

  @override
  String get adminComplaintMineFilter => 'Мои';

  @override
  String adminComplaintMoreThisMonth(int count) {
    return 'ещё $count жалоб за месяц';
  }

  @override
  String get adminComplaintTakeOver => 'Взять в работу';

  @override
  String adminComplaintAssignedTo(String name) {
    return 'В работе у $name';
  }

  @override
  String get adminComplaintReturnToNew => 'Вернуть в новые';

  @override
  String get adminComplaintResolveButton => 'Принять решение';

  @override
  String get adminComplaintResolutionDismissed => 'Не подтвердилась';

  @override
  String get adminComplaintResolutionWarned => 'Предупредить';

  @override
  String get adminComplaintResolutionCargoUnpublished => 'Снять груз';

  @override
  String get adminComplaintResolutionBlocked => 'Заблокировать';

  @override
  String get adminStatClosedOutside => 'Нашли вне Lubao';

  @override
  String adminStatClosedOutsideHint(int outside, int total) {
    return '$outside из $total закрытых';
  }

  @override
  String get cargoCloseDialogTitle => 'Закрыть груз';

  @override
  String get cargoCloseFoundInApp => 'Нашёл водителя в Lubao';

  @override
  String get cargoCloseNoCandidates =>
      'Пока нет водителей, с кем были отклик, звонок или переписка';

  @override
  String get cargoCloseDriverLabel => 'Водитель';

  @override
  String get cargoCloseFoundOutside => 'Нашёл вне Lubao';

  @override
  String get cargoCloseCancelled => 'Груз отменён';

  @override
  String get cargoCloseConfirm => 'Закрыть';

  @override
  String get cargoClosed => 'Груз закрыт';

  @override
  String get cargoClose => 'Закрыть груз';

  @override
  String get navChats => 'Чаты';

  @override
  String get chatsTabTitle => 'Чаты';

  @override
  String get chatsEmpty => 'Пока нет чатов';

  @override
  String get profileNotificationSettings => 'Уведомления';

  @override
  String get notificationSettingsTitle => 'Уведомления';

  @override
  String get notificationSettingsHint =>
      'Выключенная группа не присылает push по этим событиям';

  @override
  String get notificationGroupNewCargoMatch => 'Новый подходящий груз';

  @override
  String get notificationGroupCargoInvite => 'Приглашение на груз';

  @override
  String get notificationGroupChatMessage => 'Новое сообщение в чате';

  @override
  String get notificationGroupNewResponse => 'Отклик водителя';

  @override
  String get notificationGroupNewDriverDigest => 'Новые водители на точке';

  @override
  String get notificationGroupDealStatus => 'Смена статуса сделки';

  @override
  String get notificationGroupVerification => 'Проверка документов';

  @override
  String get notificationGroupAgreedCheck => '«Договорились?»';

  @override
  String get companyWecomTitle => 'WeCom-бот';

  @override
  String get companyWecomHint =>
      'Адрес вебхука группового бота WeCom — уведомления о новых откликах и сделках будут приходить в вашу группу';

  @override
  String get companyWecomUrlLabel => 'Вебхук URL';

  @override
  String get companyWecomTestButton => 'Проверить';

  @override
  String get companyWecomTestSuccess => 'Тестовое сообщение отправлено';

  @override
  String get companyWecomTestError => 'Не удалось отправить — проверьте адрес';

  @override
  String get chatTranslationFailed => 'Перевод недоступен';

  @override
  String get chatTranslationRetry => 'повторить';

  @override
  String get adminTranslationSettingsTitle => 'Перевод чата';

  @override
  String get adminTranslationEnabledLabel => 'Включён';

  @override
  String get adminTranslationProviderLabel => 'Провайдер';

  @override
  String get adminTranslationModelLabel => 'Модель';

  @override
  String get adminTranslationRequests7dLabel => 'Запросов за 7 дней';

  @override
  String get adminTranslationTokens7dLabel => 'Токенов за 7 дней';
}
