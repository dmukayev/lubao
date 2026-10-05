import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'lubao_localizations_en.dart';
import 'lubao_localizations_kk.dart';
import 'lubao_localizations_ru.dart';
import 'lubao_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of LubaoLocalizations
/// returned by `LubaoLocalizations.of(context)`.
///
/// Applications need to include `LubaoLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/lubao_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: LubaoLocalizations.localizationsDelegates,
///   supportedLocales: LubaoLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the LubaoLocalizations.supportedLocales
/// property.
abstract class LubaoLocalizations {
  LubaoLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static LubaoLocalizations of(BuildContext context) {
    return Localizations.of<LubaoLocalizations>(context, LubaoLocalizations)!;
  }

  static const LocalizationsDelegate<LubaoLocalizations> delegate =
      _LubaoLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'Lubao'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get commonSave;

  /// No description provided for @commonNext.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get commonBack;

  /// No description provided for @commonDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get commonDone;

  /// No description provided for @commonRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так'**
  String get commonError;

  /// No description provided for @commonSeeAll.
  ///
  /// In ru, this message translates to:
  /// **'Смотреть все'**
  String get commonSeeAll;

  /// No description provided for @commonCall.
  ///
  /// In ru, this message translates to:
  /// **'Позвонить'**
  String get commonCall;

  /// No description provided for @commonWhatsApp.
  ///
  /// In ru, this message translates to:
  /// **'WhatsApp'**
  String get commonWhatsApp;

  /// No description provided for @commonChat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get commonChat;

  /// No description provided for @commonSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get commonSend;

  /// No description provided for @commonSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get commonSearch;

  /// No description provided for @commonYes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get commonNo;

  /// No description provided for @roleSelectTitle.
  ///
  /// In ru, this message translates to:
  /// **'Кто вы?'**
  String get roleSelectTitle;

  /// No description provided for @roleSelectSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите, как вы будете пользоваться Lubao'**
  String get roleSelectSubtitle;

  /// No description provided for @roleDriver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель'**
  String get roleDriver;

  /// No description provided for @roleCompany.
  ///
  /// In ru, this message translates to:
  /// **'Логистическая компания'**
  String get roleCompany;

  /// No description provided for @driverLoginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход для водителя'**
  String get driverLoginTitle;

  /// No description provided for @driverLoginPhoneLabel.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона'**
  String get driverLoginPhoneLabel;

  /// No description provided for @driverLoginPhoneHint.
  ///
  /// In ru, this message translates to:
  /// **'+7 700 000 00 00'**
  String get driverLoginPhoneHint;

  /// No description provided for @driverLoginSendCode.
  ///
  /// In ru, this message translates to:
  /// **'Получить код'**
  String get driverLoginSendCode;

  /// No description provided for @driverLoginCodeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Код из SMS'**
  String get driverLoginCodeLabel;

  /// No description provided for @driverLoginVerify.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get driverLoginVerify;

  /// No description provided for @driverLoginCountryLabel.
  ///
  /// In ru, this message translates to:
  /// **'Страна'**
  String get driverLoginCountryLabel;

  /// No description provided for @driverOtpSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Код отправлен на {phone}'**
  String driverOtpSubtitle(String phone);

  /// No description provided for @driverOtpResend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код ещё раз'**
  String get driverOtpResend;

  /// No description provided for @driverOtpInvalidCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный код'**
  String get driverOtpInvalidCode;

  /// No description provided for @driverOtpTooManyAttempts.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток — запросите новый код'**
  String get driverOtpTooManyAttempts;

  /// No description provided for @companyRegisterTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новая компания'**
  String get companyRegisterTitle;

  /// No description provided for @companyRegisterOwnerName.
  ///
  /// In ru, this message translates to:
  /// **'Ваше имя'**
  String get companyRegisterOwnerName;

  /// No description provided for @companyRegisterCompanyName.
  ///
  /// In ru, this message translates to:
  /// **'Название компании'**
  String get companyRegisterCompanyName;

  /// No description provided for @companyRegisterCompanyNameRu.
  ///
  /// In ru, this message translates to:
  /// **'Название по-русски'**
  String get companyRegisterCompanyNameRu;

  /// No description provided for @companyRegisterNameError.
  ///
  /// In ru, this message translates to:
  /// **'Введите название, минимум 2 символа'**
  String get companyRegisterNameError;

  /// No description provided for @companyRegisterCountry.
  ///
  /// In ru, this message translates to:
  /// **'Страна'**
  String get companyRegisterCountry;

  /// No description provided for @companyRegisterCountryError.
  ///
  /// In ru, this message translates to:
  /// **'Выберите страну'**
  String get companyRegisterCountryError;

  /// No description provided for @companyRegisterOtherCountry.
  ///
  /// In ru, this message translates to:
  /// **'Другая'**
  String get companyRegisterOtherCountry;

  /// No description provided for @companyRegisterSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Создать компанию'**
  String get companyRegisterSubmit;

  /// No description provided for @companyRegisterEmailError.
  ///
  /// In ru, this message translates to:
  /// **'Введите email'**
  String get companyRegisterEmailError;

  /// No description provided for @companyRegisterPasswordError.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 8 символов'**
  String get companyRegisterPasswordError;

  /// No description provided for @companyRegisterEmailTaken.
  ///
  /// In ru, this message translates to:
  /// **'Этот email уже зарегистрирован. Войти?'**
  String get companyRegisterEmailTaken;

  /// No description provided for @companyLoginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход для компании'**
  String get companyLoginTitle;

  /// No description provided for @companyLoginEmailLabel.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get companyLoginEmailLabel;

  /// No description provided for @companyLoginVerify.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get companyLoginVerify;

  /// No description provided for @companyLoginLockedOut.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток. Попробуйте через 15 минут'**
  String get companyLoginLockedOut;

  /// No description provided for @companyLoginShowPassword.
  ///
  /// In ru, this message translates to:
  /// **'Показать пароль'**
  String get companyLoginShowPassword;

  /// No description provided for @companyLoginHidePassword.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть пароль'**
  String get companyLoginHidePassword;

  /// No description provided for @companyLoginRegisterLink.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get companyLoginRegisterLink;

  /// No description provided for @companyLoginForgotPasswordLink.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get companyLoginForgotPasswordLink;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Восстановление пароля'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSendCode.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код'**
  String get forgotPasswordSendCode;

  /// No description provided for @forgotPasswordCodeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Код из письма'**
  String get forgotPasswordCodeLabel;

  /// No description provided for @forgotPasswordNewPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get forgotPasswordNewPasswordLabel;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Сменить пароль'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Пароль изменён, войдите с новым паролем'**
  String get forgotPasswordSuccess;

  /// No description provided for @forgotPasswordResend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код ещё раз'**
  String get forgotPasswordResend;

  /// No description provided for @forgotPasswordInvalidCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный или истёкший код'**
  String get forgotPasswordInvalidCode;

  /// No description provided for @forgotPasswordNoEmailLink.
  ///
  /// In ru, this message translates to:
  /// **'Письмо не приходит?'**
  String get forgotPasswordNoEmailLink;

  /// No description provided for @supportContactTitle.
  ///
  /// In ru, this message translates to:
  /// **'Связаться с поддержкой'**
  String get supportContactTitle;

  /// No description provided for @supportContactBody.
  ///
  /// In ru, this message translates to:
  /// **'Если письмо не приходит, напишите нам любым удобным способом'**
  String get supportContactBody;

  /// No description provided for @supportContactWhatsapp.
  ///
  /// In ru, this message translates to:
  /// **'WhatsApp'**
  String get supportContactWhatsapp;

  /// No description provided for @supportContactWechat.
  ///
  /// In ru, this message translates to:
  /// **'WeChat'**
  String get supportContactWechat;

  /// No description provided for @supportContactEmail.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get supportContactEmail;

  /// No description provided for @supportContactNone.
  ///
  /// In ru, this message translates to:
  /// **'Контакты поддержки скоро появятся здесь'**
  String get supportContactNone;

  /// No description provided for @acceptInviteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение в компанию'**
  String get acceptInviteTitle;

  /// No description provided for @acceptInviteSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Вас пригласили в «{companyName}» — роль: {role}'**
  String acceptInviteSubtitle(String companyName, String role);

  /// No description provided for @acceptInviteNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ваше имя'**
  String get acceptInviteNameLabel;

  /// No description provided for @acceptInvitePhoneLabel.
  ///
  /// In ru, this message translates to:
  /// **'Телефон (для водителей)'**
  String get acceptInvitePhoneLabel;

  /// No description provided for @acceptInviteWechatLabel.
  ///
  /// In ru, this message translates to:
  /// **'WeChat (необязательно)'**
  String get acceptInviteWechatLabel;

  /// No description provided for @acceptInviteSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Войти в компанию'**
  String get acceptInviteSubmit;

  /// No description provided for @acceptInviteInvalidToken.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение недействительно или уже использовано'**
  String get acceptInviteInvalidToken;

  /// No description provided for @emailVerifyBannerText.
  ///
  /// In ru, this message translates to:
  /// **'Email не подтверждён'**
  String get emailVerifyBannerText;

  /// No description provided for @emailVerifyBannerAction.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get emailVerifyBannerAction;

  /// No description provided for @emailVerifyDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение email'**
  String get emailVerifyDialogTitle;

  /// No description provided for @emailVerifyDialogCodeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Код из письма'**
  String get emailVerifyDialogCodeLabel;

  /// No description provided for @emailVerifyDialogSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get emailVerifyDialogSubmit;

  /// No description provided for @employeesInviteButton.
  ///
  /// In ru, this message translates to:
  /// **'Пригласить сотрудника'**
  String get employeesInviteButton;

  /// No description provided for @employeesInviteEmailLabel.
  ///
  /// In ru, this message translates to:
  /// **'Email сотрудника'**
  String get employeesInviteEmailLabel;

  /// No description provided for @employeesInviteRoleOwner.
  ///
  /// In ru, this message translates to:
  /// **'Владелец'**
  String get employeesInviteRoleOwner;

  /// No description provided for @employeesInviteRoleLogist.
  ///
  /// In ru, this message translates to:
  /// **'Логист'**
  String get employeesInviteRoleLogist;

  /// No description provided for @employeesInviteSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Создать ссылку'**
  String get employeesInviteSubmit;

  /// No description provided for @employeesInviteLinkReady.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка-приглашение действует 7 дней. Скопируйте и отправьте в WeChat/WhatsApp:'**
  String get employeesInviteLinkReady;

  /// No description provided for @employeesInviteCopyLink.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать'**
  String get employeesInviteCopyLink;

  /// No description provided for @employeesInviteCopied.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка скопирована'**
  String get employeesInviteCopied;

  /// No description provided for @driverSetupTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройка профиля'**
  String get driverSetupTitle;

  /// No description provided for @driverRegisterTitle.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get driverRegisterTitle;

  /// No description provided for @driverVerificationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Верификация'**
  String get driverVerificationTitle;

  /// No description provided for @driverVerificationIntro.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы откликаться на грузы и подтверждать сделки, подтвердите личность — это займёт около 2 минут'**
  String get driverVerificationIntro;

  /// No description provided for @driverVerificationSelfie.
  ///
  /// In ru, this message translates to:
  /// **'Селфи'**
  String get driverVerificationSelfie;

  /// No description provided for @driverVerificationVehiclePassport.
  ///
  /// In ru, this message translates to:
  /// **'Техпаспорт тягача'**
  String get driverVerificationVehiclePassport;

