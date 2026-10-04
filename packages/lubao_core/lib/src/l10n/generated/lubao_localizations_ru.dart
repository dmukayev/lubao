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
  String get feedSectionHome => 'Домой';

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
  String get profileLanguage => 'Язык';

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
  String get adminVerificationEmpty => 'Нет документов на проверку';

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
}
