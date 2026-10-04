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
  String get companyLoginTitle => 'Компания үшін кіру';

  @override
  String get companyLoginEmailLabel => 'Email';

  @override
  String get companyLoginByCode => 'Код бойынша';

  @override
  String get companyLoginByPassword => 'Құпия сөз бойынша';

  @override
  String get companyLoginSendCode => 'Кодты алу';

  @override
  String get companyLoginVerify => 'Кіру';

  @override
  String companyOtpSubtitle(String email) {
    return 'Код $email поштасына жіберілді';
  }

  @override
  String get companyOtpCodeLabel => 'Хаттан алынған код';

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
  String get feedSectionHome => 'Үйге';

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
  String get profileLanguage => 'Тіл';

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
  String get companySetPasswordHint =>
      'Міндетті емес — email-кодсыз кіруге мүмкіндік береді';

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
  String get driversAtPointTitle => 'Хоргосқа кімдер келеді';

  @override
  String get driversAtPointSubtitle =>
      'Алдын ала келетінін хабарлаған жүргізушілер';

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
  String get adminVerificationEmpty => 'Тексеруге құжат жоқ';

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
}