  /// No description provided for @driverVerificationTrailerPassport.
  ///
  /// In ru, this message translates to:
  /// **'Техпаспорт прицепа'**
  String get driverVerificationTrailerPassport;

  /// No description provided for @driverVerificationLicense.
  ///
  /// In ru, this message translates to:
  /// **'Права'**
  String get driverVerificationLicense;

  /// No description provided for @driverVerificationStatusNone.
  ///
  /// In ru, this message translates to:
  /// **'Не загружено'**
  String get driverVerificationStatusNone;

  /// No description provided for @driverVerificationStatusPending.
  ///
  /// In ru, this message translates to:
  /// **'На проверке'**
  String get driverVerificationStatusPending;

  /// No description provided for @driverVerificationStatusApproved.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждено'**
  String get driverVerificationStatusApproved;

  /// No description provided for @driverVerificationStatusRejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get driverVerificationStatusRejected;

  /// No description provided for @driverVerificationUploadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить фото'**
  String get driverVerificationUploadFailed;

  /// No description provided for @driverVerificationRequiredPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы откликнуться, подтвердите личность — 2 минуты'**
  String get driverVerificationRequiredPrompt;

  /// No description provided for @driverVerificationRequiredAction.
  ///
  /// In ru, this message translates to:
  /// **'Пройти верификацию'**
  String get driverVerificationRequiredAction;

  /// No description provided for @profileCompleteness.
  ///
  /// In ru, this message translates to:
  /// **'Профиль заполнен на {percent}% — проверенные водители получают в 3 раза больше приглашений'**
  String profileCompleteness(int percent);

  /// No description provided for @driverSetupStepOf.
  ///
  /// In ru, this message translates to:
  /// **'Шаг {step} из {total}'**
  String driverSetupStepOf(int step, int total);

  /// No description provided for @driverSetupFullName.
  ///
  /// In ru, this message translates to:
  /// **'Ф.И.О.'**
  String get driverSetupFullName;

  /// No description provided for @driverSetupFullNameError.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя: 2-80 букв, без цифр'**
  String get driverSetupFullNameError;

  /// No description provided for @driverSetupHomeCityError.
  ///
  /// In ru, this message translates to:
  /// **'Выберите город'**
  String get driverSetupHomeCityError;

  /// No description provided for @driverSetupBodyTypeError.
  ///
  /// In ru, this message translates to:
  /// **'Выберите тип кузова'**
  String get driverSetupBodyTypeError;

  /// No description provided for @cityNotListed.
  ///
  /// In ru, this message translates to:
  /// **'Нет моего города'**
  String get cityNotListed;

  /// No description provided for @addCitySettlementLabel.
  ///
  /// In ru, this message translates to:
  /// **'Населённый пункт'**
  String get addCitySettlementLabel;

  /// No description provided for @addCitySettlementError.
  ///
  /// In ru, this message translates to:
  /// **'Введите название населённого пункта'**
  String get addCitySettlementError;

  /// No description provided for @addCityRegionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Область/регион'**
  String get addCityRegionLabel;

  /// No description provided for @addCityRegionError.
  ///
  /// In ru, this message translates to:
  /// **'Выберите область'**
  String get addCityRegionError;

  /// No description provided for @addCitySubmit.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get addCitySubmit;

  /// No description provided for @driverSetupHomeCity.
  ///
  /// In ru, this message translates to:
  /// **'Домашний город'**
  String get driverSetupHomeCity;

  /// No description provided for @driverSetupCountries.
  ///
  /// In ru, this message translates to:
  /// **'Направления'**
  String get driverSetupCountries;

  /// No description provided for @driverSetupAnyCountry.
  ///
  /// In ru, this message translates to:
  /// **'Любая страна'**
  String get driverSetupAnyCountry;

  /// No description provided for @driverSetupPermits.
  ///
  /// In ru, this message translates to:
  /// **'Допуски'**
  String get driverSetupPermits;

  /// No description provided for @driverSetupVehicleBodyType.
  ///
  /// In ru, this message translates to:
  /// **'Тип кузова'**
  String get driverSetupVehicleBodyType;

  /// No description provided for @driverSetupVehiclePlate.
  ///
  /// In ru, this message translates to:
  /// **'Гос. номер'**
  String get driverSetupVehiclePlate;

  /// No description provided for @driverSetupVehicleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Какая у вас машина?'**
  String get driverSetupVehicleTitle;

  /// No description provided for @driverSetupVehicleSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Заполните один раз — мы будем подбирать грузы под неё'**
  String get driverSetupVehicleSubtitle;

  /// No description provided for @driverSetupCapacity.
  ///
  /// In ru, this message translates to:
  /// **'Грузоподъёмность'**
  String get driverSetupCapacity;

  /// No description provided for @driverSetupDocuments.
  ///
  /// In ru, this message translates to:
  /// **'Документы на машину'**
  String get driverSetupDocuments;

  /// No description provided for @driverSetupDirectionsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Куда готовы ехать?'**
  String get driverSetupDirectionsTitle;

  /// No description provided for @driverSetupDirectionsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Покажем грузы в эти страны первыми. Можно поменять в любой момент'**
  String get driverSetupDirectionsSubtitle;

  /// No description provided for @driverSetupCountriesSelected.
  ///
  /// In ru, this message translates to:
  /// **'Выбрано стран: {count}'**
  String driverSetupCountriesSelected(int count);

  /// No description provided for @driverSetupSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить и продолжить'**
  String get driverSetupSubmit;

  /// No description provided for @feedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Грузы в Хоргосе'**
  String get feedTitle;

  /// No description provided for @driverHomeGreeting.
  ///
  /// In ru, this message translates to:
  /// **'Сәлем,'**
  String get driverHomeGreeting;

  /// No description provided for @driverHomeAnonsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мой анонс'**
  String get driverHomeAnonsTitle;

  /// No description provided for @driverHomeLogistsCount.
  ///
  /// In ru, this message translates to:
  /// **'Логистов рядом: {count}'**
  String driverHomeLogistsCount(int count);

  /// No description provided for @driverHomeSince.
  ///
  /// In ru, this message translates to:
  /// **'На месте с {date}'**
  String driverHomeSince(String date);

  /// No description provided for @driverHomeCheckInEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Заявите о прибытии — логисты увидят вас заранее'**
  String get driverHomeCheckInEmpty;

  /// No description provided for @driverHomeCheckInButton.
  ///
  /// In ru, this message translates to:
  /// **'Я уже на месте'**
  String get driverHomeCheckInButton;

  /// No description provided for @driverHomeLeaveButton.
  ///
  /// In ru, this message translates to:
  /// **'Я уехал'**
  String get driverHomeLeaveButton;

  /// No description provided for @driverHomeCancelButton.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get driverHomeCancelButton;

  /// No description provided for @driverHomeAnnounceButton.
  ///
  /// In ru, this message translates to:
  /// **'Буду на точке'**
  String get driverHomeAnnounceButton;

  /// No description provided for @driverHomeRepeatButton.
  ///
  /// In ru, this message translates to:
  /// **'Повторить прошлый анонс'**
  String get driverHomeRepeatButton;

  /// No description provided for @driverHomeEditButton.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get driverHomeEditButton;

  /// No description provided for @driverHomePlannedFor.
  ///
  /// In ru, this message translates to:
  /// **'Будет {date}'**
  String driverHomePlannedFor(String date);

  /// No description provided for @announceArrivalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Буду на точке'**
  String get announceArrivalTitle;

  /// No description provided for @announceArrivalWhen.
  ///
  /// In ru, this message translates to:
  /// **'Когда'**
  String get announceArrivalWhen;

  /// No description provided for @announceArrivalToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get announceArrivalToday;

  /// No description provided for @announceArrivalTomorrow.
  ///
  /// In ru, this message translates to:
  /// **'Завтра'**
  String get announceArrivalTomorrow;

  /// No description provided for @announceArrivalDayAfter.
  ///
  /// In ru, this message translates to:
  /// **'Послезавтра'**
  String get announceArrivalDayAfter;

  /// No description provided for @announceArrivalPickDate.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать дату'**
  String get announceArrivalPickDate;

  /// No description provided for @announceArrivalWhere.
  ///
  /// In ru, this message translates to:
  /// **'Где'**
  String get announceArrivalWhere;

  /// No description provided for @announceArrivalCountries.
  ///
  /// In ru, this message translates to:
  /// **'Куда готов'**
  String get announceArrivalCountries;

  /// No description provided for @announceArrivalWaitDays.
  ///
  /// In ru, this message translates to:
  /// **'Сколько готовы ждать'**
  String get announceArrivalWaitDays;

  /// No description provided for @announceArrivalWaitDaysValue.
  ///
  /// In ru, this message translates to:
  /// **'{days} дн.'**
  String announceArrivalWaitDaysValue(int days);

  /// No description provided for @announceArrivalSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать'**
  String get announceArrivalSubmit;

  /// No description provided for @driverHomeFeedCount.
  ///
  /// In ru, this message translates to:
  /// **'Подходящие грузы {count}'**
  String driverHomeFeedCount(int count);

  /// No description provided for @feedEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет подходящих грузов'**
  String get feedEmpty;

  /// No description provided for @feedSectionHome.
  ///
  /// In ru, this message translates to:
  /// **'Близко к дому'**
  String get feedSectionHome;

  /// No description provided for @feedSectionSelected.
  ///
  /// In ru, this message translates to:
  /// **'Ваши направления'**
  String get feedSectionSelected;

  /// No description provided for @feedSectionOther.
  ///
  /// In ru, this message translates to:
  /// **'Остальные направления'**
  String get feedSectionOther;

  /// No description provided for @cargoPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get cargoPrice;

  /// No description provided for @cargoWeight.
  ///
  /// In ru, this message translates to:
  /// **'Вес'**
  String get cargoWeight;

  /// No description provided for @cargoVolume.
  ///
  /// In ru, this message translates to:
  /// **'Объём'**
  String get cargoVolume;

  /// No description provided for @cargoPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии'**
  String get cargoPhotos;

  /// No description provided for @unitKg.
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get unitKg;

  /// No description provided for @unitM3.
  ///
  /// In ru, this message translates to:
  /// **'м³'**
  String get unitM3;

  /// No description provided for @unitTon.
  ///
  /// In ru, this message translates to:
  /// **'т'**
  String get unitTon;

  /// No description provided for @cargoReadyDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата готовности'**
  String get cargoReadyDate;

  /// No description provided for @cargoDestination.
  ///
  /// In ru, this message translates to:
  /// **'Направление'**
  String get cargoDestination;

  /// No description provided for @cargoBodyType.
  ///
  /// In ru, this message translates to:
  /// **'Кузов'**
  String get cargoBodyType;

  /// No description provided for @cargoRespond.
  ///
  /// In ru, this message translates to:
  /// **'Откликнуться'**
  String get cargoRespond;

  /// No description provided for @cargoAlreadyResponded.
  ///
  /// In ru, this message translates to:
  /// **'Вы откликнулись'**
  String get cargoAlreadyResponded;

  /// No description provided for @cargoDetailTitle.
  ///
  /// In ru, this message translates to:
  /// **'Груз'**
  String get cargoDetailTitle;

  /// No description provided for @cargoDetailDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get cargoDetailDescription;

  /// No description provided for @cargoDetailCompany.
  ///
  /// In ru, this message translates to:
  /// **'Компания'**
  String get cargoDetailCompany;

  /// No description provided for @cargoDetailPriceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Цена за рейс'**
  String get cargoDetailPriceLabel;

