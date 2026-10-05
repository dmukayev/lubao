// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'lubao_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LubaoLocalizationsEn extends LubaoLocalizations {
  LubaoLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lubao';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDone => 'Done';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get chatOpenFailed => 'Couldn\'t open chat';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonCall => 'Call';

  @override
  String get commonWhatsApp => 'WhatsApp';

  @override
  String get commonChat => 'Chat';

  @override
  String get commonSend => 'Send';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get roleSelectTitle => 'Who are you?';

  @override
  String get roleSelectSubtitle => 'Choose how you\'ll use Lubao';

  @override
  String get roleDriver => 'Driver';

  @override
  String get roleCompany => 'Logistics company';

  @override
  String get driverLoginTitle => 'Driver sign-in';

  @override
  String get driverLoginPhoneLabel => 'Phone number';

  @override
  String get driverLoginPhoneHint => '+7 700 000 00 00';

  @override
  String get driverLoginSendCode => 'Get code';

  @override
  String get driverLoginCodeLabel => 'SMS code';

  @override
  String get driverLoginVerify => 'Sign in';

  @override
  String get driverLoginCountryLabel => 'Country';

  @override
  String driverOtpSubtitle(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get driverOtpResend => 'Resend code';

  @override
  String get driverOtpInvalidCode => 'Invalid code';

  @override
  String get driverOtpTooManyAttempts =>
      'Too many attempts — request a new code';

  @override
  String get companyRegisterTitle => 'New company';

  @override
  String get companyRegisterOwnerName => 'Your name';

  @override
  String get companyRegisterCompanyName => 'Company name';

  @override
  String get companyRegisterCompanyNameRu => 'Name in Russian';

  @override
  String get companyRegisterNameError => 'Enter a name, at least 2 characters';

  @override
  String get companyRegisterCountry => 'Country';

  @override
  String get companyRegisterCountryError => 'Choose a country';

  @override
  String get companyRegisterOtherCountry => 'Other';

  @override
  String get companyRegisterSubmit => 'Create company';

  @override
  String get companyRegisterEmailError => 'Enter an email';

  @override
  String get companyRegisterPasswordError => 'At least 8 characters';

  @override
  String get companyRegisterEmailTaken =>
      'This email is already registered. Sign in?';

  @override
  String get companyLoginTitle => 'Company sign-in';

  @override
  String get companyLoginEmailLabel => 'Email';

  @override
  String get companyLoginVerify => 'Sign in';

  @override
  String get companyLoginLockedOut =>
      'Too many attempts. Try again in 15 minutes';

  @override
  String get companyLoginShowPassword => 'Show password';

  @override
  String get companyLoginHidePassword => 'Hide password';

  @override
  String get companyLoginRegisterLink => 'Register';

  @override
  String get companyLoginForgotPasswordLink => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Password recovery';

  @override
  String get forgotPasswordSendCode => 'Send code';

  @override
  String get forgotPasswordCodeLabel => 'Code from the email';

  @override
  String get forgotPasswordNewPasswordLabel => 'New password';

  @override
  String get forgotPasswordSubmit => 'Change password';

  @override
  String get forgotPasswordSuccess =>
      'Password changed, sign in with the new password';

  @override
  String get forgotPasswordResend => 'Resend code';

  @override
  String get forgotPasswordInvalidCode => 'Invalid or expired code';

  @override
  String get forgotPasswordNoEmailLink => 'Email not arriving?';

  @override
  String get supportContactTitle => 'Contact support';

  @override
  String get supportContactBody =>
      'If the email isn\'t arriving, reach us any way that\'s convenient';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportContactWechat => 'WeChat';

  @override
  String get supportContactEmail => 'Email';

  @override
  String get supportContactNone => 'Support contacts will appear here soon';

  @override
  String get acceptInviteTitle => 'Company invitation';

  @override
  String acceptInviteSubtitle(String companyName, String role) {
    return 'You\'ve been invited to «$companyName» — role: $role';
  }

  @override
  String get acceptInviteNameLabel => 'Your name';

  @override
  String get acceptInvitePhoneLabel => 'Phone (for drivers)';

  @override
  String get acceptInviteWechatLabel => 'WeChat (optional)';

  @override
  String get acceptInviteSubmit => 'Join company';

  @override
  String get acceptInviteInvalidToken =>
      'This invitation is invalid or already used';

  @override
  String get emailVerifyBannerText => 'Email not confirmed';

  @override
  String get emailVerifyBannerAction => 'Confirm';

  @override
  String get emailVerifyDialogTitle => 'Confirm email';

  @override
  String get emailVerifyDialogCodeLabel => 'Code from the email';

  @override
  String get emailVerifyDialogSubmit => 'Confirm';

  @override
  String get employeesInviteButton => 'Invite employee';

  @override
  String get employeesInviteEmailLabel => 'Employee email';

  @override
  String get employeesInviteRoleOwner => 'Owner';

  @override
  String get employeesInviteRoleLogist => 'Logist';

  @override
  String get employeesInviteSubmit => 'Create link';

  @override
  String get employeesInviteLinkReady =>
      'The invite link is valid for 7 days. Copy it and send via WeChat/WhatsApp:';

  @override
  String get employeesInviteCopyLink => 'Copy';

  @override
  String get employeesInviteCopied => 'Link copied';

  @override
  String get driverSetupTitle => 'Profile setup';

  @override
  String get driverRegisterTitle => 'Registration';

  @override
  String get driverVerificationTitle => 'Verification';

  @override
  String get driverVerificationIntro =>
      'To respond to cargo and confirm deals, verify your identity — it takes about 2 minutes';

  @override
  String get driverVerificationConsent =>
      'Documents are recognized on Lubao\'s servers in Kazakhstan. Your ID number is stored encrypted and used only to verify your identity and prevent blocked users from re-registering.';

  @override
  String get driverVerificationSelfie => 'Selfie';

  @override
  String get driverVerificationVehiclePassport =>
      'Truck registration certificate';

  @override
  String get driverVerificationTrailerPassport =>
      'Trailer registration certificate';

  @override
  String get driverVerificationLicense => 'Driver\'s license';

  @override
  String get driverVerificationStatusNone => 'Not uploaded';

  @override
  String get driverVerificationStatusPending => 'Under review';

  @override
  String get driverVerificationStatusApproved => 'Approved';

  @override
  String get driverVerificationStatusRejected => 'Rejected';

  @override
  String get driverVerificationUploadFailed => 'Couldn\'t upload the photo';

  @override
  String get driverVerificationRequiredPrompt =>
      'Verify your identity to respond — 2 minutes';

  @override
  String get driverVerificationRequiredAction => 'Get verified';

  @override
  String profileCompleteness(int percent) {
    return 'Profile is $percent% complete — verified drivers get 3x more invitations';
  }

  @override
  String driverSetupStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get driverSetupFullName => 'Full name';

  @override
  String get driverSetupFullNameError =>
      'Enter a name: 2-80 letters, no digits';

  @override
  String get driverSetupHomeCityError => 'Choose a city';

  @override
  String get driverSetupBodyTypeError => 'Choose a body type';

  @override
  String get cityNotListed => 'My city isn\'t listed';

  @override
  String get addCitySettlementLabel => 'Settlement';

  @override
  String get addCitySettlementError => 'Enter the settlement name';

  @override
  String get addCityRegionLabel => 'Region';

  @override
  String get addCityRegionError => 'Choose a region';

  @override
  String get addCitySubmit => 'Continue';

  @override
  String get driverSetupHomeCity => 'Home city';

  @override
  String get driverSetupCountries => 'Directions';

  @override
  String get driverSetupAnyCountry => 'Any country';

  @override
  String get driverSetupPermits => 'Permits';

  @override
  String get driverSetupVehicleBodyType => 'Body type';

  @override
  String get driverSetupVehiclePlate => 'License plate';

  @override
  String get driverSetupVehicleTitle => 'What\'s your truck?';

  @override
  String get driverSetupVehicleSubtitle =>
      'Fill this in once — we\'ll match cargo to it';

  @override
  String get driverSetupCapacity => 'Payload capacity';

  @override
  String get driverSetupDocuments => 'Vehicle documents';

  @override
  String get driverSetupDirectionsTitle => 'Where are you willing to go?';

  @override
  String get driverSetupDirectionsSubtitle =>
      'We\'ll show cargo to these countries first. You can change this anytime';

  @override
  String driverSetupCountriesSelected(int count) {
    return 'Countries selected: $count';
  }

  @override
  String get driverSetupSubmit => 'Save and continue';

  @override
  String get feedTitle => 'Cargo in Khorgos';

  @override
  String get driverHomeGreeting => 'Hi,';

  @override
  String get driverHomeAnonsTitle => 'My announcement';

  @override
  String driverHomeLogistsCount(int count) {
    return 'Logists nearby: $count';
  }

  @override
  String driverHomeSince(String date) {
    return 'On site since $date';
  }

  @override
  String get driverHomeCheckInEmpty =>
      'Announce your arrival — logists will see you ahead of time';

  @override
  String get driverHomeCheckInButton => 'I\'m already on site';

  @override
  String get driverHomeLeaveButton => 'I\'ve left';

  @override
  String get driverHomeCancelButton => 'Cancel';

  @override
  String get driverHomeAnnounceButton => 'I\'ll be on site';

  @override
  String get driverHomeRepeatButton => 'Repeat last announcement';

  @override
  String get driverHomeEditButton => 'Edit';

  @override
  String driverHomePlannedFor(String date) {
    return 'Arriving $date';
  }

  @override
  String get announceArrivalTitle => 'I\'ll be on site';

  @override
  String get announceArrivalWhen => 'When';

  @override
  String get announceArrivalToday => 'Today';

  @override
  String get announceArrivalTomorrow => 'Tomorrow';

  @override
  String get announceArrivalDayAfter => 'Day after tomorrow';

  @override
  String get announceArrivalPickDate => 'Pick a date';

  @override
  String get announceArrivalWhere => 'Where';

  @override
  String get announceArrivalCountries => 'Willing to go to';

  @override
  String get announceArrivalWaitDays => 'How long are you willing to wait';

  @override
  String announceArrivalWaitDaysValue(int days) {
    return '$days d.';
  }

  @override
  String get announceArrivalSubmit => 'Publish';

  @override
  String driverHomeFeedCount(int count) {
    return 'Matching cargo $count';
  }

  @override
  String get feedEmpty => 'No matching cargo yet';

  @override
  String get feedSectionHome => 'Close to home';

  @override
  String get feedSectionSelected => 'Your directions';

  @override
  String get feedSectionOther => 'Other directions';

  @override
  String get cargoPrice => 'Price';

  @override
  String get cargoWeight => 'Weight';

  @override
  String get cargoVolume => 'Volume';

  @override
  String get cargoPhotos => 'Photos';

  @override
  String get unitKg => 'kg';

  @override
  String get unitM3 => 'm³';

  @override
  String get unitTon => 't';

  @override
  String get cargoReadyDate => 'Ready date';

  @override
  String get cargoDestination => 'Destination';

  @override
  String get cargoBodyType => 'Body type';

  @override
  String get cargoRespond => 'Respond';

  @override
  String get cargoAlreadyResponded => 'You\'ve responded';

  @override
  String get cargoDetailTitle => 'Cargo';

  @override
  String get cargoDetailDescription => 'Description';

  @override
  String get cargoDetailCompany => 'Company';

  @override
  String get cargoDetailPriceLabel => 'Price per trip';

  @override
  String cargoDetailCompanyDeals(int count) {
    return '$count deals on Lubao';
  }

  @override
  String get cargoDetailNoReviews => 'No reviews yet';

  @override
  String get cargoStatusPublished => 'Published';

  @override
  String get cargoStatusArchived => 'Archived';

  @override
  String get cargoStatusExpired => 'Expired';

  @override
  String get cargoStatusCancelled => 'Cancelled';

  @override
  String get dealsTitle => 'My deals';

  @override
  String get dealsEmpty => 'No deals yet';

  @override
  String get dealStatusSelected => 'Selected';

  @override
  String get dealStatusConfirmed => 'Confirmed by driver';

  @override
  String get dealStatusLoaded => 'Loaded';

  @override
  String get dealStatusInTransit => 'In transit';

  @override
  String get dealStatusDelivered => 'Delivered';

  @override
  String get dealStatusCancelled => 'Cancelled';

  @override
  String get dealDetailTitle => 'Deal';

  @override
  String get dealTimelineTitle => 'Deal status';

  @override
  String get dealDriverLocationTitle => 'Driver\'s location';

  @override
  String get dealLocationUpdatedAt => 'Updated';

  @override
  String get dealLocationNoData => 'Coordinates not received yet';

  @override
  String get dealConfirm => 'Confirm';

  @override
  String get dealMarkLoaded => 'Cargo loaded';

  @override
  String get dealMarkInTransit => 'In transit';

  @override
  String get dealMarkDelivered => 'Delivered';

  @override
  String get dealCancel => 'Cancel deal';

  @override
  String get dealCancelReasonLabel => 'Cancellation reason';

  @override
  String get dealCancelledBy => 'Cancelled by';

  @override
  String get reviewTitle => 'Leave a review';

  @override
  String get reviewRatingLabel => 'Rating';

  @override
  String get reviewCommentLabel => 'Comment';

  @override
  String get reviewSubmit => 'Submit review';

  @override
  String get reviewsReceivedTitle => 'Reviews';

  @override
  String get responsesTitle => 'Responses';

  @override
  String get responsesEmpty => 'No responses yet';

  @override
  String get responseSelect => 'Select driver';

  @override
  String get responseReject => 'Reject';

  @override
  String get responseStatusPending => 'Pending';

  @override
  String get responseStatusSelected => 'Selected';

  @override
  String get responseStatusRejected => 'Rejected';

  @override
  String get responseStatusCancelled => 'Cancelled';

  @override
  String get myCargosTitle => 'My cargo';

  @override
  String get myCargosEmpty => 'You haven\'t posted any cargo yet';

  @override
  String get postCargoTitle => 'New cargo';

  @override
  String get postCargoDestinationCountry => 'Destination country';

  @override
  String get postCargoDestinationCity => 'Destination city';

  @override
  String get postCargoBodyType => 'Body type';

  @override
  String get postCargoVolume => 'Volume, m³';

  @override
  String get postCargoWeight => 'Weight, kg';

  @override
  String get postCargoPhotos => 'Photos';

  @override
  String get postCargoAddPhotoCamera => 'Camera';

  @override
  String get postCargoAddPhotoGallery => 'Gallery';

  @override
  String get postCargoRemovePhoto => 'Remove photo';

  @override
  String get postCargoPhotoUploadFailed => 'Couldn\'t upload the photo';

  @override
  String get postCargoPrice => 'Price';

  @override
  String get postCargoCurrency => 'Currency';

  @override
  String get postCargoReadyDate => 'Ready date';

  @override
  String get postCargoDescription => 'Cargo description';

  @override
  String get postCargoSubmit => 'Publish';

  @override
  String get editCargoTitle => 'Edit cargo';

  @override
  String get cargoEdit => 'Edit';

  @override
  String get cargoDelete => 'Delete';

  @override
  String get cargoDeleteConfirmTitle => 'Delete cargo?';

  @override
  String get cargoDeleteConfirmMessage =>
      'The cargo will be unpublished. Response and deal history will be kept.';

  @override
  String get cargoDeleted => 'Cargo deleted';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatInputHint => 'Message';

  @override
  String get chatEmpty => 'Start the conversation';

  @override
  String get chatAttachLocation => 'Attach location';

  @override
  String get chatLocationMessagePrefix => 'Location on map';

  @override
  String get chatLocationError => 'Couldn\'t determine the location';

  @override
  String get chatTranslatedBadge => 'Translated';

  @override
  String get chatShowOriginal => 'original';

  @override
  String chatWritesIn(String language) {
    return 'Writing in $language';
  }

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatConfirmTitle => 'A logist selected you for this cargo';

  @override
  String get chatConfirmSubtitle =>
      'Confirm — the deal will be locked in, and you\'ll receive a review and rating';

  @override
  String get chatConfirmButton => 'Confirm the trip';

  @override
  String get chatQuickReplyAtPlace => 'I\'m on site';

  @override
  String get chatQuickReplyLoaded => 'Loaded';

  @override
  String get chatQuickReplyLate1h => 'Running 1 hour late';

  @override
  String get wholeCountrySuffix => 'whole country';

  @override
  String get searchCityCountryHint => 'Start typing a city or country';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileRatingLabel => 'Rating';

  @override
  String get profileVerified => 'Verified';

  @override
  String get profileNotVerified => 'Not verified';

  @override
  String get profileLanguage => 'Язык · Тіл · 语言 · Language';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileCompanyName => 'Company';

  @override
  String get profileMembers => 'Employees';

  @override
  String get profileMyDevices => 'My devices';

  @override
  String get companySetPasswordTitle => 'Sign-in password';

  @override
  String get companySetPasswordHint => 'Change your sign-in password';

  @override
  String get companySetPasswordTooShort => 'At least 8 characters';

  @override
  String get devicesTitle => 'My devices';

  @override
  String get devicesCurrentBadge => 'Current device';

  @override
  String get devicesLogoutThis => 'Log out on this device';

  @override
  String get devicesLogoutAllOthers => 'Log out everywhere else';

  @override
  String get devicesLogoutAllOthersConfirm =>
      'All other devices will be logged out. Continue?';

  @override
  String get devicesEmpty => 'No active devices';

  @override
  String get adminLoginLockedOut =>
      'Too many failed attempts, try again in 15 minutes';

  @override
  String get languageKk => 'Қазақша';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageZh => '中文';

  @override
  String get navFeed => 'Cargo';

  @override
  String get navDeals => 'Deals';

  @override
  String get navProfile => 'Profile';

  @override
  String get navCargos => 'Cargo';

  @override
  String get navResponses => 'Responses';

  @override
  String get navDrivers => 'Drivers';

  @override
  String driversAtPointTitle(String point) {
    return 'Who\'s at $point';
  }

  @override
  String get driversAtPointSubtitle =>
      'Drivers who announced their arrival in advance';

  @override
  String driversAtPointDispatchFrom(String point) {
    return 'Cargo dispatch point: $point';
  }

  @override
  String get driversAtPointPickDate => 'Pick a date';

  @override
  String driversAtPointCountAtPlace(int count) {
    return 'On site now: $count';
  }

  @override
  String get driversAtPointEmpty => 'No one\'s on site yet';

  @override
  String get driversAtPointFilterCountry => 'Country';

  @override
  String get driversAtPointFilterBodyType => 'Body type';

  @override
  String get driversAtPointFilterMinCapacity => 'From 20 t';

  @override
  String get driversAtPointFilterVerifiedOnly => 'Verified only';

  @override
  String get driversAtPointInvite => 'Invite to cargo';

  @override
  String get driversAtPointPickCargo => 'Choose cargo';

  @override
  String get driversAtPointNoCargos => 'Publish a cargo first';

  @override
  String get driversAtPointInviteSent => 'Invitation sent';

  @override
  String driversAtPointArrivedAt(String time) {
    return 'On site since $time';
  }

  @override
  String driversAtPointPlannedAt(String time) {
    return 'Arriving $time';
  }

  @override
  String get driversAtPointToday => 'Today';

  @override
  String get adminLoginTitle => 'Admin sign-in';

  @override
  String get adminLoginEmailLabel => 'Email';

  @override
  String get adminLoginPasswordLabel => 'Password';

  @override
  String get adminLoginSubmit => 'Sign in';

  @override
  String get adminDashboardTitle => 'Overview';

  @override
  String get adminStatDrivers => 'Drivers';

  @override
  String get adminStatCompanies => 'Companies';

  @override
  String get adminStatCargosPublished => 'Active cargo';

  @override
  String get adminStatDealsActive => 'Deals in progress';

  @override
  String get adminStatDealsDelivered => 'Deals delivered';

  @override
  String get adminStatPendingDocs => 'Documents pending review';

  @override
  String get adminStatOpenComplaints => 'Open complaints';

  @override
  String get adminNavDashboard => 'Overview';

  @override
  String get adminNavVerification => 'Verification';

  @override
  String get adminNavComplaints => 'Complaints';

  @override
  String get adminNavCompanies => 'Companies';

  @override
  String get adminNavDrivers => 'Drivers';

  @override
  String get adminNavReference => 'Reference data';

  @override
  String get adminVerificationTitle => 'Documents to review';

  @override
  String get adminVerificationEmpty => 'All reviewed 👍';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminReject => 'Reject';

  @override
  String get adminRejectReasonLabel => 'Rejection reason';

  @override
  String get adminComplaintsTitle => 'Complaints';

  @override
  String get adminComplaintsEmpty => 'No complaints';

  @override
  String get adminResolve => 'Resolved';

  @override
  String get adminMarkInReview => 'In review';

  @override
  String get adminCompaniesTitle => 'Companies';

  @override
  String get adminDriversTitle => 'Drivers';

  @override
  String get adminVerified => 'Verified';

  @override
  String get adminNotVerified => 'Not verified';

  @override
  String get adminReferenceTitle => 'Reference data';

  @override
  String get adminPendingCitiesTab => 'New cities';

  @override
  String get adminPendingCitiesEmpty => 'No new cities from users';

  @override
  String get adminMergeCity => 'Merge';

  @override
  String get adminMergeCityTarget => 'City to merge into';

  @override
  String get adminCitySubmittedBy => 'Submitted by';

  @override
  String get adminCityRegion => 'Region';

  @override
  String get adminAddBodyType => 'Add body type';

  @override
  String get adminAddPermit => 'Add permit';

  @override
  String get adminAddPoint => 'Add loading point';

  @override
  String get adminPointCity => 'City';

  @override
  String get adminNameKk => 'Name (kk)';

  @override
  String get adminNameRu => 'Name (ru)';

  @override
  String get adminNameZh => 'Name (zh)';

  @override
  String get adminCode => 'Code';

  @override
  String get adminActive => 'Active';

  @override
  String get adminInactive => 'Inactive';

  @override
  String get accountBlockedMessage =>
      'Your account has been blocked. Contact support';

  @override
  String get adminSearchCompanyHint => 'Name, email, registration number';

  @override
  String get adminSearchDriverHint => 'Name, phone, license plate';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterPending => 'Pending';

  @override
  String get adminFilterVerified => 'Verified';

  @override
  String get adminFilterBlocked => 'Blocked';

  @override
  String get adminCompaniesEmpty => 'No companies found';

  @override
  String get adminDriversEmpty => 'No drivers found';

  @override
  String get adminColName => 'Name';

  @override
  String get adminColOwner => 'Owner';

  @override
  String get adminColEmployees => 'Employees';

  @override
  String get adminColCargos => 'Active cargo';

  @override
  String get adminColStatus => 'Status';

  @override
  String get adminColRating => 'Rating';

  @override
  String get adminColDeals => 'Deals';

  @override
  String get adminColPhone => 'Phone';

  @override
  String get adminColCity => 'City';

  @override
  String get adminColVehicle => 'Vehicle';

  @override
  String get adminBlockedBadge => 'Blocked';

  @override
  String adminPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get adminBlockConfirmTitle => 'Block this driver?';

  @override
  String get adminBlockCompanyConfirmTitle => 'Block this company?';

  @override
  String get adminBlock => 'Block';

  @override
  String get adminBlockCompany => 'Block company';

  @override
  String get adminUnblockConfirmTitle => 'Unblock?';

  @override
  String get adminUnblock => 'Unblock';

  @override
  String get adminVerifyMissingDocsError =>
      'Not all required documents are approved — check \"verified personally\" and try again';

  @override
  String get adminResetPasswordConfirmTitle => 'Reset the owner\'s password?';

  @override
  String get adminResetPasswordDialogTitle => 'Temporary password';

  @override
  String get adminResetPassword => 'Reset password';

  @override
  String get adminCopied => 'Copied';

  @override
  String get adminToggleVerification => 'Change verification status';

  @override
  String get adminStatComplaints => 'Complaints';

  @override
  String get adminStatCancellations => 'Cancellations';

  @override
  String get adminStatCalls => 'Calls';

  @override
  String get adminDocuments => 'Documents';

  @override
  String get adminNoDocuments => 'No documents';

  @override
  String get adminLegalDetails => 'Legal details';

  @override
  String get adminInvites => 'Invites';

  @override
  String get adminInviteUsed => 'Used';

  @override
  String get adminTabCargos => 'Cargo';

  @override
  String get adminTabDeals => 'Deals';

  @override
  String get adminTabReviews => 'Reviews';

  @override
  String get adminTabLog => 'Log';

  @override
  String get adminNoCargos => 'No cargo';

  @override
  String get adminNoDeals => 'No deals';

  @override
  String get adminNoReviews => 'No reviews';

  @override
  String get adminNoLog => 'No entries';

  @override
  String get adminEndSessionsConfirmTitle => 'End all sessions?';

  @override
  String get adminEndSessions => 'End sessions';

  @override
  String adminWithUsSince(String date) {
    return 'With us since $date';
  }

  @override
  String adminLastLogin(String date) {
    return 'Last login: $date';
  }

  @override
  String get adminReasonLabel => 'Reason';

  @override
  String get adminVerifyDialogTitle => 'Mark as Verified';

  @override
  String get adminUnverifyDialogTitle => 'Remove Verified status';

  @override
  String get adminForceVerifyCheckbox => 'I verified the documents personally';

  @override
  String get adminBlacklistMatchTitle => 'Blacklist match';

  @override
  String get adminBlacklistMatchIntro =>
      'Active blocks found among this profile\'s identifiers:';

  @override
  String get adminBlacklistMatchOverride => 'Confirm despite the blacklist';

  @override
  String get adminRejectPresetUnreadable => 'Unreadable photo';

  @override
  String get adminRejectPresetExpired => 'Document expired';

  @override
  String get adminRejectPresetMismatch => 'Name mismatch';

  @override
  String get adminRejectPresetOther => 'Other / reason';

  @override
  String get adminDocTypeCompanyRegistration => 'Registration certificate';

  @override
  String get adminDocTypeIdentity => 'Identity document';

  @override
  String get adminDocTypeOther => 'Other document';

  @override
  String get adminRotate => 'Rotate';

  @override
  String get adminComplaintReporter => 'Reporter';

  @override
  String get adminComplaintTarget => 'Complaint target';

  @override
  String get adminAttentionTitle => 'Needs attention';

  @override
  String get adminAttentionEmpty => 'All clear — nothing needs attention';

  @override
  String adminAttentionPendingVerification(int count) {
    return 'Pending verification: $count people';
  }

  @override
  String adminAttentionOpenComplaints(int count) {
    return 'Open complaints: $count';
  }

  @override
  String adminAttentionStaleDeals(int count) {
    return 'Deals stuck > 3 days: $count';
  }

  @override
  String adminAttentionUnverifiedCompanies(int count) {
    return 'Unverified companies: $count';
  }

  @override
  String adminAttentionPendingCities(int count) {
    return 'New cities: $count';
  }

  @override
  String get adminRecentEventsTitle => 'Recent events';

  @override
  String get adminAuditLogLink => 'Log →';

  @override
  String get adminAuditLogTitle => 'Action log';

  @override
  String get adminNoEvents => 'No events';

  @override
  String get adminPeriodLabel => 'Period:';

  @override
  String get adminPeriodToday => 'Today';

  @override
  String get adminPeriod7d => '7 days';

  @override
  String get adminPeriod30d => '30 days';

  @override
  String get adminStatOnSiteToday => 'On site today';

  @override
  String adminStatOnSiteWeek(int count) {
    return 'This week: $count';
  }

  @override
  String get adminGlobalSearchHint =>
      'Search: name, phone, email, plate, cargo/deal #';

  @override
  String get adminSearchNoResults => 'No results';

  @override
  String get adminNavCargos => 'Cargo';

  @override
  String get adminNavDeals => 'Deals';

  @override
  String get adminNavSettings => 'Settings';

  @override
  String get adminCargosTitle => 'Cargo';

  @override
  String get adminCargosEmpty => 'No cargo found';

  @override
  String get adminDealsTitle => 'Deals';

  @override
  String get adminDealsEmpty => 'No deals found';

  @override
  String get adminFilterActive => 'Active';

  @override
  String get adminFilterStale => 'Stuck > 3 days';

  @override
  String get adminFilterOnSite => 'On site';

  @override
  String get adminColRoute => 'Route';

  @override
  String get adminColBodyType => 'Body type';

  @override
  String get adminColPrice => 'Price';

  @override
  String get adminColCompany => 'Company';

  @override
  String get adminColDriver => 'Driver';

  @override
  String get adminColResponses => 'Responses';

  @override
  String get adminColPublished => 'Published';

  @override
  String get adminColCreated => 'Created';

  @override
  String get adminColStale => 'Stuck';

  @override
  String adminStaleDays(int days) {
    return '$days d.';
  }

  @override
  String get adminSettingsEmpty => 'No settings yet';

  @override
  String get adminVerificationTabDrivers => 'Drivers';

  @override
  String get adminVerificationTabCompanies => 'Companies';

  @override
  String get adminVerificationNoSelection =>
      'Select a person or company from the queue on the left';

  @override
  String adminVerificationReasonNew(int count) {
    return 'New · $count documents';
  }

  @override
  String adminVerificationReasonResubmitted(String type) {
    return 'Resubmitted: $type';
  }

  @override
  String get adminVerificationReasonVehicleChanged => 'Changed vehicle';

  @override
  String get adminVerificationOpenCard => 'Open profile →';

  @override
  String get adminVerificationCrossCheckTitle => 'Cross-check with profile';

  @override
  String get adminCrossCheckName => 'Name ↔ driver\'s license';

  @override
  String get adminCrossCheckPhoto => 'Selfie face ↔ license photo';

  @override
  String get adminCrossCheckPlate => 'Plate number ↔ tractor registration';

  @override
  String get adminCrossCheckTrailerPlate => 'Trailer ↔ trailer registration';

  @override
  String get adminCrossCheckCompanyName => 'Name ↔ license';

  @override
  String get adminCrossCheckCompanyTaxId => 'Registration No. ↔ license';

  @override
  String get adminCrossCheckMatch => 'Matches';

  @override
  String get adminCrossCheckMismatch => 'Mismatch';

  @override
  String get adminConfirmDriverButton => 'Confirm driver';

  @override
  String get adminConfirmCompanyButton => 'Confirm company';

  @override
  String get adminReturnForReworkButton => 'Return for rework';

  @override
  String get adminReturnForReworkDialogTitle => 'Return for rework';

  @override
  String get adminReturnForReworkNoteLabel => 'Note (what to reshoot)';

  @override
  String get adminVerificationMissingDocsHint =>
      'Mark all required documents as OK to enable confirmation';

  @override
  String get adminVerificationCompareWithSelfie => 'Compare with selfie';

  @override
  String get adminRecognitionTitle => 'Recognized';

  @override
  String get adminRecognitionSkipped => 'OCR unavailable — review manually';

  @override
  String get adminRecognitionPending => 'Recognition queued…';

  @override
  String get adminRecognitionFailed => 'Recognition failed';

  @override
  String get adminRecognitionMatchOk => 'Verified';

  @override
  String get adminRecognitionNeedsReview => 'Needs review';

  @override
  String get adminRecognitionDuplicate => 'Duplicate with another owner';

  @override
  String get adminRecognitionBlacklisted => 'Blacklisted';

  @override
  String get adminRecognitionBlacklistBanner =>
      'Matches the blacklist — cannot be verified without an explicit decision';

  @override
  String get adminRecognitionChecksumHint => 'check digit is valid';

  @override
  String get adminRecognitionEditValue => 'Edit value';

  @override
  String get adminRecognitionFieldFullName => 'Full name';

  @override
  String get adminRecognitionFieldIin => 'ID number';

  @override
  String get adminRecognitionFieldLicenseNumber => 'License number';

  @override
  String get adminRecognitionFieldExpiryDate => 'Expiry date';

  @override
  String get adminRecognitionFieldPlateNumber => 'Plate number';

  @override
  String get adminRecognitionFieldVin => 'VIN';

  @override
  String get adminRecognitionFieldBrand => 'Brand';

  @override
  String get adminRecognitionFieldCapacityTons => 'Capacity, t';

  @override
  String get adminRecognitionFieldCompanyName => 'Company name';

  @override
  String get adminRecognitionFieldBin => 'Business ID (BIN)';

  @override
  String get adminRecognitionFieldUscc => 'Unified Social Credit Code (USCC)';

  @override
  String get adminIdentifiersCardTitle => 'Identifiers';

  @override
  String get adminIdentifierBlockHistoryTitle => 'Block history';

  @override
  String get adminIdentifierLifted => 'Lifted';

  @override
  String get adminIdentifierActive => 'Active';

  @override
  String get adminIdentifierReveal => 'Show';

  @override
  String get adminRejectPresetPlateMismatch => 'Plate number mismatch';

  @override
  String get adminCargoUnpublish => 'Unpublish';

  @override
  String get adminCargoUnpublishDialogTitle => 'Unpublish this cargo';

  @override
  String get adminCargoEdit => 'Edit';

  @override
  String get adminCargoEditDialogTitle => 'Edit cargo';

  @override
  String get adminCargoPublishedAt => 'Published';

  @override
  String get adminCargoExpiresAt => 'Expires';

  @override
  String get adminCargoArchivedAt => 'Unpublished';

  @override
  String get adminCargoTabResponses => 'Responses';

  @override
  String get adminNoResponses => 'No responses yet';

  @override
  String get adminDealCancel => 'Cancel deal';

  @override
  String get adminDealCancelDialogTitle => 'Cancel this deal';

  @override
  String get adminDealFixStatus => 'Fix status';

  @override
  String get adminDealFixStatusDialogTitle => 'Fix deal status';

  @override
  String get adminDealOpenCargo => 'Cargo →';

  @override
  String adminDealCancelledBy(String role) {
    return 'Cancelled by $role';
  }

  @override
  String get adminDealStatusHistoryTitle => 'Status history';

  @override
  String get adminDealTabChat => 'Chat';

  @override
  String get adminDealTabCalls => 'Calls';

  @override
  String get adminDealShowChat => 'Show chat';

  @override
  String get adminNoChat => 'No messages';

  @override
  String get adminNoCalls => 'No calls yet';

  @override
  String get adminContactEventCall => 'Call';

  @override
  String get adminContactEventWhatsapp => 'WhatsApp';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get adminEdit => 'Edit';

  @override
  String get adminTransferOwnershipTitle => 'Transfer ownership';

  @override
  String get adminDemoteToLogistTitle => 'Demote to logist';

  @override
  String get adminLastOwnerError =>
      'Can\'t — this is the company\'s last owner';

  @override
  String get adminRemoveMemberTitle => 'Remove employee';

  @override
  String get adminRemoveMember => 'Remove';

  @override
  String get adminChangeMemberEmailTitle => 'Change employee email';

  @override
  String get adminEmailTakenError => 'This email is already in use';

  @override
  String get adminCompanyCity => 'City';

  @override
  String get adminLegalAddress => 'Legal address';

  @override
  String get adminTaxId => 'Registration No.';

  @override
  String get adminPhoneChangeWarning =>
      'Saving will end all of the driver\'s sessions';

  @override
  String get adminVehicleBrand => 'Brand';

  @override
  String get adminVehicleTractorTitle => 'Tractor';

  @override
  String get adminVehicleTrailerTitle => 'Trailer';

  @override
  String get adminVehicleLengthM => 'Length, m';

  @override
  String get adminNameEn => 'Name (en)';

  @override
  String get adminSortOrder => 'Sort order';

  @override
  String get adminLat => 'Latitude';

  @override
  String get adminLng => 'Longitude';

  @override
  String get adminCitiesTab => 'Cities';

  @override
  String get adminSettingDefaultCity => 'Default location';

  @override
  String get adminSettingNotSet => 'Not set';

  @override
  String get adminSettingHomeRadius => '\"Near home\" radius, km';

  @override
  String get adminUnitKm => 'km';

  @override
  String get adminSettingCargoArchiveDays =>
      'Cargo archive period without responses';

  @override
  String get adminComplaintResolutionTitle => 'Resolution';

  @override
  String get adminComplaintResolutionNoteLabel => 'Reply to the reporter';

  @override
  String get adminComplaintSelectHint =>
      'Select a complaint from the queue on the left';

  @override
  String get adminComplaintTabNew => 'New';

  @override
  String get adminComplaintTabInReview => 'In review';

  @override
  String get adminComplaintTabClosed => 'Closed';

  @override
  String get adminComplaintMineFilter => 'Mine';

  @override
  String adminComplaintMoreThisMonth(int count) {
    return '$count more this month';
  }

  @override
  String get adminComplaintTakeOver => 'Take over';

  @override
  String adminComplaintAssignedTo(String name) {
    return 'Assigned to $name';
  }

  @override
  String get adminComplaintReturnToNew => 'Return to new';

  @override
  String get adminComplaintResolveButton => 'Resolve';

  @override
  String get adminComplaintResolutionDismissed => 'Not confirmed';

  @override
  String get adminComplaintResolutionWarned => 'Warn';

  @override
  String get adminComplaintResolutionCargoUnpublished => 'Unpublish cargo';

  @override
  String get adminComplaintResolutionBlocked => 'Block';

  @override
  String get adminStatClosedOutside => 'Found outside Lubao';

  @override
  String adminStatClosedOutsideHint(int outside, int total) {
    return '$outside of $total closed';
  }

  @override
  String get cargoCloseDialogTitle => 'Close cargo';

  @override
  String get cargoCloseFoundInApp => 'Found a driver in Lubao';

  @override
  String get cargoCloseNoCandidates =>
      'No drivers with a response, call or chat yet';

  @override
  String get cargoCloseDriverLabel => 'Driver';

  @override
  String get cargoCloseFoundOutside => 'Found outside Lubao';

  @override
  String get cargoCloseCancelled => 'Cargo cancelled';

  @override
  String get cargoCloseConfirm => 'Close';

  @override
  String get cargoClosed => 'Cargo closed';

  @override
  String get cargoClose => 'Close cargo';

  @override
  String get navChats => 'Chats';

  @override
  String get chatsTabTitle => 'Chats';

  @override
  String get chatsEmpty => 'No chats yet';

  @override
  String get profileNotificationSettings => 'Notifications';

  @override
  String get notificationSettingsTitle => 'Notifications';

  @override
  String get notificationSettingsHint =>
      'A disabled group will not send push for these events';

  @override
  String get notificationGroupNewCargoMatch => 'New matching cargo';

  @override
  String get notificationGroupCargoInvite => 'Cargo invitation';

  @override
  String get notificationGroupChatMessage => 'New chat message';

  @override
  String get notificationGroupNewResponse => 'Driver response';

  @override
  String get notificationGroupNewDriverDigest => 'New drivers at point';

  @override
  String get notificationGroupDealStatus => 'Deal status change';

  @override
  String get notificationGroupVerification => 'Document verification';

  @override
  String get notificationGroupAgreedCheck => '\"Agreed?\" check';

  @override
  String get companyWecomTitle => 'WeCom bot';

  @override
  String get companyWecomHint =>
      'WeCom group bot webhook URL — new response and deal notifications will be sent to your group';

  @override
  String get companyWecomUrlLabel => 'Webhook URL';

  @override
  String get companyWecomTestButton => 'Test';

  @override
  String get companyWecomTestSuccess => 'Test message sent';

  @override
  String get companyWecomTestError => 'Failed to send — check the URL';

  @override
  String get chatTranslationFailed => 'Translation unavailable';

  @override
  String get chatTranslationRetry => 'retry';

  @override
  String get adminTranslationSettingsTitle => 'Chat translation';

  @override
  String get adminTranslationEnabledLabel => 'Enabled';

  @override
  String get adminTranslationProviderLabel => 'Provider';

  @override
  String get adminTranslationModelLabel => 'Model';

  @override
  String get adminTranslationRequests7dLabel => 'Requests in 7 days';

  @override
  String get adminTranslationTokens7dLabel => 'Tokens in 7 days';

  @override
  String get adminAuditActionAdminViewedChat => 'Admin opened the chat';

  @override
  String get adminAuditActionCargoUnpublished => 'Cargo unpublished';

  @override
  String get adminAuditActionCargoUpdated => 'Cargo updated';

  @override
  String get adminAuditActionCityUpdated => 'City updated';

  @override
  String get adminAuditActionCompanyBlocked => 'Company blocked';

  @override
  String get adminAuditActionCompanyMemberEmailChanged =>
      'Employee email changed';

  @override
  String get adminAuditActionCompanyMemberRemoved =>
      'Employee removed from company';

  @override
  String get adminAuditActionCompanyMemberRoleChanged =>
      'Employee role changed';

  @override
  String get adminAuditActionCompanyPasswordReset => 'Company password reset';

  @override
  String get adminAuditActionCompanyReturnedForRework =>
      'Company documents returned for rework';

  @override
  String get adminAuditActionCompanyUnblocked => 'Company unblocked';

  @override
  String get adminAuditActionCompanyUnverified => 'Company unverified';

  @override
  String get adminAuditActionCompanyUpdated => 'Company details updated';

  @override
  String get adminAuditActionCompanyVerified => 'Company verified';

  @override
  String get adminAuditActionComplaintAssigned => 'Complaint taken into work';

  @override
  String get adminAuditActionComplaintResolved => 'Complaint resolved';

  @override
  String get adminAuditActionComplaintUnassigned =>
      'Complaint returned to the queue';

  @override
  String get adminAuditActionDealCancelledByAdmin => 'Deal cancelled by admin';

  @override
  String get adminAuditActionDealStatusFixed => 'Deal status fixed';

  @override
  String get adminAuditActionDriverReturnedForRework =>
      'Driver documents returned for rework';

  @override
  String get adminAuditActionDriverUnverified => 'Driver unverified';

  @override
  String get adminAuditActionDriverUpdated => 'Driver details updated';

  @override
  String get adminAuditActionDriverVerified => 'Driver verified';

  @override
  String get adminAuditActionPointUpdated => 'Point updated';

  @override
  String get adminAuditActionSessionsRevoked => 'Sessions revoked';

  @override
  String get adminAuditActionSettingChanged => 'Setting changed';

  @override
  String get adminAuditActionUserBlocked => 'User blocked';

  @override
  String get adminAuditActionUserUnblocked => 'User unblocked';

  @override
  String get adminAuditActionBodyTypeUpdated => 'Body type updated';

  @override
  String get adminAuditActionPermitUpdated => 'Permit updated';

  @override
  String get adminAuditFieldDestinationCountry => 'Destination country';

  @override
  String get adminAuditFieldDestinationCity => 'Destination city';

  @override
  String get adminAuditFieldBodyType => 'Body type';

  @override
  String get adminAuditFieldWeight => 'Weight, kg';

  @override
  String get adminAuditFieldVolume => 'Volume, m³';

  @override
  String get adminAuditFieldPhotos => 'Photos';

  @override
  String get adminAuditFieldPrice => 'Price';

  @override
  String get adminAuditFieldCurrency => 'Currency';

  @override
  String get adminAuditFieldReadyDate => 'Ready date';

  @override
  String get adminAuditFieldDescription => 'Description';

  @override
  String get adminAuditFieldName => 'Name';

  @override
  String get adminAuditFieldNameRu => 'Name (Russian)';

  @override
  String get adminAuditFieldCountry => 'Country';

  @override
  String get adminAuditFieldCity => 'City';

  @override
  String get adminAuditFieldLegalAddress => 'Legal address';

  @override
  String get adminAuditFieldTaxId => 'Tax ID';

  @override
  String get adminAuditFieldFullName => 'Full name';

  @override
  String get adminAuditFieldPhone => 'Phone';

  @override
  String get adminAuditFieldHomeCity => 'Home city';

  @override
  String get adminAuditFieldAnyCountry => 'Any country';

  @override
  String get adminAuditFieldCountries => 'Countries';

  @override
  String get adminAuditFieldPermits => 'Permits';

  @override
  String get adminAuditFieldVehicle => 'Vehicle';

  @override
  String get adminAuditFieldPlateNumber => 'Plate number';

  @override
  String get adminAuditFieldCapacity => 'Capacity, t';

  @override
  String get adminAuditFieldLength => 'Length, m';

  @override
  String get adminAuditFieldBrand => 'Brand';

  @override
  String get adminAuditFieldIsActive => 'Active';

  @override
  String get adminAuditFieldSortOrder => 'Sort order';

  @override
  String get adminAuditFieldStatus => 'Status';

  @override
  String get postCargoVerificationRequired =>
      'Publishing cargo will open after the company is verified — upload the registration certificate in the company profile';

  @override
  String get companyNotVerifiedBannerText =>
      'The company is not verified. You can view drivers and message them, but you can\'t publish cargo — upload the registration certificate below';

  @override
  String get companyEditTitle => 'Company details';

  @override
  String get companyEditCityLabel => 'City';

  @override
  String get companyEditLegalAddressLabel => 'Legal address';

  @override
  String get companyEditTaxIdLabel => 'Registration number (统一社会信用代码 / BIN)';

  @override
  String get companyEditTaxIdError =>
      'Invalid registration number format for your country';

  @override
  String get myProfileTitle => 'My profile';

  @override
  String get myProfileNameLabel => 'Name';

  @override
  String get myProfilePhoneLabel => 'Phone for drivers';

  @override
  String get myProfileWechatLabel => 'WeChat';

  @override
  String get myProfileNameError => 'Enter a name';

  @override
  String get myProfileNotSetYet => 'Fill in your profile';

  @override
  String get companyVerificationTitle => 'Verify the company';

  @override
  String get companyVerificationHint =>
      'Upload the registration certificate — we\'ll cross-check it with the official registry and call the registered number, usually within 1 business day';

  @override
  String get companyVerificationStatusNone => 'Document not uploaded';

  @override
  String get companyVerificationStatusPending => 'Under review';

  @override
  String get companyVerificationStatusRejected => 'Needs to be re-taken';

  @override
  String get adminNavSearch => 'Search';

  @override
  String get adminNavMore => 'More';

  @override
  String get garageTitle => 'My garage';

  @override
  String get garageTractorsSection => 'TRACTORS';

  @override
  String get garageTrailersSection => 'TRAILERS';

  @override
  String get garageVerified => 'verified';

  @override
  String get garagePending => 'under review';

  @override
  String get garageAddedYesterday => 'added yesterday';

  @override
  String get garageAddVehicle => 'Add a vehicle';

  @override
  String get garageEmptyTractors => 'No tractors yet';

  @override
  String get garageEmptyTrailers => 'No trailers yet';

  @override
  String get garageOcrHint =>
      'Photograph the registration certificate — the plate and VIN fill in automatically. Review and submit.';

  @override
  String get garageArchive => 'Archive';

  @override
  String get garageArchived => 'Vehicle archived';

  @override
  String get garageKindTitle => 'What kind of vehicle?';

  @override
  String get garageKindTractor => 'Tractor';

  @override
  String get garageKindTrailer => 'Trailer';

  @override
  String get garageVin => 'VIN';

  @override
  String get garageLength => 'Length, m';

  @override
  String get garagePhotoRequired => 'Photograph the registration certificate';

  @override
  String get garageSubmit => 'Submit for review';

  @override
  String get garageAddFailed => 'Couldn\'t add the vehicle';

  @override
  String get garageFieldRequired => 'This field is required';

  @override
  String get garageComboTitle => 'What are you driving?';

  @override
  String get garageComboTractorLabel => 'Tractor';

  @override
  String get garageComboTrailerLabel => 'Trailer';

  @override
  String get garageComboPendingBadge => 'under review';

  @override
  String get garageComboEmpty =>
      'Your garage is empty — add a vehicle in your profile';

  @override
  String get garageGoToGarage => 'My garage';
}
