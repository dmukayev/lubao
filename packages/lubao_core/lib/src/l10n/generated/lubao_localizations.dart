import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  /// **'Домой'**
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
  /// **'Язык'**
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
  /// **'Нет документов на проверку'**
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
      <String>['kk', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_LubaoLocalizationsDelegate old) => false;
}

LubaoLocalizations lookupLubaoLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