  /// No description provided for @cargoDetailCompanyDeals.
  ///
  /// In ru, this message translates to:
  /// **'{count} сделок в Lubao'**
  String cargoDetailCompanyDeals(int count);

  /// No description provided for @cargoDetailNoReviews.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет отзывов'**
  String get cargoDetailNoReviews;

  /// No description provided for @cargoStatusPublished.
  ///
  /// In ru, this message translates to:
  /// **'Опубликован'**
  String get cargoStatusPublished;

  /// No description provided for @cargoStatusArchived.
  ///
  /// In ru, this message translates to:
  /// **'В архиве'**
  String get cargoStatusArchived;

  /// No description provided for @cargoStatusExpired.
  ///
  /// In ru, this message translates to:
  /// **'Истёк'**
  String get cargoStatusExpired;

  /// No description provided for @cargoStatusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get cargoStatusCancelled;

  /// No description provided for @dealsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои сделки'**
  String get dealsTitle;

  /// No description provided for @dealsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Сделок пока нет'**
  String get dealsEmpty;

  /// No description provided for @dealStatusSelected.
  ///
  /// In ru, this message translates to:
  /// **'Выбран'**
  String get dealStatusSelected;

  /// No description provided for @dealStatusConfirmed.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждён водителем'**
  String get dealStatusConfirmed;

  /// No description provided for @dealStatusLoaded.
  ///
  /// In ru, this message translates to:
  /// **'Загружен'**
  String get dealStatusLoaded;

  /// No description provided for @dealStatusInTransit.
  ///
  /// In ru, this message translates to:
  /// **'В пути'**
  String get dealStatusInTransit;

  /// No description provided for @dealStatusDelivered.
  ///
  /// In ru, this message translates to:
  /// **'Доставлено'**
  String get dealStatusDelivered;

  /// No description provided for @dealStatusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменена'**
  String get dealStatusCancelled;

  /// No description provided for @dealDetailTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сделка'**
  String get dealDetailTitle;

  /// No description provided for @dealTimelineTitle.
  ///
  /// In ru, this message translates to:
  /// **'Статус сделки'**
  String get dealTimelineTitle;

  /// No description provided for @dealDriverLocationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Местоположение водителя'**
  String get dealDriverLocationTitle;

  /// No description provided for @dealLocationUpdatedAt.
  ///
  /// In ru, this message translates to:
  /// **'Обновлено'**
  String get dealLocationUpdatedAt;

  /// No description provided for @dealLocationNoData.
  ///
  /// In ru, this message translates to:
  /// **'Координаты ещё не получены'**
  String get dealLocationNoData;

  /// No description provided for @dealConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get dealConfirm;

  /// No description provided for @dealMarkLoaded.
  ///
  /// In ru, this message translates to:
  /// **'Груз загружен'**
  String get dealMarkLoaded;

  /// No description provided for @dealMarkInTransit.
  ///
  /// In ru, this message translates to:
  /// **'В пути'**
  String get dealMarkInTransit;

  /// No description provided for @dealMarkDelivered.
  ///
  /// In ru, this message translates to:
  /// **'Доставлено'**
  String get dealMarkDelivered;

  /// No description provided for @dealCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отменить сделку'**
  String get dealCancel;

  /// No description provided for @dealCancelReasonLabel.
  ///
  /// In ru, this message translates to:
  /// **'Причина отмены'**
  String get dealCancelReasonLabel;

  /// No description provided for @dealCancelledBy.
  ///
  /// In ru, this message translates to:
  /// **'Отменил(а)'**
  String get dealCancelledBy;

  /// No description provided for @reviewTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оставить отзыв'**
  String get reviewTitle;

  /// No description provided for @reviewRatingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Оценка'**
  String get reviewRatingLabel;

  /// No description provided for @reviewCommentLabel.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get reviewCommentLabel;

  /// No description provided for @reviewSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Отправить отзыв'**
  String get reviewSubmit;

  /// No description provided for @reviewsReceivedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы'**
  String get reviewsReceivedTitle;

  /// No description provided for @responsesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отклики'**
  String get responsesTitle;

  /// No description provided for @responsesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет откликов'**
  String get responsesEmpty;

  /// No description provided for @responseSelect.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать водителя'**
  String get responseSelect;

  /// No description provided for @responseReject.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get responseReject;

  /// No description provided for @responseStatusPending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает'**
  String get responseStatusPending;

  /// No description provided for @responseStatusSelected.
  ///
  /// In ru, this message translates to:
  /// **'Выбран'**
  String get responseStatusSelected;

  /// No description provided for @responseStatusRejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонён'**
  String get responseStatusRejected;

  /// No description provided for @responseStatusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get responseStatusCancelled;

  /// No description provided for @myCargosTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои грузы'**
  String get myCargosTitle;

  /// No description provided for @myCargosEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Вы ещё не публиковали грузы'**
  String get myCargosEmpty;

  /// No description provided for @postCargoTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый груз'**
  String get postCargoTitle;

  /// No description provided for @postCargoDestinationCountry.
  ///
  /// In ru, this message translates to:
  /// **'Страна назначения'**
  String get postCargoDestinationCountry;

  /// No description provided for @postCargoDestinationCity.
  ///
  /// In ru, this message translates to:
  /// **'Город назначения'**
  String get postCargoDestinationCity;

  /// No description provided for @postCargoBodyType.
  ///
  /// In ru, this message translates to:
  /// **'Тип кузова'**
  String get postCargoBodyType;

  /// No description provided for @postCargoVolume.
  ///
  /// In ru, this message translates to:
  /// **'Объём, м³'**
  String get postCargoVolume;

  /// No description provided for @postCargoWeight.
  ///
  /// In ru, this message translates to:
  /// **'Вес, кг'**
  String get postCargoWeight;

  /// No description provided for @postCargoPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии'**
  String get postCargoPhotos;

  /// No description provided for @postCargoAddPhotoCamera.
  ///
  /// In ru, this message translates to:
  /// **'Камера'**
  String get postCargoAddPhotoCamera;

  /// No description provided for @postCargoAddPhotoGallery.
  ///
  /// In ru, this message translates to:
  /// **'Галерея'**
  String get postCargoAddPhotoGallery;

  /// No description provided for @postCargoRemovePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get postCargoRemovePhoto;

  /// No description provided for @postCargoPhotoUploadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить фото'**
  String get postCargoPhotoUploadFailed;

  /// No description provided for @postCargoPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get postCargoPrice;

  /// No description provided for @postCargoCurrency.
  ///
  /// In ru, this message translates to:
  /// **'Валюта'**
  String get postCargoCurrency;

  /// No description provided for @postCargoReadyDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата готовности'**
  String get postCargoReadyDate;

  /// No description provided for @postCargoDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание груза'**
  String get postCargoDescription;

  /// No description provided for @postCargoSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать'**
  String get postCargoSubmit;

  /// No description provided for @editCargoTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать груз'**
  String get editCargoTitle;

  /// No description provided for @cargoEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get cargoEdit;

  /// No description provided for @cargoDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get cargoDelete;

  /// No description provided for @cargoDeleteConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить груз?'**
  String get cargoDeleteConfirmTitle;

  /// No description provided for @cargoDeleteConfirmMessage.
  ///
  /// In ru, this message translates to:
  /// **'Груз будет снят с публикации. История откликов и сделок сохранится.'**
  String get cargoDeleteConfirmMessage;

  /// No description provided for @cargoDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Груз удалён'**
  String get cargoDeleted;

  /// No description provided for @chatTitle.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get chatTitle;

  /// No description provided for @chatInputHint.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get chatInputHint;

  /// No description provided for @chatEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Начните переписку'**
  String get chatEmpty;

  /// No description provided for @chatAttachLocation.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить точку'**
  String get chatAttachLocation;

  /// No description provided for @chatLocationMessagePrefix.
  ///
  /// In ru, this message translates to:
  /// **'Точка на карте'**
  String get chatLocationMessagePrefix;

  /// No description provided for @chatLocationError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить местоположение'**
  String get chatLocationError;

  /// No description provided for @chatTranslatedBadge.
  ///
  /// In ru, this message translates to:
  /// **'Переведено'**
  String get chatTranslatedBadge;

  /// No description provided for @chatShowOriginal.
  ///
  /// In ru, this message translates to:
  /// **'оригинал'**
  String get chatShowOriginal;

  /// No description provided for @chatWritesIn.
  ///
  /// In ru, this message translates to:
  /// **'Пишет на {language}'**
  String chatWritesIn(String language);

  /// No description provided for @chatToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get chatToday;

  /// No description provided for @chatYesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get chatYesterday;

  /// No description provided for @chatConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Логист выбрал вас на этот груз'**
  String get chatConfirmTitle;

  /// No description provided for @chatConfirmSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите — сделка зафиксируется, и вы получите отзыв и рейтинг'**
  String get chatConfirmSubtitle;

  /// No description provided for @chatConfirmButton.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждаю перевозку'**
  String get chatConfirmButton;

  /// No description provided for @chatQuickReplyAtPlace.
  ///
  /// In ru, this message translates to:
  /// **'Я на месте'**
  String get chatQuickReplyAtPlace;

  /// No description provided for @chatQuickReplyLoaded.
  ///
  /// In ru, this message translates to:
  /// **'Загрузился'**
  String get chatQuickReplyLoaded;

  /// No description provided for @chatQuickReplyLate1h.
  ///
  /// In ru, this message translates to:
  /// **'Опаздываю на 1 час'**
  String get chatQuickReplyLate1h;

  /// No description provided for @wholeCountrySuffix.
  ///
  /// In ru, this message translates to:
  /// **'вся страна'**
  String get wholeCountrySuffix;

  /// No description provided for @searchCityCountryHint.
  ///
  /// In ru, this message translates to:
  /// **'Начните вводить город или страну'**
  String get searchCityCountryHint;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @profileLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get profileLogout;

  /// No description provided for @profileRatingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг'**
  String get profileRatingLabel;

  /// No description provided for @profileVerified.
  ///
  /// In ru, this message translates to:
  /// **'Проверен'**
  String get profileVerified;

  /// No description provided for @profileNotVerified.
  ///
  /// In ru, this message translates to:
  /// **'Не проверен'**
  String get profileNotVerified;

  /// No description provided for @profileLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык · Тіл · 语言 · Language'**
  String get profileLanguage;

  /// No description provided for @profilePhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get profilePhone;

  /// No description provided for @profileEmail.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileCompanyName.
  ///
  /// In ru, this message translates to:
  /// **'Компания'**
  String get profileCompanyName;

  /// No description provided for @profileMembers.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудники'**
  String get profileMembers;

  /// No description provided for @profileMyDevices.
  ///
  /// In ru, this message translates to:
  /// **'Мои устройства'**
  String get profileMyDevices;

  /// No description provided for @companySetPasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пароль для входа'**
  String get companySetPasswordTitle;

  /// No description provided for @companySetPasswordHint.
  ///
  /// In ru, this message translates to:
  /// **'Сменить пароль для входа'**
  String get companySetPasswordHint;

  /// No description provided for @companySetPasswordTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 8 символов'**
  String get companySetPasswordTooShort;

  /// No description provided for @devicesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои устройства'**
  String get devicesTitle;

  /// No description provided for @devicesCurrentBadge.
  ///
  /// In ru, this message translates to:
  /// **'Текущее устройство'**
  String get devicesCurrentBadge;

  /// No description provided for @devicesLogoutThis.
  ///
  /// In ru, this message translates to:
  /// **'Выйти на этом устройстве'**
  String get devicesLogoutThis;

