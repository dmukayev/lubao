// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'lubao_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class LubaoLocalizationsKk extends LubaoLocalizations {
  LubaoLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appName => 'Lubao';

  @override
  String get commonCancel => 'Бас тарту';

  @override
  String get commonSave => 'Сақтау';

  @override
  String get commonNext => 'Келесі';

  @override
  String get commonBack => 'Артқа';

  @override
  String get commonDone => 'Дайын';

  @override
  String get commonRetry => 'Қайталау';

  @override
  String get commonLoading => 'Жүктелуде...';

  @override
  String get commonError => 'Бірдеңе дұрыс болмады';

  @override
  String get commonSeeAll => 'Барлығын көру';

  @override
  String get commonCall => 'Қоңырау шалу';

  @override
  String get commonWhatsApp => 'WhatsApp';

  @override
  String get commonChat => 'Чат';

  @override
  String get commonSend => 'Жіберу';

  @override
  String get commonSearch => 'Іздеу';

  @override
  String get commonYes => 'Иә';

  @override
  String get commonNo => 'Жоқ';

  @override
  String get roleSelectTitle => 'Сіз кімсіз?';

  @override
  String get roleSelectSubtitle => 'Lubao-ны қалай пайдаланатыныңызды таңдаңыз';

  @override
  String get roleDriver => 'Жүргізуші';

  @override
  String get roleCompany => 'Логистикалық компания';

  @override
  String get driverLoginTitle => 'Жүргізуші үшін кіру';

  @override
  String get driverLoginPhoneLabel => 'Телефон нөмірі';

  @override
  String get driverLoginPhoneHint => '+7 700 000 00 00';

  @override
  String get driverLoginSendCode => 'Кодты алу';

  @override
  String get driverLoginCodeLabel => 'SMS коды';

  @override
  String get driverLoginVerify => 'Кіру';

  @override
  String get driverLoginCountryLabel => 'Ел';

  @override
  String driverOtpSubtitle(String phone) {
    return 'Код $phone нөміріне жіберілді';
  }

  @override
  String get driverOtpResend => 'Кодты қайта жіберу';

  @override
  String get driverOtpInvalidCode => 'Код дұрыс емес';

  @override
  String get driverOtpTooManyAttempts => 'Әрекет тым көп — жаңа код сұраңыз';

  @override
  String get companyRegisterTitle => 'Жаңа компания';

  @override
  String get companyRegisterOwnerName => 'Атыңыз';

  @override
  String get companyRegisterCompanyName => 'Компания атауы';

  @override
  String get companyRegisterCompanyNameRu => 'Орысша атауы';

  @override
  String get companyRegisterNameError => 'Атауын енгізіңіз, кемінде 2 таңба';

  @override
  String get companyRegisterCountry => 'Ел';

  @override
  String get companyRegisterCountryError => 'Елді таңдаңыз';

  @override
  String get companyRegisterOtherCountry => 'Басқа';

  @override
  String get companyRegisterSubmit => 'Компания құру';

  @override
  String get companyRegisterEmailError => 'Email енгізіңіз';

  @override
  String get companyRegisterPasswordError => 'Кемінде 8 таңба';

  @override
  String get companyRegisterEmailTaken =>
      'Бұл email бұрын тіркелген. Кіру керек пе?';

  @override
  String get companyLoginTitle => 'Компания үшін кіру';

  @override
  String get companyLoginEmailLabel => 'Email';

  @override
  String get companyLoginVerify => 'Кіру';

  @override
  String get companyLoginLockedOut =>
      'Әрекет тым көп. 15 минуттан кейін қайталаңыз';

  @override
  String get companyLoginShowPassword => 'Құпия сөзді көрсету';

  @override
  String get companyLoginHidePassword => 'Құпия сөзді жасыру';

  @override
  String get companyLoginRegisterLink => 'Тіркелу';

  @override
  String get companyLoginForgotPasswordLink =>
      'Құпия сөзді ұмытып қалдыңыз ба?';

  @override
  String get forgotPasswordTitle => 'Құпия сөзді қалпына келтіру';

  @override
  String get forgotPasswordSendCode => 'Код жіберу';

  @override
  String get forgotPasswordCodeLabel => 'Хаттан алынған код';

  @override
  String get forgotPasswordNewPasswordLabel => 'Жаңа құпия сөз';

  @override
  String get forgotPasswordSubmit => 'Құпия сөзді ауыстыру';

  @override
  String get forgotPasswordSuccess =>
      'Құпия сөз ауыстырылды, жаңасымен кіріңіз';

  @override
  String get forgotPasswordResend => 'Кодты қайта жіберу';

  @override
  String get forgotPasswordInvalidCode => 'Код дұрыс емес немесе мерзімі өтті';

  @override
  String get forgotPasswordNoEmailLink => 'Хат келмей тұр ма?';

  @override
  String get supportContactTitle => 'Қолдау қызметіне хабарласу';

  @override
  String get supportContactBody =>
      'Хат келмесе, бізге қолайлы тәсілмен жазыңыз';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportContactWechat => 'WeChat';

  @override
  String get supportContactEmail => 'Email';

  @override
  String get supportContactNone =>
      'Қолдау қызметінің байланыстары жақында осында пайда болады';

  @override
  String get acceptInviteTitle => 'Компанияға шақыру';

  @override
  String acceptInviteSubtitle(String companyName, String role) {
    return 'Сізді «$companyName» компаниясына шақырды — рөлі: $role';
  }

  @override
  String get acceptInviteNameLabel => 'Атыңыз';

  @override
  String get acceptInvitePhoneLabel => 'Телефон (жүргізушілер үшін)';

  @override
  String get acceptInviteWechatLabel => 'WeChat (міндетті емес)';

  @override
  String get acceptInviteSubmit => 'Компанияға кіру';

  @override
  String get acceptInviteInvalidToken =>
      'Шақыру жарамсыз немесе бұрын қолданылған';

  @override
  String get emailVerifyBannerText => 'Email расталмаған';

  @override
  String get emailVerifyBannerAction => 'Растау';

  @override
  String get emailVerifyDialogTitle => 'Email-ды растау';

  @override
  String get emailVerifyDialogCodeLabel => 'Хаттан алынған код';

  @override
  String get emailVerifyDialogSubmit => 'Растау';

  @override
  String get employeesInviteButton => 'Қызметкерді шақыру';

  @override
  String get employeesInviteEmailLabel => 'Қызметкердің email-ы';

  @override
  String get employeesInviteRoleOwner => 'Иесі';

  @override
  String get employeesInviteRoleLogist => 'Логист';

  @override
  String get employeesInviteSubmit => 'Сілтеме құру';

  @override
  String get employeesInviteLinkReady =>
      'Шақыру сілтемесі 7 күн жарамды. Көшіріп, WeChat/WhatsApp-қа жіберіңіз:';

  @override
  String get employeesInviteCopyLink => 'Көшіру';

  @override
  String get employeesInviteCopied => 'Сілтеме көшірілді';

  @override
  String get driverSetupTitle => 'Профильді баптау';

  @override
  String get driverRegisterTitle => 'Тіркелу';

  @override
  String get driverVerificationTitle => 'Верификация';

  @override
  String get driverVerificationIntro =>
      'Жүктерге жауап беру және мәмілелерді растау үшін жеке басыңызды растаңыз — бұл шамамен 2 минут алады';

  @override
  String get driverVerificationSelfie => 'Селфи';

  @override
  String get driverVerificationVehiclePassport => 'Тартқыштың техпаспорты';

  @override
  String get driverVerificationTrailerPassport => 'Тіркеменің техпаспорты';

  @override
  String get driverVerificationLicense => 'Құқықтар';

  @override
  String get driverVerificationStatusNone => 'Жүктелмеген';

  @override
  String get driverVerificationStatusPending => 'Тексерілуде';

  @override
  String get driverVerificationStatusApproved => 'Расталды';

  @override
  String get driverVerificationStatusRejected => 'Қабылданбады';

  @override
  String get driverVerificationUploadFailed =>
      'Фотосуретті жүктеу мүмкін болмады';

  @override
  String get driverVerificationRequiredPrompt =>
      'Жауап беру үшін жеке басыңызды растаңыз — 2 минут';

  @override
  String get driverVerificationRequiredAction => 'Верификациядан өту';

  @override
  String profileCompleteness(int percent) {
    return 'Профиль $percent% толтырылды — тексерілген жүргізушілер 3 есе көп шақыру алады';
  }

  @override
  String driverSetupStepOf(int step, int total) {
    return '$total-ден $step-қадам';
  }

  @override
  String get driverSetupFullName => 'Т.А.Ә.';

  @override
  String get driverSetupFullNameError =>
      'Атыңызды енгізіңіз: 2-80 әріп, сандарсыз';

  @override
  String get driverSetupHomeCityError => 'Қаланы таңдаңыз';

  @override
  String get driverSetupBodyTypeError => 'Кузов түрін таңдаңыз';

  @override
  String get cityNotListed => 'Менің қалам тізімде жоқ';

  @override
  String get addCitySettlementLabel => 'Елді мекен';

  @override
  String get addCitySettlementError => 'Елді мекен атауын енгізіңіз';

  @override
  String get addCityRegionLabel => 'Облыс/өңір';

  @override
  String get addCityRegionError => 'Облысты таңдаңыз';

  @override
  String get addCitySubmit => 'Жалғастыру';

  @override
  String get driverSetupHomeCity => 'Тұрғылықты қала';

  @override
  String get driverSetupCountries => 'Бағыттар';

  @override
  String get driverSetupAnyCountry => 'Кез келген ел';

  @override
  String get driverSetupPermits => 'Рұқсаттар';

  @override
  String get driverSetupVehicleBodyType => 'Кузов түрі';

  @override
  String get driverSetupVehiclePlate => 'Мемлекеттік нөмір';

  @override
  String get driverSetupVehicleTitle => 'Көлігіңіз қандай?';

  @override
  String get driverSetupVehicleSubtitle =>
      'Бір рет толтырыңыз — жүктерді соған қарай таңдаймыз';

  @override
  String get driverSetupCapacity => 'Жүк көтергіштігі';

  @override
  String get driverSetupDocuments => 'Көлікке құжаттар';

  @override
  String get driverSetupDirectionsTitle => 'Қайда баруға дайынсыз?';

  @override
  String get driverSetupDirectionsSubtitle =>
      'Осы елдердегі жүктерді бірінші көрсетеміз. Кез келген уақытта өзгертуге болады';

  @override
  String driverSetupCountriesSelected(int count) {
    return 'Таңдалған елдер: $count';
  }

  @override
  String get driverSetupSubmit => 'Сақтап, жалғастыру';

  @override
  String get feedTitle => 'Хоргостағы жүктер';

  @override
  String get driverHomeGreeting => 'Сәлем,';

  @override
  String get driverHomeAnonsTitle => 'Менің анонсым';

  @override
  String driverHomeLogistsCount(int count) {
    return 'Жақын логистер: $count';
  }

  @override
  String driverHomeSince(String date) {
    return '$date бастап осындамын';
  }

  @override
  String get driverHomeCheckInEmpty =>
      'Келетініңізді хабарлаңыз — логистер сізді алдын ала көреді';

  @override
  String get driverHomeCheckInButton => 'Мен қазірдің өзінде осындамын';

  @override
  String get driverHomeLeaveButton => 'Кеттім';

  @override
  String get driverHomeCancelButton => 'Болдырмау';

  @override
  String get driverHomeAnnounceButton => 'Нүктеде боламын';

  @override
  String get driverHomeRepeatButton => 'Соңғы анонсты қайталау';

  @override
  String get driverHomeEditButton => 'Өзгерту';

  @override
  String driverHomePlannedFor(String date) {
    return '$date болады';
  }

  @override
  String get announceArrivalTitle => 'Нүктеде боламын';

  @override
  String get announceArrivalWhen => 'Қашан';

  @override
  String get announceArrivalToday => 'Бүгін';

  @override
  String get announceArrivalTomorrow => 'Ертең';

  @override
  String get announceArrivalDayAfter => 'Арғы күні';

  @override
  String get announceArrivalPickDate => 'Күнді таңдау';

  @override
  String get announceArrivalWhere => 'Қайда';

  @override
  String get announceArrivalCountries => 'Қай елдерге дайын';

  @override
  String get announceArrivalWaitDays => 'Қанша күтуге дайынсыз';

  @override
  String announceArrivalWaitDaysValue(int days) {
    return '$days күн';
  }

  @override
  String get announceArrivalSubmit => 'Жариялау';

  @override
  String driverHomeFeedCount(int count) {
    return 'Сәйкес жүктер $count';
  }

  @override
  String get feedEmpty => 'Әзірге сәйкес жүктер жоқ';

  @override
  String get feedSectionHome => 'Үйге жақын';

  @override
  String get feedSectionSelected => 'Сіздің бағыттарыңыз';

  @override
  String get feedSectionOther => 'Басқа бағыттар';

  @override
  String get cargoPrice => 'Бағасы';

  @override
  String get cargoWeight => 'Салмағы';

  @override
  String get cargoVolume => 'Көлемі';

  @override
  String get cargoPhotos => 'Фотосуреттер';

  @override
  String get unitKg => 'кг';

  @override
  String get unitM3 => 'м³';

  @override
  String get unitTon => 'т';

  @override
  String get cargoReadyDate => 'Дайын болу күні';

  @override
  String get cargoDestination => 'Бағыты';

  @override
  String get cargoBodyType => 'Кузов';

  @override
  String get cargoRespond => 'Жауап беру';

  @override
  String get cargoAlreadyResponded => 'Сіз жауап бердіңіз';

  @override
  String get cargoDetailTitle => 'Жүк';

  @override
  String get cargoDetailDescription => 'Сипаттама';

  @override
  String get cargoDetailCompany => 'Компания';

  @override
  String get cargoDetailPriceLabel => 'Рейс құны';

  @override
  String cargoDetailCompanyDeals(int count) {
    return 'Lubao-да $count мәміле';
  }

  @override
  String get cargoDetailNoReviews => 'Әзірге пікір жоқ';

  @override
  String get cargoStatusPublished => 'Жарияланды';

  @override
  String get cargoStatusArchived => 'Мұрағатта';

  @override
  String get cargoStatusExpired => 'Мерзімі өтті';

  @override
  String get cargoStatusCancelled => 'Бас тартылды';

  @override
  String get dealsTitle => 'Менің мәмілелерім';

  @override
  String get dealsEmpty => 'Әзірге мәміле жоқ';

  @override
  String get dealStatusSelected => 'Таңдалды';

  @override
  String get dealStatusConfirmed => 'Жүргізуші растады';

  @override
  String get dealStatusLoaded => 'Тиелді';

  @override
  String get dealStatusInTransit => 'Жолда';

  @override
  String get dealStatusDelivered => 'Жеткізілді';

  @override
  String get dealStatusCancelled => 'Бас тартылды';

  @override
  String get dealDetailTitle => 'Мәміле';

  @override
  String get dealTimelineTitle => 'Мәміле мәртебесі';

  @override
  String get dealDriverLocationTitle => 'Жүргізушінің орналасқан жері';

  @override
  String get dealLocationUpdatedAt => 'Жаңартылды';

  @override
  String get dealLocationNoData => 'Координаттар әлі алынған жоқ';

  @override
  String get dealConfirm => 'Растау';

  @override
  String get dealMarkLoaded => 'Жүк тиелді';

  @override
  String get dealMarkInTransit => 'Жолда';

  @override
  String get dealMarkDelivered => 'Жеткізілді';

  @override
  String get dealCancel => 'Мәміледен бас тарту';

  @override
  String get dealCancelReasonLabel => 'Бас тарту себебі';

  @override
  String get dealCancelledBy => 'Бас тартқан';

  @override
  String get reviewTitle => 'Пікір қалдыру';

  @override
  String get reviewRatingLabel => 'Баға';

  @override
  String get reviewCommentLabel => 'Пікір';

  @override
  String get reviewSubmit => 'Пікірді жіберу';

  @override
  String get reviewsReceivedTitle => 'Пікірлер';

  @override
  String get responsesTitle => 'Жауаптар';

  @override
  String get responsesEmpty => 'Әзірге жауаптар жоқ';

  @override
  String get responseSelect => 'Жүргізушіні таңдау';

  @override
  String get responseReject => 'Бас тарту';

  @override
  String get responseStatusPending => 'Күтуде';

  @override
  String get responseStatusSelected => 'Таңдалды';

  @override
  String get responseStatusRejected => 'Бас тартылды';

  @override
  String get responseStatusCancelled => 'Күші жойылды';

  @override
  String get myCargosTitle => 'Менің жүктерім';

  @override
  String get myCargosEmpty => 'Сіз әлі жүк жарияламадыңыз';

  @override
  String get postCargoTitle => 'Жаңа жүк';

  @override
  String get postCargoDestinationCountry => 'Межелі ел';

  @override
  String get postCargoDestinationCity => 'Межелі қала';

  @override
  String get postCargoBodyType => 'Кузов түрі';

  @override
  String get postCargoVolume => 'Көлемі, м³';

  @override
  String get postCargoWeight => 'Салмағы, кг';

  @override
  String get postCargoPhotos => 'Фотосуреттер';

  @override
  String get postCargoAddPhotoCamera => 'Камера';

  @override
  String get postCargoAddPhotoGallery => 'Галерея';

  @override
  String get postCargoRemovePhoto => 'Фотосуретті өшіру';

  @override
  String get postCargoPhotoUploadFailed => 'Фотосуретті жүктеу мүмкін болмады';

  @override
  String get postCargoPrice => 'Бағасы';

  @override
  String get postCargoCurrency => 'Валюта';

  @override
  String get postCargoReadyDate => 'Дайын болу күні';

  @override
  String get postCargoDescription => 'Жүк сипаттамасы';

  @override
  String get postCargoSubmit => 'Жариялау';

  @override
  String get editCargoTitle => 'Жүкті өзгерту';

  @override
  String get cargoEdit => 'Өзгерту';

  @override
  String get cargoDelete => 'Жою';

  @override
  String get cargoDeleteConfirmTitle => 'Жүкті жоясыз ба?';

  @override
  String get cargoDeleteConfirmMessage =>
      'Жүк жарияланымнан алынады. Өтінімдер мен мәмілелер тарихы сақталады.';

  @override
  String get cargoDeleted => 'Жүк жойылды';

  @override
  String get chatTitle => 'Чат';

  @override
  String get chatInputHint => 'Хабарлама';

  @override
  String get chatEmpty => 'Хат алысуды бастаңыз';

  @override
  String get chatAttachLocation => 'Нүктені тіркеу';

  @override
  String get chatLocationMessagePrefix => 'Картадағы нүкте';

  @override
  String get chatLocationError => 'Орналасқан жерді анықтау мүмкін болмады';

  @override
  String get chatTranslatedBadge => 'Аударылды';

  @override
  String get chatShowOriginal => 'түпнұсқа';

  @override
  String chatWritesIn(String language) {
    return '$language тілінде жазады';
  }

  @override
  String get chatToday => 'Бүгін';

  @override
  String get chatYesterday => 'Кеше';

  @override
  String get chatConfirmTitle => 'Логист сізді осы жүкке таңдады';

  @override
  String get chatConfirmSubtitle =>
      'Растаңыз — мәміле бекітіледі, сіз пікір мен рейтинг аласыз';

  @override
  String get chatConfirmButton => 'Тасымалды растаймын';

  @override
  String get chatQuickReplyAtPlace => 'Мен орындамын';

  @override
  String get chatQuickReplyLoaded => 'Тиедім';

  @override
  String get chatQuickReplyLate1h => '1 сағатқа кешігемін';

  @override
  String get wholeCountrySuffix => 'бүкіл ел';

  @override
  String get searchCityCountryHint => 'Қала немесе елді теруді бастаңыз';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileLogout => 'Шығу';

  @override
  String get profileRatingLabel => 'Рейтинг';

  @override
  String get profileVerified => 'Тексерілген';

  @override
  String get profileNotVerified => 'Тексерілмеген';

  @override
  String get profileLanguage => 'Язык · Тіл · 语言 · Language';

  @override
  String get profilePhone => 'Телефон';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileCompanyName => 'Компания';

  @override
  String get profileMembers => 'Қызметкерлер';

  @override
  String get profileMyDevices => 'Менің құрылғыларым';

  @override
  String get companySetPasswordTitle => 'Кіру құпия сөзі';

  @override
  String get companySetPasswordHint => 'Кіру құпия сөзін ауыстыру';

  @override
  String get companySetPasswordTooShort => 'Кемінде 8 таңба';

  @override
  String get devicesTitle => 'Менің құрылғыларым';

  @override
  String get devicesCurrentBadge => 'Ағымдағы құрылғы';

  @override
  String get devicesLogoutThis => 'Осы құрылғыда шығу';

  @override
  String get devicesLogoutAllOthers => 'Барлық басқаларынан шығу';

  @override
  String get devicesLogoutAllOthersConfirm =>
      'Барлық басқа құрылғылар жүйеден шығады. Жалғастыру керек пе?';

  @override
  String get devicesEmpty => 'Белсенді құрылғылар жоқ';

  @override
  String get adminLoginLockedOut =>
      'Қате әрекеттер тым көп, 15 минуттан кейін қайталап көріңіз';

  @override
  String get languageKk => 'Қазақша';

  @override
  String get languageRu => 'Орысша';

  @override
  String get languageZh => 'Қытайша';

  @override
  String get navFeed => 'Жүктер';

  @override
  String get navDeals => 'Мәмілелер';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navCargos => 'Жүктер';

  @override
  String get navResponses => 'Жауаптар';

  @override
  String get navDrivers => 'Жүргізушілер';

  @override
  String driversAtPointTitle(String point) {
    return '$point нүктесінде кімдер болады';
  }

  @override
  String get driversAtPointSubtitle =>
      'Алдын ала келетінін хабарлаған жүргізушілер';

  @override
  String driversAtPointDispatchFrom(String point) {
    return 'Жүк жөнелту пункті: $point';
  }

  @override
  String get driversAtPointPickDate => 'Күнді таңдау';

  @override
  String driversAtPointCountAtPlace(int count) {
    return 'Қазір орында: $count';
  }

  @override
  String get driversAtPointEmpty => 'Әзірге ешкім орында жоқ';

  @override
  String get driversAtPointFilterCountry => 'Ел';

  @override
  String get driversAtPointFilterBodyType => 'Кузов';

  @override
  String get driversAtPointFilterMinCapacity => '20 т-дан';

  @override
  String get driversAtPointFilterVerifiedOnly => 'Тек тексерілгендер';

  @override
  String get driversAtPointInvite => 'Жүкке шақыру';

  @override
  String get driversAtPointPickCargo => 'Жүкті таңдаңыз';

  @override
  String get driversAtPointNoCargos => 'Алдымен жүк жариялаңыз';

  @override
  String get driversAtPointInviteSent => 'Шақыру жіберілді';

  @override
  String driversAtPointArrivedAt(String time) {
    return '$time бастап орында';
  }

  @override
  String driversAtPointPlannedAt(String time) {
    return '$time болады';
  }

  @override
  String get driversAtPointToday => 'Бүгін';

  @override
  String get adminLoginTitle => 'Әкімші тіркелгісіне кіру';

  @override
  String get adminLoginEmailLabel => 'Email';

  @override
  String get adminLoginPasswordLabel => 'Құпия сөз';

  @override
  String get adminLoginSubmit => 'Кіру';

  @override
  String get adminDashboardTitle => 'Шолу';

  @override
  String get adminStatDrivers => 'Жүргізушілер';

  @override
  String get adminStatCompanies => 'Компаниялар';

  @override
  String get adminStatCargosPublished => 'Белсенді жүктер';

  @override
  String get adminStatDealsActive => 'Жұмыстағы мәмілелер';

  @override
  String get adminStatDealsDelivered => 'Жеткізілген мәмілелер';

  @override
  String get adminStatPendingDocs => 'Тексерудегі құжаттар';

  @override
  String get adminStatOpenComplaints => 'Ашық шағымдар';

  @override
  String get adminNavDashboard => 'Шолу';

  @override
  String get adminNavVerification => 'Верификация';

  @override
  String get adminNavComplaints => 'Шағымдар';

  @override
  String get adminNavCompanies => 'Компаниялар';

  @override
  String get adminNavDrivers => 'Жүргізушілер';

  @override
  String get adminNavReference => 'Анықтамалықтар';

  @override
  String get adminVerificationTitle => 'Тексеруге арналған құжаттар';

  @override
  String get adminVerificationEmpty => 'Барлығы тексерілді 👍';

  @override
  String get adminApprove => 'Мақұлдау';

  @override
  String get adminReject => 'Бас тарту';

  @override
  String get adminRejectReasonLabel => 'Бас тарту себебі';

  @override
  String get adminComplaintsTitle => 'Шағымдар';

  @override
  String get adminComplaintsEmpty => 'Шағым жоқ';

  @override
  String get adminResolve => 'Шешілді';

  @override
  String get adminMarkInReview => 'Қарауда';

  @override
  String get adminCompaniesTitle => 'Компаниялар';

  @override
  String get adminDriversTitle => 'Жүргізушілер';

  @override
  String get adminVerified => 'Тексерілген';

  @override
  String get adminNotVerified => 'Тексерілмеген';

  @override
  String get adminReferenceTitle => 'Анықтамалықтар';

  @override
  String get adminPendingCitiesTab => 'Жаңа қалалар';

  @override
  String get adminPendingCitiesEmpty => 'Пайдаланушылардан жаңа қалалар жоқ';

  @override
  String get adminMergeCity => 'Біріктіру';

  @override
  String get adminMergeCityTarget => 'Біріктіретін қала';

  @override
  String get adminCitySubmittedBy => 'Қосқан';

  @override
  String get adminCityRegion => 'Облыс';

  @override
  String get adminAddBodyType => 'Кузов түрін қосу';

  @override
  String get adminAddPermit => 'Рұқсат қосу';

  @override
  String get adminAddPoint => 'Тиеу нүктесін қосу';

  @override
  String get adminPointCity => 'Қала';

  @override
  String get adminNameKk => 'Атауы (kk)';

  @override
  String get adminNameRu => 'Атауы (ru)';

  @override
  String get adminNameZh => 'Атауы (zh)';

  @override
  String get adminCode => 'Код';

  @override
  String get adminActive => 'Белсенді';

  @override
  String get adminInactive => 'Белсенді емес';

  @override
  String get accountBlockedMessage =>
      'Аккаунт бұғатталған. Қолдау қызметіне хабарласыңыз';

  @override
  String get adminSearchCompanyHint => 'Атауы, email, тіркеу нөмірі';

  @override
  String get adminSearchDriverHint => 'Аты, телефон, мем. нөмір';

  @override
  String get adminFilterAll => 'Барлығы';

  @override
  String get adminFilterPending => 'Тексеруде';

  @override
  String get adminFilterVerified => 'Тексерілген';

  @override
  String get adminFilterBlocked => 'Бұғатталған';

  @override
  String get adminCompaniesEmpty => 'Компаниялар табылмады';

  @override
  String get adminDriversEmpty => 'Жүргізушілер табылмады';

  @override
  String get adminColName => 'Аты';

  @override
  String get adminColOwner => 'Иесі';

  @override
  String get adminColEmployees => 'Қызметкерлер';

  @override
  String get adminColCargos => 'Белсенді жүктер';

  @override
  String get adminColStatus => 'Мәртебе';

  @override
  String get adminColRating => 'Рейтинг';

  @override
  String get adminColDeals => 'Мәмілелер';

  @override
  String get adminColPhone => 'Телефон';

  @override
  String get adminColCity => 'Қала';

  @override
  String get adminColVehicle => 'Көлік';

  @override
  String get adminBlockedBadge => 'Бұғатталған';

  @override
  String adminPageOf(int page, int total) {
    return '$page / $total бет';
  }

  @override
  String get adminBlockConfirmTitle => 'Жүргізушіні бұғаттау керек пе?';

  @override
  String get adminBlockCompanyConfirmTitle => 'Компанияны бұғаттау керек пе?';

  @override
  String get adminBlock => 'Бұғаттау';

  @override
  String get adminBlockCompany => 'Компанияны бұғаттау';

  @override
  String get adminUnblockConfirmTitle => 'Бұғаттан шығару керек пе?';

  @override
  String get adminUnblock => 'Бұғаттан шығару';

  @override
  String get adminVerifyMissingDocsError =>
      'Барлық міндетті құжаттар мақұлданбаған — «өзім тексердім» белгісін қойып, қайталаңыз';

  @override
  String get adminResetPasswordConfirmTitle =>
      'Иесінің құпия сөзін ысыру керек пе?';

  @override
  String get adminResetPasswordDialogTitle => 'Уақытша құпия сөз';

  @override
  String get adminResetPassword => 'Құпия сөзді ысыру';

  @override
  String get adminCopied => 'Көшірілді';

  @override
  String get adminToggleVerification => 'Тексеру мәртебесін өзгерту';

  @override
  String get adminStatComplaints => 'Шағымдар';

  @override
  String get adminStatCancellations => 'Бас тартулар';

  @override
  String get adminStatCalls => 'Қоңыраулар';

  @override
  String get adminDocuments => 'Құжаттар';

  @override
  String get adminNoDocuments => 'Құжаттар жоқ';

  @override
  String get adminLegalDetails => 'Заңды деректер';

  @override
  String get adminInvites => 'Шақырулар';

  @override
  String get adminInviteUsed => 'Қолданылды';

  @override
  String get adminTabCargos => 'Жүктер';

  @override
  String get adminTabDeals => 'Мәмілелер';

  @override
  String get adminTabReviews => 'Пікірлер';

  @override
  String get adminTabLog => 'Журнал';

  @override
  String get adminNoCargos => 'Жүктер жоқ';

  @override
  String get adminNoDeals => 'Мәмілелер жоқ';

  @override
  String get adminNoReviews => 'Пікірлер жоқ';

  @override
  String get adminNoLog => 'Жазбалар жоқ';

  @override
  String get adminEndSessionsConfirmTitle => 'Барлық сессияны аяқтау керек пе?';

  @override
  String get adminEndSessions => 'Сессияларды аяқтау';

  @override
  String adminWithUsSince(String date) {
    return 'Бізбен бірге $date-ден';
  }

  @override
  String adminLastLogin(String date) {
    return 'Соңғы кіру: $date';
  }

  @override
  String get adminReasonLabel => 'Себеп';

  @override
  String get adminVerifyDialogTitle => '«Тексерілген» деп белгілеу';

  @override
  String get adminUnverifyDialogTitle => '«Тексерілген» белгісін алып тастау';

  @override
  String get adminForceVerifyCheckbox => 'Құжаттарды өзім тексердім';

  @override
  String get adminRejectPresetUnreadable => 'Фото оқылмайды';

  @override
  String get adminRejectPresetExpired => 'Құжат мерзімі өтті';

  @override
  String get adminRejectPresetMismatch => 'Аты-жөні сәйкес келмейді';

  @override
  String get adminRejectPresetOther => 'Басқа / себеп';

  @override
  String get adminDocTypeCompanyRegistration => 'Тіркеу туралы куәлік';

  @override
  String get adminDocTypeIdentity => 'Жеке куәлік';

  @override
  String get adminDocTypeOther => 'Басқа құжат';

  @override
  String get adminRotate => 'Бұру';

  @override
  String get adminComplaintReporter => 'Шағымданушы';

  @override
  String get adminComplaintTarget => 'Шағым нысаны';

  @override
  String get adminAttentionTitle => 'Назар аудару қажет';

  @override
  String get adminAttentionEmpty => 'Бәрі дұрыс — назар аудару қажет емес';

  @override
  String adminAttentionPendingVerification(int count) {
    return 'Тексеруде: $count адам';
  }

  @override
  String adminAttentionOpenComplaints(int count) {
    return 'Ашық шағымдар: $count';
  }

  @override
  String adminAttentionStaleDeals(int count) {
    return '3 күннен артық қозғалыссыз мәмілелер: $count';
  }

  @override
  String adminAttentionUnverifiedCompanies(int count) {
    return 'Тексерілмеген компаниялар: $count';
  }

  @override
  String adminAttentionPendingCities(int count) {
    return 'Жаңа қалалар: $count';
  }

  @override
  String get adminRecentEventsTitle => 'Соңғы оқиғалар';

  @override
  String get adminAuditLogLink => 'Журнал →';

  @override
  String get adminAuditLogTitle => 'Әрекеттер журналы';

  @override
  String get adminNoEvents => 'Оқиғалар жоқ';

  @override
  String get adminPeriodLabel => 'Кезең:';

  @override
  String get adminPeriodToday => 'Бүгін';

  @override
  String get adminPeriod7d => '7 күн';

  @override
  String get adminPeriod30d => '30 күн';

  @override
  String get adminStatOnSiteToday => 'Бүгін нүктеде';

  @override
  String adminStatOnSiteWeek(int count) {
    return 'Аптада: $count';
  }

  @override
  String get adminGlobalSearchHint =>
      'Іздеу: аты, телефон, email, мем. нөмір, жүк/мәміле №';

  @override
  String get adminSearchNoResults => 'Ештеңе табылмады';

  @override
  String get adminNavCargos => 'Жүктер';

  @override
  String get adminNavDeals => 'Мәмілелер';

  @override
  String get adminNavSettings => 'Баптаулар';

  @override
  String get adminCargosTitle => 'Жүктер';

  @override
  String get adminCargosEmpty => 'Жүктер табылмады';

  @override
  String get adminDealsTitle => 'Мәмілелер';

  @override
  String get adminDealsEmpty => 'Мәмілелер табылмады';

  @override
  String get adminFilterActive => 'Жұмыста';

  @override
  String get adminFilterStale => '3 күннен артық қозғалыссыз';

  @override
  String get adminFilterOnSite => 'Нүктеде';

  @override
  String get adminColRoute => 'Бағыт';

  @override
  String get adminColBodyType => 'Кузов';

  @override
  String get adminColPrice => 'Баға';

  @override
  String get adminColCompany => 'Компания';

  @override
  String get adminColDriver => 'Жүргізуші';

  @override
  String get adminColResponses => 'Жауаптар';

  @override
  String get adminColPublished => 'Жарияланды';

  @override
  String get adminColCreated => 'Құрылды';

  @override
  String get adminColStale => 'Қозғалыссыз';

  @override
  String adminStaleDays(int days) {
    return '$days күн';
  }

  @override
  String get adminSettingsEmpty => 'Баптаулар әлі жоқ';

  @override
  String get adminVerificationTabDrivers => 'Жүргізушілер';

  @override
  String get adminVerificationTabCompanies => 'Компаниялар';

  @override
  String get adminVerificationNoSelection =>
      'Сол жақтағы кезектен адамды немесе компанияны таңдаңыз';

  @override
  String adminVerificationReasonNew(int count) {
    return 'Жаңа · $count құжат';
  }

  @override
  String adminVerificationReasonResubmitted(String type) {
    return 'Қайта: $type';
  }

  @override
  String get adminVerificationReasonVehicleChanged => 'Көлігін ауыстырды';

  @override
  String get adminVerificationOpenCard => 'Карточка →';

  @override
  String get adminVerificationCrossCheckTitle => 'Профильмен салыстыру';

  @override
  String get adminCrossCheckName => 'Аты-жөні ↔ құқық';

  @override
  String get adminCrossCheckPhoto => 'Селфидегі бет ↔ құқықтағы фото';

  @override
  String get adminCrossCheckPlate => 'Мемнөмір ↔ тартқыштың техпаспорты';

  @override
  String get adminCrossCheckTrailerPlate => 'Тіркеме ↔ тіркеменің техпаспорты';

  @override
  String get adminCrossCheckCompanyName => 'Атауы ↔ лицензия';

  @override
  String get adminCrossCheckCompanyTaxId => 'Тіркеу нөмірі ↔ лицензия';

  @override
  String get adminCrossCheckMatch => 'Сәйкес келеді';

  @override
  String get adminCrossCheckMismatch => 'Сәйкес келмейді';

  @override
  String get adminConfirmDriverButton => 'Жүргізушіні растау';

  @override
  String get adminConfirmCompanyButton => 'Компанияны растау';

  @override
  String get adminReturnForReworkButton => 'Қайта өңдеуге қайтару';

  @override
  String get adminReturnForReworkDialogTitle => 'Қайта өңдеуге қайтару';

  @override
  String get adminReturnForReworkNoteLabel =>
      'Түсініктеме (нені қайта түсіру керек)';

  @override
  String get adminVerificationMissingDocsHint =>
      'Растау үшін барлық міндетті құжаттарды «дұрыс» деп белгілеңіз';

  @override
  String get adminVerificationCompareWithSelfie => 'Селфимен қатар';

  @override
  String get adminRejectPresetPlateMismatch => 'Мемнөмір сәйкес келмейді';

  @override
  String get adminCargoUnpublish => 'Жариялаудан алу';

  @override
  String get adminCargoUnpublishDialogTitle => 'Жүкті жариялаудан алу';

  @override
  String get adminCargoEdit => 'Түзету';

  @override
  String get adminCargoEditDialogTitle => 'Жүкті түзету';

  @override
  String get adminCargoPublishedAt => 'Жарияланды';

  @override
  String get adminCargoExpiresAt => 'Мерзімі өтеді';

  @override
  String get adminCargoArchivedAt => 'Жариялаудан алынды';

  @override
  String get adminCargoTabResponses => 'Жауаптар';

  @override
  String get adminNoResponses => 'Әзірге жауап жоқ';

  @override
  String get adminDealCancel => 'Мәмілені болдырмау';

  @override
  String get adminDealCancelDialogTitle => 'Мәмілені болдырмау';

  @override
  String get adminDealFixStatus => 'Мәртебесін түзету';

  @override
  String get adminDealFixStatusDialogTitle => 'Мәміле мәртебесін түзету';

  @override
  String get adminDealOpenCargo => 'Жүк →';

  @override
  String adminDealCancelledBy(String role) {
    return 'Болдырылмады ($role)';
  }

  @override
  String get adminDealStatusHistoryTitle => 'Мәртебелер тарихы';

  @override
  String get adminDealTabChat => 'Хат алмасу';

  @override
  String get adminDealTabCalls => 'Қоңыраулар';

  @override
  String get adminDealShowChat => 'Хат алмасуды көрсету';

  @override
  String get adminNoChat => 'Хабарлама жоқ';

  @override
  String get adminNoCalls => 'Қоңыраулар болмады';

  @override
  String get adminContactEventCall => 'Қоңырау';

  @override
  String get adminContactEventWhatsapp => 'WhatsApp';

  @override
  String get roleAdmin => 'Әкімші';

  @override
  String get adminEdit => 'Өзгерту';

  @override
  String get adminTransferOwnershipTitle => 'Иелікті беру';

  @override
  String get adminDemoteToLogistTitle => 'Логистке дейін төмендету';

  @override
  String get adminLastOwnerError => 'Болмайды — бұл компанияның соңғы иесі';

  @override
  String get adminRemoveMemberTitle => 'Қызметкерді жою';

  @override
  String get adminRemoveMember => 'Жою';

  @override
  String get adminChangeMemberEmailTitle => 'Қызметкердің email-ін өзгерту';

  @override
  String get adminEmailTakenError => 'Бұл email қолданыста';

  @override
  String get adminCompanyCity => 'Қала';

  @override
  String get adminLegalAddress => 'Заңды мекенжай';

  @override
  String get adminTaxId => 'Тіркеу нөмірі (БСН)';

  @override
  String get adminPhoneChangeWarning =>
      'Сақтағанда жүргізушінің барлық сеансы аяқталады';

  @override
  String get adminVehicleBrand => 'Маркасы';

  @override
  String get adminVehicleLengthM => 'Ұзындығы, м';

  @override
  String get adminNameEn => 'Атауы (en)';

  @override
  String get adminSortOrder => 'Реті';

  @override
  String get adminLat => 'Ендік';

  @override
  String get adminLng => 'Бойлық';

  @override
  String get adminCitiesTab => 'Қалалар';

  @override
  String get adminSettingDefaultCity => 'Әдепкі нүкте';

  @override
  String get adminSettingNotSet => 'Орнатылмаған';

  @override
  String get adminSettingHomeRadius => '«Үйге жақын» радиусы, км';

  @override
  String get adminUnitKm => 'км';

  @override
  String get adminSettingCargoArchiveDays => 'Жауапсыз жүк мұрағатталу мерзімі';

  @override
  String get adminComplaintResolutionTitle => 'Шешім';

  @override
  String get adminComplaintResolutionNoteLabel => 'Шағым авторына жауап';

  @override
  String get adminComplaintSelectHint =>
      'Сол жақтағы кезектен шағымды таңдаңыз';

  @override
  String get adminComplaintTabNew => 'Жаңа';

  @override
  String get adminComplaintTabInReview => 'Жұмыста';

  @override
  String get adminComplaintTabClosed => 'Жабылған';

  @override
  String get adminComplaintMineFilter => 'Менікі';

  @override
  String adminComplaintMoreThisMonth(int count) {
    return 'осы айда тағы $count шағым';
  }

  @override
  String get adminComplaintTakeOver => 'Жұмысқа алу';

  @override
  String adminComplaintAssignedTo(String name) {
    return '$name жұмысында';
  }

  @override
  String get adminComplaintReturnToNew => 'Жаңаларға қайтару';

  @override
  String get adminComplaintResolveButton => 'Шешім қабылдау';

  @override
  String get adminComplaintResolutionDismissed => 'Расталмады';

  @override
  String get adminComplaintResolutionWarned => 'Ескерту жасау';

  @override
  String get adminComplaintResolutionCargoUnpublished =>
      'Жүкті жариялаудан алу';

  @override
  String get adminComplaintResolutionBlocked => 'Бұғаттау';

  @override
  String get adminStatClosedOutside => 'Lubao-дан тыс тапты';

  @override
  String adminStatClosedOutsideHint(int outside, int total) {
    return '$total жабылғаннан $outside';
  }

  @override
  String get cargoCloseDialogTitle => 'Жүкті жабу';

  @override
  String get cargoCloseFoundInApp => 'Жүргізушіні Lubao-дан тапты';

  @override
  String get cargoCloseNoCandidates =>
      'Әзірге жауап, қоңырау немесе хат алмасу болған жүргізуші жоқ';

  @override
  String get cargoCloseDriverLabel => 'Жүргізуші';

  @override
  String get cargoCloseFoundOutside => 'Lubao-дан тыс тапты';

  @override
  String get cargoCloseCancelled => 'Жүк болдырылмады';

  @override
  String get cargoCloseConfirm => 'Жабу';

  @override
  String get cargoClosed => 'Жүк жабылды';

  @override
  String get cargoClose => 'Жүкті жабу';

  @override
  String get navChats => 'Чаттар';

  @override
  String get chatsTabTitle => 'Чаттар';

  @override
  String get chatsEmpty => 'Әзірге чат жоқ';

  @override
  String get profileNotificationSettings => 'Хабарландырулар';

  @override
  String get notificationSettingsTitle => 'Хабарландырулар';

  @override
  String get notificationSettingsHint =>
      'Өшірілген топ бұл оқиғалар бойынша push жібермейді';

  @override
  String get notificationGroupNewCargoMatch => 'Жаңа сәйкес жүк';

  @override
  String get notificationGroupCargoInvite => 'Жүкке шақыру';

  @override
  String get notificationGroupChatMessage => 'Чатта жаңа хабарлама';

  @override
  String get notificationGroupNewResponse => 'Жүргізушінің жауабы';

  @override
  String get notificationGroupNewDriverDigest => 'Нүктеде жаңа жүргізушілер';

  @override
  String get notificationGroupDealStatus => 'Мәміле мәртебесінің өзгеруі';

  @override
  String get notificationGroupVerification => 'Құжаттарды тексеру';

  @override
  String get notificationGroupAgreedCheck => '«Келістіңіз бе?»';

  @override
  String get companyWecomTitle => 'WeCom-бот';

  @override
  String get companyWecomHint =>
      'WeCom топтық бот вебхугінің мекенжайы — жаңа жауаптар мен мәмілелер туралы хабарландырулар тобыңызға келеді';

  @override
  String get companyWecomUrlLabel => 'Вебхук URL';

  @override
  String get companyWecomTestButton => 'Тексеру';

  @override
  String get companyWecomTestSuccess => 'Сынақ хабарламасы жіберілді';

  @override
  String get companyWecomTestError =>
      'Жіберу мүмкін болмады — мекенжайды тексеріңіз';

  @override
  String get chatTranslationFailed => 'Аударма қолжетімсіз';

  @override
  String get chatTranslationRetry => 'қайталау';

  @override
  String get adminTranslationSettingsTitle => 'Чат аудармасы';

  @override
  String get adminTranslationEnabledLabel => 'Қосулы';

  @override
  String get adminTranslationProviderLabel => 'Провайдер';

  @override
  String get adminTranslationModelLabel => 'Модель';

  @override
  String get adminTranslationRequests7dLabel => '7 күндегі сұраулар';

  @override
  String get adminTranslationTokens7dLabel => '7 күндегі токендер';

  @override
  String get adminAuditActionAdminViewedChat => 'Админ чатты ашты';

  @override
  String get adminAuditActionCargoUnpublished => 'Жүк жарияланымнан алынды';

  @override
  String get adminAuditActionCargoUpdated => 'Жүк өзгертілді';

  @override
  String get adminAuditActionCityUpdated => 'Қала өзгертілді';

  @override
  String get adminAuditActionCompanyBlocked => 'Компания блокталды';

  @override
  String get adminAuditActionCompanyMemberEmailChanged =>
      'Қызметкердің email өзгертілді';

  @override
  String get adminAuditActionCompanyMemberRemoved =>
      'Қызметкер компаниядан шығарылды';

  @override
  String get adminAuditActionCompanyMemberRoleChanged =>
      'Қызметкердің рөлі өзгертілді';

  @override
  String get adminAuditActionCompanyPasswordReset =>
      'Компанияның паролі қалпына келтірілді';

  @override
  String get adminAuditActionCompanyReturnedForRework =>
      'Компания құжаттары түзетуге қайтарылды';

  @override
  String get adminAuditActionCompanyUnblocked => 'Компания блоктан шығарылды';

  @override
  String get adminAuditActionCompanyUnverified => 'Компания тексерістен алынды';

  @override
  String get adminAuditActionCompanyUpdated => 'Компания деректері өзгертілді';

  @override
  String get adminAuditActionCompanyVerified => 'Компания тексерілді';

  @override
  String get adminAuditActionComplaintAssigned => 'Шағым жұмысқа алынды';

  @override
  String get adminAuditActionComplaintResolved => 'Шағым шешілді';

  @override
  String get adminAuditActionComplaintUnassigned => 'Шағым кезекке қайтарылды';

  @override
  String get adminAuditActionDealCancelledByAdmin =>
      'Мәміле админ тарапынан болдырылмады';

  @override
  String get adminAuditActionDealStatusFixed => 'Мәміле мәртебесі түзетілді';

  @override
  String get adminAuditActionDriverReturnedForRework =>
      'Жүргізуші құжаттары түзетуге қайтарылды';

  @override
  String get adminAuditActionDriverUnverified => 'Жүргізуші тексерістен алынды';

  @override
  String get adminAuditActionDriverUpdated => 'Жүргізуші деректері өзгертілді';

  @override
  String get adminAuditActionDriverVerified => 'Жүргізуші тексерілді';

  @override
  String get adminAuditActionPointUpdated => 'Нүкте өзгертілді';

  @override
  String get adminAuditActionSessionsRevoked => 'Сессиялар аяқталды';

  @override
  String get adminAuditActionSettingChanged => 'Баптау өзгертілді';

  @override
  String get adminAuditActionUserBlocked => 'Пайдаланушы блокталды';

  @override
  String get adminAuditActionUserUnblocked => 'Пайдаланушы блоктан шығарылды';

  @override
  String get adminAuditActionBodyTypeUpdated => 'Кузов түрі өзгертілді';

  @override
  String get adminAuditActionPermitUpdated => 'Рұқсат өзгертілді';

  @override
  String get adminAuditFieldDestinationCountry => 'Межелі ел';

  @override
  String get adminAuditFieldDestinationCity => 'Межелі қала';

  @override
  String get adminAuditFieldBodyType => 'Кузов түрі';

  @override
  String get adminAuditFieldWeight => 'Салмақ, кг';

  @override
  String get adminAuditFieldVolume => 'Көлем, м³';

  @override
  String get adminAuditFieldPhotos => 'Фото';

  @override
  String get adminAuditFieldPrice => 'Баға';

  @override
  String get adminAuditFieldCurrency => 'Валюта';

  @override
  String get adminAuditFieldReadyDate => 'Дайын болу күні';

  @override
  String get adminAuditFieldDescription => 'Сипаттама';

  @override
  String get adminAuditFieldName => 'Атауы';

  @override
  String get adminAuditFieldNameRu => 'Атауы (орысша)';

  @override
  String get adminAuditFieldCountry => 'Ел';

  @override
  String get adminAuditFieldCity => 'Қала';

  @override
  String get adminAuditFieldLegalAddress => 'Заңды мекенжай';

  @override
  String get adminAuditFieldTaxId => 'СТТН/БСН';

  @override
  String get adminAuditFieldFullName => 'Аты-жөні';

  @override
  String get adminAuditFieldPhone => 'Телефон';

  @override
  String get adminAuditFieldHomeCity => 'Тұрғылықты қала';

  @override
  String get adminAuditFieldAnyCountry => 'Кез келген ел';

  @override
  String get adminAuditFieldCountries => 'Елдер';

  @override
  String get adminAuditFieldPermits => 'Рұқсаттар';

  @override
  String get adminAuditFieldVehicle => 'Көлік';

  @override
  String get adminAuditFieldPlateNumber => 'Мемлекеттік нөмірі';

  @override
  String get adminAuditFieldCapacity => 'Жүк көтергіштігі, т';

  @override
  String get adminAuditFieldLength => 'Ұзындығы, м';

  @override
  String get adminAuditFieldBrand => 'Маркасы';

  @override
  String get adminAuditFieldIsActive => 'Белсенді';

  @override
  String get adminAuditFieldSortOrder => 'Реті';

  @override
  String get adminAuditFieldStatus => 'Мәртебе';
}
