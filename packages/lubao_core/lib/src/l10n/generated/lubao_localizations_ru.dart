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
  String get errorNetwork =>
      'Нет связи с сервером. Проверьте интернет и повторите';

  @override
  String get errorServer => 'Сервер временно недоступен. Попробуйте позже';

  @override
  String get errorForbidden => 'Это действие вам недоступно';

  @override
  String get errorInvalidData => 'Проверьте введённые данные';

  @override
  String errorFieldMax(String field, String limit) {
    return '$field — не больше $limit';
  }

  @override
  String errorFieldMin(String field, String limit) {
    return '$field — не меньше $limit';
  }

  @override
  String errorFieldMaxLength(String field, String limit) {
    return '$field — не длиннее $limit символов';
  }

  @override
  String errorFieldInvalid(String field) {
    return '$field — проверьте значение';
  }

  @override
  String fieldMax(String limit) {
    return 'Не больше $limit';
  }

  @override
  String get fieldPositive => 'Должно быть больше 0';

  @override
  String get fieldNotNumber => 'Введите число';

  @override
  String get errorSessionExpired => 'Сессия истекла — войдите снова';

  @override
  String get chatOpenFailed => 'Не удалось открыть чат';

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
  String get driverVerificationConsent =>
      'Документы распознаются на серверах Lubao в Казахстане. ИИН хранится в зашифрованном виде и используется только для проверки личности и защиты от повторной регистрации заблокированных пользователей.';

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
  String get unitPallets => 'пал.';

  @override
  String get dealVehicleFullTitle => 'Машина заполнена';

  @override
  String get dealVehicleNotVerified =>
      'Машина ещё на проверке — откройте гараж';

  @override
  String dealVehicleFullBody(String used, String capacity, String unit) {
    return 'Подтверждён груз $used из $capacity $unit. Чтобы взять этот, сначала завершите или отмените текущий.';
  }

  @override
  String get dealVehicleFullNextTrip =>
      'Этот груз грузится в другой день — это следующий рейс. Подтвердите его после доставки текущего.';

  @override
  String get dealVehicleFullOpenCurrent => 'К текущей сделке';

  @override
  String get dealCancelReasonTookAnother => 'Взял другой груз';

  @override
  String driverAlreadyHauling(String used, String unit) {
    return 'Уже везёт: $used $unit';
  }

  @override
  String driverAlreadyHaulingOf(String used, String capacity, String unit) {
    return 'Уже везёт: $used из $capacity $unit';
  }

  @override
  String get driverHaulingBusyNoWeight => 'Машина занята (груз без веса)';

  @override
  String driverHaulingLoading(String date) {
    return 'погрузка $date';
  }

  @override
  String get selectDriverVehicleFullTitle => 'Машина водителя уже заполнена';

  @override
  String selectDriverVehicleFullBody(String haul) {
    return '$haul. Выбрать можно, но водитель не сможет подтвердить перевозку, пока не завершит или не отменит текущую.';
  }

  @override
  String get selectDriverAnywayButton => 'Выбрать всё равно';

  @override
  String driverCancelShare(int cancelled, int total) {
    return 'Отменил $cancelled из $total сделок';
  }

  @override
  String get garageSizeTitle => 'Размер кузова';

  @override
  String get garageSizeCustom => 'Свой размер';

  @override
  String get garageSizeLength => 'Длина внутри, м';

  @override
  String get garageSizeWidth => 'Ширина внутри, м';

  @override
  String get garageSizeHeight => 'Высота внутри, м';

  @override
  String get garageSizePrompt =>
      'Укажите размер кузова — грузы подберутся точнее';

  @override
  String get garageSizeChange => 'Изменить размер';

  @override
  String get postCargoPallets => 'Паллеты (шт.)';

  @override
  String postCargoFitCount(int count) {
    return 'Подходит $count водителям на точке';
  }

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
  String get postCargoDestinationError => 'Выберите направление';

  @override
  String get postCargoBodyTypeError => 'Выберите тип кузова';

  @override
  String get postCargoPriceError => 'Укажите цену числом';

  @override
  String get postCargoDestinationCountry => 'Страна назначения';

  @override
  String get postCargoDestinationCity => 'Город назначения';

  @override
  String get postCargoBodyType => 'Тип кузова';

  @override
  String get postCargoVolume => 'Объём, м³';

  @override
  String get postCargoWeight => 'Вес';

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
  String get chatAttachLocation => 'Отправить моё место';

  @override
  String get chatLocationMessagePrefix => 'Точка на карте';

  @override
  String get chatLocationError => 'Не удалось определить местоположение';

  @override
  String get locationRationaleTitle => 'Геопозиция';

  @override
  String get locationRationaleBody =>
      'Приложение один раз возьмёт ваше текущее место и отправит ссылку на карту в чат — только в этот чат и только сейчас. Слежки нет: пока вы не в рейсе, местоположение нигде не передаётся.';

  @override
  String get locationRationaleContinue => 'Продолжить';

  @override
  String get chatLoadingPlaceTooltip => 'Место погрузки';

  @override
  String get chatLoadingPlaceDialogTitle => 'Вставьте ссылку на место погрузки';

  @override
  String get chatLoadingPlaceDialogHint => 'Ссылка из Baidu/Amap/2ГИС';

  @override
  String get chatLoadingPlaceMessagePrefix => 'Место погрузки';

  @override
  String get chatLoadingPlaceLinkInvalid =>
      'Нужна ссылка https:// длиной до 500 символов';

  @override
  String get chatTranslatedBadge => 'Переведено';

  @override
  String get chatShowOriginal => 'оригинал';

  @override
  String chatWritesIn(String language) {
    return 'Пишет на $language';
  }

  @override
  String get languageNameRu => 'русском';

  @override
  String get languageNameKk => 'казахском';

  @override
  String get languageNameZh => 'китайском';

  @override
  String get languageNameEn => 'английском';

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
  String get chatCargoReadyButton => 'Готов взять';

  @override
  String get chatResponseSentLabel => 'Отклик отправлен';

  @override
  String get chatWithdrawButton => 'Отозвать';

  @override
  String get chatOfferCargoButton => 'Предложить груз';

  @override
  String get chatResponseClosed => 'Отклик закрыт';

  @override
  String get chatCargoAlreadyHasDeal => 'На этот груз уже выбран водитель';

  @override
  String get chatOfferCargoSheetTitle => 'Выберите груз';

  @override
  String chatSystemDriverReady(String name) {
    return '$name готов взять груз';
  }

  @override
  String chatSystemDriverSelected(String name) {
    return 'Водитель $name выбран для перевозки';
  }

  @override
  String get chatSystemResponseRejected => 'Логист отклонил отклик';

  @override
  String get chatSystemDealConfirmed => 'Перевозка подтверждена водителем';

  @override
  String chatSystemResponseWithdrawn(String name) {
    return '$name отозвал(а) отклик';
  }

  @override
  String get chatSystemCargoOffered => 'Логист предложил груз';

  @override
  String get cargoStatusInDeal => 'В сделке';

  @override
  String get myResponsesTitle => 'Мои отклики';

  @override
  String get myResponsesEmpty => 'Откликов пока нет';

  @override
  String get responseStatusInvited => 'Приглашён';

  @override
  String get chatSystemDriverInvited => 'Логист приглашает водителя на груз';

  @override
  String chatSystemInvitationDeclined(String name) {
    return '$name отказался от приглашения';
  }

  @override
  String get chatSystemCargoTaken => 'Груз ушёл другому водителю';

  @override
  String get cargoInvitedTitle => 'Вас приглашают на этот груз';

  @override
  String get cargoDecline => 'Отказаться';

  @override
  String get cargoNotAvailable => 'Груз уже занят';

  @override
  String get cargoVerifyHint =>
      'Чтобы подтвердить перевозку, пройдите проверку в профиле';

  @override
  String get chatWaitingDriver => 'Ждём ответа водителя';

  @override
  String get cargoResponseSent => 'Отклик отправлен';

  @override
  String get cargoYouAreSelected => 'Вас выбрали';

  @override
  String get chatQuickReplyAtPlace => 'Я на месте';

  @override
  String get chatQuickReplyLoaded => 'Загрузился';

  @override
  String get chatQuickReplyLate1h => 'Опаздываю на 1 час';

  @override
  String get chatQuickReplyCargoReady => 'Груз готов к погрузке';

  @override
  String get chatQuickReplyWhenArrive => 'Когда сможете подъехать?';

  @override
  String get chatQuickReplySendLocation => 'Пришлите, пожалуйста, ваше место';

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
    return 'Кто свободен: $point';
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
  String get driversAtPointTodayShort => 'Сег';

  @override
  String get driversAtPointFilterCapacityChip => 'Тоннаж';

  @override
  String get driversAtPointInviteShort => 'Пригласить';

  @override
  String get driversAtPointFilterAll => 'Все';

  @override
  String get driversAtPointFilterMinCapacityTitle => 'Грузоподъёмность';

  @override
  String driversAtPointMinCapacityLabel(int n) {
    return 'от $n т';
  }

  @override
  String get driversAtPointPickPoint => 'Точка загрузки';

  @override
  String get driversAtPointTitleShort => 'Водители';

  @override
  String get driversAtPointFilterVerifiedChip => 'Проверенные';

  @override
  String driversAtPointNowAtPlace(int count) {
    return 'На месте сейчас · $count';
  }

  @override
  String driversAtPointMoreToday(int count) {
    return 'ещё $count будут сегодня';
  }

  @override
  String driversAtPointWillBeOnDay(String day, int count) {
    return 'Будут $day · $count';
  }

  @override
  String driversAtPointOnSiteAgo(String ago) {
    return 'На месте · $ago';
  }

  @override
  String driversAtPointAgoMinutes(int n) {
    return '$n мин назад';
  }

  @override
  String driversAtPointAgoHours(int n) {
    return '$n ч назад';
  }

  @override
  String get driversAtPointAgoJustNow => 'только что';

  @override
  String driversAtPointPlannedApprox(String day, String time) {
    return '$day ~$time';
  }

  @override
  String get weekdayShort1 => 'Пн';

  @override
  String get weekdayShort2 => 'Вт';

  @override
  String get weekdayShort3 => 'Ср';

  @override
  String get weekdayShort4 => 'Чт';

  @override
  String get weekdayShort5 => 'Пт';

  @override
  String get weekdayShort6 => 'Сб';

  @override
  String get weekdayShort7 => 'Вс';

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
  String get adminBodySizePresetsTab => 'Размеры кузова';

  @override
  String get adminAddBodySizePreset => 'Добавить шаблон размера';

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
  String get adminBlockedByPhoneBadge => 'Номер в чёрном списке';

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
  String get adminBlacklistMatchTitle => 'Совпадение с чёрным списком';

  @override
  String get adminBlacklistMatchIntro =>
      'Среди идентификаторов этой карточки есть активные блокировки:';

  @override
  String get adminBlacklistMatchOverride =>
      'Подтвердить вопреки чёрному списку';

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
  String adminAttentionBlacklistMatches(int count) {
    return 'Совпадения с чёрным списком: $count';
  }

  @override
  String get adminBlockAlsoByTitle => 'Заблокировать также по:';

  @override
  String get adminIdentifierTypeIin => 'ИИН';

  @override
  String get adminIdentifierTypeLicense => 'Номер прав';

  @override
  String get adminIdentifierTypePhone => 'Телефон';

  @override
  String get adminIdentifierTypeVin => 'VIN';

  @override
  String get adminIdentifierTypePlate => 'Госномер';

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
  String get adminVerificationBlacklistedBadge => 'Чёрный список';

  @override
  String get adminConfirmDespiteBlacklist => 'Подтвердить вопреки совпадению';

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
  String get adminRecognitionTitle => 'Распознано';

  @override
  String get adminRecognitionSkipped => 'OCR недоступен — проверьте вручную';

  @override
  String get adminRecognitionPending => 'Распознавание в очереди…';

  @override
  String get adminRecognitionFailed => 'Не удалось распознать';

  @override
  String get adminRecognitionRetry => 'Распознать заново';

  @override
  String get adminRecognitionMatchOk => 'Проверено';

  @override
  String get adminRecognitionNeedsReview => 'Проверьте';

  @override
  String get adminRecognitionDuplicate => 'Дубль у другого владельца';

  @override
  String get adminRecognitionBlacklisted => 'В чёрном списке';

  @override
  String get adminRecognitionBlacklistBanner =>
      'Совпадение с чёрным списком — подтвердить без явного решения нельзя';

  @override
  String get adminRecognitionChecksumHint => 'контрольная цифра верна';

  @override
  String get adminRecognitionEditValue => 'Изменить значение';

  @override
  String get adminRecognitionFieldFullName => 'ФИО';

  @override
  String get adminRecognitionFieldIin => 'ИИН';

  @override
  String get adminRecognitionFieldLicenseNumber => 'Номер прав';

  @override
  String get adminRecognitionFieldExpiryDate => 'Срок действия';

  @override
  String get adminRecognitionFieldBirthDate => 'Дата рождения';

  @override
  String get adminRecognitionFieldPlateNumber => 'Госномер';

  @override
  String get adminRecognitionFieldVin => 'VIN';

  @override
  String get adminRecognitionFieldBrand => 'Марка';

  @override
  String get adminRecognitionFieldCapacityTons => 'Грузоподъёмность, т';

  @override
  String get adminRecognitionFieldCompanyName => 'Название компании';

  @override
  String get adminRecognitionFieldBin => 'БИН';

  @override
  String get adminRecognitionFieldUscc => '统一社会信用代码';

  @override
  String get adminIdentifiersCardTitle => 'Идентификаторы';

  @override
  String get adminIdentifierBlockHistoryTitle => 'История блокировок';

  @override
  String get adminIdentifierLifted => 'Снята';

  @override
  String get adminIdentifierActive => 'Активна';

  @override
  String get adminIdentifierReveal => 'Показать';

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
  String get adminVehicleTractorTitle => 'Тягач';

  @override
  String get adminVehicleTrailerTitle => 'Прицеп';

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

  @override
  String get adminAuditActionAdminViewedChat => 'Админ открыл чат';

  @override
  String get adminAuditActionCargoUnpublished => 'Груз снят с публикации';

  @override
  String get adminAuditActionCargoUpdated => 'Груз изменён';

  @override
  String get adminAuditActionCityUpdated => 'Город изменён';

  @override
  String get adminAuditActionCompanyBlocked => 'Компания заблокирована';

  @override
  String get adminAuditActionCompanyMemberEmailChanged =>
      'Email сотрудника изменён';

  @override
  String get adminAuditActionCompanyMemberRemoved =>
      'Сотрудник удалён из компании';

  @override
  String get adminAuditActionCompanyMemberRoleChanged =>
      'Роль сотрудника изменена';

  @override
  String get adminAuditActionCompanyPasswordReset => 'Пароль компании сброшен';

  @override
  String get adminAuditActionCompanyReturnedForRework =>
      'Документы компании вернули на доработку';

  @override
  String get adminAuditActionCompanyUnblocked => 'Компания разблокирована';

  @override
  String get adminAuditActionCompanyUnverified => 'Компания снята с проверки';

  @override
  String get adminAuditActionCompanyUpdated => 'Данные компании изменены';

  @override
  String get adminAuditActionCompanyVerified => 'Компания подтверждена';

  @override
  String get adminAuditActionComplaintAssigned => 'Жалоба взята в работу';

  @override
  String get adminAuditActionComplaintResolved => 'Жалоба решена';

  @override
  String get adminAuditActionComplaintUnassigned =>
      'Жалоба возвращена в очередь';

  @override
  String get adminAuditActionDealCancelledByAdmin => 'Сделка отменена админом';

  @override
  String get adminAuditActionDealStatusFixed => 'Статус сделки исправлен';

  @override
  String get adminAuditActionDriverReturnedForRework =>
      'Документы водителя вернули на доработку';

  @override
  String get adminAuditActionDriverUnverified => 'Водитель снят с проверки';

  @override
  String get adminAuditActionDriverUpdated => 'Данные водителя изменены';

  @override
  String get adminAuditActionDriverVerified => 'Водитель подтверждён';

  @override
  String get adminAuditActionPointUpdated => 'Точка изменена';

  @override
  String get adminAuditActionSessionsRevoked => 'Сессии завершены';

  @override
  String get adminAuditActionSettingChanged => 'Настройка изменена';

  @override
  String get adminAuditActionUserBlocked => 'Пользователь заблокирован';

  @override
  String get adminAuditActionUserUnblocked => 'Пользователь разблокирован';

  @override
  String get adminAuditActionBodyTypeUpdated => 'Тип кузова изменён';

  @override
  String get adminAuditActionPermitUpdated => 'Допуск изменён';

  @override
  String get adminAuditFieldDestinationCountry => 'Страна назначения';

  @override
  String get adminAuditFieldDestinationCity => 'Город назначения';

  @override
  String get adminAuditFieldBodyType => 'Тип кузова';

  @override
  String get adminAuditFieldWeight => 'Вес, кг';

  @override
  String get adminAuditFieldVolume => 'Объём, м³';

  @override
  String get adminAuditFieldPhotos => 'Фото';

  @override
  String get adminAuditFieldPrice => 'Цена';

  @override
  String get adminAuditFieldCurrency => 'Валюта';

  @override
  String get adminAuditFieldReadyDate => 'Дата готовности';

  @override
  String get adminAuditFieldDescription => 'Описание';

  @override
  String get adminAuditFieldName => 'Название';

  @override
  String get adminAuditFieldNameRu => 'Название (рус.)';

  @override
  String get adminAuditFieldCountry => 'Страна';

  @override
  String get adminAuditFieldCity => 'Город';

  @override
  String get adminAuditFieldLegalAddress => 'Юридический адрес';

  @override
  String get adminAuditFieldTaxId => 'ИНН/БИН';

  @override
  String get adminAuditFieldFullName => 'Имя';

  @override
  String get adminAuditFieldPhone => 'Телефон';

  @override
  String get adminAuditFieldHomeCity => 'Домашний город';

  @override
  String get adminAuditFieldAnyCountry => 'Любая страна';

  @override
  String get adminAuditFieldCountries => 'Страны';

  @override
  String get adminAuditFieldPermits => 'Допуски';

  @override
  String get adminAuditFieldVehicle => 'Транспорт';

  @override
  String get adminAuditFieldPlateNumber => 'Госномер';

  @override
  String get adminAuditFieldCapacity => 'Грузоподъёмность, т';

  @override
  String get adminAuditFieldLength => 'Длина, м';

  @override
  String get adminAuditFieldBrand => 'Марка';

  @override
  String get adminAuditFieldIsActive => 'Активен';

  @override
  String get adminAuditFieldSortOrder => 'Порядок';

  @override
  String get adminAuditFieldStatus => 'Статус';

  @override
  String get postCargoVerificationRequired =>
      'Публикация грузов откроется после проверки компании — загрузите свидетельство о регистрации в профиле';

  @override
  String get companyNotVerifiedBannerText =>
      'Компания не проверена. Можно смотреть водителей и писать им, но нельзя опубликовать груз — загрузите свидетельство о регистрации ниже';

  @override
  String get companyEditTitle => 'Данные компании';

  @override
  String get companyEditCityLabel => 'Город';

  @override
  String get companyEditLegalAddressLabel => 'Юридический адрес';

  @override
  String get companyEditTaxIdLabel => 'Рег. номер (统一社会信用代码 / БИН)';

  @override
  String get companyEditTaxIdError =>
      'Неверный формат рег. номера для вашей страны';

  @override
  String get myProfileTitle => 'Мой профиль';

  @override
  String get myProfileNameLabel => 'Имя';

  @override
  String get myProfilePhoneLabel => 'Телефон для водителей';

  @override
  String get myProfileWechatLabel => 'WeChat';

  @override
  String get myProfileNameError => 'Введите имя';

  @override
  String get myProfileNotSetYet => 'Заполните профиль';

  @override
  String get companyVerificationTitle => 'Подтвердите компанию';

  @override
  String get companyVerificationHint =>
      'Загрузите свидетельство о регистрации — сверим с реестром и позвоним на номер из реестра, обычно до 1 рабочего дня';

  @override
  String get companyVerificationStatusNone => 'Документ не загружен';

  @override
  String get companyVerificationStatusPending => 'На проверке';

  @override
  String get companyVerificationStatusRejected => 'Нужно переснять';

  @override
  String get adminNavSearch => 'Поиск';

  @override
  String get adminNavMore => 'Ещё';

  @override
  String get garageTitle => 'Мой гараж';

  @override
  String get garageAddDocument => 'Добавить документ';

  @override
  String get garageDocumentSent => 'Техпаспорт отправлен на проверку';

  @override
  String get garageTractorsSection => 'ТЯГАЧИ';

  @override
  String get garageTrailersSection => 'ПРИЦЕПЫ';

  @override
  String get garageVerified => 'проверена';

  @override
  String get garagePending => 'на проверке';

  @override
  String get garageAddedYesterday => 'добавлен вчера';

  @override
  String get garageAddVehicle => 'Добавить машину или прицеп';

  @override
  String get garageEmptyTractors => 'Нет тягачей';

  @override
  String get garageEmptyTrailers => 'Нет прицепов';

  @override
  String get garageOcrHint =>
      'Сфотографируйте техпаспорт — госномер и VIN заполнятся сами. Проверьте и отправьте.';

  @override
  String get garageArchive => 'В архив';

  @override
  String get garageArchived => 'Машина перенесена в архив';

  @override
  String get garageKindTitle => 'Какая машина?';

  @override
  String get garageKindTractor => 'Тягач';

  @override
  String get garageKindTrailer => 'Прицеп';

  @override
  String get garageVin => 'VIN';

  @override
  String get garageLength => 'Длина, м';

  @override
  String get garagePhotoRequired => 'Сфотографируйте техпаспорт';

  @override
  String get garageSubmit => 'Отправить на проверку';

  @override
  String get garageAddFailed => 'Не удалось добавить машину';

  @override
  String get garageFieldRequired => 'Заполните поле';

  @override
  String get garageComboTitle => 'На чём едете?';

  @override
  String get garageComboTractorLabel => 'Тягач';

  @override
  String get garageComboTrailerLabel => 'Прицеп';

  @override
  String get garageComboPendingBadge => 'на проверке';

  @override
  String get garageComboEmpty =>
      'В гараже пока пусто — добавьте машину в профиле';

  @override
  String get garageGoToGarage => 'Мой гараж';

  @override
  String get cityPickerTitle => 'Выберите город';

  @override
  String get cityPickerSearchHint => 'Поиск города';

  @override
  String get cityPickerNearby => 'Рядом со мной';

  @override
  String get cityPickerNearbyNotFound =>
      'Рядом нет подходящего города — выберите из списка';

  @override
  String get cityPickerRecent => 'Недавние';

  @override
  String get cityPickerAll => 'Все города';

  @override
  String get cityPickerNothingFound => 'Ничего не найдено';

  @override
  String get cityFieldPlaceholder => 'Выберите город';

  @override
  String get announceArrivalCityError => 'Выберите город, где вы свободны';

  @override
  String get announceArrivalAddAnother => 'Ещё один анонс';

  @override
  String get announceArrivalOthers => 'Дальше в планах';

  @override
  String get announceArrivalLimit => 'Не больше пяти анонсов одновременно';

  @override
  String get arrivalQuestionDay => 'Доехали? Нажмите «Я на месте»';

  @override
  String get arrivalQuestionStill => 'Ещё ищете груз?';

  @override
  String get arrivalStillYes => 'Да, ищу';

  @override
  String get arrivalStillLeft => 'Уехал';

  @override
  String get feedBadgePartial => 'Догруз';

  @override
  String get feedLoadMore => 'Показать ещё';

  @override
  String cargoPartialHintFits(String committed, String cargo, String capacity) {
    return 'Помещается к текущему: $committed т + $cargo т из $capacity т';
  }

  @override
  String cargoPartialHintFull(String committed, String cargo, String capacity) {
    return 'Не поместится к текущему: $committed т + $cargo т из $capacity т';
  }

  @override
  String get cargoPartialHintNextTrip =>
      'Другая дата погрузки — это следующий рейс, а не догруз';

  @override
  String get cargoPickupCityLabel => 'Город погрузки';

  @override
  String get postCargoPickupCity => 'Город погрузки';

  @override
  String get postCargoPickupCityError => 'Выберите город погрузки';

  @override
  String get postCargoAllowPartial => 'Можно догрузом';

  @override
  String get postCargoAllowPartialHint =>
      'Груз не на всю машину — водитель может взять ещё';

  @override
  String get notificationGroupArrivalCheck =>
      'Напоминания об анонсе («Доехали?»)';

  @override
  String get adminPointKind => 'Вид точки';

  @override
  String get adminPointKindCity => 'Город';

  @override
  String get adminPointKindTerminal => 'Терминал (геозона)';

  @override
  String get adminPointRadius => 'Радиус геозоны, м';

  @override
  String get adminPointTerminalNeedsGeofence =>
      'Для терминала нужны широта, долгота и радиус';

  @override
  String get adminCityStatsTitle => 'По городам';

  @override
  String get adminCityStatsArrivals => 'Анонсы';

  @override
  String get adminCityStatsCargos => 'Грузы';

  @override
  String get adminCityStatsDeals => 'Сделки';

  @override
  String get adminCityStatsEmpty => 'Пока нет активности по городам';

  @override
  String get consentUnderstood => 'Понятно';

  @override
  String get tripTrackingConsentTitle => 'Местоположение на время рейса';

  @override
  String get tripTrackingConsentBody =>
      'На время рейса приложение будет передавать ваше местоположение логисту. Это можно поставить на паузу в карточке сделки.';

  @override
  String get tripTrackingSwitchTitle => 'Передавать местоположение логисту';

  @override
  String get tripTrackingSwitchOn => 'Включено на время рейса';

  @override
  String get tripTrackingSwitchPaused => 'На паузе — логист не видит, где вы';

  @override
  String get terminalWatchConsentTitle => 'Отметка «уехал» по местоположению';

  @override
  String get terminalWatchConsentBody =>
      'Пока вы «на месте» на терминале, приложение будет проверять, не уехали ли вы, и закроет анонс само. Местоположение логисту при этом не передаётся.';

  @override
  String get locationRationaleNearbyBody =>
      'Приложение один раз определит ваше местоположение, чтобы найти ближайший город. Оно нигде не сохраняется, слежки нет.';

  @override
  String get loginChannelTitle => 'Куда прислать код';

  @override
  String get loginChannelWhatsapp => 'WhatsApp';

  @override
  String get loginChannelTelegram => 'Telegram';

  @override
  String get loginChannelSms => 'SMS';

  @override
  String loginCodeSentVia(String channel) {
    return 'Код отправлен: $channel';
  }

  @override
  String get loginSendOtherWay => 'Не пришло? Отправить по-другому';

  @override
  String get adminLoginChannelsTitle => 'Каналы кода входа';

  @override
  String get adminLoginChannelsHint =>
      'Порядок — сверху вниз: первый включённый предлагается водителю по умолчанию, при сбое код уходит следующим.';

  @override
  String get adminLoginChannelsNoKeys => 'нет ключей';

  @override
  String get adminMoveUp => 'Выше';

  @override
  String get adminMoveDown => 'Ниже';

  @override
  String get adminLoginChannelsSaved => 'Каналы сохранены';

  @override
  String get pushChannelName => 'Уведомления Lubao';

  @override
  String get postCargoWeightError => 'Вес — до 60 т (60 000 кг)';

  @override
  String get companyLoginInvalidCredentials => 'Неверный email или пароль';

  @override
  String get mapsOpen => 'Открыть в картах';

  @override
  String get mapsApple => 'Apple Карты';

  @override
  String get mapsGoogle => 'Google Maps';

  @override
  String get mapsYandex => 'Яндекс Карты';

  @override
  String get maps2gis => '2ГИС';

  @override
  String get mapsAmap => '高德地图 (Amap)';

  @override
  String get mapsBaidu => '百度地图 (Baidu)';

  @override
  String get mapsCopyCoordinates => 'Скопировать координаты';

  @override
  String get mapsCoordinatesCopied => 'Координаты скопированы';

  @override
  String get adminRatesTitle => 'Курсы валют (НБ РК)';

  @override
  String get adminRatesHint =>
      'Обновляются сами каждый день в 10:00 по курсу Нацбанка. Ручная правка автоматически не перезаписывается.';

  @override
  String get adminRateEdit => 'Изменить курс';

  @override
  String chatSystemDriverSaysAgreed(String name) {
    return '$name: договорились — выберите водителя, чтобы сделка пошла по шагам';
  }

  @override
  String get adminNavBlacklist => 'Чёрный список';

  @override
  String get adminBlacklistAdd => 'Добавить в чёрный список';

  @override
  String get adminBlacklistType => 'Что блокируем';

  @override
  String get adminBlacklistValue => 'Значение';

  @override
  String get adminBlacklistLift => 'Снять блокировку';

  @override
  String get adminBlacklistLifted => 'Снята';

  @override
  String get adminBlacklistEmpty => 'Чёрный список пуст';

  @override
  String get adminBlacklistShowLifted => 'Показать снятые';

  @override
  String get adminIdentifierTypeBin => 'БИН';

  @override
  String get adminIdentifierTypeUscc => 'USCC (КНР)';

  @override
  String get adminBlacklistInvalid => 'Значение не подходит для этого типа';

  @override
  String get profileDeleteAccount => 'Удалить аккаунт';

  @override
  String get profileDeleteAccountTitle => 'Удалить аккаунт?';

  @override
  String get profileDeleteAccountBody =>
      'Имя, телефон, email, документы и данные машин будут удалены, вход в аккаунт закроется на всех устройствах. Завершённые сделки и отзывы останутся без вашего имени. Отменить удаление нельзя.';

  @override
  String get profileDeleteAccountConfirm => 'Удалить';

  @override
  String get profileDeleteAccountActiveDeals =>
      'Сначала завершите или отмените активные сделки.';

  @override
  String get profileDeleteAccountOwnerHasMembers =>
      'В компании есть сотрудники: сначала передайте владение или удалите их.';

  @override
  String get pdConsentTitle => 'Согласие на обработку данных';

  @override
  String get pdConsentBody =>
      'Чтобы проверить вас, мы храним фото документов и данные из них (ФИО, ИИН, номер прав, госномер, VIN). Данные хранятся на серверах в Казахстане, видны только проверяющему администратору и не передаются третьим лицам. Документы удаляются вместе с аккаунтом.';

  @override
  String get pdConsentCheckbox =>
      'Я согласен на сбор и обработку моих персональных данных';

  @override
  String get pdConsentContinue => 'Продолжить';

  @override
  String get legalTerms => 'Условия использования';

  @override
  String get legalPrivacy => 'Политика конфиденциальности';

  @override
  String get appUpdateTitle => 'Обновите приложение';

  @override
  String get appUpdateBody =>
      'Эта версия больше не поддерживается. Установите новую — это займёт минуту.';

  @override
  String get appUpdateButton => 'Обновить';

  @override
  String get legalOffer => 'Оферта для компаний';

  @override
  String get companyRegisterOfferAccept =>
      'Я принимаю оферту: Lubao — информационная площадка, не перевозчик и не сторона договора перевозки';

  @override
  String legalLoginNotice(String terms, String privacy) {
    return 'Продолжая, вы принимаете $terms и $privacy';
  }

  @override
  String get legalTermsLink => 'Условия';

  @override
  String get legalPrivacyLink => 'Политику конфиденциальности';

  @override
  String get aboutTitle => 'О приложении';

  @override
  String aboutVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get contactRespondFirst =>
      'Откликнитесь на груз — и появится телефон логиста. После проверки документов звонить можно сразу.';

  @override
  String get contactDailyLimit =>
      'На сегодня открыто слишком много номеров. Попробуйте завтра или напишите в чат.';

  @override
  String get contactCompanyNotVerified =>
      'Звонить водителям можно после проверки компании. Пока — напишите в чат.';

  @override
  String get contactNoPhone => 'Номер не указан — напишите в чат.';

  @override
  String get tooManyRequests => 'Слишком много запросов. Подождите минуту.';

  @override
  String adminSuspiciousTitle(String name, int count) {
    return 'Похоже на парсинг: $name — $count номеров за сутки';
  }

  @override
  String adminSuspiciousLimitHits(int count) {
    return 'Упирался в суточный лимит: $count';
  }

  @override
  String get adminSuspiciousOk => 'Всё в порядке';

  @override
  String get adminSuspiciousBlock => 'Заблокировать';

  @override
  String get vehiclePhotoFront => 'Спереди, с госномером';

  @override
  String get vehiclePhotoSide => 'Сбоку';

  @override
  String get vehiclePhotoStepTitle => 'Сфотографируйте машину';

  @override
  String get vehiclePhotoStepHint =>
      'Логист увидит машину в вашей карточке и в документах на рейс. Можно пропустить и добавить позже.';

  @override
  String get commonSkip => 'Пропустить';

  @override
  String get garagePhotosReminder => 'Добавьте фото машины';

  @override
  String get vehiclePhotosNone => 'Фото нет';

  @override
  String get driverDocsTitle => 'Документы водителя';

  @override
  String get driverDocsLocked => 'Откроются после подтверждения водителем';

  @override
  String get driverDocsDownloadPdf => 'Скачать PDF';

  @override
  String get driverDocsOpen => 'Документы';

  @override
  String get driverDocsVehiclePending => 'Машина ещё на проверке';

  @override
  String get driverDocsIin => 'ИИН';

  @override
  String get driverDocsLicense => 'Водительское удостоверение';

  @override
  String get driverDocsSelfie => 'Фото водителя';

  @override
  String get driverDocsPassport => 'Техпаспорт';

  @override
  String get driverDocsExpired =>
      'Документы закрыты: прошло 30 дней после доставки';

  @override
  String cargoDealDriverConfirmed(String name) {
    return 'Водитель: $name · подтвердил';
  }

  @override
  String cargoDealDriverWaiting(String name) {
    return 'Водитель: $name · ждём подтверждения';
  }

  @override
  String dealConfirmDocsNotice(String company) {
    return 'Логисту $company откроются ваши документы на рейс: удостоверение, права, техпаспорта. Только по этой сделке.';
  }

  @override
  String dealDocsOpenedAt(String when) {
    return 'Логист открыл документы $when';
  }

  @override
  String get dealDocsAccessTitle => 'Кто открывал документы';

  @override
  String get adminVehicleAutoVerified => 'Проверена автоматически';

  @override
  String get adminVehicleRevoke => 'Отозвать проверку';

  @override
  String get garageEmptyTitle => 'Добавьте машину';

  @override
  String get garageEmptyBody =>
      'Сфотографируйте техпаспорт — госномер и VIN заполнятся сами.';

  @override
  String get garageNoPlate => 'Без номера';

  @override
  String get feedStateResponded => 'Вы откликнулись';

  @override
  String get feedStateInvited => 'Вас приглашают';

  @override
  String get feedStateSelected => 'Вы выбраны — подтвердите';

  @override
  String feedStateOthers(int count) {
    return 'Откликнулись: $count';
  }

  @override
  String homeMyResponsesSummary(int total) {
    return 'Ваши отклики: $total';
  }

  @override
  String homeMyResponsesPending(int count) {
    return 'ждут ответа $count';
  }

  @override
  String homeMyResponsesInvited(int count) {
    return 'приглашение $count';
  }

  @override
  String homeMyResponsesSelected(int count) {
    return 'выбраны $count';
  }

  @override
  String get driverSetupFirstName => 'Как вас зовут';

  @override
  String get directionRegionsAll => 'Вся страна';

  @override
  String directionRegionsCount(int count) {
    return 'Области: $count';
  }

  @override
  String directionRegionsTitle(String country) {
    return 'Куда в $country';
  }

  @override
  String get driverSetupPermitsOptional => 'Допуски — если есть';

  @override
  String licenseNameBanner(String name) {
    return 'В правах: $name. Подставить в профиль?';
  }

  @override
  String get licenseNameAccept => 'Да, это я';

  @override
  String statusLookingFrom(String city) {
    return 'Ищу груз из $city';
  }

  @override
  String statusOnTheWay(String city, String day) {
    return 'Еду, буду в $city $day';
  }

  @override
  String get statusInTrip => 'В рейсе';

  @override
  String get statusNotLooking => 'Не ищу';

  @override
  String get whereNowTitle => 'Где вы сейчас?';

  @override
  String get whereNowGoing => 'Еду, буду в …';

  @override
  String get whereNowNotLooking => 'Пока не ищу';

  @override
  String get whereNowOtherCity => 'Я в другом городе';

  @override
  String whereNowGpsHint(String city) {
    return 'Вы теперь в $city?';
  }

  @override
  String deliveredAskTitle(String city) {
    return 'Вы в $city. Ищете груз отсюда?';
  }

  @override
  String get unitM => 'м';

  @override
  String get unitLiters => 'л';

  @override
  String get unitCelsius => '°C';

  @override
  String get unitCars => 'маш.';

  @override
  String get unitSlots => 'шт.';

  @override
  String get unitSections => 'секц.';

  @override
  String get bodySpecsTitle => 'Параметры кузова';

  @override
  String get cargoSpecsTitle => 'Параметры груза';

  @override
  String get cargoExtraBodyTypes => 'Подходят также';

  @override
  String get specYes => 'да';

  @override
  String get specNo => 'нет';

  @override
  String get adminBodyTypeNameEdit => 'Название и порядок';

  @override
  String get adminBodyTypeProfileEdit => 'Профиль и поля';

  @override
  String get adminBodyTypeProfile => 'Профиль';

  @override
  String get adminBodyTypeFieldsJson => 'Поля (JSON)';

  @override
  String adminBodyTypeFieldsInvalid(String errors) {
    return 'Поля не сохранены: $errors';
  }

  @override
  String get dealStatusCancelRequested => 'Запрошена отмена';

  @override
  String get dealStatusDisputed => 'Отмена оспорена';

  @override
  String get cancelReasonVehicleBreakdown => 'Машина сломалась';

  @override
  String get cancelReasonCargoNotReady => 'Груз не готов';

  @override
  String get cancelReasonOtherPartyUnresponsive => 'Вторая сторона не отвечает';

  @override
  String get cancelReasonTermsChanged => 'Изменились условия';

  @override
  String get cancelReasonOther => 'Другое';

  @override
  String get dealCancelReasonPick => 'Почему отменяете?';

  @override
  String get dealCancelOtherHint => 'Опишите причину';

  @override
  String get dealCancelRequestNotice =>
      'Груз уже в пути — отмена только с согласия второй стороны. Без ответа за 24 часа она пройдёт сама.';

  @override
  String get dealCancelRequestSend => 'Отправить запрос';

  @override
  String dealCancelRequestedByMe(String time) {
    return 'Вы запросили отмену. Ждём ответа до $time';
  }

  @override
  String dealCancelRequestedByOther(String name, String reason, String time) {
    return '$name просит отменить сделку: $reason. Без ответа до $time отмена пройдёт';
  }

  @override
  String get dealCancelConfirm => 'Подтвердить отмену';

  @override
  String get dealCancelDispute => 'Оспорить';

  @override
  String get dealDisputeReasonLabel => 'Почему вы не согласны?';

  @override
  String get dealDisputedNotice => 'Отмена оспорена — решит администратор';

  @override
  String cancelStatsLine(int cancelled, int total) {
    return 'отменил $cancelled из $total';
  }

  @override
  String cancelStatsAfterLoad(int count) {
    return 'после загрузки $count';
  }

  @override
  String get complaintOfferTitle => 'Пожаловаться?';

  @override
  String get complaintOfferBody =>
      'Сделку отменили, когда груз уже был в машине. Расскажите администратору, что случилось.';

  @override
  String get complaintReasonLabel => 'Что случилось';

  @override
  String get complaintSend => 'Пожаловаться';

  @override
  String get complaintSent => 'Жалоба отправлена';

  @override
  String chatSystemCancelRequested(String reason) {
    return 'Запрошена отмена сделки: $reason. Без ответа за 24 часа отмена пройдёт';
  }

  @override
  String get chatSystemCancelConfirmed =>
      'Отмена подтверждена — сделка отменена';

  @override
  String get chatSystemCancelDisputed =>
      'Отмена оспорена — решит администратор';

  @override
  String get chatSystemCancelResolved => 'Администратор отменил сделку';

  @override
  String get chatSystemCancelResumed =>
      'Администратор вернул сделку в «В пути»';

  @override
  String get chatSystemCancelAuto =>
      'Ответа на запрос отмены не было 24 часа — сделка отменена';

  @override
  String get adminDisputesTitle => 'Споры об отмене';

  @override
  String adminDisputeRequested(String who, String reason) {
    return '$who просит отмену: $reason';
  }

  @override
  String adminDisputeObjection(String reason) {
    return 'Возражение: $reason';
  }

  @override
  String get adminDisputeCancelDriver => 'Отменить — виноват водитель';

  @override
  String get adminDisputeCancelCompany => 'Отменить — виновата компания';

  @override
  String get adminDisputeCancelNeutral => 'Отменить — без вины';

  @override
  String get adminDisputeResume => 'Вернуть в «В пути»';

  @override
  String get adminCancellationsTitle => 'Отмены';

  @override
  String get cancelStageBeforeConfirm => 'до подтверждения';

  @override
  String get cancelStageAfterConfirm => 'после подтверждения';

  @override
  String get cancelStageAfterLoad => 'после загрузки';

  @override
  String get cancelStageInTransit => 'в пути';

  @override
  String get cancelAtFault => 'по своей вине';

  @override
  String get unitKm => 'км';

  @override
  String get feedLoadToday => 'погрузка сегодня';

  @override
  String get feedLoadTomorrow => 'погрузка завтра';

  @override
  String feedLoadOn(String date) {
    return 'погрузка $date';
  }

  @override
  String perKmKzt(String value) {
    return '$value ₸/км';
  }

  @override
  String feedRespondedCount(int count) {
    return 'откликнулись $count';
  }

  @override
  String cargoMarketMonth(String from, String to) {
    return 'Рынок за месяц: $from–$to ₸/км';
  }

  @override
  String get postCargoCategory => 'Что везёте';

  @override
  String get postCargoCategoryRequired => 'Выберите категорию груза';

  @override
  String postCargoMarketHint(String median, int deals) {
    return 'По этому маршруту за месяц: медиана $median ₸/км, сделок $deals';
  }

  @override
  String postCargoDistanceHint(String km) {
    return '≈ $km км по дорогам';
  }

  @override
  String postCargoDistancePerKm(String km, String perKm) {
    return '≈ $km км по дорогам · ваша цена ≈ $perKm ₸/км';
  }

  @override
  String get postCargoDistanceCounting => 'Считаем расстояние…';

  @override
  String get adminRoutePricesTitle => 'Цены по маршрутам';

  @override
  String get adminRoutePricesEmpty =>
      'Пока мало данных: статистика появляется при 5+ точках по маршруту за месяц';

  @override
  String get adminColBucket => 'Направление';

  @override
  String get adminColTonnage => 'Тоннаж';

  @override
  String get adminColMedian => 'Медиана ₸/км';

  @override
  String get adminColRange => 'P25–P75';

  @override
  String get adminColPoints => 'Точек';

  @override
  String get adminColDealPoints => 'Из них сделок';

  @override
  String get adminExportCsv => 'Выгрузить CSV';

  @override
  String get adminAllFilter => 'Все';

  @override
  String get bucketKz => 'Внутри РК';

  @override
  String get bucketCis => 'СНГ';

  @override
  String get bucketCnFar => 'Китай / дальнее';

  @override
  String tonnageUpTo(int tons) {
    return 'до $tons т';
  }

  @override
  String get tonnageOver => 'больше 10 т';

  @override
  String get adminCargoCategoriesTitle => 'Категории груза';

  @override
  String get adminCsvSaved => 'CSV сохранён';

  @override
  String get dealVehicleOneDealTitle => 'Машина занята';

  @override
  String get dealVehicleOneDealBody =>
      'Для этой машины одна перевозка за раз — завершите текущую.';

  @override
  String get adminSettingPartialLoads => 'Догруз (сборные грузы)';

  @override
  String get adminSettingPartialLoadsHint =>
      'Выключен — одна перевозка на машину, без пометки «можно догрузом». Включён — догруз только для тента, изотерма и рефа.';

  @override
  String adminRecognitionDuplicateOf(String name) {
    return 'Дубликат у $name';
  }

  @override
  String get driverLoginTelegram => 'Войти через Telegram';

  @override
  String get driverLoginTelegramWaiting =>
      'Откройте Telegram, нажмите «Старт», затем «Поделиться номером» — вход произойдёт сам';

  @override
  String get driverLoginTelegramExpired =>
      'Ссылка для входа устарела — нажмите «Войти через Telegram» ещё раз';

  @override
  String get driverLoginOrPhone => 'или по номеру телефона';

  @override
  String get loginChannelTelegramBot => 'Бот Telegram (вход без кода)';

  @override
  String get vehiclePhotoFrontTitle => 'Спереди';

  @override
  String get vehiclePhotoFrontHint => 'Чтобы читался госномер';

  @override
  String get vehiclePhotoSideTitle => 'Сбоку';

  @override
  String get vehiclePhotoSideHint => 'Вся машина целиком, с прицепом';

  @override
  String get vehiclePhotoTake => 'Сфотографировать';

  @override
  String get vehiclePhotoRetake => 'Переснять';

  @override
  String get vehiclePhotoFailed => 'Не отправилось';

  @override
  String profileAddVehicleRegistered(String details) {
    return 'При регистрации: $details. Без госномера и техпаспорта логист не видит вашу машину и не отдаст груз.';
  }

  @override
  String get profileAddVehiclePlain =>
      'Без госномера и техпаспорта логист не видит вашу машину и не отдаст груз.';

  @override
  String get garageAddPhotoChip => 'Добавьте фото';

  @override
  String get avatarOfferTitle => 'Поставить это фото в профиль?';

  @override
  String get avatarOfferBody => 'Логисты будут видеть его';

  @override
  String get avatarOfferYes => 'Да';

  @override
  String get avatarOfferOther => 'Сделать другое';

  @override
  String get avatarOfferLater => 'Не сейчас';

  @override
  String get avatarAdd => 'Добавить фото';

  @override
  String get avatarChange => 'Сменить фото';

  @override
  String get avatarRemove => 'Убрать фото';

  @override
  String get avatarHint => 'Логисты видят фото рядом с вашим именем';

  @override
  String get adminAvatarRemoveReason => 'Причина (например, жалоба на фото)';

  @override
  String postCargoWeightLooksLikeKg(String kg, String tons) {
    return 'Это $kg кг = $tons т?';
  }

  @override
  String postCargoWeightLooksLikeTons(String tons) {
    return 'Может, $tons т?';
  }

  @override
  String get cargosTabActive => 'Активные';

  @override
  String get cargosTabWork => 'В работе';

  @override
  String get cargosTabArchive => 'Архив';

  @override
  String get cargosEmptyActive => 'Активных грузов нет — опубликуйте груз';

  @override
  String get cargosEmptyWork => 'Сейчас нет грузов в работе';

  @override
  String get cargosEmptyArchive => 'В архиве пусто';

  @override
  String get cargoRepeat => 'Повторить';

  @override
  String get cargosArchiveCity => 'Город';

  @override
  String get cargosArchivePeriod => 'Период';

  @override
  String get cargosArchiveReset => 'Сбросить';

  @override
  String cargoResponsesCount(int count) {
    return 'Отклики: $count';
  }

  @override
  String cargoResponsesNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count новых',
      many: '$count новых',
      few: '$count новых',
      one: '1 новый',
    );
    return '$_temp0';
  }

  @override
  String get navTrips => 'Мои рейсы';

  @override
  String get tripsTitle => 'Мои рейсы';

  @override
  String get tripsNeedAnswer => 'Нужно ответить';

  @override
  String get tripsWaiting => 'Жду ответа логиста';

  @override
  String get tripsInWork => 'В работе';

  @override
  String get tripsSelectedBadge => 'Вас выбрали — подтвердите';

  @override
  String get tripsConfirm => 'Подтвердить рейс';

  @override
  String tripsInvitedBadge(int hours) {
    return 'Вас пригласили · осталось $hours ч';
  }

  @override
  String get tripsAccept => 'Готов взять';

  @override
  String get tripsDecline => 'Отказаться';

  @override
  String get tripsWithdraw => 'Отозвать отклик';

  @override
  String get tripsEmpty => 'Откликайтесь на грузы в ленте';

  @override
  String get tripsGoFeed => 'В ленту';

  @override
  String get historyTitle => 'История рейсов';

  @override
  String get historyAll => 'Все';

  @override
  String get historyDelivered => 'Доставлено';

  @override
  String get historyFailed => 'Не сложилось';

  @override
  String get historyEmpty => 'Здесь появятся завершённые рейсы';

  @override
  String get closeReasonTakenByOther => 'Груз ушёл другому';

  @override
  String get closeReasonRejectedByLogist => 'Логист отказал';

  @override
  String get closeReasonWithdrawn => 'Вы отозвали';

  @override
  String get closeReasonInviteExpired => 'Приглашение истекло';

  @override
  String get closeReasonCargoClosed => 'Груз снят';

  @override
  String get closeReasonCargoArchived => 'Груз в архиве';

  @override
  String get closeReasonDealCancelled => 'Сделка отменена';

  @override
  String get closeReasonAccountDeleted => 'Аккаунт удалён';

  @override
  String homeActionSelected(String route, String price) {
    return 'Вас выбрали на $route, $price';
  }

  @override
  String get homeActionSelectedCta => 'Подтвердить в «Моих рейсах» →';

  @override
  String homeActionInvited(String route, int hours) {
    return 'Вас пригласили на $route · осталось $hours ч';
  }

  @override
  String get homeActionInvitedCta => 'Ответить →';

  @override
  String get profileTripHistory => 'История рейсов';

  @override
  String responsesInactive(int count) {
    return 'Неактивные · $count';
  }

  @override
  String get responsesWaitingDriver => 'ждём ответа водителя';

  @override
  String get responsesNewDot => 'Новый отклик';

  @override
  String get shareButton => 'Поделиться';

  @override
  String get shareAllButton => 'Все';

  @override
  String get shareAllWeb => 'Поделиться всеми';

  @override
  String get shareDialogCargo => 'Поделиться грузом';

  @override
  String get shareDialogAll => 'Поделиться всеми грузами';

  @override
  String get shareDialogDriver => 'Поделиться анонсом';

  @override
  String get shareCopyText => 'Копировать текст';

  @override
  String get shareTextCopied => 'Текст скопирован';

  @override
  String get shareLinkButton => 'Ссылка';

  @override
  String get shareLinkCopied => 'Ссылка скопирована';

  @override
  String get shareWeChatQr => 'WeChat — QR';

  @override
  String get shareWeChatHint =>
      'WeChat: отсканируйте телефоном — текст уже скопирован, вставьте в чат';

  @override
  String get shareEditHint => 'Текст можно поправить перед отправкой';

  @override
  String shareCargoLoading(String date) {
    return 'погрузка $date';
  }

  @override
  String shareCargoRespond(String url) {
    return 'Откликнуться: $url';
  }

  @override
  String shareAllTitle(String company) {
    return '$company — грузы на сегодня';
  }

  @override
  String shareAllFooter(String url) {
    return 'Все грузы и отклик: $url';
  }

  @override
  String get shareDriverTitle => 'Свободна фура';

  @override
  String shareDriverFrom(String city, String date) {
    return '$city, с $date';
  }

  @override
  String get shareDriverAnyDirection => 'в любую сторону';

  @override
  String shareDriverDirection(String countries) {
    return 'направление: $countries';
  }

  @override
  String shareDriverOffer(String url) {
    return 'Предложить груз: $url';
  }

  @override
  String get shareVerified => 'Проверен';

  @override
  String get shareOpenFailed => 'Ссылка не открылась — возможно, она устарела';

  @override
  String get shareCompanyCargosTitle => 'Грузы компании';

  @override
  String adminShareStats(int links, int opens, int came) {
    return 'Поделились: $links · открытий: $opens · пришло по ссылкам: $came';
  }

  @override
  String get driverCardTitle => 'Водитель';

  @override
  String get driverCardNotLooking => 'Сейчас не ищет груз';

  @override
  String driverCardTrips(int count) {
    return 'Рейсов в Lubao: $count';
  }

  @override
  String get driverCardChat => 'Написать';

  @override
  String get shareLinkPromptText => 'Пришли по ссылке?';

  @override
  String get shareLinkPromptOpen => 'Открыть груз';

  @override
  String get shareLinkPromptNotFound =>
      'Ссылка не найдена — откройте её ещё раз из сообщения';

  @override
  String get commonPaste => 'Вставить';

  @override
  String get driversInvitePickHint => 'Отметьте груз и нажмите «Пригласить»';

  @override
  String driversInviteTitle(String name) {
    return 'Пригласить $name';
  }

  @override
  String get dealVehicleRequired =>
      'Для рейса нужны тягач и прицеп — добавьте недостающее в гараже';
}