  /// No description provided for @devicesLogoutAllOthers.
  ///
  /// In ru, this message translates to:
  /// **'Выйти на всех остальных'**
  String get devicesLogoutAllOthers;

  /// No description provided for @devicesLogoutAllOthersConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Все остальные устройства будут разлогинены. Продолжить?'**
  String get devicesLogoutAllOthersConfirm;

  /// No description provided for @devicesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет активных устройств'**
  String get devicesEmpty;

  /// No description provided for @adminLoginLockedOut.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много неверных попыток, попробуйте через 15 минут'**
  String get adminLoginLockedOut;

  /// No description provided for @languageKk.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get languageKk;

  /// No description provided for @languageRu.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// No description provided for @languageZh.
  ///
  /// In ru, this message translates to:
  /// **'中文'**
  String get languageZh;

  /// No description provided for @navFeed.
  ///
  /// In ru, this message translates to:
  /// **'Грузы'**
  String get navFeed;

  /// No description provided for @navDeals.
  ///
  /// In ru, this message translates to:
  /// **'Сделки'**
  String get navDeals;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navProfile;

  /// No description provided for @navCargos.
  ///
  /// In ru, this message translates to:
  /// **'Грузы'**
  String get navCargos;

  /// No description provided for @navResponses.
  ///
  /// In ru, this message translates to:
  /// **'Отклики'**
  String get navResponses;

  /// No description provided for @navDrivers.
  ///
  /// In ru, this message translates to:
  /// **'Водители'**
  String get navDrivers;

  /// No description provided for @driversAtPointTitle.
  ///
  /// In ru, this message translates to:
  /// **'Кто будет на {point}'**
  String driversAtPointTitle(String point);

  /// No description provided for @driversAtPointSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Водители, которые заранее сообщили о прибытии'**
  String get driversAtPointSubtitle;

  /// No description provided for @driversAtPointDispatchFrom.
  ///
  /// In ru, this message translates to:
  /// **'Пункт отправки груза: {point}'**
  String driversAtPointDispatchFrom(String point);

  /// No description provided for @driversAtPointPickDate.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать дату'**
  String get driversAtPointPickDate;

  /// No description provided for @driversAtPointCountAtPlace.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас на месте: {count}'**
  String driversAtPointCountAtPlace(int count);

  /// No description provided for @driversAtPointEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока никого нет на месте'**
  String get driversAtPointEmpty;

  /// No description provided for @driversAtPointFilterCountry.
  ///
  /// In ru, this message translates to:
  /// **'Страна'**
  String get driversAtPointFilterCountry;

  /// No description provided for @driversAtPointFilterBodyType.
  ///
  /// In ru, this message translates to:
  /// **'Кузов'**
  String get driversAtPointFilterBodyType;

  /// No description provided for @driversAtPointFilterMinCapacity.
  ///
  /// In ru, this message translates to:
  /// **'От 20 т'**
  String get driversAtPointFilterMinCapacity;

  /// No description provided for @driversAtPointFilterVerifiedOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только проверенные'**
  String get driversAtPointFilterVerifiedOnly;

  /// No description provided for @driversAtPointInvite.
  ///
  /// In ru, this message translates to:
  /// **'Пригласить к грузу'**
  String get driversAtPointInvite;

  /// No description provided for @driversAtPointPickCargo.
  ///
  /// In ru, this message translates to:
  /// **'Выберите груз'**
  String get driversAtPointPickCargo;

  /// No description provided for @driversAtPointNoCargos.
  ///
  /// In ru, this message translates to:
  /// **'Сначала опубликуйте груз'**
  String get driversAtPointNoCargos;

  /// No description provided for @driversAtPointInviteSent.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение отправлено'**
  String get driversAtPointInviteSent;

  /// No description provided for @driversAtPointArrivedAt.
  ///
  /// In ru, this message translates to:
  /// **'На месте с {time}'**
  String driversAtPointArrivedAt(String time);

  /// No description provided for @driversAtPointPlannedAt.
  ///
  /// In ru, this message translates to:
  /// **'Будет {time}'**
  String driversAtPointPlannedAt(String time);

  /// No description provided for @driversAtPointToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get driversAtPointToday;

  /// No description provided for @adminLoginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход в админ-панель'**
  String get adminLoginTitle;

  /// No description provided for @adminLoginEmailLabel.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get adminLoginEmailLabel;

  /// No description provided for @adminLoginPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get adminLoginPasswordLabel;

  /// No description provided for @adminLoginSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get adminLoginSubmit;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Обзор'**
  String get adminDashboardTitle;

  /// No description provided for @adminStatDrivers.
  ///
  /// In ru, this message translates to:
  /// **'Водители'**
  String get adminStatDrivers;

  /// No description provided for @adminStatCompanies.
  ///
  /// In ru, this message translates to:
  /// **'Компании'**
  String get adminStatCompanies;

  /// No description provided for @adminStatCargosPublished.
  ///
  /// In ru, this message translates to:
  /// **'Активные грузы'**
  String get adminStatCargosPublished;

  /// No description provided for @adminStatDealsActive.
  ///
  /// In ru, this message translates to:
  /// **'Сделки в работе'**
  String get adminStatDealsActive;

  /// No description provided for @adminStatDealsDelivered.
  ///
  /// In ru, this message translates to:
  /// **'Доставлено сделок'**
  String get adminStatDealsDelivered;

  /// No description provided for @adminStatPendingDocs.
  ///
  /// In ru, this message translates to:
  /// **'Документы на проверке'**
  String get adminStatPendingDocs;

  /// No description provided for @adminStatOpenComplaints.
  ///
  /// In ru, this message translates to:
  /// **'Открытые жалобы'**
  String get adminStatOpenComplaints;

  /// No description provided for @adminNavDashboard.
  ///
  /// In ru, this message translates to:
  /// **'Обзор'**
  String get adminNavDashboard;

  /// No description provided for @adminNavVerification.
  ///
  /// In ru, this message translates to:
  /// **'Верификация'**
  String get adminNavVerification;

  /// No description provided for @adminNavComplaints.
  ///
  /// In ru, this message translates to:
  /// **'Жалобы'**
  String get adminNavComplaints;

  /// No description provided for @adminNavCompanies.
  ///
  /// In ru, this message translates to:
  /// **'Компании'**
  String get adminNavCompanies;

  /// No description provided for @adminNavDrivers.
  ///
  /// In ru, this message translates to:
  /// **'Водители'**
  String get adminNavDrivers;

  /// No description provided for @adminNavReference.
  ///
  /// In ru, this message translates to:
  /// **'Справочники'**
  String get adminNavReference;

  /// No description provided for @adminVerificationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Документы на проверку'**
  String get adminVerificationTitle;

  /// No description provided for @adminVerificationEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Все проверены 👍'**
  String get adminVerificationEmpty;

  /// No description provided for @adminApprove.
  ///
  /// In ru, this message translates to:
  /// **'Одобрить'**
  String get adminApprove;

  /// No description provided for @adminReject.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get adminReject;

  /// No description provided for @adminRejectReasonLabel.
  ///
  /// In ru, this message translates to:
  /// **'Причина отклонения'**
  String get adminRejectReasonLabel;

  /// No description provided for @adminComplaintsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Жалобы'**
  String get adminComplaintsTitle;

  /// No description provided for @adminComplaintsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Жалоб нет'**
  String get adminComplaintsEmpty;

  /// No description provided for @adminResolve.
  ///
  /// In ru, this message translates to:
  /// **'Решено'**
  String get adminResolve;

  /// No description provided for @adminMarkInReview.
  ///
  /// In ru, this message translates to:
  /// **'В работе'**
  String get adminMarkInReview;

  /// No description provided for @adminCompaniesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Компании'**
  String get adminCompaniesTitle;

  /// No description provided for @adminDriversTitle.
  ///
  /// In ru, this message translates to:
  /// **'Водители'**
  String get adminDriversTitle;

  /// No description provided for @adminVerified.
  ///
  /// In ru, this message translates to:
  /// **'Проверен'**
  String get adminVerified;

  /// No description provided for @adminNotVerified.
  ///
  /// In ru, this message translates to:
  /// **'Не проверен'**
  String get adminNotVerified;

  /// No description provided for @adminReferenceTitle.
  ///
  /// In ru, this message translates to:
  /// **'Справочники'**
  String get adminReferenceTitle;

  /// No description provided for @adminPendingCitiesTab.
  ///
  /// In ru, this message translates to:
  /// **'Новые города'**
  String get adminPendingCitiesTab;

  /// No description provided for @adminPendingCitiesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет новых городов от пользователей'**
  String get adminPendingCitiesEmpty;

  /// No description provided for @adminMergeCity.
  ///
  /// In ru, this message translates to:
  /// **'Объединить'**
  String get adminMergeCity;

  /// No description provided for @adminMergeCityTarget.
  ///
  /// In ru, this message translates to:
  /// **'Город для объединения'**
  String get adminMergeCityTarget;

  /// No description provided for @adminCitySubmittedBy.
  ///
  /// In ru, this message translates to:
  /// **'Добавил'**
  String get adminCitySubmittedBy;

  /// No description provided for @adminCityRegion.
  ///
  /// In ru, this message translates to:
  /// **'Область'**
  String get adminCityRegion;

  /// No description provided for @adminAddBodyType.
  ///
  /// In ru, this message translates to:
  /// **'Добавить тип кузова'**
  String get adminAddBodyType;

  /// No description provided for @adminAddPermit.
  ///
  /// In ru, this message translates to:
  /// **'Добавить допуск'**
  String get adminAddPermit;

  /// No description provided for @adminAddPoint.
  ///
  /// In ru, this message translates to:
  /// **'Добавить точку загрузки'**
  String get adminAddPoint;

  /// No description provided for @adminPointCity.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get adminPointCity;

  /// No description provided for @adminNameKk.
  ///
  /// In ru, this message translates to:
  /// **'Название (kk)'**
  String get adminNameKk;

  /// No description provided for @adminNameRu.
  ///
  /// In ru, this message translates to:
  /// **'Название (ru)'**
  String get adminNameRu;

  /// No description provided for @adminNameZh.
  ///
  /// In ru, this message translates to:
  /// **'Название (zh)'**
  String get adminNameZh;

  /// No description provided for @adminCode.
  ///
  /// In ru, this message translates to:
  /// **'Код'**
  String get adminCode;

  /// No description provided for @adminActive.
  ///
  /// In ru, this message translates to:
  /// **'Активна'**
  String get adminActive;

  /// No description provided for @adminInactive.
  ///
  /// In ru, this message translates to:
  /// **'Неактивна'**
  String get adminInactive;

  /// No description provided for @accountBlockedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт заблокирован. Обратитесь в поддержку'**
  String get accountBlockedMessage;

  /// No description provided for @adminSearchCompanyHint.
  ///
  /// In ru, this message translates to:
  /// **'Название, email, рег. номер'**
  String get adminSearchCompanyHint;

  /// No description provided for @adminSearchDriverHint.
  ///
  /// In ru, this message translates to:
  /// **'Имя, телефон, гос. номер'**
  String get adminSearchDriverHint;

  /// No description provided for @adminFilterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get adminFilterAll;

  /// No description provided for @adminFilterPending.
  ///
  /// In ru, this message translates to:
  /// **'На проверке'**
  String get adminFilterPending;

  /// No description provided for @adminFilterVerified.
  ///
  /// In ru, this message translates to:
  /// **'Проверенные'**
  String get adminFilterVerified;

  /// No description provided for @adminFilterBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Блокированные'**
  String get adminFilterBlocked;

