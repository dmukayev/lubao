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
  String get errorNetwork =>
      'Сервермен байланыс жоқ. Интернетті тексеріп, қайталаңыз';

  @override
  String get errorServer => 'Сервер уақытша қолжетімсіз. Кейінірек қайталаңыз';

  @override
  String get errorForbidden => 'Бұл әрекет сізге қолжетімсіз';

  @override
  String get errorInvalidData => 'Енгізілген деректерді тексеріңіз';

  @override
  String errorFieldMax(String field, String limit) {
    return '$field — $limit аспауы керек';
  }

  @override
  String errorFieldMin(String field, String limit) {
    return '$field — $limit кем болмауы керек';
  }

  @override
  String errorFieldMaxLength(String field, String limit) {
    return '$field — $limit таңбадан аспауы керек';
  }

  @override
  String errorFieldInvalid(String field) {
    return '$field — мәнін тексеріңіз';
  }

  @override
  String fieldMax(String limit) {
    return '$limit аспауы керек';
  }

  @override
  String get fieldPositive => '0-ден үлкен болуы керек';

  @override
  String get fieldNotNumber => 'Сан енгізіңіз';

  @override
  String fieldMin(String limit) {
    return '$limit кем болмауы керек';
  }

  @override
  String get fieldRequired => 'Міндетті өріс';

  @override
  String errorFieldRequired(String field) {
    return '$field — міндетті';
  }

  @override
  String get errorSessionExpired => 'Сессия аяқталды — қайта кіріңіз';

  @override
  String get chatOpenFailed => 'Чатты ашу мүмкін болмады';

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
  String get driverVerificationConsent =>
      'Құжаттар Lubao серверлерінде, Қазақстанда танылады. ЖСН шифрланған түрде сақталады және тек жеке басты тексеру және бұғатталған пайдаланушылардың қайта тіркелуінен қорғау үшін қолданылады.';

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
  String get unitPallets => 'пал.';

  @override
  String get dealVehicleFullTitle => 'Көлік толы';

  @override
  String get dealVehicleNotVerified => 'Көлік әлі тексерілуде — гаражды ашыңыз';

  @override
  String dealVehicleFullBody(String used, String capacity, String unit) {
    return '$capacity $unit ішінен $used расталған. Мұны алу үшін ағымдағыны аяқтаңыз немесе бас тартыңыз.';
  }

  @override
  String get dealVehicleFullNextTrip =>
      'Бұл жүк басқа күні тиеледі — бұл келесі рейс. Ағымдағыны жеткізгеннен кейін растаңыз.';

  @override
  String get dealVehicleFullOpenCurrent => 'Ағымдағы мәмілеге';

  @override
  String get dealCancelReasonTookAnother => 'Басқа жүк алдым';

  @override
  String driverAlreadyHauling(String used, String unit) {
    return 'Қазір тасып жүр: $used $unit';
  }

  @override
  String driverAlreadyHaulingOf(String used, String capacity, String unit) {
    return 'Қазір тасып жүр: $capacity $unit ішінен $used';
  }

  @override
  String get driverHaulingBusyNoWeight =>
      'Көлік бос емес (жүк салмағы көрсетілмеген)';

  @override
  String driverHaulingLoading(String date) {
    return 'тиеу $date';
  }

  @override
  String get selectDriverVehicleFullTitle => 'Жүргізушінің көлігі толып тұр';

  @override
  String selectDriverVehicleFullBody(String haul) {
    return '$haul. Таңдауға болады, бірақ жүргізуші ағымдағы тасымалды аяқтамай немесе тоқтатпай, жаңасын растай алмайды.';
  }

  @override
  String get selectDriverAnywayButton => 'Бәрібір таңдау';

  @override
  String driverCancelShare(int cancelled, int total) {
    return '$total мәміленің $cancelled бас тартқан';
  }

  @override
  String get garageSizeTitle => 'Шанақ өлшемі';

  @override
  String get garageSizeCustom => 'Өз өлшемім';

  @override
  String get garageSizeLength => 'Іші ұзындығы, м';

  @override
  String get garageSizeWidth => 'Іші ені, м';

  @override
  String get garageSizeHeight => 'Іші биіктігі, м';

  @override
  String get garageSizePrompt =>
      'Шанақ өлшемін көрсетіңіз — жүктер дәлірек іріктеледі';

  @override
  String get garageSizeChange => 'Өлшемді өзгерту';

  @override
  String get postCargoPallets => 'Паллеттер (дана)';

  @override
  String postCargoFitCount(int count) {
    return 'Нүктедегі $count жүргізушіге сай келеді';
  }

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
  String get postCargoDestinationError => 'Бағытты таңдаңыз';

  @override
  String get postCargoBodyTypeError => 'Кузов түрін таңдаңыз';

  @override
  String get postCargoPriceError => 'Бағаны санмен көрсетіңіз';

  @override
  String get postCargoDestinationCountry => 'Межелі ел';

  @override
  String get postCargoDestinationCity => 'Межелі қала';

  @override
  String get postCargoBodyType => 'Кузов түрі';

  @override
  String get postCargoVolume => 'Көлемі, м³';

  @override
  String get postCargoWeight => 'Салмағы';

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
  String get chatAttachLocation => 'Менің орнымды жіберу';

  @override
  String get chatLocationMessagePrefix => 'Картадағы нүкте';

  @override
  String get chatLocationError => 'Орналасқан жерді анықтау мүмкін болмады';

  @override
  String get locationRationaleTitle => 'Геопозиция';

  @override
  String get locationRationaleBody =>
      'Қолданба ағымдағы орныңызды бір рет алып, картаға сілтемені осы чатқа ғана жібереді — тек қазір. Бақылау жоқ: рейсте болмағанда орналасқан жер еш жерге жіберілмейді.';

  @override
  String get locationRationaleContinue => 'Жалғастыру';

  @override
  String get chatLoadingPlaceTooltip => 'Тиеу орны';

  @override
  String get chatLoadingPlaceDialogTitle => 'Тиеу орнына сілтеме қойыңыз';

  @override
  String get chatLoadingPlaceDialogHint => 'Baidu/Amap/2ГИС сілтемесі';

  @override
  String get chatLoadingPlaceMessagePrefix => 'Тиеу орны';

  @override
  String get chatLoadingPlaceLinkInvalid =>
      'https:// сілтемесі керек, ұзындығы 500 таңбаға дейін';

  @override
  String get chatTranslatedBadge => 'Аударылды';

  @override
  String get chatShowOriginal => 'түпнұсқа';

  @override
  String chatWritesIn(String language) {
    return '$language тілінде жазады';
  }

  @override
  String get languageNameRu => 'орыс';

  @override
  String get languageNameKk => 'қазақ';

  @override
  String get languageNameZh => 'қытай';

  @override
  String get languageNameEn => 'ағылшын';

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
  String get chatCargoReadyButton => 'Алуға дайын';

  @override
  String get chatResponseSentLabel => 'Өтінім жіберілді';

  @override
  String get chatWithdrawButton => 'Қайтарып алу';

  @override
  String get chatOfferCargoButton => 'Жүк ұсыну';

  @override
  String get chatResponseClosed => 'Өтінім жабылды';

  @override
  String get chatCargoAlreadyHasDeal => 'Бұл жүкке жүргізуші таңдалып қойған';

  @override
  String get chatOfferCargoSheetTitle => 'Жүкті таңдаңыз';

  @override
  String chatSystemDriverReady(String name) {
    return '$name жүкті алуға дайын';
  }

  @override
  String chatSystemDriverSelected(String name) {
    return '$name жүргізушісі тасымалдауға таңдалды';
  }

  @override
  String get chatSystemResponseRejected => 'Логист өтінімді қабылдамады';

  @override
  String get chatSystemDealConfirmed => 'Жүргізуші тасымалды растады';

  @override
  String chatSystemResponseWithdrawn(String name) {
    return '$name өтінімін қайтарып алды';
  }

  @override
  String get chatSystemCargoOffered => 'Логист жүк ұсынды';

  @override
  String get cargoStatusInDeal => 'Мәміледе';

  @override
  String get myResponsesTitle => 'Менің өтінімдерім';

  @override
  String get myResponsesEmpty => 'Әзірге өтінім жоқ';

  @override
  String get responseStatusInvited => 'Шақырылды';

  @override
  String get chatSystemDriverInvited => 'Логист жүргізушіні жүкке шақырады';

  @override
  String chatSystemInvitationDeclined(String name) {
    return '$name шақырудан бас тартты';
  }

  @override
  String get chatSystemCargoTaken => 'Жүк басқа жүргізушіге кетті';

  @override
  String get cargoInvitedTitle => 'Сізді осы жүкке шақырады';

  @override
  String get cargoDecline => 'Бас тарту';

  @override
  String get cargoNotAvailable => 'Жүк бос емес';

  @override
  String get cargoVerifyHint =>
      'Тасымалды растау үшін профильде тексеруден өтіңіз';

  @override
  String get chatWaitingDriver => 'Жүргізушінің жауабын күтеміз';

  @override
  String get cargoResponseSent => 'Өтінім жіберілді';

  @override
  String get cargoYouAreSelected => 'Сіз таңдалдыңыз';

  @override
  String get chatQuickReplyAtPlace => 'Мен орындамын';

  @override
  String get chatQuickReplyLoaded => 'Тиедім';

  @override
  String get chatQuickReplyLate1h => '1 сағатқа кешігемін';

  @override
  String get chatQuickReplyCargoReady => 'Жүк тиеуге дайын';

  @override
  String get chatQuickReplyWhenArrive => 'Қашан жете аласыз?';

  @override
  String get chatQuickReplySendLocation => 'Орныңызды жіберіңізші';

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
    return 'Бос жүргізушілер: $point';
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
  String get driversAtPointTodayShort => 'Бүг';

  @override
  String get driversAtPointFilterCapacityChip => 'Тоннаж';

  @override
  String get driversAtPointInviteShort => 'Шақыру';

  @override
  String get driversAtPointFilterAll => 'Барлығы';

  @override
  String get driversAtPointFilterMinCapacityTitle => 'Көтеру қабілеті';

  @override
  String driversAtPointMinCapacityLabel(int n) {
    return '$n т-дан';
  }

  @override
  String get driversAtPointPickPoint => 'Тиеу нүктесі';

  @override
  String get driversAtPointTitleShort => 'Жүргізушілер';

  @override
  String get driversAtPointFilterVerifiedChip => 'Тексерілген';

  @override
  String driversAtPointNowAtPlace(int count) {
    return 'Қазір орнында · $count';
  }

  @override
  String driversAtPointMoreToday(int count) {
    return 'тағы $count бүгін келеді';
  }

  @override
  String driversAtPointWillBeOnDay(String day, int count) {
    return '$day келеді · $count';
  }

  @override
  String driversAtPointOnSiteAgo(String ago) {
    return 'Орнында · $ago';
  }

  @override
  String driversAtPointAgoMinutes(int n) {
    return '$n мин бұрын';
  }

  @override
  String driversAtPointAgoHours(int n) {
    return '$n сағ бұрын';
  }

  @override
  String get driversAtPointAgoJustNow => 'жаңа ғана';

  @override
  String driversAtPointPlannedApprox(String day, String time) {
    return '$day ~$time';
  }

  @override
  String get weekdayShort1 => 'Дс';

  @override
  String get weekdayShort2 => 'Сс';

  @override
  String get weekdayShort3 => 'Ср';

  @override
  String get weekdayShort4 => 'Бс';

  @override
  String get weekdayShort5 => 'Жм';

  @override
  String get weekdayShort6 => 'Сб';

  @override
  String get weekdayShort7 => 'Жс';

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
  String get adminBodySizePresetsTab => 'Шанақ өлшемдері';

  @override
  String get adminAddBodySizePreset => 'Өлшем шаблонын қосу';

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
  String get adminBlockedByPhoneBadge => 'Нөмір қара тізімде';

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
  String get adminBlacklistMatchTitle => 'Қара тізімге сәйкестік';

  @override
  String get adminBlacklistMatchIntro =>
      'Осы карточканың идентификаторлары арасында белсенді блоктаулар бар:';

  @override
  String get adminBlacklistMatchOverride => 'Қара тізімге қарамастан растау';

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
  String adminAttentionBlacklistMatches(int count) {
    return 'Қара тізіммен сәйкестіктер: $count';
  }

  @override
  String get adminBlockAlsoByTitle => 'Сондай-ақ мыналар бойынша бұғаттау:';

  @override
  String get adminIdentifierTypeIin => 'ЖСН';

  @override
  String get adminIdentifierTypeLicense => 'Куәлік нөмірі';

  @override
  String get adminIdentifierTypePhone => 'Телефон';

  @override
  String get adminIdentifierTypeVin => 'VIN';

  @override
  String get adminIdentifierTypePlate => 'Мемлекеттік нөмір';

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
  String get adminVerificationBlacklistedBadge => 'Қара тізім';

  @override
  String get adminConfirmDespiteBlacklist => 'Сәйкестікке қарамастан растау';

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
  String get adminRecognitionTitle => 'Танылды';

  @override
  String get adminRecognitionSkipped => 'OCR қолжетімсіз — қолмен тексеріңіз';

  @override
  String get adminRecognitionPending => 'Тану кезекте…';

  @override
  String get adminRecognitionFailed => 'Тану мүмкін болмады';

  @override
  String get adminRecognitionRetry => 'Қайта тану';

  @override
  String get adminRecognitionMatchOk => 'Тексерілді';

  @override
  String get adminRecognitionNeedsReview => 'Тексеріңіз';

  @override
  String get adminRecognitionDuplicate => 'Басқа иесінде қайталанады';

  @override
  String get adminRecognitionBlacklisted => 'Қара тізімде';

  @override
  String get adminRecognitionBlacklistBanner =>
      'Қара тізіммен сәйкестік — анық шешімсіз растау мүмкін емес';

  @override
  String get adminRecognitionChecksumHint => 'тексеру цифры дұрыс';

  @override
  String get adminRecognitionEditValue => 'Мәнді өзгерту';

  @override
  String get adminRecognitionFieldFullName => 'Аты-жөні';

  @override
  String get adminRecognitionFieldIin => 'ЖСН';

  @override
  String get adminRecognitionFieldLicenseNumber =>
      'Жүргізуші куәлігінің нөмірі';

  @override
  String get adminRecognitionFieldExpiryDate => 'Жарамдылық мерзімі';

  @override
  String get adminRecognitionFieldBirthDate => 'Туған күні';

  @override
  String get adminRecognitionFieldPlateNumber => 'Мемлекеттік нөмір';

  @override
  String get adminRecognitionFieldVin => 'VIN';

  @override
  String get adminRecognitionFieldBrand => 'Маркасы';

  @override
  String get adminRecognitionFieldCapacityTons => 'Жүк көтергіштігі, т';

  @override
  String get adminRecognitionFieldCompanyName => 'Компания атауы';

  @override
  String get adminRecognitionFieldBin => 'БСН';

  @override
  String get adminRecognitionFieldUscc => '统一社会信用代码';

  @override
  String get adminIdentifiersCardTitle => 'Идентификаторлар';

  @override
  String get adminIdentifierBlockHistoryTitle => 'Бұғаттау тарихы';

  @override
  String get adminIdentifierLifted => 'Алынды';

  @override
  String get adminIdentifierActive => 'Белсенді';

  @override
  String get adminIdentifierReveal => 'Көрсету';

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
  String get adminVehicleTractorTitle => 'Тартқыш';

  @override
  String get adminVehicleTrailerTitle => 'Тіркеме';

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
  String get adminComplaintNoteRequired =>
      'Авторға жауап жазыңыз — ол оны көреді';

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

  @override
  String get postCargoVerificationRequired =>
      'Жүктерді жариялау компания тексерілгеннен кейін ашылады — тіркеу туралы куәлікті компания профилінде жүктеңіз';

  @override
  String get companyNotVerifiedBannerText =>
      'Компания тексерілмеген. Жүргізушілерді көруге және оларға жазуға болады, бірақ жүк жариялау мүмкін емес — төмендегі тіркеу туралы куәлікті жүктеңіз';

  @override
  String get companyEditTitle => 'Компания деректері';

  @override
  String get companyEditCityLabel => 'Қала';

  @override
  String get companyEditLegalAddressLabel => 'Заңды мекенжай';

  @override
  String get companyEditTaxIdLabel => 'Тіркеу нөмірі (統一社会信用代码 / БСН)';

  @override
  String get companyEditTaxIdError =>
      'Еліңіз үшін тіркеу нөмірінің форматы қате';

  @override
  String get myProfileTitle => 'Менің профилім';

  @override
  String get myProfileNameLabel => 'Аты-жөні';

  @override
  String get myProfilePhoneLabel => 'Жүргізушілер үшін телефон';

  @override
  String get myProfileWechatLabel => 'WeChat';

  @override
  String get myProfileNameError => 'Атын енгізіңіз';

  @override
  String get myProfileNotSetYet => 'Профильді толтырыңыз';

  @override
  String get companyVerificationTitle => 'Компанияны растаңыз';

  @override
  String get companyVerificationHint =>
      'Тіркеу туралы куәлікті жүктеңіз — тізіліммен салыстырамыз және тізілімдегі нөмірге қоңырау шаламыз, әдетте 1 жұмыс күніне дейін';

  @override
  String get companyVerificationStatusNone => 'Құжат жүктелмеген';

  @override
  String get companyVerificationStatusPending => 'Тексерілуде';

  @override
  String get companyVerificationStatusRejected => 'Қайта түсіру керек';

  @override
  String get adminNavSearch => 'Іздеу';

  @override
  String get adminNavMore => 'Көбірек';

  @override
  String get garageTitle => 'Менің гаражым';

  @override
  String get garageAddDocument => 'Құжат қосу';

  @override
  String get garageDocumentSent => 'Техпаспорт тексеруге жіберілді';

  @override
  String get garageTractorsSection => 'ТЯГАЧТАР';

  @override
  String get garageTrailersSection => 'ТІРКЕМЕЛЕР';

  @override
  String get garageVerified => 'тексерілді';

  @override
  String get garagePending => 'тексеруде';

  @override
  String get garageAddedYesterday => 'кеше қосылды';

  @override
  String get garageAddVehicle => 'Машина не тіркеме қосу';

  @override
  String get garageEmptyTractors => 'Тягач жоқ';

  @override
  String get garageEmptyTrailers => 'Тіркеме жоқ';

  @override
  String get garageOcrHint =>
      'Техпаспортты суретке түсіріңіз — мемномер мен VIN өздігінен толады. Тексеріп, жіберіңіз.';

  @override
  String get garageArchive => 'Мұрағатқа';

  @override
  String get garageArchived => 'Машина мұрағатқа ауыстырылды';

  @override
  String get garageKindTitle => 'Қандай машина?';

  @override
  String get garageKindTractor => 'Тягач';

  @override
  String get garageKindTrailer => 'Тіркеме';

  @override
  String get garageVin => 'VIN';

  @override
  String get garageLength => 'Ұзындығы, м';

  @override
  String get garagePhotoRequired => 'Техпаспортты суретке түсіріңіз';

  @override
  String get garageSubmit => 'Тексеруге жіберу';

  @override
  String get garageAddFailed => 'Машина қосылмады';

  @override
  String get garageFieldRequired => 'Жолды толтырыңыз';

  @override
  String get garageComboTitle => 'Немен барасыз?';

  @override
  String get garageComboTractorLabel => 'Тягач';

  @override
  String get garageComboTrailerLabel => 'Тіркеме';

  @override
  String get garageComboPendingBadge => 'тексеруде';

  @override
  String get garageComboEmpty => 'Гараж бос — профильде машина қосыңыз';

  @override
  String get garageGoToGarage => 'Менің гаражым';

  @override
  String get cityPickerTitle => 'Қаланы таңдаңыз';

  @override
  String get cityPickerSearchHint => 'Қаланы іздеу';

  @override
  String get cityPickerNearby => 'Маған жақын';

  @override
  String get cityPickerNearbyNotFound =>
      'Жақын жерде қала табылмады — тізімнен таңдаңыз';

  @override
  String get cityPickerRecent => 'Соңғылар';

  @override
  String get cityPickerAll => 'Барлық қалалар';

  @override
  String get cityPickerNothingFound => 'Ештеңе табылмады';

  @override
  String get cityFieldPlaceholder => 'Қаланы таңдаңыз';

  @override
  String get announceArrivalCityError => 'Бос болатын қаланы таңдаңыз';

  @override
  String get announceArrivalAddAnother => 'Тағы бір жариялау';

  @override
  String get announceArrivalOthers => 'Жоспардағы келесілері';

  @override
  String get announceArrivalLimit =>
      'Бір уақытта бестен артық жариялауға болмайды';

  @override
  String get arrivalQuestionDay =>
      'Жеттіңіз бе? «Мен осындамын» түймесін басыңыз';

  @override
  String get arrivalQuestionStill => 'Әлі жүк іздеп жүрсіз бе?';

  @override
  String get arrivalStillYes => 'Иә, іздеп жүрмін';

  @override
  String get arrivalStillLeft => 'Кеттім';

  @override
  String get feedBadgePartial => 'Қосымша жүк';

  @override
  String get feedLoadMore => 'Тағы көрсету';

  @override
  String cargoPartialHintFits(String committed, String cargo, String capacity) {
    return 'Ағымдағы жүкке сыяды: $committed т + $cargo т / $capacity т';
  }

  @override
  String cargoPartialHintFull(String committed, String cargo, String capacity) {
    return 'Ағымдағы жүкке сыймайды: $committed т + $cargo т / $capacity т';
  }

  @override
  String get cargoPartialHintNextTrip =>
      'Тиеу күні басқа — бұл қосымша жүк емес, келесі рейс';

  @override
  String get cargoPickupCityLabel => 'Тиеу қаласы';

  @override
  String get postCargoPickupCity => 'Тиеу қаласы';

  @override
  String get postCargoPickupCityError => 'Тиеу қаласын таңдаңыз';

  @override
  String get postCargoAllowPartial => 'Қосымша жүк қосуға болады';

  @override
  String get postCargoAllowPartialHint =>
      'Жүк бүкіл көлікке емес — жүргізуші тағы алуы мүмкін';

  @override
  String get notificationGroupArrivalCheck =>
      'Жариялау туралы еске салу («Жеттіңіз бе?»)';

  @override
  String get adminPointKind => 'Нүкте түрі';

  @override
  String get adminPointKindCity => 'Қала';

  @override
  String get adminPointKindTerminal => 'Терминал (геоаймақ)';

  @override
  String get adminPointRadius => 'Геоаймақ радиусы, м';

  @override
  String get adminPointTerminalNeedsGeofence =>
      'Терминал үшін ендік, бойлық және радиус қажет';

  @override
  String get adminCityStatsTitle => 'Қалалар бойынша';

  @override
  String get adminCityStatsArrivals => 'Жарияланымдар';

  @override
  String get adminCityStatsCargos => 'Жүктер';

  @override
  String get adminCityStatsDeals => 'Мәмілелер';

  @override
  String get adminCityStatsEmpty => 'Қалалар бойынша белсенділік жоқ';

  @override
  String get consentUnderstood => 'Түсінікті';

  @override
  String get tripTrackingConsentTitle => 'Рейс уақытындағы орналасқан жер';

  @override
  String get tripTrackingConsentBody =>
      'Рейс кезінде қолданба орналасқан жеріңізді логистке жібереді. Мұны мәміле картасында үзіліске қоюға болады.';

  @override
  String get tripTrackingSwitchTitle => 'Орналасқан жерді логистке жіберу';

  @override
  String get tripTrackingSwitchOn => 'Рейс уақытында қосулы';

  @override
  String get tripTrackingSwitchPaused =>
      'Үзілісте — логист сіздің қайда екеніңізді көрмейді';

  @override
  String get terminalWatchConsentTitle =>
      'Орналасқан жер бойынша «кеттім» белгісі';

  @override
  String get terminalWatchConsentBody =>
      'Сіз терминалда «осындамын» кезіңде қолданба кетпегеніңізді тексеріп, хабарландыруды өзі жабады. Орналасқан жер логистке жіберілмейді.';

  @override
  String get locationRationaleNearbyBody =>
      'Қолданба ең жақын қаланы табу үшін орналасқан жеріңізді бір рет анықтайды. Ол еш жерде сақталмайды, бақылау жоқ.';

  @override
  String get loginChannelTitle => 'Кодты қайда жіберу';

  @override
  String get loginChannelWhatsapp => 'WhatsApp';

  @override
  String get loginChannelTelegram => 'Telegram';

  @override
  String get loginChannelSms => 'SMS';

  @override
  String loginCodeSentVia(String channel) {
    return 'Код жіберілді: $channel';
  }

  @override
  String get loginSendOtherWay => 'Келмеді ме? Басқа жолмен жіберу';

  @override
  String get adminLoginChannelsTitle => 'Кіру коды арналары';

  @override
  String get adminLoginChannelsHint =>
      'Реті — жоғарыдан төмен: бірінші қосылған арна жүргізушіге әдепкі ұсынылады, ақау болса код келесісіне кетеді.';

  @override
  String get adminLoginChannelsNoKeys => 'кілттер жоқ';

  @override
  String get adminMoveUp => 'Жоғары';

  @override
  String get adminMoveDown => 'Төмен';

  @override
  String get adminLoginChannelsSaved => 'Арналар сақталды';

  @override
  String get pushChannelName => 'Lubao хабарландырулары';

  @override
  String get postCargoWeightError => 'Салмақ — 60 т-ға дейін (60 000 кг)';

  @override
  String get companyLoginInvalidCredentials => 'Email немесе құпиясөз қате';

  @override
  String get mapsOpen => 'Картада ашу';

  @override
  String get mapsApple => 'Apple Карталар';

  @override
  String get mapsGoogle => 'Google Maps';

  @override
  String get mapsYandex => 'Яндекс Карталар';

  @override
  String get maps2gis => '2ГИС';

  @override
  String get mapsAmap => '高德地图 (Amap)';

  @override
  String get mapsBaidu => '百度地图 (Baidu)';

  @override
  String get mapsCopyCoordinates => 'Координаттарды көшіру';

  @override
  String get mapsCoordinatesCopied => 'Координаттар көшірілді';

  @override
  String get adminRatesTitle => 'Валюта бағамдары (ҰБ)';

  @override
  String get adminRatesHint =>
      'Күн сайын 10:00-де Ұлттық банк бағамы бойынша өздігінен жаңарады. Қолмен өзгерту автоматты түрде қайта жазылмайды.';

  @override
  String get adminRateEdit => 'Бағамды өзгерту';

  @override
  String chatSystemDriverSaysAgreed(String name) {
    return '$name: келістік — мәміле қадамдармен жүруі үшін жүргізушіні таңдаңыз';
  }

  @override
  String get adminNavBlacklist => 'Қара тізім';

  @override
  String get adminBlacklistAdd => 'Қара тізімге қосу';

  @override
  String get adminBlacklistType => 'Не бұғатталады';

  @override
  String get adminBlacklistValue => 'Мәні';

  @override
  String get adminBlacklistLift => 'Бұғаттан шығару';

  @override
  String get adminBlacklistLifted => 'Алынды';

  @override
  String get adminBlacklistEmpty => 'Қара тізім бос';

  @override
  String get adminBlacklistShowLifted => 'Алынғандарды көрсету';

  @override
  String get adminIdentifierTypeBin => 'БСН';

  @override
  String get adminIdentifierTypeUscc => 'USCC (ҚХР)';

  @override
  String get adminBlacklistInvalid => 'Мән бұл түрге сәйкес келмейді';

  @override
  String get profileDeleteAccount => 'Аккаунтты жою';

  @override
  String get profileDeleteAccountTitle => 'Аккаунтты жою керек пе?';

  @override
  String get profileDeleteAccountBody =>
      'Аты-жөні, телефон, email, құжаттар мен көлік деректері жойылады, аккаунтқа кіру барлық құрылғыда жабылады. Аяқталған мәмілелер мен пікірлер сіздің атыңызсыз қалады. Жоюды болдырмау мүмкін емес.';

  @override
  String get profileDeleteAccountConfirm => 'Жою';

  @override
  String get profileDeleteAccountActiveDeals =>
      'Алдымен белсенді мәмілелерді аяқтаңыз немесе тоқтатыңыз.';

  @override
  String get profileDeleteAccountOwnerHasMembers =>
      'Компанияда қызметкерлер бар: алдымен иелікті беріңіз немесе оларды шығарыңыз.';

  @override
  String get pdConsentTitle => 'Деректерді өңдеуге келісім';

  @override
  String get pdConsentBody =>
      'Сізді тексеру үшін құжаттардың фотосы мен ондағы деректерді (аты-жөні, ЖСН, куәлік нөмірі, мемлекеттік нөмір, VIN) сақтаймыз. Деректер Қазақстандағы серверлерде сақталады, тек тексеретін әкімшіге көрінеді және үшінші тұлғаларға берілмейді. Құжаттар аккаунтпен бірге жойылады.';

  @override
  String get pdConsentCheckbox =>
      'Жеке деректерімді жинауға және өңдеуге келісемін';

  @override
  String get pdConsentContinue => 'Жалғастыру';

  @override
  String get legalTerms => 'Пайдалану шарттары';

  @override
  String get legalPrivacy => 'Құпиялылық саясаты';

  @override
  String get appUpdateTitle => 'Қосымшаны жаңартыңыз';

  @override
  String get appUpdateBody =>
      'Бұл нұсқа енді қолдау көрсетілмейді. Жаңасын орнатыңыз — бір минут қана.';

  @override
  String get appUpdateButton => 'Жаңарту';

  @override
  String get legalOffer => 'Компанияларға арналған оферта';

  @override
  String get companyRegisterOfferAccept =>
      'Офертаны қабылдаймын: Lubao — ақпараттық алаң, тасымалдаушы емес және тасымал шартының тарапы емес';

  @override
  String legalLoginNotice(String terms, String privacy) {
    return 'Жалғастыра отырып, сіз $terms мен $privacy қабылдайсыз';
  }

  @override
  String get legalTermsLink => 'Шарттарды';

  @override
  String get legalPrivacyLink => 'Құпиялылық саясатын';

  @override
  String get aboutTitle => 'Қосымша туралы';

  @override
  String aboutVersion(String version) {
    return 'Нұсқа $version';
  }

  @override
  String get contactRespondFirst =>
      'Жүкке жауап беріңіз — логистің телефоны пайда болады. Құжаттар тексерілгеннен кейін бірден қоңырау шалуға болады.';

  @override
  String get contactDailyLimit =>
      'Бүгін тым көп нөмір ашылды. Ертең қайталаңыз немесе чатқа жазыңыз.';

  @override
  String get contactCompanyNotVerified =>
      'Жүргізушілерге компания тексерілгеннен кейін қоңырау шалуға болады. Әзірге чатқа жазыңыз.';

  @override
  String get contactNoPhone => 'Нөмір көрсетілмеген — чатқа жазыңыз.';

  @override
  String get tooManyRequests => 'Сұраныс тым көп. Бір минут күтіңіз.';

  @override
  String adminSuspiciousTitle(String name, int count) {
    return 'Парсингке ұқсайды: $name — тәулігіне $count нөмір';
  }

  @override
  String adminSuspiciousLimitHits(int count) {
    return 'Тәуліктік шекке тірелді: $count';
  }

  @override
  String get adminSuspiciousOk => 'Бәрі дұрыс';

  @override
  String get adminSuspiciousBlock => 'Бұғаттау';

  @override
  String get vehiclePhotoFront => 'Алдынан, мемлекеттік нөмірімен';

  @override
  String get vehiclePhotoSide => 'Бүйірінен';

  @override
  String get vehiclePhotoStepTitle => 'Көлікті суретке түсіріңіз';

  @override
  String get vehiclePhotoStepHint =>
      'Логист көлікті сіздің карточкаңызда және рейс құжаттарында көреді. Өткізіп, кейін қосуға болады.';

  @override
  String get commonSkip => 'Өткізу';

  @override
  String get garagePhotosReminder => 'Көлік фотосын қосыңыз';

  @override
  String get vehiclePhotosNone => 'Фото жоқ';

  @override
  String get driverDocsTitle => 'Жүргізуші құжаттары';

  @override
  String get driverDocsLocked => 'Жүргізуші растағаннан кейін ашылады';

  @override
  String get driverDocsDownloadPdf => 'PDF жүктеу';

  @override
  String get driverDocsOpen => 'Құжаттар';

  @override
  String get driverDocsVehiclePending => 'Көлік әлі тексерілуде';

  @override
  String get driverDocsIin => 'ЖСН';

  @override
  String get driverDocsLicense => 'Жүргізуші куәлігі';

  @override
  String get driverDocsSelfie => 'Жүргізушінің фотосы';

  @override
  String get driverDocsPassport => 'Техпаспорт';

  @override
  String get driverDocsExpired =>
      'Құжаттар жабық: жеткізілгеннен кейін 30 күн өтті';

  @override
  String cargoDealDriverConfirmed(String name) {
    return 'Жүргізуші: $name · растады';
  }

  @override
  String cargoDealDriverWaiting(String name) {
    return 'Жүргізуші: $name · растауды күтеміз';
  }

  @override
  String dealConfirmDocsNotice(String company) {
    return '$company логисіне рейске арналған құжаттарыңыз ашылады: куәлік, жүргізуші куәлігі, техпаспорттар. Тек осы мәміле бойынша.';
  }

  @override
  String dealDocsOpenedAt(String when) {
    return 'Логист құжаттарды ашты: $when';
  }

  @override
  String get dealDocsAccessTitle => 'Құжаттарды кім ашты';

  @override
  String get adminVehicleAutoVerified => 'Автоматты түрде тексерілді';

  @override
  String get adminVehicleRevoke => 'Тексеруді қайтару';

  @override
  String get garageEmptyTitle => 'Көлік қосыңыз';

  @override
  String get garageEmptyBody =>
      'Техпаспортты суретке түсіріңіз — мемлекеттік нөмір мен VIN өздігінен толтырылады.';

  @override
  String get garageNoPlate => 'Нөмірсіз';

  @override
  String get feedStateResponded => 'Сіз жауап бердіңіз';

  @override
  String get feedStateInvited => 'Сізді шақырады';

  @override
  String get feedStateSelected => 'Сіз таңдалдыңыз — растаңыз';

  @override
  String feedStateOthers(int count) {
    return 'Жауап бергендер: $count';
  }

  @override
  String homeMyResponsesSummary(int total) {
    return 'Сіздің жауаптарыңыз: $total';
  }

  @override
  String homeMyResponsesPending(int count) {
    return 'жауап күтуде $count';
  }

  @override
  String homeMyResponsesInvited(int count) {
    return 'шақыру $count';
  }

  @override
  String homeMyResponsesSelected(int count) {
    return 'таңдалды $count';
  }

  @override
  String get driverSetupFirstName => 'Атыңыз кім';

  @override
  String get directionRegionsAll => 'Бүкіл ел';

  @override
  String directionRegionsCount(int count) {
    return 'Облыстар: $count';
  }

  @override
  String directionRegionsTitle(String country) {
    return '$country ішінде қайда';
  }

  @override
  String get driverSetupPermitsOptional => 'Рұқсаттар — бар болса';

  @override
  String licenseNameBanner(String name) {
    return 'Куәлікте: $name. Профильге қою керек пе?';
  }

  @override
  String get licenseNameAccept => 'Иә, бұл мен';

  @override
  String statusLookingFrom(String city) {
    return '$city қаласынан жүк іздеймін';
  }

  @override
  String statusOnTheWay(String city, String day) {
    return 'Жолдамын, $city қаласында $day боламын';
  }

  @override
  String get statusInTrip => 'Рейсте';

  @override
  String get statusNotLooking => 'Іздемеймін';

  @override
  String get whereNowTitle => 'Қазір қайдасыз?';

  @override
  String get whereNowGoing => 'Жолдамын, … боламын';

  @override
  String get whereNowNotLooking => 'Әзірге іздемеймін';

  @override
  String get whereNowOtherCity => 'Мен басқа қаладамын';

  @override
  String whereNowGpsHint(String city) {
    return 'Сіз қазір $city қаласындасыз ба?';
  }

  @override
  String deliveredAskTitle(String city) {
    return 'Сіз $city қаласындасыз. Осы жерден жүк іздейсіз бе?';
  }

  @override
  String get unitM => 'м';

  @override
  String get unitLiters => 'л';

  @override
  String get unitCelsius => '°C';

  @override
  String get unitCars => 'көлік';

  @override
  String get unitSlots => 'дана';

  @override
  String get unitSections => 'секц.';

  @override
  String get bodySpecsTitle => 'Шанақ параметрлері';

  @override
  String get cargoSpecsTitle => 'Жүк параметрлері';

  @override
  String get cargoExtraBodyTypes => 'Сондай-ақ сәйкес келеді';

  @override
  String get specYes => 'иә';

  @override
  String get specNo => 'жоқ';

  @override
  String get adminBodyTypeNameEdit => 'Атауы мен реті';

  @override
  String get adminBodyTypeProfileEdit => 'Профиль және өрістер';

  @override
  String get adminBodyTypeProfile => 'Профиль';

  @override
  String get adminBodyTypeFieldsJson => 'Өрістер (JSON)';

  @override
  String adminBodyTypeFieldsInvalid(String errors) {
    return 'Өрістер сақталмады: $errors';
  }

  @override
  String get dealStatusCancelRequested => 'Болдырмау сұралды';

  @override
  String get dealStatusDisputed => 'Болдырмау даулы';

  @override
  String get cancelReasonVehicleBreakdown => 'Көлік бұзылды';

  @override
  String get cancelReasonCargoNotReady => 'Жүк дайын емес';

  @override
  String get cancelReasonOtherPartyUnresponsive =>
      'Екінші тарап жауап бермейді';

  @override
  String get cancelReasonTermsChanged => 'Шарттар өзгерді';

  @override
  String get cancelReasonOther => 'Басқа';

  @override
  String get dealCancelReasonPick => 'Неге болдырмайсыз?';

  @override
  String get dealCancelOtherHint => 'Себебін жазыңыз';

  @override
  String get dealCancelRequestNotice =>
      'Жүк жолда — болдырмау тек екінші тараптың келісімімен. 24 сағат жауап болмаса, өзі өтеді.';

  @override
  String get dealCancelRequestSend => 'Сұрау жіберу';

  @override
  String dealCancelRequestedByMe(String time) {
    return 'Сіз болдырмауды сұрадыңыз. $time дейін жауап күтеміз';
  }

  @override
  String dealCancelRequestedByOther(String name, String reason, String time) {
    return '$name мәмілені болдырмауды сұрайды: $reason. $time дейін жауап болмаса, болдырылмайды';
  }

  @override
  String get dealCancelConfirm => 'Болдырмауды растау';

  @override
  String get dealCancelDispute => 'Дауласу';

  @override
  String get dealDisputeReasonLabel => 'Неге келіспейсіз?';

  @override
  String get dealDisputedNotice => 'Болдырмау даулы — әкімші шешеді';

  @override
  String cancelStatsLine(int cancelled, int total) {
    return '$total ішінен $cancelled болдырмады';
  }

  @override
  String cancelStatsAfterLoad(int count) {
    return 'тиелгеннен кейін $count';
  }

  @override
  String get complaintOfferTitle => 'Шағымдану керек пе?';

  @override
  String get complaintOfferBody =>
      'Мәміле жүк көлікте болғанда болдырылмады. Әкімшіге не болғанын айтыңыз.';

  @override
  String get complaintReasonLabel => 'Не болды';

  @override
  String get complaintSend => 'Шағымдану';

  @override
  String get complaintSent => 'Шағым жіберілді';

  @override
  String chatSystemCancelRequested(String reason) {
    return 'Мәмілені болдырмау сұралды: $reason. 24 сағат жауап болмаса, болдырылмайды';
  }

  @override
  String get chatSystemCancelConfirmed =>
      'Болдырмау расталды — мәміле болдырылмады';

  @override
  String get chatSystemCancelDisputed => 'Болдырмау даулы — әкімші шешеді';

  @override
  String get chatSystemCancelResolved => 'Әкімші мәмілені болдырмады';

  @override
  String get chatSystemCancelResumed =>
      'Әкімші мәмілені «Жолда» күйіне қайтарды';

  @override
  String get chatSystemCancelAuto =>
      'Болдырмау сұрауына 24 сағат жауап болмады — мәміле болдырылмады';

  @override
  String get adminDisputesTitle => 'Болдырмау даулары';

  @override
  String adminDisputeRequested(String who, String reason) {
    return '$who болдырмауды сұрайды: $reason';
  }

  @override
  String adminDisputeObjection(String reason) {
    return 'Қарсылық: $reason';
  }

  @override
  String get adminDisputeCancelDriver => 'Болдырмау — жүргізуші кінәлі';

  @override
  String get adminDisputeCancelCompany => 'Болдырмау — компания кінәлі';

  @override
  String get adminDisputeCancelNeutral => 'Болдырмау — кінәсіз';

  @override
  String get adminDisputeResume => '«Жолда» күйіне қайтару';

  @override
  String get adminCancellationsTitle => 'Болдырмаулар';

  @override
  String get cancelStageBeforeConfirm => 'растауға дейін';

  @override
  String get cancelStageAfterConfirm => 'растаудан кейін';

  @override
  String get cancelStageAfterLoad => 'тиелгеннен кейін';

  @override
  String get cancelStageInTransit => 'жолда';

  @override
  String get cancelAtFault => 'өз кінәсінен';

  @override
  String get unitKm => 'км';

  @override
  String get feedLoadToday => 'тиеу бүгін';

  @override
  String get feedLoadTomorrow => 'тиеу ертең';

  @override
  String feedLoadOn(String date) {
    return 'тиеу $date';
  }

  @override
  String perKmKzt(String value) {
    return '$value ₸/км';
  }

  @override
  String feedRespondedCount(int count) {
    return '$count жауап берді';
  }

  @override
  String cargoMarketMonth(String from, String to) {
    return 'Айлық нарық: $from–$to ₸/км';
  }

  @override
  String get postCargoCategory => 'Не тасымалдайсыз';

  @override
  String get postCargoCategoryRequired => 'Жүк санатын таңдаңыз';

  @override
  String postCargoMarketHint(String median, int deals) {
    return 'Осы бағыт бойынша айына: медиана $median ₸/км, мәмілелер $deals';
  }

  @override
  String cargoAdvance(String amount) {
    return 'аванс $amount';
  }

  @override
  String get paymentFormCashShort => 'қолма-қол';

  @override
  String get paymentFormCardShort => 'картаға';

  @override
  String get paymentFormCashlessShort => 'шотқа';

  @override
  String paymentDelayShort(String days) {
    return 'кейінге қалдыру $days күн';
  }

  @override
  String get paymentFormCash => 'Қолма-қол';

  @override
  String get paymentFormCard => 'Картаға';

  @override
  String get paymentFormCashless => 'Шотқа';

  @override
  String get postCargoPaymentTitle => 'Төлем';

  @override
  String get postCargoAdvance => 'Аванс';

  @override
  String get postCargoPaymentDelay => 'Кейінге қалдыру, күн';

  @override
  String get postCargoTrucks => 'Қанша көлік керек';

  @override
  String cargoTrucksLeft(String needed, String left) {
    return 'керек $needed · қалды $left';
  }

  @override
  String get postCargoAdvanceTooBig => 'Аванс бағадан аспауы керек';

  @override
  String get companyKindTitle => 'Компания түрі';

  @override
  String get companyKindShipper => 'Жүк иесі';

  @override
  String get companyKindForwarder => 'Экспедитор';

  @override
  String get companyKindCarrier => 'Тасымалдаушы';

  @override
  String postCargoDistanceHint(String km) {
    return 'Жолмен ≈ $km км';
  }

  @override
  String postCargoDistancePerKm(String km, String perKm) {
    return 'Жолмен ≈ $km км · сіздің бағаңыз ≈ $perKm ₸/км';
  }

  @override
  String get postCargoDistanceCounting => 'Қашықтық есептелуде…';

  @override
  String get adminRoutePricesTitle => 'Бағыттар бойынша бағалар';

  @override
  String get adminRoutePricesEmpty =>
      'Деректер аз: статистика бағыт бойынша айына 5+ нүктеде шығады';

  @override
  String get adminColBucket => 'Бағыт';

  @override
  String get adminColTonnage => 'Тоннаж';

  @override
  String get adminColMedian => 'Медиана ₸/км';

  @override
  String get adminColRange => 'P25–P75';

  @override
  String get adminColPoints => 'Нүктелер';

  @override
  String get adminColDealPoints => 'Оның ішінде мәмілелер';

  @override
  String get adminExportCsv => 'CSV жүктеу';

  @override
  String get adminAllFilter => 'Барлығы';

  @override
  String get bucketKz => 'ҚР ішінде';

  @override
  String get bucketCis => 'ТМД';

  @override
  String get bucketCnFar => 'Қытай / алыс';

  @override
  String tonnageUpTo(int tons) {
    return '$tons т дейін';
  }

  @override
  String get tonnageOver => '10 т-дан астам';

  @override
  String get adminCargoCategoriesTitle => 'Жүк санаттары';

  @override
  String get adminCsvSaved => 'CSV сақталды';

  @override
  String get dealVehicleOneDealTitle => 'Көлік бос емес';

  @override
  String get dealVehicleOneDealBody =>
      'Бұл көлікке бір уақытта бір тасымал — ағымдағысын аяқтаңыз.';

  @override
  String get adminSettingPartialLoads => 'Қосымша жүк (жинақ жүк)';

  @override
  String get adminSettingPartialLoadsHint =>
      'Өшірулі — бір көлікке бір тасымал, «қосымша жүк» белгісіз. Қосулы — тек тент, изотерм және реф үшін.';

  @override
  String adminRecognitionDuplicateOf(String name) {
    return '$name иесінде қайталанады';
  }

  @override
  String get driverLoginTelegram => 'Telegram арқылы кіру';

  @override
  String get driverLoginTelegramWaiting =>
      'Telegram-ды ашып, «Старт», содан кейін «Нөмірмен бөлісу» түймесін басыңыз — кіру өздігінен болады';

  @override
  String get driverLoginTelegramExpired =>
      'Кіру сілтемесінің мерзімі өтті — «Telegram арқылы кіру» түймесін қайта басыңыз';

  @override
  String get driverLoginOrPhone => 'немесе телефон нөмірі бойынша';

  @override
  String get loginChannelTelegramBot => 'Telegram боты (кодсыз кіру)';

  @override
  String get vehiclePhotoFrontTitle => 'Алдынан';

  @override
  String get vehiclePhotoFrontHint => 'Мемлекеттік нөмір оқылатындай';

  @override
  String get vehiclePhotoSideTitle => 'Бүйірінен';

  @override
  String get vehiclePhotoSideHint => 'Көлік толық, тіркемесімен';

  @override
  String get vehiclePhotoTake => 'Суретке түсіру';

  @override
  String get vehiclePhotoRetake => 'Қайта түсіру';

  @override
  String get vehiclePhotoFailed => 'Жіберілмеді';

  @override
  String profileAddVehicleRegistered(String details) {
    return 'Тіркелу кезінде: $details. Мемлекеттік нөмір мен техпаспортсыз логист көлігіңізді көрмейді және жүк бермейді.';
  }

  @override
  String get profileAddVehiclePlain =>
      'Мемлекеттік нөмір мен техпаспортсыз логист көлігіңізді көрмейді және жүк бермейді.';

  @override
  String get garageAddPhotoChip => 'Сурет қосыңыз';

  @override
  String get avatarOfferTitle => 'Осы суретті профильге қоясыз ба?';

  @override
  String get avatarOfferBody => 'Логистер оны көреді';

  @override
  String get avatarOfferYes => 'Иә';

  @override
  String get avatarOfferOther => 'Басқасын түсіру';

  @override
  String get avatarOfferLater => 'Қазір емес';

  @override
  String get avatarAdd => 'Сурет қосу';

  @override
  String get avatarChange => 'Суретті ауыстыру';

  @override
  String get avatarRemove => 'Суретті алып тастау';

  @override
  String get avatarHint => 'Логистер суретті атыңыздың жанынан көреді';

  @override
  String get adminAvatarRemoveReason => 'Себебі (мысалы, суретке шағым)';

  @override
  String postCargoWeightLooksLikeKg(String kg, String tons) {
    return 'Бұл $kg кг = $tons т ма?';
  }

  @override
  String postCargoWeightLooksLikeTons(String tons) {
    return 'Мүмкін, $tons т?';
  }

  @override
  String get cargosTabActive => 'Белсенді';

  @override
  String get cargosTabWork => 'Жұмыста';

  @override
  String get cargosTabArchive => 'Мұрағат';

  @override
  String get cargosEmptyActive => 'Белсенді жүк жоқ — жүк жариялаңыз';

  @override
  String get cargosEmptyWork => 'Қазір жұмыстағы жүк жоқ';

  @override
  String get cargosEmptyArchive => 'Мұрағат бос';

  @override
  String get cargoRepeat => 'Қайталау';

  @override
  String get cargosArchiveCity => 'Қала';

  @override
  String get cargosArchivePeriod => 'Кезең';

  @override
  String get cargosArchiveReset => 'Тазарту';

  @override
  String cargoResponsesCount(int count) {
    return 'Жауаптар: $count';
  }

  @override
  String cargoResponsesNew(int count) {
    return '$count жаңа';
  }

  @override
  String get navTrips => 'Менің рейстерім';

  @override
  String get tripsTitle => 'Менің рейстерім';

  @override
  String get tripsNeedAnswer => 'Жауап беру керек';

  @override
  String get tripsWaiting => 'Логистің жауабын күтемін';

  @override
  String get tripsInWork => 'Жұмыста';

  @override
  String get tripsSelectedBadge => 'Сізді таңдады — растаңыз';

  @override
  String get tripsConfirm => 'Рейсті растау';

  @override
  String tripsInvitedBadge(int hours) {
    return 'Сізді шақырды · $hours сағ қалды';
  }

  @override
  String get tripsAccept => 'Алуға дайынмын';

  @override
  String get tripsDecline => 'Бас тарту';

  @override
  String get tripsWithdraw => 'Жауапты қайтарып алу';

  @override
  String get tripsEmpty => 'Таспадағы жүктерге жауап беріңіз';

  @override
  String get tripsGoFeed => 'Таспаға';

  @override
  String get historyTitle => 'Рейстер тарихы';

  @override
  String get historyAll => 'Барлығы';

  @override
  String get historyDelivered => 'Жеткізілді';

  @override
  String get historyFailed => 'Болмады';

  @override
  String get historyEmpty => 'Мұнда аяқталған рейстер шығады';

  @override
  String get closeReasonTakenByOther => 'Жүк басқаға кетті';

  @override
  String get closeReasonRejectedByLogist => 'Логист бас тартты';

  @override
  String get closeReasonWithdrawn => 'Сіз қайтарып алдыңыз';

  @override
  String get closeReasonInviteExpired => 'Шақыру мерзімі өтті';

  @override
  String get closeReasonCargoClosed => 'Жүк алынып тасталды';

  @override
  String get closeReasonCargoArchived => 'Жүк мұрағатта';

  @override
  String get closeReasonDealCancelled => 'Мәміле болдырылмады';

  @override
  String get closeReasonAccountDeleted => 'Аккаунт жойылды';

  @override
  String homeActionSelected(String route, String price) {
    return 'Сізді $route бағытына таңдады, $price';
  }

  @override
  String get homeActionSelectedCta => '«Менің рейстерімде» растау →';

  @override
  String homeActionInvited(String route, int hours) {
    return 'Сізді $route бағытына шақырды · $hours сағ қалды';
  }

  @override
  String get homeActionInvitedCta => 'Жауап беру →';

  @override
  String get profileTripHistory => 'Рейстер тарихы';

  @override
  String responsesInactive(int count) {
    return 'Белсенді емес · $count';
  }

  @override
  String get responsesWaitingDriver => 'жүргізушінің жауабын күтеміз';

  @override
  String get responsesNewDot => 'Жаңа жауап';

  @override
  String get shareButton => 'Бөлісу';

  @override
  String get shareAllButton => 'Барлығы';

  @override
  String get shareAllWeb => 'Барлығымен бөлісу';

  @override
  String get shareDialogCargo => 'Жүкпен бөлісу';

  @override
  String get shareDialogAll => 'Барлық жүктермен бөлісу';

  @override
  String get shareDialogDriver => 'Анонспен бөлісу';

  @override
  String get shareCopyText => 'Мәтінді көшіру';

  @override
  String get shareTextCopied => 'Мәтін көшірілді';

  @override
  String get shareLinkButton => 'Сілтеме';

  @override
  String get shareLinkCopied => 'Сілтеме көшірілді';

  @override
  String get shareWeChatQr => 'WeChat — QR';

  @override
  String get shareWeChatHint =>
      'WeChat: телефонмен сканерлеңіз — мәтін көшірілді, чатқа қойыңыз';

  @override
  String get shareEditHint => 'Жіберер алдында мәтінді түзетуге болады';

  @override
  String shareCargoLoading(String date) {
    return 'тиеу $date';
  }

  @override
  String shareCargoRespond(String url) {
    return 'Жауап беру: $url';
  }

  @override
  String shareAllTitle(String company) {
    return '$company — бүгінгі жүктер';
  }

  @override
  String shareAllFooter(String url) {
    return 'Барлық жүктер және жауап: $url';
  }

  @override
  String get shareDriverTitle => 'Фура бос';

  @override
  String shareDriverFrom(String city, String date) {
    return '$city, $date бастап';
  }

  @override
  String get shareDriverAnyDirection => 'кез келген бағытқа';

  @override
  String shareDriverDirection(String countries) {
    return 'бағыты: $countries';
  }

  @override
  String shareDriverOffer(String url) {
    return 'Жүк ұсыну: $url';
  }

  @override
  String get shareVerified => 'Тексерілген';

  @override
  String get shareOpenFailed => 'Сілтеме ашылмады — ескірген болуы мүмкін';

  @override
  String get shareCompanyCargosTitle => 'Компания жүктері';

  @override
  String adminShareStats(int links, int opens, int came) {
    return 'Бөлісті: $links · ашылды: $opens · сілтемемен келді: $came';
  }

  @override
  String get driverCardTitle => 'Жүргізуші';

  @override
  String get driverCardNotLooking => 'Қазір жүк іздемейді';

  @override
  String driverCardTrips(int count) {
    return 'Lubao-дағы рейстер: $count';
  }

  @override
  String get driverCardChat => 'Жазу';

  @override
  String get shareLinkPromptText => 'Сілтеме арқылы келдіңіз бе?';

  @override
  String get shareLinkPromptOpen => 'Жүкті ашу';

  @override
  String get shareLinkPromptNotFound =>
      'Сілтеме табылмады — хабарламадан қайта ашыңыз';

  @override
  String get commonPaste => 'Қою';

  @override
  String get driversInvitePickHint => 'Жүкті белгілеп, «Шақыру» басыңыз';

  @override
  String driversInviteTitle(String name) {
    return '$name шақыру';
  }

  @override
  String get dealVehicleRequired =>
      'Рейс үшін тартқыш пен тіркеме керек — жетіспейтінін гаражға қосыңыз';
}