  /// No description provided for @adminCompaniesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Компании не найдены'**
  String get adminCompaniesEmpty;

  /// No description provided for @adminDriversEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Водители не найдены'**
  String get adminDriversEmpty;

  /// No description provided for @adminColName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get adminColName;

  /// No description provided for @adminColOwner.
  ///
  /// In ru, this message translates to:
  /// **'Владелец'**
  String get adminColOwner;

  /// No description provided for @adminColEmployees.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудники'**
  String get adminColEmployees;

  /// No description provided for @adminColCargos.
  ///
  /// In ru, this message translates to:
  /// **'Активные грузы'**
  String get adminColCargos;

  /// No description provided for @adminColStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get adminColStatus;

  /// No description provided for @adminColRating.
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг'**
  String get adminColRating;

  /// No description provided for @adminColDeals.
  ///
  /// In ru, this message translates to:
  /// **'Сделки'**
  String get adminColDeals;

  /// No description provided for @adminColPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get adminColPhone;

  /// No description provided for @adminColCity.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get adminColCity;

  /// No description provided for @adminColVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Машина'**
  String get adminColVehicle;

  /// No description provided for @adminBlockedBadge.
  ///
  /// In ru, this message translates to:
  /// **'Блокирован'**
  String get adminBlockedBadge;

  /// No description provided for @adminPageOf.
  ///
  /// In ru, this message translates to:
  /// **'Страница {page} из {total}'**
  String adminPageOf(int page, int total);

  /// No description provided for @adminBlockConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать водителя?'**
  String get adminBlockConfirmTitle;

  /// No description provided for @adminBlockCompanyConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать компанию?'**
  String get adminBlockCompanyConfirmTitle;

  /// No description provided for @adminBlock.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать'**
  String get adminBlock;

  /// No description provided for @adminBlockCompany.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать компанию'**
  String get adminBlockCompany;

  /// No description provided for @adminUnblockConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать?'**
  String get adminUnblockConfirmTitle;

  /// No description provided for @adminUnblock.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать'**
  String get adminUnblock;

  /// No description provided for @adminVerifyMissingDocsError.
  ///
  /// In ru, this message translates to:
  /// **'Не все обязательные документы одобрены — поставьте галочку «проверил лично» и повторите'**
  String get adminVerifyMissingDocsError;

  /// No description provided for @adminResetPasswordConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить пароль владельца?'**
  String get adminResetPasswordConfirmTitle;

  /// No description provided for @adminResetPasswordDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Временный пароль'**
  String get adminResetPasswordDialogTitle;

  /// No description provided for @adminResetPassword.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить пароль'**
  String get adminResetPassword;

  /// No description provided for @adminCopied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано'**
  String get adminCopied;

  /// No description provided for @adminToggleVerification.
  ///
  /// In ru, this message translates to:
  /// **'Изменить статус проверки'**
  String get adminToggleVerification;

  /// No description provided for @adminStatComplaints.
  ///
  /// In ru, this message translates to:
  /// **'Жалобы'**
  String get adminStatComplaints;

  /// No description provided for @adminStatCancellations.
  ///
  /// In ru, this message translates to:
  /// **'Отмены'**
  String get adminStatCancellations;

  /// No description provided for @adminStatCalls.
  ///
  /// In ru, this message translates to:
  /// **'Звонки'**
  String get adminStatCalls;

  /// No description provided for @adminDocuments.
  ///
  /// In ru, this message translates to:
  /// **'Документы'**
  String get adminDocuments;

  /// No description provided for @adminNoDocuments.
  ///
  /// In ru, this message translates to:
  /// **'Документов нет'**
  String get adminNoDocuments;

  /// No description provided for @adminLegalDetails.
  ///
  /// In ru, this message translates to:
  /// **'Юридические данные'**
  String get adminLegalDetails;

  /// No description provided for @adminInvites.
  ///
  /// In ru, this message translates to:
  /// **'Приглашения'**
  String get adminInvites;

  /// No description provided for @adminInviteUsed.
  ///
  /// In ru, this message translates to:
  /// **'Использовано'**
  String get adminInviteUsed;

  /// No description provided for @adminTabCargos.
  ///
  /// In ru, this message translates to:
  /// **'Грузы'**
  String get adminTabCargos;

  /// No description provided for @adminTabDeals.
  ///
  /// In ru, this message translates to:
  /// **'Сделки'**
  String get adminTabDeals;

  /// No description provided for @adminTabReviews.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы'**
  String get adminTabReviews;

  /// No description provided for @adminTabLog.
  ///
  /// In ru, this message translates to:
  /// **'Журнал'**
  String get adminTabLog;

  /// No description provided for @adminNoCargos.
  ///
  /// In ru, this message translates to:
  /// **'Грузов нет'**
  String get adminNoCargos;

  /// No description provided for @adminNoDeals.
  ///
  /// In ru, this message translates to:
  /// **'Сделок нет'**
  String get adminNoDeals;

  /// No description provided for @adminNoReviews.
  ///
  /// In ru, this message translates to:
  /// **'Отзывов нет'**
  String get adminNoReviews;

  /// No description provided for @adminNoLog.
  ///
  /// In ru, this message translates to:
  /// **'Записей нет'**
  String get adminNoLog;

  /// No description provided for @adminEndSessionsConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Завершить все сессии?'**
  String get adminEndSessionsConfirmTitle;

  /// No description provided for @adminEndSessions.
  ///
  /// In ru, this message translates to:
  /// **'Завершить сессии'**
  String get adminEndSessions;

  /// No description provided for @adminWithUsSince.
  ///
  /// In ru, this message translates to:
  /// **'С нами с {date}'**
  String adminWithUsSince(String date);

  /// No description provided for @adminLastLogin.
  ///
  /// In ru, this message translates to:
  /// **'Последний вход: {date}'**
  String adminLastLogin(String date);

  /// No description provided for @adminReasonLabel.
  ///
  /// In ru, this message translates to:
  /// **'Причина'**
  String get adminReasonLabel;

  /// No description provided for @adminVerifyDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поставить «Проверен»'**
  String get adminVerifyDialogTitle;

  /// No description provided for @adminUnverifyDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Снять «Проверен»'**
  String get adminUnverifyDialogTitle;

  /// No description provided for @adminForceVerifyCheckbox.
  ///
  /// In ru, this message translates to:
  /// **'Я проверил документы лично'**
  String get adminForceVerifyCheckbox;

  /// No description provided for @adminRejectPresetUnreadable.
  ///
  /// In ru, this message translates to:
  /// **'Нечитаемое фото'**
  String get adminRejectPresetUnreadable;

  /// No description provided for @adminRejectPresetExpired.
  ///
  /// In ru, this message translates to:
  /// **'Документ просрочен'**
  String get adminRejectPresetExpired;

  /// No description provided for @adminRejectPresetMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Имя не совпадает'**
  String get adminRejectPresetMismatch;

  /// No description provided for @adminRejectPresetOther.
  ///
  /// In ru, this message translates to:
  /// **'Другое / причина'**
  String get adminRejectPresetOther;

  /// No description provided for @adminDocTypeCompanyRegistration.
  ///
  /// In ru, this message translates to:
  /// **'Свидетельство о регистрации'**
  String get adminDocTypeCompanyRegistration;

  /// No description provided for @adminDocTypeIdentity.
  ///
  /// In ru, this message translates to:
  /// **'Удостоверение личности'**
  String get adminDocTypeIdentity;

  /// No description provided for @adminDocTypeOther.
  ///
  /// In ru, this message translates to:
  /// **'Другой документ'**
  String get adminDocTypeOther;

  /// No description provided for @adminRotate.
  ///
  /// In ru, this message translates to:
  /// **'Повернуть'**
  String get adminRotate;

  /// No description provided for @adminComplaintReporter.
  ///
  /// In ru, this message translates to:
  /// **'Заявитель'**
  String get adminComplaintReporter;

  /// No description provided for @adminComplaintTarget.
  ///
  /// In ru, this message translates to:
  /// **'Объект жалобы'**
  String get adminComplaintTarget;

  /// No description provided for @adminAttentionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Требует внимания'**
  String get adminAttentionTitle;

  /// No description provided for @adminAttentionEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Всё в порядке — внимания не требуется'**
  String get adminAttentionEmpty;

  /// No description provided for @adminAttentionPendingVerification.
  ///
  /// In ru, this message translates to:
  /// **'На проверке: {count} человек'**
  String adminAttentionPendingVerification(int count);

  /// No description provided for @adminAttentionOpenComplaints.
  ///
  /// In ru, this message translates to:
  /// **'Открытых жалоб: {count}'**
  String adminAttentionOpenComplaints(int count);

  /// No description provided for @adminAttentionStaleDeals.
  ///
  /// In ru, this message translates to:
  /// **'Сделок без движения > 3 дней: {count}'**
  String adminAttentionStaleDeals(int count);

  /// No description provided for @adminAttentionUnverifiedCompanies.
  ///
  /// In ru, this message translates to:
  /// **'Непроверенных компаний: {count}'**
  String adminAttentionUnverifiedCompanies(int count);

  /// No description provided for @adminAttentionPendingCities.
  ///
  /// In ru, this message translates to:
  /// **'Новых городов: {count}'**
  String adminAttentionPendingCities(int count);

  /// No description provided for @adminRecentEventsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Последние события'**
  String get adminRecentEventsTitle;

  /// No description provided for @adminAuditLogLink.
  ///
  /// In ru, this message translates to:
  /// **'Журнал →'**
  String get adminAuditLogLink;

  /// No description provided for @adminAuditLogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Журнал действий'**
  String get adminAuditLogTitle;

  /// No description provided for @adminNoEvents.
  ///
  /// In ru, this message translates to:
  /// **'Событий нет'**
  String get adminNoEvents;

  /// No description provided for @adminPeriodLabel.
  ///
  /// In ru, this message translates to:
  /// **'Период:'**
  String get adminPeriodLabel;

  /// No description provided for @adminPeriodToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get adminPeriodToday;

  /// No description provided for @adminPeriod7d.
  ///
  /// In ru, this message translates to:
  /// **'7 дней'**
  String get adminPeriod7d;

  /// No description provided for @adminPeriod30d.
  ///
  /// In ru, this message translates to:
  /// **'30 дней'**
  String get adminPeriod30d;

  /// No description provided for @adminStatOnSiteToday.
  ///
  /// In ru, this message translates to:
  /// **'На точке сегодня'**
  String get adminStatOnSiteToday;

  /// No description provided for @adminStatOnSiteWeek.
  ///
  /// In ru, this message translates to:
  /// **'На неделе: {count}'**
  String adminStatOnSiteWeek(int count);

  /// No description provided for @adminGlobalSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск: имя, телефон, email, госномер, № груза/сделки'**
  String get adminGlobalSearchHint;

  /// No description provided for @adminSearchNoResults.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get adminSearchNoResults;

  /// No description provided for @adminNavCargos.
  ///
  /// In ru, this message translates to:
  /// **'Грузы'**
  String get adminNavCargos;

  /// No description provided for @adminNavDeals.
  ///
  /// In ru, this message translates to:
  /// **'Сделки'**
  String get adminNavDeals;

  /// No description provided for @adminNavSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get adminNavSettings;

  /// No description provided for @adminCargosTitle.
  ///
  /// In ru, this message translates to:
  /// **'Грузы'**
  String get adminCargosTitle;

  /// No description provided for @adminCargosEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Грузы не найдены'**
  String get adminCargosEmpty;

  /// No description provided for @adminDealsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сделки'**
  String get adminDealsTitle;

  /// No description provided for @adminDealsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Сделки не найдены'**
  String get adminDealsEmpty;

  /// No description provided for @adminFilterActive.
  ///
  /// In ru, this message translates to:
  /// **'В работе'**
  String get adminFilterActive;

  /// No description provided for @adminFilterStale.
  ///
  /// In ru, this message translates to:
  /// **'Без движения > 3 дней'**
  String get adminFilterStale;

  /// No description provided for @adminFilterOnSite.
  ///
  /// In ru, this message translates to:
  /// **'На точке'**
  String get adminFilterOnSite;

  /// No description provided for @adminColRoute.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут'**
  String get adminColRoute;

  /// No description provided for @adminColBodyType.
  ///
  /// In ru, this message translates to:
  /// **'Кузов'**
  String get adminColBodyType;

  /// No description provided for @adminColPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get adminColPrice;

  /// No description provided for @adminColCompany.
  ///
  /// In ru, this message translates to:
  /// **'Компания'**
  String get adminColCompany;

  /// No description provided for @adminColDriver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель'**
  String get adminColDriver;

  /// No description provided for @adminColResponses.
  ///
  /// In ru, this message translates to:
  /// **'Откликов'**
  String get adminColResponses;

  /// No description provided for @adminColPublished.
  ///
  /// In ru, this message translates to:
  /// **'Опубликован'**
  String get adminColPublished;

  /// No description provided for @adminColCreated.
  ///
  /// In ru, this message translates to:
  /// **'Создана'**
  String get adminColCreated;

  /// No description provided for @adminColStale.
  ///
  /// In ru, this message translates to:
  /// **'Без движения'**
  String get adminColStale;

  /// No description provided for @adminStaleDays.
  ///
  /// In ru, this message translates to:
  /// **'{days} дн.'**
  String adminStaleDays(int days);

  /// No description provided for @adminSettingsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Настроек пока нет'**
  String get adminSettingsEmpty;

  /// No description provided for @adminVerificationTabDrivers.
  ///
  /// In ru, this message translates to:
  /// **'Водители'**
  String get adminVerificationTabDrivers;

  /// No description provided for @adminVerificationTabCompanies.
  ///
  /// In ru, this message translates to:
  /// **'Компании'**
  String get adminVerificationTabCompanies;

  /// No description provided for @adminVerificationNoSelection.
  ///
  /// In ru, this message translates to:
  /// **'Выберите человека или компанию из очереди слева'**
  String get adminVerificationNoSelection;

  /// No description provided for @adminVerificationReasonNew.
  ///
  /// In ru, this message translates to:
  /// **'Новый · {count} документов'**
  String adminVerificationReasonNew(int count);

  /// No description provided for @adminVerificationReasonResubmitted.
  ///
  /// In ru, this message translates to:
  /// **'Повторно: {type}'**
  String adminVerificationReasonResubmitted(String type);

  /// No description provided for @adminVerificationReasonVehicleChanged.
  ///
  /// In ru, this message translates to:
  /// **'Сменил машину'**
  String get adminVerificationReasonVehicleChanged;

  /// No description provided for @adminVerificationOpenCard.
  ///
  /// In ru, this message translates to:
  /// **'Карточка →'**
  String get adminVerificationOpenCard;

  /// No description provided for @adminVerificationCrossCheckTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сверка с профилем'**
  String get adminVerificationCrossCheckTitle;

  /// No description provided for @adminCrossCheckName.
  ///
  /// In ru, this message translates to:
  /// **'Имя ↔ права'**
  String get adminCrossCheckName;

  /// No description provided for @adminCrossCheckPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Лицо на селфи ↔ фото в правах'**
  String get adminCrossCheckPhoto;

  /// No description provided for @adminCrossCheckPlate.
  ///
  /// In ru, this message translates to:
  /// **'Госномер ↔ техпаспорт тягача'**
  String get adminCrossCheckPlate;

  /// No description provided for @adminCrossCheckTrailerPlate.
  ///
  /// In ru, this message translates to:
  /// **'Прицеп ↔ техпаспорт прицепа'**
  String get adminCrossCheckTrailerPlate;

  /// No description provided for @adminCrossCheckCompanyName.
  ///
  /// In ru, this message translates to:
  /// **'Название ↔ лицензия'**
  String get adminCrossCheckCompanyName;

  /// No description provided for @adminCrossCheckCompanyTaxId.
  ///
  /// In ru, this message translates to:
  /// **'Рег. номер ↔ лицензия'**
  String get adminCrossCheckCompanyTaxId;

  /// No description provided for @adminCrossCheckMatch.
  ///
  /// In ru, this message translates to:
  /// **'Совпадает'**
  String get adminCrossCheckMatch;

  /// No description provided for @adminCrossCheckMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Не совпадает'**
  String get adminCrossCheckMismatch;

  /// No description provided for @adminConfirmDriverButton.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить водителя'**
  String get adminConfirmDriverButton;

  /// No description provided for @adminConfirmCompanyButton.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить компанию'**
  String get adminConfirmCompanyButton;

  /// No description provided for @adminReturnForReworkButton.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть на доработку'**
  String get adminReturnForReworkButton;

  /// No description provided for @adminReturnForReworkDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть на доработку'**
  String get adminReturnForReworkDialogTitle;

  /// No description provided for @adminReturnForReworkNoteLabel.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий (что переснять)'**
  String get adminReturnForReworkNoteLabel;

  /// No description provided for @adminVerificationMissingDocsHint.
  ///
  /// In ru, this message translates to:
  /// **'Отметьте все обязательные документы как «в порядке», чтобы подтвердить'**
  String get adminVerificationMissingDocsHint;

  /// No description provided for @adminVerificationCompareWithSelfie.
  ///
  /// In ru, this message translates to:
  /// **'Рядом с селфи'**
  String get adminVerificationCompareWithSelfie;

  /// No description provided for @adminRejectPresetPlateMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Госномер не совпадает'**
  String get adminRejectPresetPlateMismatch;

  /// No description provided for @adminCargoUnpublish.
  ///
  /// In ru, this message translates to:
  /// **'Снять с публикации'**
  String get adminCargoUnpublish;

  /// No description provided for @adminCargoUnpublishDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Снять груз с публикации'**
  String get adminCargoUnpublishDialogTitle;

  /// No description provided for @adminCargoEdit.
  ///
  /// In ru, this message translates to:
  /// **'Исправить'**
  String get adminCargoEdit;

  /// No description provided for @adminCargoEditDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Исправить груз'**
  String get adminCargoEditDialogTitle;

  /// No description provided for @adminCargoPublishedAt.
  ///
  /// In ru, this message translates to:
  /// **'Опубликован'**
  String get adminCargoPublishedAt;

  /// No description provided for @adminCargoExpiresAt.
  ///
  /// In ru, this message translates to:
  /// **'Истекает'**
  String get adminCargoExpiresAt;

  /// No description provided for @adminCargoArchivedAt.
  ///
  /// In ru, this message translates to:
  /// **'Снят с публикации'**
  String get adminCargoArchivedAt;

  /// No description provided for @adminCargoTabResponses.
  ///
  /// In ru, this message translates to:
  /// **'Отклики'**
  String get adminCargoTabResponses;

  /// No description provided for @adminNoResponses.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет откликов'**
  String get adminNoResponses;

  /// No description provided for @adminDealCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отменить сделку'**
  String get adminDealCancel;

  /// No description provided for @adminDealCancelDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить сделку'**
  String get adminDealCancelDialogTitle;

  /// No description provided for @adminDealFixStatus.
  ///
  /// In ru, this message translates to:
  /// **'Исправить статус'**
  String get adminDealFixStatus;

  /// No description provided for @adminDealFixStatusDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Исправить статус сделки'**
  String get adminDealFixStatusDialogTitle;

  /// No description provided for @adminDealOpenCargo.
  ///
  /// In ru, this message translates to:
  /// **'Груз →'**
  String get adminDealOpenCargo;

  /// No description provided for @adminDealCancelledBy.
  ///
  /// In ru, this message translates to:
  /// **'Отменено ({role})'**
  String adminDealCancelledBy(String role);

  /// No description provided for @adminDealStatusHistoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'История статусов'**
  String get adminDealStatusHistoryTitle;

  /// No description provided for @adminDealTabChat.
  ///
  /// In ru, this message translates to:
  /// **'Переписка'**
  String get adminDealTabChat;

  /// No description provided for @adminDealTabCalls.
  ///
  /// In ru, this message translates to:
  /// **'Звонки'**
  String get adminDealTabCalls;

  /// No description provided for @adminDealShowChat.
  ///
  /// In ru, this message translates to:
  /// **'Показать переписку'**
  String get adminDealShowChat;

  /// No description provided for @adminNoChat.
  ///
  /// In ru, this message translates to:
  /// **'Сообщений нет'**
  String get adminNoChat;

  /// No description provided for @adminNoCalls.
  ///
  /// In ru, this message translates to:
  /// **'Звонков не было'**
  String get adminNoCalls;

  /// No description provided for @adminContactEventCall.
  ///
  /// In ru, this message translates to:
  /// **'Звонок'**
  String get adminContactEventCall;

  /// No description provided for @adminContactEventWhatsapp.
  ///
  /// In ru, this message translates to:
  /// **'WhatsApp'**
  String get adminContactEventWhatsapp;

  /// No description provided for @roleAdmin.
  ///
  /// In ru, this message translates to:
  /// **'Админ'**
  String get roleAdmin;

  /// No description provided for @adminEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get adminEdit;

  /// No description provided for @adminTransferOwnershipTitle.
  ///
  /// In ru, this message translates to:
  /// **'Передать владение'**
  String get adminTransferOwnershipTitle;

  /// No description provided for @adminDemoteToLogistTitle.
  ///
  /// In ru, this message translates to:
  /// **'Понизить до логиста'**
  String get adminDemoteToLogistTitle;

  /// No description provided for @adminLastOwnerError.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя — это последний владелец компании'**
  String get adminLastOwnerError;

  /// No description provided for @adminRemoveMemberTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить сотрудника'**
  String get adminRemoveMemberTitle;

  /// No description provided for @adminRemoveMember.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get adminRemoveMember;

  /// No description provided for @adminChangeMemberEmailTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сменить email сотрудника'**
  String get adminChangeMemberEmailTitle;

  /// No description provided for @adminEmailTakenError.
  ///
  /// In ru, this message translates to:
  /// **'Этот email уже используется'**
  String get adminEmailTakenError;

  /// No description provided for @adminCompanyCity.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get adminCompanyCity;

  /// No description provided for @adminLegalAddress.
  ///
  /// In ru, this message translates to:
  /// **'Юридический адрес'**
  String get adminLegalAddress;

  /// No description provided for @adminTaxId.
  ///
  /// In ru, this message translates to:
  /// **'Рег. номер (БИН)'**
  String get adminTaxId;

  /// No description provided for @adminPhoneChangeWarning.
  ///
  /// In ru, this message translates to:
  /// **'При сохранении все сессии водителя будут завершены'**
  String get adminPhoneChangeWarning;

  /// No description provided for @adminVehicleBrand.
  ///
  /// In ru, this message translates to:
  /// **'Марка'**
  String get adminVehicleBrand;

  /// No description provided for @adminVehicleLengthM.
  ///
  /// In ru, this message translates to:
  /// **'Длина, м'**
  String get adminVehicleLengthM;

  /// No description provided for @adminNameEn.
  ///
  /// In ru, this message translates to:
  /// **'Название (en)'**
  String get adminNameEn;

  /// No description provided for @adminSortOrder.
  ///
  /// In ru, this message translates to:
  /// **'Порядок'**
  String get adminSortOrder;

  /// No description provided for @adminLat.
  ///
  /// In ru, this message translates to:
  /// **'Широта'**
  String get adminLat;

  /// No description provided for @adminLng.
  ///
  /// In ru, this message translates to:
  /// **'Долгота'**
  String get adminLng;

  /// No description provided for @adminCitiesTab.
  ///
  /// In ru, this message translates to:
  /// **'Города'**
  String get adminCitiesTab;

  /// No description provided for @adminSettingDefaultCity.
  ///
  /// In ru, this message translates to:
  /// **'Точка по умолчанию'**
  String get adminSettingDefaultCity;

  /// No description provided for @adminSettingNotSet.
  ///
  /// In ru, this message translates to:
  /// **'Не задано'**
  String get adminSettingNotSet;

  /// No description provided for @adminSettingHomeRadius.
  ///
  /// In ru, this message translates to:
  /// **'Радиус «Близко к дому», км'**
  String get adminSettingHomeRadius;

  /// No description provided for @adminUnitKm.
  ///
  /// In ru, this message translates to:
  /// **'км'**
  String get adminUnitKm;

  /// No description provided for @adminSettingCargoArchiveDays.
  ///
  /// In ru, this message translates to:
  /// **'Срок архива груза без откликов'**
  String get adminSettingCargoArchiveDays;

  /// No description provided for @adminComplaintResolutionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Решение'**
  String get adminComplaintResolutionTitle;

  /// No description provided for @adminComplaintResolutionNoteLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ответ автору жалобы'**
  String get adminComplaintResolutionNoteLabel;

  /// No description provided for @adminComplaintSelectHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите жалобу из очереди слева'**
  String get adminComplaintSelectHint;

  /// No description provided for @adminComplaintTabNew.
  ///
  /// In ru, this message translates to:
  /// **'Новые'**
  String get adminComplaintTabNew;

  /// No description provided for @adminComplaintTabInReview.
  ///
  /// In ru, this message translates to:
  /// **'В работе'**
  String get adminComplaintTabInReview;

  /// No description provided for @adminComplaintTabClosed.
  ///
  /// In ru, this message translates to:
  /// **'Закрытые'**
  String get adminComplaintTabClosed;

  /// No description provided for @adminComplaintMineFilter.
  ///
  /// In ru, this message translates to:
  /// **'Мои'**
  String get adminComplaintMineFilter;

  /// No description provided for @adminComplaintMoreThisMonth.
  ///
  /// In ru, this message translates to:
  /// **'ещё {count} жалоб за месяц'**
  String adminComplaintMoreThisMonth(int count);

  /// No description provided for @adminComplaintTakeOver.
  ///
  /// In ru, this message translates to:
  /// **'Взять в работу'**
  String get adminComplaintTakeOver;

  /// No description provided for @adminComplaintAssignedTo.
  ///
  /// In ru, this message translates to:
  /// **'В работе у {name}'**
  String adminComplaintAssignedTo(String name);

  /// No description provided for @adminComplaintReturnToNew.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть в новые'**
  String get adminComplaintReturnToNew;

  /// No description provided for @adminComplaintResolveButton.
  ///
  /// In ru, this message translates to:
  /// **'Принять решение'**
  String get adminComplaintResolveButton;

  /// No description provided for @adminComplaintResolutionDismissed.
  ///
  /// In ru, this message translates to:
  /// **'Не подтвердилась'**
  String get adminComplaintResolutionDismissed;

  /// No description provided for @adminComplaintResolutionWarned.
  ///
  /// In ru, this message translates to:
  /// **'Предупредить'**
  String get adminComplaintResolutionWarned;

  /// No description provided for @adminComplaintResolutionCargoUnpublished.
  ///
  /// In ru, this message translates to:
  /// **'Снять груз'**
  String get adminComplaintResolutionCargoUnpublished;

  /// No description provided for @adminComplaintResolutionBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать'**
  String get adminComplaintResolutionBlocked;

  /// No description provided for @adminStatClosedOutside.
  ///
  /// In ru, this message translates to:
  /// **'Нашли вне Lubao'**
  String get adminStatClosedOutside;

  /// No description provided for @adminStatClosedOutsideHint.
  ///
  /// In ru, this message translates to:
  /// **'{outside} из {total} закрытых'**
  String adminStatClosedOutsideHint(int outside, int total);

  /// No description provided for @cargoCloseDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть груз'**
  String get cargoCloseDialogTitle;

  /// No description provided for @cargoCloseFoundInApp.
  ///
  /// In ru, this message translates to:
  /// **'Нашёл водителя в Lubao'**
  String get cargoCloseFoundInApp;

  /// No description provided for @cargoCloseNoCandidates.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет водителей, с кем были отклик, звонок или переписка'**
  String get cargoCloseNoCandidates;

  /// No description provided for @cargoCloseDriverLabel.
  ///
  /// In ru, this message translates to:
  /// **'Водитель'**
  String get cargoCloseDriverLabel;

  /// No description provided for @cargoCloseFoundOutside.
  ///
  /// In ru, this message translates to:
  /// **'Нашёл вне Lubao'**
  String get cargoCloseFoundOutside;

  /// No description provided for @cargoCloseCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Груз отменён'**
  String get cargoCloseCancelled;

  /// No description provided for @cargoCloseConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get cargoCloseConfirm;

  /// No description provided for @cargoClosed.
  ///
  /// In ru, this message translates to:
  /// **'Груз закрыт'**
  String get cargoClosed;

  /// No description provided for @cargoClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть груз'**
  String get cargoClose;

  /// No description provided for @navChats.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get navChats;

  /// No description provided for @chatsTabTitle.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get chatsTabTitle;

  /// No description provided for @chatsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет чатов'**
  String get chatsEmpty;

  /// No description provided for @profileNotificationSettings.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get profileNotificationSettings;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsHint.
  ///
  /// In ru, this message translates to:
  /// **'Выключенная группа не присылает push по этим событиям'**
  String get notificationSettingsHint;

  /// No description provided for @notificationGroupNewCargoMatch.
  ///
  /// In ru, this message translates to:
  /// **'Новый подходящий груз'**
  String get notificationGroupNewCargoMatch;

  /// No description provided for @notificationGroupCargoInvite.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение на груз'**
  String get notificationGroupCargoInvite;

  /// No description provided for @notificationGroupChatMessage.
  ///
  /// In ru, this message translates to:
  /// **'Новое сообщение в чате'**
  String get notificationGroupChatMessage;

  /// No description provided for @notificationGroupNewResponse.
  ///
  /// In ru, this message translates to:
  /// **'Отклик водителя'**
  String get notificationGroupNewResponse;

  /// No description provided for @notificationGroupNewDriverDigest.
  ///
  /// In ru, this message translates to:
  /// **'Новые водители на точке'**
  String get notificationGroupNewDriverDigest;

  /// No description provided for @notificationGroupDealStatus.
  ///
  /// In ru, this message translates to:
  /// **'Смена статуса сделки'**
  String get notificationGroupDealStatus;

  /// No description provided for @notificationGroupVerification.
  ///
  /// In ru, this message translates to:
  /// **'Проверка документов'**
  String get notificationGroupVerification;

  /// No description provided for @notificationGroupAgreedCheck.
  ///
  /// In ru, this message translates to:
  /// **'«Договорились?»'**
  String get notificationGroupAgreedCheck;

  /// No description provided for @companyWecomTitle.
  ///
  /// In ru, this message translates to:
  /// **'WeCom-бот'**
  String get companyWecomTitle;

  /// No description provided for @companyWecomHint.
  ///
  /// In ru, this message translates to:
  /// **'Адрес вебхука группового бота WeCom — уведомления о новых откликах и сделках будут приходить в вашу группу'**
  String get companyWecomHint;

  /// No description provided for @companyWecomUrlLabel.
  ///
  /// In ru, this message translates to:
  /// **'Вебхук URL'**
  String get companyWecomUrlLabel;

  /// No description provided for @companyWecomTestButton.
  ///
  /// In ru, this message translates to:
  /// **'Проверить'**
  String get companyWecomTestButton;

  /// No description provided for @companyWecomTestSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Тестовое сообщение отправлено'**
  String get companyWecomTestSuccess;

  /// No description provided for @companyWecomTestError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить — проверьте адрес'**
  String get companyWecomTestError;

  /// No description provided for @chatTranslationFailed.
  ///
  /// In ru, this message translates to:
  /// **'Перевод недоступен'**
  String get chatTranslationFailed;

  /// No description provided for @chatTranslationRetry.
  ///
  /// In ru, this message translates to:
  /// **'повторить'**
  String get chatTranslationRetry;

  /// No description provided for @adminTranslationSettingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Перевод чата'**
  String get adminTranslationSettingsTitle;

  /// No description provided for @adminTranslationEnabledLabel.
  ///
  /// In ru, this message translates to:
  /// **'Включён'**
  String get adminTranslationEnabledLabel;

  /// No description provided for @adminTranslationProviderLabel.
  ///
  /// In ru, this message translates to:
  /// **'Провайдер'**
  String get adminTranslationProviderLabel;

  /// No description provided for @adminTranslationModelLabel.
  ///
  /// In ru, this message translates to:
  /// **'Модель'**
  String get adminTranslationModelLabel;

  /// No description provided for @adminTranslationRequests7dLabel.
  ///
  /// In ru, this message translates to:
  /// **'Запросов за 7 дней'**
  String get adminTranslationRequests7dLabel;

  /// No description provided for @adminTranslationTokens7dLabel.
  ///
  /// In ru, this message translates to:
  /// **'Токенов за 7 дней'**
  String get adminTranslationTokens7dLabel;

  /// No description provided for @adminAuditActionAdminViewedChat.
  ///
  /// In ru, this message translates to:
  /// **'Админ открыл чат'**
  String get adminAuditActionAdminViewedChat;

  /// No description provided for @adminAuditActionCargoUnpublished.
  ///
  /// In ru, this message translates to:
  /// **'Груз снят с публикации'**
  String get adminAuditActionCargoUnpublished;

  /// No description provided for @adminAuditActionCargoUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Груз изменён'**
  String get adminAuditActionCargoUpdated;

  /// No description provided for @adminAuditActionCityUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Город изменён'**
  String get adminAuditActionCityUpdated;

  /// No description provided for @adminAuditActionCompanyBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Компания заблокирована'**
  String get adminAuditActionCompanyBlocked;

  /// No description provided for @adminAuditActionCompanyMemberEmailChanged.
  ///
  /// In ru, this message translates to:
  /// **'Email сотрудника изменён'**
  String get adminAuditActionCompanyMemberEmailChanged;

  /// No description provided for @adminAuditActionCompanyMemberRemoved.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник удалён из компании'**
  String get adminAuditActionCompanyMemberRemoved;

  /// No description provided for @adminAuditActionCompanyMemberRoleChanged.
  ///
  /// In ru, this message translates to:
  /// **'Роль сотрудника изменена'**
  String get adminAuditActionCompanyMemberRoleChanged;

  /// No description provided for @adminAuditActionCompanyPasswordReset.
  ///
  /// In ru, this message translates to:
  /// **'Пароль компании сброшен'**
  String get adminAuditActionCompanyPasswordReset;

  /// No description provided for @adminAuditActionCompanyReturnedForRework.
  ///
  /// In ru, this message translates to:
  /// **'Документы компании вернули на доработку'**
  String get adminAuditActionCompanyReturnedForRework;

  /// No description provided for @adminAuditActionCompanyUnblocked.
  ///
  /// In ru, this message translates to:
  /// **'Компания разблокирована'**
  String get adminAuditActionCompanyUnblocked;

  /// No description provided for @adminAuditActionCompanyUnverified.
  ///
  /// In ru, this message translates to:
  /// **'Компания снята с проверки'**
  String get adminAuditActionCompanyUnverified;

  /// No description provided for @adminAuditActionCompanyUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Данные компании изменены'**
  String get adminAuditActionCompanyUpdated;

  /// No description provided for @adminAuditActionCompanyVerified.
  ///
  /// In ru, this message translates to:
  /// **'Компания подтверждена'**
  String get adminAuditActionCompanyVerified;

  /// No description provided for @adminAuditActionComplaintAssigned.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба взята в работу'**
  String get adminAuditActionComplaintAssigned;

  /// No description provided for @adminAuditActionComplaintResolved.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба решена'**
  String get adminAuditActionComplaintResolved;

  /// No description provided for @adminAuditActionComplaintUnassigned.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба возвращена в очередь'**
  String get adminAuditActionComplaintUnassigned;

  /// No description provided for @adminAuditActionDealCancelledByAdmin.
  ///
  /// In ru, this message translates to:
  /// **'Сделка отменена админом'**
  String get adminAuditActionDealCancelledByAdmin;

  /// No description provided for @adminAuditActionDealStatusFixed.
  ///
  /// In ru, this message translates to:
  /// **'Статус сделки исправлен'**
  String get adminAuditActionDealStatusFixed;

  /// No description provided for @adminAuditActionDriverReturnedForRework.
  ///
  /// In ru, this message translates to:
  /// **'Документы водителя вернули на доработку'**
  String get adminAuditActionDriverReturnedForRework;

  /// No description provided for @adminAuditActionDriverUnverified.
  ///
  /// In ru, this message translates to:
  /// **'Водитель снят с проверки'**
  String get adminAuditActionDriverUnverified;

  /// No description provided for @adminAuditActionDriverUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Данные водителя изменены'**
  String get adminAuditActionDriverUpdated;

  /// No description provided for @adminAuditActionDriverVerified.
  ///
  /// In ru, this message translates to:
  /// **'Водитель подтверждён'**
  String get adminAuditActionDriverVerified;

  /// No description provided for @adminAuditActionPointUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Точка изменена'**
  String get adminAuditActionPointUpdated;

  /// No description provided for @adminAuditActionSessionsRevoked.
  ///
  /// In ru, this message translates to:
  /// **'Сессии завершены'**
  String get adminAuditActionSessionsRevoked;

  /// No description provided for @adminAuditActionSettingChanged.
  ///
  /// In ru, this message translates to:
  /// **'Настройка изменена'**
  String get adminAuditActionSettingChanged;

  /// No description provided for @adminAuditActionUserBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь заблокирован'**
  String get adminAuditActionUserBlocked;

  /// No description provided for @adminAuditActionUserUnblocked.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь разблокирован'**
  String get adminAuditActionUserUnblocked;

  /// No description provided for @adminAuditActionBodyTypeUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Тип кузова изменён'**
  String get adminAuditActionBodyTypeUpdated;

  /// No description provided for @adminAuditActionPermitUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Допуск изменён'**
  String get adminAuditActionPermitUpdated;

  /// No description provided for @adminAuditFieldDestinationCountry.
  ///
  /// In ru, this message translates to:
  /// **'Страна назначения'**
  String get adminAuditFieldDestinationCountry;

  /// No description provided for @adminAuditFieldDestinationCity.
  ///
  /// In ru, this message translates to:
  /// **'Город назначения'**
  String get adminAuditFieldDestinationCity;

  /// No description provided for @adminAuditFieldBodyType.
  ///
  /// In ru, this message translates to:
  /// **'Тип кузова'**
  String get adminAuditFieldBodyType;

  /// No description provided for @adminAuditFieldWeight.
  ///
  /// In ru, this message translates to:
  /// **'Вес, кг'**
  String get adminAuditFieldWeight;

  /// No description provided for @adminAuditFieldVolume.
  ///
  /// In ru, this message translates to:
  /// **'Объём, м³'**
  String get adminAuditFieldVolume;

  /// No description provided for @adminAuditFieldPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get adminAuditFieldPhotos;

  /// No description provided for @adminAuditFieldPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get adminAuditFieldPrice;

  /// No description provided for @adminAuditFieldCurrency.
  ///
  /// In ru, this message translates to:
  /// **'Валюта'**
  String get adminAuditFieldCurrency;

  /// No description provided for @adminAuditFieldReadyDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата готовности'**
  String get adminAuditFieldReadyDate;

  /// No description provided for @adminAuditFieldDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get adminAuditFieldDescription;

  /// No description provided for @adminAuditFieldName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get adminAuditFieldName;

  /// No description provided for @adminAuditFieldNameRu.
  ///
  /// In ru, this message translates to:
  /// **'Название (рус.)'**
  String get adminAuditFieldNameRu;

  /// No description provided for @adminAuditFieldCountry.
  ///
  /// In ru, this message translates to:
  /// **'Страна'**
  String get adminAuditFieldCountry;

  /// No description provided for @adminAuditFieldCity.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get adminAuditFieldCity;

  /// No description provided for @adminAuditFieldLegalAddress.
  ///
  /// In ru, this message translates to:
  /// **'Юридический адрес'**
  String get adminAuditFieldLegalAddress;

  /// No description provided for @adminAuditFieldTaxId.
  ///
  /// In ru, this message translates to:
  /// **'ИНН/БИН'**
  String get adminAuditFieldTaxId;

  /// No description provided for @adminAuditFieldFullName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get adminAuditFieldFullName;

  /// No description provided for @adminAuditFieldPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get adminAuditFieldPhone;

  /// No description provided for @adminAuditFieldHomeCity.
  ///
  /// In ru, this message translates to:
  /// **'Домашний город'**
  String get adminAuditFieldHomeCity;

  /// No description provided for @adminAuditFieldAnyCountry.
  ///
  /// In ru, this message translates to:
  /// **'Любая страна'**
  String get adminAuditFieldAnyCountry;

  /// No description provided for @adminAuditFieldCountries.
  ///
  /// In ru, this message translates to:
  /// **'Страны'**
  String get adminAuditFieldCountries;

  /// No description provided for @adminAuditFieldPermits.
  ///
  /// In ru, this message translates to:
  /// **'Допуски'**
  String get adminAuditFieldPermits;

  /// No description provided for @adminAuditFieldVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Транспорт'**
  String get adminAuditFieldVehicle;

  /// No description provided for @adminAuditFieldPlateNumber.
  ///
  /// In ru, this message translates to:
  /// **'Госномер'**
  String get adminAuditFieldPlateNumber;

  /// No description provided for @adminAuditFieldCapacity.
  ///
  /// In ru, this message translates to:
  /// **'Грузоподъёмность, т'**
  String get adminAuditFieldCapacity;

  /// No description provided for @adminAuditFieldLength.
  ///
  /// In ru, this message translates to:
  /// **'Длина, м'**
  String get adminAuditFieldLength;

  /// No description provided for @adminAuditFieldBrand.
  ///
  /// In ru, this message translates to:
  /// **'Марка'**
  String get adminAuditFieldBrand;

  /// No description provided for @adminAuditFieldIsActive.
  ///
  /// In ru, this message translates to:
  /// **'Активен'**
  String get adminAuditFieldIsActive;

  /// No description provided for @adminAuditFieldSortOrder.
  ///
  /// In ru, this message translates to:
  /// **'Порядок'**
  String get adminAuditFieldSortOrder;

  /// No description provided for @adminAuditFieldStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get adminAuditFieldStatus;

  /// No description provided for @postCargoVerificationRequired.
  ///
  /// In ru, this message translates to:
  /// **'Публикация грузов откроется после проверки компании — загрузите свидетельство о регистрации в профиле'**
  String get postCargoVerificationRequired;

  /// No description provided for @companyNotVerifiedBannerText.
  ///
  /// In ru, this message translates to:
  /// **'Компания не проверена. Можно смотреть водителей и писать им, но нельзя опубликовать груз — загрузите свидетельство о регистрации ниже'**
  String get companyNotVerifiedBannerText;

  /// No description provided for @companyEditTitle.
  ///
  /// In ru, this message translates to:
  /// **'Данные компании'**
  String get companyEditTitle;

  /// No description provided for @companyEditCityLabel.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get companyEditCityLabel;

  /// No description provided for @companyEditLegalAddressLabel.
  ///
  /// In ru, this message translates to:
  /// **'Юридический адрес'**
  String get companyEditLegalAddressLabel;

  /// No description provided for @companyEditTaxIdLabel.
  ///
  /// In ru, this message translates to:
  /// **'Рег. номер (统一社会信用代码 / БИН)'**
  String get companyEditTaxIdLabel;

  /// No description provided for @companyEditTaxIdError.
  ///
  /// In ru, this message translates to:
  /// **'Неверный формат рег. номера для вашей страны'**
  String get companyEditTaxIdError;

  /// No description provided for @myProfileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мой профиль'**
  String get myProfileTitle;

  /// No description provided for @myProfileNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get myProfileNameLabel;

  /// No description provided for @myProfilePhoneLabel.
  ///
  /// In ru, this message translates to:
  /// **'Телефон для водителей'**
  String get myProfilePhoneLabel;

  /// No description provided for @myProfileWechatLabel.
  ///
  /// In ru, this message translates to:
  /// **'WeChat'**
  String get myProfileWechatLabel;

  /// No description provided for @myProfileNameError.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя'**
  String get myProfileNameError;

  /// No description provided for @myProfileNotSetYet.
  ///
  /// In ru, this message translates to:
  /// **'Заполните профиль'**
  String get myProfileNotSetYet;

  /// No description provided for @companyVerificationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите компанию'**
  String get companyVerificationTitle;

  /// No description provided for @companyVerificationHint.
  ///
  /// In ru, this message translates to:
  /// **'Загрузите свидетельство о регистрации — сверим с реестром и позвоним на номер из реестра, обычно до 1 рабочего дня'**
  String get companyVerificationHint;

  /// No description provided for @companyVerificationStatusNone.
  ///
  /// In ru, this message translates to:
  /// **'Документ не загружен'**
  String get companyVerificationStatusNone;

  /// No description provided for @companyVerificationStatusPending.
  ///
  /// In ru, this message translates to:
  /// **'На проверке'**
  String get companyVerificationStatusPending;

  /// No description provided for @companyVerificationStatusRejected.
  ///
  /// In ru, this message translates to:
  /// **'Нужно переснять'**
  String get companyVerificationStatusRejected;
}

class _LubaoLocalizationsDelegate
    extends LocalizationsDelegate<LubaoLocalizations> {
  const _LubaoLocalizationsDelegate();

  @override
  Future<LubaoLocalizations> load(Locale locale) {
    return SynchronousFuture<LubaoLocalizations>(
      lookupLubaoLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_LubaoLocalizationsDelegate old) => false;
}

LubaoLocalizations lookupLubaoLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LubaoLocalizationsEn();
    case 'kk':
      return LubaoLocalizationsKk();
    case 'ru':
      return LubaoLocalizationsRu();
    case 'zh':
      return LubaoLocalizationsZh();
  }

  throw FlutterError(
    'LubaoLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
