// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'lubao_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class LubaoLocalizationsZh extends LubaoLocalizations {
  LubaoLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Lubao';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonNext => '下一步';

  @override
  String get commonBack => '返回';

  @override
  String get commonDone => '完成';

  @override
  String get commonRetry => '重试';

  @override
  String get commonLoading => '加载中...';

  @override
  String get commonError => '出错了';

  @override
  String get errorNetwork => '无法连接服务器，请检查网络后重试';

  @override
  String get errorServer => '服务器暂时不可用，请稍后重试';

  @override
  String get errorForbidden => '您无法执行此操作';

  @override
  String get errorInvalidData => '请检查填写的内容';

  @override
  String errorFieldMax(String field, String limit) {
    return '$field：不能超过 $limit';
  }

  @override
  String errorFieldMin(String field, String limit) {
    return '$field：不能小于 $limit';
  }

  @override
  String errorFieldMaxLength(String field, String limit) {
    return '$field：不能超过 $limit 个字符';
  }

  @override
  String errorFieldInvalid(String field) {
    return '$field：请检查填写内容';
  }

  @override
  String fieldMax(String limit) {
    return '不能超过 $limit';
  }

  @override
  String get fieldPositive => '必须大于 0';

  @override
  String get fieldNotNumber => '请输入数字';

  @override
  String fieldMin(String limit) {
    return '不能小于 $limit';
  }

  @override
  String get fieldRequired => '必填项';

  @override
  String errorFieldRequired(String field) {
    return '$field：必填';
  }

  @override
  String get errorSessionExpired => '登录已过期，请重新登录';

  @override
  String get chatOpenFailed => '无法打开聊天';

  @override
  String get commonSeeAll => '查看全部';

  @override
  String get commonCall => '拨打电话';

  @override
  String get commonWhatsApp => 'WhatsApp';

  @override
  String get commonChat => '聊天';

  @override
  String get commonSend => '发送';

  @override
  String get commonSearch => '搜索';

  @override
  String get commonYes => '是';

  @override
  String get commonNo => '否';

  @override
  String get roleSelectTitle => '您是?';

  @override
  String get roleSelectSubtitle => '请选择您使用路宝的身份';

  @override
  String get roleDriver => '司机';

  @override
  String get roleCompany => '物流公司';

  @override
  String get driverLoginTitle => '司机登录';

  @override
  String get driverLoginPhoneLabel => '手机号码';

  @override
  String get driverLoginPhoneHint => '+7 700 000 00 00';

  @override
  String get driverLoginSendCode => '获取验证码';

  @override
  String get driverLoginCodeLabel => '短信验证码';

  @override
  String get driverLoginVerify => '登录';

  @override
  String get driverLoginCountryLabel => '国家';

  @override
  String driverOtpSubtitle(String phone) {
    return '验证码已发送至 $phone';
  }

  @override
  String get driverOtpResend => '重新发送验证码';

  @override
  String get driverOtpInvalidCode => '验证码错误';

  @override
  String get driverOtpTooManyAttempts => '尝试次数过多——请获取新验证码';

  @override
  String get companyRegisterTitle => '新建公司';

  @override
  String get companyRegisterOwnerName => '您的姓名';

  @override
  String get companyRegisterCompanyName => '公司名称';

  @override
  String get companyRegisterCompanyNameRu => '俄语名称';

  @override
  String get companyRegisterNameError => '请输入名称，至少2个字符';

  @override
  String get companyRegisterCountry => '国家';

  @override
  String get companyRegisterCountryError => '请选择国家';

  @override
  String get companyRegisterOtherCountry => '其他';

  @override
  String get companyRegisterSubmit => '创建公司';

  @override
  String get companyRegisterEmailError => '请输入邮箱';

  @override
  String get companyRegisterPasswordError => '至少8个字符';

  @override
  String get companyRegisterEmailTaken => '该邮箱已注册。登录？';

  @override
  String get companyLoginTitle => '公司登录';

  @override
  String get companyLoginEmailLabel => '邮箱';

  @override
  String get companyLoginVerify => '登录';

  @override
  String get companyLoginLockedOut => '尝试次数过多，请15分钟后重试';

  @override
  String get companyLoginShowPassword => '显示密码';

  @override
  String get companyLoginHidePassword => '隐藏密码';

  @override
  String get companyLoginRegisterLink => '注册';

  @override
  String get companyLoginForgotPasswordLink => '忘记密码？';

  @override
  String get forgotPasswordTitle => '找回密码';

  @override
  String get forgotPasswordSendCode => '发送验证码';

  @override
  String get forgotPasswordCodeLabel => '邮箱验证码';

  @override
  String get forgotPasswordNewPasswordLabel => '新密码';

  @override
  String get forgotPasswordSubmit => '更改密码';

  @override
  String get forgotPasswordSuccess => '密码已更改，请用新密码登录';

  @override
  String get forgotPasswordResend => '重新发送验证码';

  @override
  String get forgotPasswordInvalidCode => '验证码错误或已过期';

  @override
  String get forgotPasswordNoEmailLink => '没收到邮件？';

  @override
  String get supportContactTitle => '联系客服';

  @override
  String get supportContactBody => '如果邮件没有送达，请通过以下方式联系我们';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportContactWechat => '微信';

  @override
  String get supportContactEmail => '邮箱';

  @override
  String get supportContactNone => '客服联系方式即将在此显示';

  @override
  String get acceptInviteTitle => '加入公司邀请';

  @override
  String acceptInviteSubtitle(String companyName, String role) {
    return '您被邀请加入「$companyName」——角色：$role';
  }

  @override
  String get acceptInviteNameLabel => '您的姓名';

  @override
  String get acceptInvitePhoneLabel => '电话（供司机联系）';

  @override
  String get acceptInviteWechatLabel => '微信（可选）';

  @override
  String get acceptInviteSubmit => '加入公司';

  @override
  String get acceptInviteInvalidToken => '邀请无效或已被使用';

  @override
  String get emailVerifyBannerText => '邮箱未验证';

  @override
  String get emailVerifyBannerAction => '验证';

  @override
  String get emailVerifyDialogTitle => '验证邮箱';

  @override
  String get emailVerifyDialogCodeLabel => '邮箱验证码';

  @override
  String get emailVerifyDialogSubmit => '验证';

  @override
  String get employeesInviteButton => '邀请员工';

  @override
  String get employeesInviteEmailLabel => '员工邮箱';

  @override
  String get employeesInviteRoleOwner => '所有者';

  @override
  String get employeesInviteRoleLogist => '物流员';

  @override
  String get employeesInviteSubmit => '生成邀请链接';

  @override
  String get employeesInviteLinkReady => '邀请链接7天内有效，复制后可通过微信/WhatsApp转发：';

  @override
  String get employeesInviteCopyLink => '复制';

  @override
  String get employeesInviteCopied => '链接已复制';

  @override
  String get driverSetupTitle => '设置个人资料';

  @override
  String get driverRegisterTitle => '注册';

  @override
  String get driverVerificationTitle => '身份认证';

  @override
  String get driverVerificationIntro => '为了响应货源和确认交易，请完成身份认证——大约需要2分钟';

  @override
  String get driverVerificationConsent =>
      '文件在哈萨克斯坦境内的Lubao服务器上进行识别。身份证号以加密方式存储，仅用于身份核实和防止被封禁用户重新注册。';

  @override
  String get driverVerificationSelfie => '自拍照';

  @override
  String get driverVerificationVehiclePassport => '牵引车行驶证';

  @override
  String get driverVerificationTrailerPassport => '挂车行驶证';

  @override
  String get driverVerificationLicense => '驾驶证';

  @override
  String get driverVerificationStatusNone => '未上传';

  @override
  String get driverVerificationStatusPending => '审核中';

  @override
  String get driverVerificationStatusApproved => '已通过';

  @override
  String get driverVerificationStatusRejected => '已拒绝';

  @override
  String get driverVerificationUploadFailed => '照片上传失败';

  @override
  String get driverVerificationRequiredPrompt => '要响应货源，请先完成身份认证——2分钟';

  @override
  String get driverVerificationRequiredAction => '去认证';

  @override
  String profileCompleteness(int percent) {
    return '资料完整度$percent%——已认证司机获得的邀请多3倍';
  }

  @override
  String driverSetupStepOf(int step, int total) {
    return '第 $step 步，共 $total 步';
  }

  @override
  String get driverSetupFullName => '姓名';

  @override
  String get driverSetupFullNameError => '请输入姓名：2-80个字母，不含数字';

  @override
  String get driverSetupHomeCityError => '请选择城市';

  @override
  String get driverSetupBodyTypeError => '请选择车厢类型';

  @override
  String get cityNotListed => '没有我的城市';

  @override
  String get addCitySettlementLabel => '居民点名称';

  @override
  String get addCitySettlementError => '请输入居民点名称';

  @override
  String get addCityRegionLabel => '州/地区';

  @override
  String get addCityRegionError => '请选择州/地区';

  @override
  String get addCitySubmit => '继续';

  @override
  String get driverSetupHomeCity => '常住城市';

  @override
  String get driverSetupCountries => '运输方向';

  @override
  String get driverSetupAnyCountry => '任意国家';

  @override
  String get driverSetupPermits => '资质证件';

  @override
  String get driverSetupVehicleBodyType => '车厢类型';

  @override
  String get driverSetupVehiclePlate => '车牌号';

  @override
  String get driverSetupVehicleTitle => '您的车辆信息';

  @override
  String get driverSetupVehicleSubtitle => '只需填写一次——我们将据此为您匹配货源';

  @override
  String get driverSetupCapacity => '载重量';

  @override
  String get driverSetupDocuments => '车辆证件';

  @override
  String get driverSetupDirectionsTitle => '您愿意前往哪里？';

  @override
  String get driverSetupDirectionsSubtitle => '我们将优先展示这些国家的货源，随时可以更改';

  @override
  String driverSetupCountriesSelected(int count) {
    return '已选择$count个国家';
  }

  @override
  String get driverSetupSubmit => '保存并继续';

  @override
  String get driverHomeAnonsTitle => '我的位置公告';

  @override
  String driverHomeLogistsCount(int count) {
    return '附近物流公司：$count';
  }

  @override
  String driverHomeSince(String date) {
    return '到达时间：$date';
  }

  @override
  String get driverHomeCheckInEmpty => '提前通知到达时间——物流公司会提前看到您';

  @override
  String get driverHomeCheckInButton => '我已到达';

  @override
  String get driverHomeLeaveButton => '我已离开';

  @override
  String get driverHomeCancelButton => '取消';

  @override
  String get driverHomeAnnounceButton => '预告到达';

  @override
  String get driverHomeRepeatButton => '重复上次预告';

  @override
  String get driverHomeEditButton => '修改';

  @override
  String driverHomePlannedFor(String date) {
    return '预计 $date';
  }

  @override
  String get announceArrivalTitle => '预告到达';

  @override
  String get announceArrivalWhen => '何时';

  @override
  String get announceArrivalToday => '今天';

  @override
  String get announceArrivalTomorrow => '明天';

  @override
  String get announceArrivalDayAfter => '后天';

  @override
  String get announceArrivalPickDate => '选择日期';

  @override
  String get announceArrivalWhere => '地点';

  @override
  String get announceArrivalCountries => '可前往的国家';

  @override
  String get announceArrivalWaitDays => '愿意等待多久';

  @override
  String announceArrivalWaitDaysValue(int days) {
    return '$days 天';
  }

  @override
  String get announceArrivalSubmit => '发布';

  @override
  String driverHomeFeedCount(int count) {
    return '匹配货源 $count';
  }

  @override
  String get feedEmpty => '暂无合适的货源';

  @override
  String get feedSectionHome => '离家近';

  @override
  String get feedSectionSelected => '您选择的方向';

  @override
  String get feedSectionOther => '其他方向';

  @override
  String get cargoPrice => '价格';

  @override
  String get cargoWeight => '重量';

  @override
  String get cargoVolume => '体积';

  @override
  String get cargoPhotos => '照片';

  @override
  String get unitKg => '公斤';

  @override
  String get unitM3 => '立方米';

  @override
  String get unitTon => '吨';

  @override
  String get unitPallets => '托';

  @override
  String get dealVehicleFullTitle => '车辆已满载';

  @override
  String get dealVehicleNotVerified => '车辆仍在审核中——请打开车库';

  @override
  String dealVehicleFullBody(String used, String capacity, String unit) {
    return '已确认 $used／$capacity $unit。要接这单，请先完成或取消当前运输。';
  }

  @override
  String get dealVehicleFullNextTrip => '该货物装货日期不同 — 属于下一趟。请在当前运输交付后再确认。';

  @override
  String get dealVehicleFullOpenCurrent => '查看当前交易';

  @override
  String get dealCancelReasonTookAnother => '已接其他货物';

  @override
  String driverAlreadyHauling(String used, String unit) {
    return '正在承运：$used $unit';
  }

  @override
  String driverAlreadyHaulingOf(String used, String capacity, String unit) {
    return '正在承运：$used/$capacity $unit';
  }

  @override
  String get driverHaulingBusyNoWeight => '车辆已被占用（货物未填重量）';

  @override
  String driverHaulingLoading(String date) {
    return '装货 $date';
  }

  @override
  String get selectDriverVehicleFullTitle => '司机车辆已满载';

  @override
  String selectDriverVehicleFullBody(String haul) {
    return '$haul。可以选择，但司机在完成或取消当前运输前无法确认新运输。';
  }

  @override
  String get selectDriverAnywayButton => '仍然选择';

  @override
  String driverCancelShare(int cancelled, int total) {
    return '已取消 $total 笔交易中的 $cancelled 笔';
  }

  @override
  String get garageSizeTitle => '车厢尺寸';

  @override
  String get garageSizeCustom => '自定义尺寸';

  @override
  String get garageSizeLength => '内部长度（米）';

  @override
  String get garageSizeWidth => '内部宽度（米）';

  @override
  String get garageSizeHeight => '内部高度（米）';

  @override
  String get garageSizePrompt => '填写车厢尺寸 — 货源匹配更精准';

  @override
  String get garageSizeChange => '修改尺寸';

  @override
  String get postCargoPallets => '托盘数（个）';

  @override
  String postCargoFitCount(int count) {
    return '适合点上 $count 位司机';
  }

  @override
  String get cargoReadyDate => '备货日期';

  @override
  String get cargoDestination => '目的地';

  @override
  String get cargoBodyType => '车厢类型';

  @override
  String get cargoRespond => '申请接单';

  @override
  String get cargoAlreadyResponded => '您已申请';

  @override
  String get cargoDetailTitle => '货源详情';

  @override
  String get cargoDetailDescription => '描述';

  @override
  String get cargoDetailCompany => '公司';

  @override
  String get cargoDetailPriceLabel => '运费';

  @override
  String cargoDetailCompanyDeals(int count) {
    return '在Lubao完成$count笔交易';
  }

  @override
  String get cargoDetailNoReviews => '暂无评价';

  @override
  String get cargoStatusPublished => '已发布';

  @override
  String get cargoStatusArchived => '已归档';

  @override
  String get cargoStatusExpired => '已过期';

  @override
  String get cargoStatusCancelled => '已取消';

  @override
  String get dealsTitle => '我的订单';

  @override
  String get dealsEmpty => '暂无订单';

  @override
  String get dealStatusSelected => '已选定';

  @override
  String get dealStatusConfirmed => '司机已确认';

  @override
  String get dealStatusLoaded => '已装货';

  @override
  String get dealStatusInTransit => '运输中';

  @override
  String get dealStatusDelivered => '已送达';

  @override
  String get dealStatusCancelled => '已取消';

  @override
  String get dealDetailTitle => '订单详情';

  @override
  String get dealTimelineTitle => '订单状态';

  @override
  String get dealDriverLocationTitle => '司机位置';

  @override
  String get dealLocationUpdatedAt => '更新于';

  @override
  String get dealLocationNoData => '尚未获取坐标';

  @override
  String get dealConfirm => '确认';

  @override
  String get dealMarkLoaded => '标记为已装货';

  @override
  String get dealMarkInTransit => '标记为运输中';

  @override
  String get dealMarkDelivered => '标记为已送达';

  @override
  String get dealCancel => '取消订单';

  @override
  String get dealCancelReasonLabel => '取消原因';

  @override
  String get dealCancelledBy => '取消方';

  @override
  String get reviewTitle => '发表评价';

  @override
  String get reviewRatingLabel => '评分';

  @override
  String get reviewCommentLabel => '评语';

  @override
  String get reviewSubmit => '提交评价';

  @override
  String get reviewsReceivedTitle => '评价';

  @override
  String get responsesTitle => '申请列表';

  @override
  String get responsesEmpty => '暂无申请';

  @override
  String get responseSelect => '选择司机';

  @override
  String get responseReject => '拒绝';

  @override
  String get responseStatusPending => '等待中';

  @override
  String get responseStatusSelected => '已选定';

  @override
  String get responseStatusRejected => '已拒绝';

  @override
  String get responseStatusCancelled => '已取消';

  @override
  String get myCargosTitle => '我发布的货源';

  @override
  String get myCargosEmpty => '您还没有发布货源';

  @override
  String get postCargoTitle => '发布货源';

  @override
  String get postCargoDestinationError => '请选择目的地';

  @override
  String get postCargoBodyTypeError => '请选择车厢类型';

  @override
  String get postCargoPriceError => '请填写价格（数字）';

  @override
  String get postCargoDestinationCountry => '目的国家';

  @override
  String get postCargoDestinationCity => '目的城市';

  @override
  String get postCargoBodyType => '车厢类型';

  @override
  String get postCargoVolume => '体积(m³)';

  @override
  String get postCargoWeight => '重量';

  @override
  String get postCargoPhotos => '照片';

  @override
  String get postCargoAddPhotoCamera => '拍照';

  @override
  String get postCargoAddPhotoGallery => '从相册选择';

  @override
  String get postCargoRemovePhoto => '删除照片';

  @override
  String get postCargoPhotoUploadFailed => '照片上传失败';

  @override
  String get postCargoPrice => '价格';

  @override
  String get postCargoCurrency => '货币';

  @override
  String get postCargoReadyDate => '备货日期';

  @override
  String get postCargoDescription => '货源描述';

  @override
  String get postCargoSubmit => '发布';

  @override
  String get editCargoTitle => '编辑货源';

  @override
  String get cargoEdit => '编辑';

  @override
  String get cargoDelete => '删除';

  @override
  String get cargoDeleteConfirmTitle => '删除此货源？';

  @override
  String get cargoDeleteConfirmMessage => '货源将下架，响应和交易记录会保留。';

  @override
  String get cargoDeleted => '货源已删除';

  @override
  String get chatTitle => '聊天';

  @override
  String get chatInputHint => '输入消息';

  @override
  String get chatEmpty => '开始对话';

  @override
  String get chatAttachLocation => '发送我的位置';

  @override
  String get chatLocationMessagePrefix => '地图位置';

  @override
  String get chatLocationError => '无法获取位置';

  @override
  String get locationRationaleTitle => '位置';

  @override
  String get locationRationaleBody =>
      '应用仅获取一次您当前的位置，并将地图链接发送到此聊天——仅此一次。没有跟踪：不在行程中时，位置不会被共享。';

  @override
  String get locationRationaleContinue => '继续';

  @override
  String get chatLoadingPlaceTooltip => '装货地点';

  @override
  String get chatLoadingPlaceDialogTitle => '粘贴装货地点的链接';

  @override
  String get chatLoadingPlaceDialogHint => '来自百度/高德/2GIS的链接';

  @override
  String get chatLoadingPlaceMessagePrefix => '装货地点';

  @override
  String get chatLoadingPlaceLinkInvalid => '需要 https:// 链接，长度不超过 500 字符';

  @override
  String get chatTranslatedBadge => '已翻译';

  @override
  String get chatShowOriginal => '原文';

  @override
  String chatWritesIn(String language) {
    return '使用$language书写';
  }

  @override
  String get languageNameRu => '俄语';

  @override
  String get languageNameKk => '哈萨克语';

  @override
  String get languageNameZh => '中文';

  @override
  String get languageNameEn => '英语';

  @override
  String get chatToday => '今天';

  @override
  String get chatYesterday => '昨天';

  @override
  String get chatConfirmTitle => '物流公司已选择您承运此货物';

  @override
  String get chatConfirmSubtitle => '请确认——交易将被记录，您将获得评价和信誉分';

  @override
  String get chatConfirmButton => '确认承运';

  @override
  String get chatCargoReadyButton => '可以接单';

  @override
  String get chatResponseSentLabel => '已发送响应';

  @override
  String get chatWithdrawButton => '撤回';

  @override
  String get chatOfferCargoButton => '推荐货物';

  @override
  String get chatResponseClosed => '响应已关闭';

  @override
  String get chatCargoAlreadyHasDeal => '该货物已选定司机';

  @override
  String get chatOfferCargoSheetTitle => '选择货物';

  @override
  String chatSystemDriverReady(String name) {
    return '$name 已准备好承运该货物';
  }

  @override
  String chatSystemDriverSelected(String name) {
    return '已选定司机 $name 承运';
  }

  @override
  String get chatSystemResponseRejected => '物流专员拒绝了该响应';

  @override
  String get chatSystemDealConfirmed => '司机已确认运输';

  @override
  String chatSystemResponseWithdrawn(String name) {
    return '$name 已撤回响应';
  }

  @override
  String get chatSystemCargoOffered => '物流专员推荐了货物';

  @override
  String get cargoStatusInDeal => '交易中';

  @override
  String get myResponsesTitle => '我的意向';

  @override
  String get myResponsesEmpty => '暂无意向';

  @override
  String get responseStatusInvited => '已邀请';

  @override
  String get chatSystemDriverInvited => '物流方邀请司机承运此货';

  @override
  String chatSystemInvitationDeclined(String name) {
    return '$name拒绝了邀请';
  }

  @override
  String get chatSystemCargoTaken => '该货物已由其他司机承运';

  @override
  String get cargoInvitedTitle => '邀请您承运此货';

  @override
  String get cargoDecline => '拒绝';

  @override
  String get cargoNotAvailable => '货物已被占用';

  @override
  String get cargoVerifyHint => '确认运输前，请先在个人资料中完成审核';

  @override
  String get chatWaitingDriver => '等待司机回复';

  @override
  String get cargoResponseSent => '已提交意向';

  @override
  String get cargoYouAreSelected => '您已被选中';

  @override
  String get chatQuickReplyAtPlace => '我已到达';

  @override
  String get chatQuickReplyLoaded => '已装货';

  @override
  String get chatQuickReplyLate1h => '将晚到1小时';

  @override
  String get chatQuickReplyCargoReady => '货物已备好，可以装车';

  @override
  String get chatQuickReplyWhenArrive => '您什么时候能到？';

  @override
  String get chatQuickReplySendLocation => '请发一下您的位置';

  @override
  String get wholeCountrySuffix => '整个国家';

  @override
  String get searchCityCountryHint => '输入城市或国家';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileRatingLabel => '评分';

  @override
  String get profileVerified => '已认证';

  @override
  String get profileNotVerified => '未认证';

  @override
  String get profileLanguage => 'Язык · Тіл · 语言 · Language';

  @override
  String get profilePhone => '电话';

  @override
  String get profileEmail => '邮箱';

  @override
  String get profileCompanyName => '公司';

  @override
  String get profileMembers => '员工';

  @override
  String get profileMyDevices => '我的设备';

  @override
  String get companySetPasswordTitle => '登录密码';

  @override
  String get companySetPasswordHint => '更改登录密码';

  @override
  String get companySetPasswordTooShort => '至少8个字符';

  @override
  String get devicesTitle => '我的设备';

  @override
  String get devicesCurrentBadge => '当前设备';

  @override
  String get devicesLogoutThis => '退出此设备';

  @override
  String get devicesLogoutAllOthers => '退出所有其他设备';

  @override
  String get devicesLogoutAllOthersConfirm => '所有其他设备将被登出。是否继续？';

  @override
  String get devicesEmpty => '没有活跃设备';

  @override
  String get adminLoginLockedOut => '错误尝试次数过多，请15分钟后重试';

  @override
  String get languageKk => '哈萨克语';

  @override
  String get languageRu => '俄语';

  @override
  String get languageZh => '中文';

  @override
  String get navFeed => '货源';

  @override
  String get navDeals => '订单';

  @override
  String get navProfile => '我的';

  @override
  String get navCargos => '货源';

  @override
  String get navResponses => '申请';

  @override
  String get navDrivers => '司机';

  @override
  String driversAtPointTitle(String point) {
    return '$point的空闲司机';
  }

  @override
  String get driversAtPointSubtitle => '已提前通知到达的司机';

  @override
  String driversAtPointDispatchFrom(String point) {
    return '发货点：$point';
  }

  @override
  String get driversAtPointPickDate => '选择日期';

  @override
  String driversAtPointCountAtPlace(int count) {
    return '当前在场：$count';
  }

  @override
  String get driversAtPointEmpty => '暂时没有司机在场';

  @override
  String get driversAtPointFilterCountry => '国家';

  @override
  String get driversAtPointFilterBodyType => '车厢类型';

  @override
  String get driversAtPointFilterMinCapacity => '20吨以上';

  @override
  String get driversAtPointFilterVerifiedOnly => '仅显示已认证';

  @override
  String get driversAtPointInvite => '邀请承运';

  @override
  String get driversAtPointPickCargo => '选择货源';

  @override
  String get driversAtPointNoCargos => '请先发布货源';

  @override
  String get driversAtPointInviteSent => '邀请已发送';

  @override
  String driversAtPointArrivedAt(String time) {
    return '到达时间：$time';
  }

  @override
  String driversAtPointPlannedAt(String time) {
    return '预计：$time';
  }

  @override
  String get driversAtPointToday => '今天';

  @override
  String get driversAtPointTodayShort => '今';

  @override
  String get driversAtPointFilterCapacityChip => '载重';

  @override
  String get driversAtPointInviteShort => '邀请';

  @override
  String get driversAtPointFilterAll => '全部';

  @override
  String get driversAtPointFilterMinCapacityTitle => '载重';

  @override
  String driversAtPointMinCapacityLabel(int n) {
    return '$n吨以上';
  }

  @override
  String get driversAtPointPickPoint => '装货点';

  @override
  String get driversAtPointTitleShort => '司机';

  @override
  String get driversAtPointFilterVerifiedChip => '已验证';

  @override
  String driversAtPointNowAtPlace(int count) {
    return '当前在场 · $count';
  }

  @override
  String driversAtPointMoreToday(int count) {
    return '今天还有 $count 位将到';
  }

  @override
  String driversAtPointWillBeOnDay(String day, int count) {
    return '$day 将到 · $count';
  }

  @override
  String driversAtPointOnSiteAgo(String ago) {
    return '在场 · $ago';
  }

  @override
  String driversAtPointAgoMinutes(int n) {
    return '$n 分钟前';
  }

  @override
  String driversAtPointAgoHours(int n) {
    return '$n 小时前';
  }

  @override
  String get driversAtPointAgoJustNow => '刚刚';

  @override
  String driversAtPointPlannedApprox(String day, String time) {
    return '$day ~$time';
  }

  @override
  String get weekdayShort1 => '一';

  @override
  String get weekdayShort2 => '二';

  @override
  String get weekdayShort3 => '三';

  @override
  String get weekdayShort4 => '四';

  @override
  String get weekdayShort5 => '五';

  @override
  String get weekdayShort6 => '六';

  @override
  String get weekdayShort7 => '日';

  @override
  String get adminLoginTitle => '管理员登录';

  @override
  String get adminLoginEmailLabel => '邮箱';

  @override
  String get adminLoginPasswordLabel => '密码';

  @override
  String get adminLoginSubmit => '登录';

  @override
  String get adminDashboardTitle => '概览';

  @override
  String get adminStatDrivers => '司机';

  @override
  String get adminStatCompanies => '公司';

  @override
  String get adminStatCargosPublished => '在线货源';

  @override
  String get adminStatDealsActive => '进行中订单';

  @override
  String get adminStatDealsDelivered => '已完成订单';

  @override
  String get adminStatPendingDocs => '待审核文件';

  @override
  String get adminStatOpenComplaints => '待处理投诉';

  @override
  String get adminNavDashboard => '概览';

  @override
  String get adminNavVerification => '认证审核';

  @override
  String get adminNavComplaints => '投诉';

  @override
  String get adminNavCompanies => '公司';

  @override
  String get adminNavDrivers => '司机';

  @override
  String get adminNavReference => '基础数据';

  @override
  String get adminVerificationTitle => '待审核文件';

  @override
  String get adminVerificationEmpty => '全部审核完毕 👍';

  @override
  String get adminApprove => '通过';

  @override
  String get adminReject => '拒绝';

  @override
  String get adminRejectReasonLabel => '拒绝原因';

  @override
  String get adminComplaintsTitle => '投诉';

  @override
  String get adminComplaintsEmpty => '暂无投诉';

  @override
  String get adminResolve => '已解决';

  @override
  String get adminMarkInReview => '处理中';

  @override
  String get adminCompaniesTitle => '公司';

  @override
  String get adminDriversTitle => '司机';

  @override
  String get adminVerified => '已认证';

  @override
  String get adminNotVerified => '未认证';

  @override
  String get adminReferenceTitle => '基础数据';

  @override
  String get adminPendingCitiesTab => '新城市';

  @override
  String get adminPendingCitiesEmpty => '没有用户提交的新城市';

  @override
  String get adminMergeCity => '合并';

  @override
  String get adminMergeCityTarget => '合并到的城市';

  @override
  String get adminCitySubmittedBy => '提交人';

  @override
  String get adminCityRegion => '州/地区';

  @override
  String get adminAddBodyType => '添加车厢类型';

  @override
  String get adminBodySizePresetsTab => '车厢尺寸';

  @override
  String get adminAddBodySizePreset => '添加尺寸模板';

  @override
  String get adminAddPermit => '添加资质';

  @override
  String get adminAddPoint => '添加装货点';

  @override
  String get adminPointCity => '城市';

  @override
  String get adminNameKk => '名称 (kk)';

  @override
  String get adminNameRu => '名称 (ru)';

  @override
  String get adminNameZh => '名称 (zh)';

  @override
  String get adminCode => '代码';

  @override
  String get adminActive => '已启用';

  @override
  String get adminInactive => '已停用';

  @override
  String get accountBlockedMessage => '账户已被封禁。请联系客服';

  @override
  String get adminSearchCompanyHint => '名称、邮箱、注册号';

  @override
  String get adminSearchDriverHint => '姓名、电话、车牌号';

  @override
  String get adminFilterAll => '全部';

  @override
  String get adminFilterPending => '待审核';

  @override
  String get adminFilterVerified => '已验证';

  @override
  String get adminFilterBlocked => '已封禁';

  @override
  String get adminCompaniesEmpty => '未找到公司';

  @override
  String get adminDriversEmpty => '未找到司机';

  @override
  String get adminColName => '姓名';

  @override
  String get adminColOwner => '负责人';

  @override
  String get adminColEmployees => '员工';

  @override
  String get adminColCargos => '在途货源';

  @override
  String get adminColStatus => '状态';

  @override
  String get adminColRating => '评分';

  @override
  String get adminColDeals => '交易';

  @override
  String get adminColPhone => '电话';

  @override
  String get adminColCity => '城市';

  @override
  String get adminColVehicle => '车辆';

  @override
  String get adminBlockedBadge => '已封禁';

  @override
  String get adminBlockedByPhoneBadge => '号码在黑名单中';

  @override
  String adminPageOf(int page, int total) {
    return '第 $page / $total 页';
  }

  @override
  String get adminBlockConfirmTitle => '封禁该司机?';

  @override
  String get adminBlockCompanyConfirmTitle => '封禁该公司?';

  @override
  String get adminBlock => '封禁';

  @override
  String get adminBlockCompany => '封禁公司';

  @override
  String get adminUnblockConfirmTitle => '解除封禁?';

  @override
  String get adminUnblock => '解除封禁';

  @override
  String get adminVerifyMissingDocsError => '并非所有必需文件均已通过审核——勾选「亲自核实」后重试';

  @override
  String get adminResetPasswordConfirmTitle => '重置负责人密码?';

  @override
  String get adminResetPasswordDialogTitle => '临时密码';

  @override
  String get adminResetPassword => '重置密码';

  @override
  String get adminCopied => '已复制';

  @override
  String get adminToggleVerification => '更改验证状态';

  @override
  String get adminStatComplaints => '投诉';

  @override
  String get adminStatCancellations => '取消次数';

  @override
  String get adminStatCalls => '通话次数';

  @override
  String get adminDocuments => '文件';

  @override
  String get adminNoDocuments => '暂无文件';

  @override
  String get adminLegalDetails => '法律信息';

  @override
  String get adminInvites => '邀请';

  @override
  String get adminInviteUsed => '已使用';

  @override
  String get adminTabCargos => '货源';

  @override
  String get adminTabDeals => '交易';

  @override
  String get adminTabReviews => '评价';

  @override
  String get adminTabLog => '日志';

  @override
  String get adminNoCargos => '暂无货源';

  @override
  String get adminNoDeals => '暂无交易';

  @override
  String get adminNoReviews => '暂无评价';

  @override
  String get adminNoLog => '暂无记录';

  @override
  String get adminEndSessionsConfirmTitle => '结束所有会话?';

  @override
  String get adminEndSessions => '结束会话';

  @override
  String adminWithUsSince(String date) {
    return '加入时间 $date';
  }

  @override
  String adminLastLogin(String date) {
    return '最后登录: $date';
  }

  @override
  String get adminReasonLabel => '原因';

  @override
  String get adminVerifyDialogTitle => '标记为「已验证」';

  @override
  String get adminUnverifyDialogTitle => '取消「已验证」标记';

  @override
  String get adminForceVerifyCheckbox => '我已亲自核实文件';

  @override
  String get adminBlacklistMatchTitle => '与黑名单匹配';

  @override
  String get adminBlacklistMatchIntro => '该档案的标识符中存在有效的黑名单记录：';

  @override
  String get adminBlacklistMatchOverride => '仍然确认（覆盖黑名单）';

  @override
  String get adminRejectPresetUnreadable => '照片无法辨认';

  @override
  String get adminRejectPresetExpired => '证件已过期';

  @override
  String get adminRejectPresetMismatch => '姓名不匹配';

  @override
  String get adminRejectPresetOther => '其他 / 原因';

  @override
  String get adminDocTypeCompanyRegistration => '营业执照';

  @override
  String get adminDocTypeIdentity => '身份证件';

  @override
  String get adminDocTypeOther => '其他文件';

  @override
  String get adminRotate => '旋转';

  @override
  String get adminComplaintReporter => '投诉人';

  @override
  String get adminComplaintTarget => '投诉对象';

  @override
  String get adminAttentionTitle => '需要关注';

  @override
  String get adminAttentionEmpty => '一切正常——无需关注';

  @override
  String adminAttentionBlacklistMatches(int count) {
    return '黑名单匹配：$count';
  }

  @override
  String get adminBlockAlsoByTitle => '同时按以下项封禁：';

  @override
  String get adminIdentifierTypeIin => '个人识别号';

  @override
  String get adminIdentifierTypeLicense => '驾照号码';

  @override
  String get adminIdentifierTypePhone => '电话';

  @override
  String get adminIdentifierTypeVin => 'VIN';

  @override
  String get adminIdentifierTypePlate => '车牌号';

  @override
  String adminAttentionPendingVerification(int count) {
    return '待审核：$count 人';
  }

  @override
  String adminAttentionOpenComplaints(int count) {
    return '待处理投诉：$count';
  }

  @override
  String adminAttentionStaleDeals(int count) {
    return '超过3天无进展的交易：$count';
  }

  @override
  String adminAttentionUnverifiedCompanies(int count) {
    return '未验证公司：$count';
  }

  @override
  String adminAttentionPendingCities(int count) {
    return '新城市：$count';
  }

  @override
  String get adminRecentEventsTitle => '最近事件';

  @override
  String get adminAuditLogLink => '日志 →';

  @override
  String get adminAuditLogTitle => '操作日志';

  @override
  String get adminNoEvents => '暂无事件';

  @override
  String get adminPeriodLabel => '周期：';

  @override
  String get adminPeriodToday => '今天';

  @override
  String get adminPeriod7d => '7天';

  @override
  String get adminPeriod30d => '30天';

  @override
  String get adminStatOnSiteToday => '今日在场';

  @override
  String adminStatOnSiteWeek(int count) {
    return '本周：$count';
  }

  @override
  String get adminGlobalSearchHint => '搜索：姓名、电话、邮箱、车牌号、货源/交易编号';

  @override
  String get adminSearchNoResults => '未找到结果';

  @override
  String get adminNavCargos => '货源';

  @override
  String get adminNavDeals => '交易';

  @override
  String get adminNavSettings => '设置';

  @override
  String get adminCargosTitle => '货源';

  @override
  String get adminCargosEmpty => '未找到货源';

  @override
  String get adminDealsTitle => '交易';

  @override
  String get adminDealsEmpty => '未找到交易';

  @override
  String get adminFilterActive => '进行中';

  @override
  String get adminFilterStale => '超过3天无进展';

  @override
  String get adminFilterOnSite => '在现场';

  @override
  String get adminColRoute => '路线';

  @override
  String get adminColBodyType => '车厢类型';

  @override
  String get adminColPrice => '价格';

  @override
  String get adminColCompany => '公司';

  @override
  String get adminColDriver => '司机';

  @override
  String get adminColResponses => '响应数';

  @override
  String get adminColPublished => '发布时间';

  @override
  String get adminColCreated => '创建时间';

  @override
  String get adminColStale => '无进展';

  @override
  String adminStaleDays(int days) {
    return '$days 天';
  }

  @override
  String get adminSettingsEmpty => '暂无设置';

  @override
  String get adminVerificationTabDrivers => '司机';

  @override
  String get adminVerificationTabCompanies => '公司';

  @override
  String get adminVerificationNoSelection => '请从左侧队列中选择一个人或公司';

  @override
  String adminVerificationReasonNew(int count) {
    return '新提交 · $count 份文件';
  }

  @override
  String adminVerificationReasonResubmitted(String type) {
    return '重新提交：$type';
  }

  @override
  String get adminVerificationReasonVehicleChanged => '更换了车辆';

  @override
  String get adminVerificationOpenCard => '查看档案 →';

  @override
  String get adminVerificationCrossCheckTitle => '与档案核对';

  @override
  String get adminCrossCheckName => '姓名 ↔ 驾照';

  @override
  String get adminCrossCheckPhoto => '自拍照片 ↔ 驾照照片';

  @override
  String get adminCrossCheckPlate => '车牌号 ↔ 牵引车行驶证';

  @override
  String get adminCrossCheckTrailerPlate => '挂车 ↔ 挂车行驶证';

  @override
  String get adminCrossCheckCompanyName => '公司名称 ↔ 许可证';

  @override
  String get adminCrossCheckCompanyTaxId => '注册号 ↔ 许可证';

  @override
  String get adminCrossCheckMatch => '一致';

  @override
  String get adminCrossCheckMismatch => '不一致';

  @override
  String get adminConfirmDriverButton => '确认司机';

  @override
  String get adminVerificationBlacklistedBadge => '黑名单';

  @override
  String get adminConfirmDespiteBlacklist => '无视匹配仍然确认';

  @override
  String get adminConfirmCompanyButton => '确认公司';

  @override
  String get adminReturnForReworkButton => '退回修改';

  @override
  String get adminReturnForReworkDialogTitle => '退回修改';

  @override
  String get adminReturnForReworkNoteLabel => '备注（需要重新拍摄的内容）';

  @override
  String get adminVerificationMissingDocsHint => '请将所有必需文件标记为「无问题」后才能确认';

  @override
  String get adminVerificationCompareWithSelfie => '与自拍对比';

  @override
  String get adminRecognitionTitle => '已识别';

  @override
  String get adminRecognitionSkipped => 'OCR 不可用 — 请手动检查';

  @override
  String get adminRecognitionPending => '识别排队中…';

  @override
  String get adminRecognitionFailed => '识别失败';

  @override
  String get adminRecognitionRetry => '重新识别';

  @override
  String get adminRecognitionMatchOk => '已核实';

  @override
  String get adminRecognitionNeedsReview => '请核查';

  @override
  String get adminRecognitionDuplicate => '与其他持有者重复';

  @override
  String get adminRecognitionBlacklisted => '在黑名单中';

  @override
  String get adminRecognitionBlacklistBanner => '与黑名单匹配 — 未经明确决定不能确认';

  @override
  String get adminRecognitionChecksumHint => '校验位正确';

  @override
  String get adminRecognitionEditValue => '修改数值';

  @override
  String get adminRecognitionFieldFullName => '姓名';

  @override
  String get adminRecognitionFieldIin => '身份证号';

  @override
  String get adminRecognitionFieldLicenseNumber => '驾照号码';

  @override
  String get adminRecognitionFieldExpiryDate => '有效期';

  @override
  String get adminRecognitionFieldBirthDate => '出生日期';

  @override
  String get adminRecognitionFieldPlateNumber => '车牌号';

  @override
  String get adminRecognitionFieldVin => '车架号(VIN)';

  @override
  String get adminRecognitionFieldBrand => '品牌';

  @override
  String get adminRecognitionFieldCapacityTons => '载重量（吨）';

  @override
  String get adminRecognitionFieldCompanyName => '公司名称';

  @override
  String get adminRecognitionFieldBin => 'BIN（哈萨克斯坦工商识别号）';

  @override
  String get adminRecognitionFieldUscc => '统一社会信用代码';

  @override
  String get adminIdentifiersCardTitle => '身份标识';

  @override
  String get adminIdentifierBlockHistoryTitle => '封锁历史';

  @override
  String get adminIdentifierLifted => '已解除';

  @override
  String get adminIdentifierActive => '生效中';

  @override
  String get adminIdentifierReveal => '显示';

  @override
  String get adminRejectPresetPlateMismatch => '车牌号不匹配';

  @override
  String get adminCargoUnpublish => '下架';

  @override
  String get adminCargoUnpublishDialogTitle => '将货物下架';

  @override
  String get adminCargoEdit => '修改';

  @override
  String get adminCargoEditDialogTitle => '修改货物信息';

  @override
  String get adminCargoPublishedAt => '发布时间';

  @override
  String get adminCargoExpiresAt => '到期时间';

  @override
  String get adminCargoArchivedAt => '下架时间';

  @override
  String get adminCargoTabResponses => '响应';

  @override
  String get adminNoResponses => '暂无响应';

  @override
  String get adminDealCancel => '取消交易';

  @override
  String get adminDealCancelDialogTitle => '取消交易';

  @override
  String get adminDealFixStatus => '修正状态';

  @override
  String get adminDealFixStatusDialogTitle => '修正交易状态';

  @override
  String get adminDealOpenCargo => '货物 →';

  @override
  String adminDealCancelledBy(String role) {
    return '由$role取消';
  }

  @override
  String get adminDealStatusHistoryTitle => '状态历史';

  @override
  String get adminDealTabChat => '聊天记录';

  @override
  String get adminDealTabCalls => '通话记录';

  @override
  String get adminDealShowChat => '显示聊天记录';

  @override
  String get adminNoChat => '暂无消息';

  @override
  String get adminNoCalls => '暂无通话记录';

  @override
  String get adminContactEventCall => '电话';

  @override
  String get adminContactEventWhatsapp => 'WhatsApp';

  @override
  String get roleAdmin => '管理员';

  @override
  String get adminEdit => '编辑';

  @override
  String get adminTransferOwnershipTitle => '转让所有权';

  @override
  String get adminDemoteToLogistTitle => '降级为物流专员';

  @override
  String get adminLastOwnerError => '无法操作——这是公司最后一位所有者';

  @override
  String get adminRemoveMemberTitle => '移除员工';

  @override
  String get adminRemoveMember => '移除';

  @override
  String get adminChangeMemberEmailTitle => '更改员工邮箱';

  @override
  String get adminEmailTakenError => '该邮箱已被使用';

  @override
  String get adminCompanyCity => '城市';

  @override
  String get adminLegalAddress => '法定地址';

  @override
  String get adminTaxId => '注册号';

  @override
  String get adminPhoneChangeWarning => '保存后司机的所有登录会话将被终止';

  @override
  String get adminVehicleBrand => '品牌';

  @override
  String get adminVehicleTractorTitle => '牵引车';

  @override
  String get adminVehicleTrailerTitle => '挂车';

  @override
  String get adminVehicleLengthM => '长度(米)';

  @override
  String get adminNameEn => '名称 (en)';

  @override
  String get adminSortOrder => '排序';

  @override
  String get adminLat => '纬度';

  @override
  String get adminLng => '经度';

  @override
  String get adminCitiesTab => '城市';

  @override
  String get adminSettingDefaultCity => '默认地点';

  @override
  String get adminSettingNotSet => '未设置';

  @override
  String get adminSettingHomeRadius => '「离家近」半径（公里）';

  @override
  String get adminUnitKm => '公里';

  @override
  String get adminSettingCargoArchiveDays => '无响应货物的归档期限';

  @override
  String get adminComplaintResolutionTitle => '处理决定';

  @override
  String get adminComplaintResolutionNoteLabel => '回复投诉人';

  @override
  String get adminComplaintNoteRequired => '请填写给投诉人的回复——对方会看到';

  @override
  String get adminComplaintSelectHint => '请从左侧队列中选择一条投诉';

  @override
  String get adminComplaintTabNew => '新投诉';

  @override
  String get adminComplaintTabInReview => '处理中';

  @override
  String get adminComplaintTabClosed => '已关闭';

  @override
  String get adminComplaintMineFilter => '我的';

  @override
  String adminComplaintMoreThisMonth(int count) {
    return '本月还有$count起投诉';
  }

  @override
  String get adminComplaintTakeOver => '接手处理';

  @override
  String adminComplaintAssignedTo(String name) {
    return '处理人：$name';
  }

  @override
  String get adminComplaintReturnToNew => '退回新投诉';

  @override
  String get adminComplaintResolveButton => '做出决定';

  @override
  String get adminComplaintResolutionDismissed => '未成立';

  @override
  String get adminComplaintResolutionWarned => '警告';

  @override
  String get adminComplaintResolutionCargoUnpublished => '下架货物';

  @override
  String get adminComplaintResolutionBlocked => '封禁';

  @override
  String get adminStatClosedOutside => 'App外成交占比';

  @override
  String adminStatClosedOutsideHint(int outside, int total) {
    return '$total个已关闭中$outside个';
  }

  @override
  String get cargoCloseDialogTitle => '关闭货物';

  @override
  String get cargoCloseFoundInApp => '在Lubao找到司机';

  @override
  String get cargoCloseNoCandidates => '暂无响应、通话或聊天记录的司机';

  @override
  String get cargoCloseDriverLabel => '司机';

  @override
  String get cargoCloseFoundOutside => '在Lubao外找到';

  @override
  String get cargoCloseCancelled => '货物已取消';

  @override
  String get cargoCloseConfirm => '关闭';

  @override
  String get cargoClosed => '货物已关闭';

  @override
  String get cargoClose => '关闭货物';

  @override
  String get navChats => '聊天';

  @override
  String get chatsTabTitle => '聊天';

  @override
  String get chatsEmpty => '暂无聊天记录';

  @override
  String get profileNotificationSettings => '通知';

  @override
  String get notificationSettingsTitle => '通知';

  @override
  String get notificationSettingsHint => '关闭的分组不会推送这些事件';

  @override
  String get notificationGroupNewCargoMatch => '新匹配货物';

  @override
  String get notificationGroupCargoInvite => '货物邀请';

  @override
  String get notificationGroupChatMessage => '聊天新消息';

  @override
  String get notificationGroupNewResponse => '司机响应';

  @override
  String get notificationGroupNewDriverDigest => '该点新司机';

  @override
  String get notificationGroupDealStatus => '交易状态变更';

  @override
  String get notificationGroupVerification => '文件审核';

  @override
  String get notificationGroupAgreedCheck => '「谈妥了吗？」';

  @override
  String get companyWecomTitle => '企业微信机器人';

  @override
  String get companyWecomHint => '企业微信群机器人的Webhook地址——新响应和交易通知将发送到您的群组';

  @override
  String get companyWecomUrlLabel => 'Webhook网址';

  @override
  String get companyWecomTestButton => '测试';

  @override
  String get companyWecomTestSuccess => '测试消息已发送';

  @override
  String get companyWecomTestError => '发送失败——请检查地址';

  @override
  String get chatTranslationFailed => '翻译不可用';

  @override
  String get chatTranslationRetry => '重试';

  @override
  String get adminTranslationSettingsTitle => '聊天翻译';

  @override
  String get adminTranslationEnabledLabel => '已启用';

  @override
  String get adminTranslationProviderLabel => '提供商';

  @override
  String get adminTranslationModelLabel => '模型';

  @override
  String get adminTranslationRequests7dLabel => '7天内请求数';

  @override
  String get adminTranslationTokens7dLabel => '7天内令牌数';

  @override
  String get adminAuditActionAdminViewedChat => '管理员打开了聊天';

  @override
  String get adminAuditActionCargoUnpublished => '货物已下架';

  @override
  String get adminAuditActionCargoUpdated => '货物已修改';

  @override
  String get adminAuditActionCityUpdated => '城市已修改';

  @override
  String get adminAuditActionCompanyBlocked => '公司已封禁';

  @override
  String get adminAuditActionCompanyMemberEmailChanged => '员工邮箱已修改';

  @override
  String get adminAuditActionCompanyMemberRemoved => '员工已从公司移除';

  @override
  String get adminAuditActionCompanyMemberRoleChanged => '员工角色已变更';

  @override
  String get adminAuditActionCompanyPasswordReset => '公司密码已重置';

  @override
  String get adminAuditActionCompanyReturnedForRework => '公司文件已退回修改';

  @override
  String get adminAuditActionCompanyUnblocked => '公司已解封';

  @override
  String get adminAuditActionCompanyUnverified => '公司已取消验证';

  @override
  String get adminAuditActionCompanyUpdated => '公司信息已修改';

  @override
  String get adminAuditActionCompanyVerified => '公司已验证';

  @override
  String get adminAuditActionComplaintAssigned => '投诉已受理';

  @override
  String get adminAuditActionComplaintResolved => '投诉已处理';

  @override
  String get adminAuditActionComplaintUnassigned => '投诉已退回队列';

  @override
  String get adminAuditActionDealCancelledByAdmin => '交易已被管理员取消';

  @override
  String get adminAuditActionDealStatusFixed => '交易状态已更正';

  @override
  String get adminAuditActionDriverReturnedForRework => '司机文件已退回修改';

  @override
  String get adminAuditActionDriverUnverified => '司机已取消验证';

  @override
  String get adminAuditActionDriverUpdated => '司机信息已修改';

  @override
  String get adminAuditActionDriverVerified => '司机已验证';

  @override
  String get adminAuditActionPointUpdated => '地点已修改';

  @override
  String get adminAuditActionSessionsRevoked => '会话已终止';

  @override
  String get adminAuditActionSettingChanged => '设置已修改';

  @override
  String get adminAuditActionUserBlocked => '用户已封禁';

  @override
  String get adminAuditActionUserUnblocked => '用户已解封';

  @override
  String get adminAuditActionBodyTypeUpdated => '车身类型已修改';

  @override
  String get adminAuditActionPermitUpdated => '通行证已修改';

  @override
  String get adminAuditFieldDestinationCountry => '目的地国家';

  @override
  String get adminAuditFieldDestinationCity => '目的地城市';

  @override
  String get adminAuditFieldBodyType => '车身类型';

  @override
  String get adminAuditFieldWeight => '重量（公斤）';

  @override
  String get adminAuditFieldVolume => '体积（立方米）';

  @override
  String get adminAuditFieldPhotos => '照片';

  @override
  String get adminAuditFieldPrice => '价格';

  @override
  String get adminAuditFieldCurrency => '货币';

  @override
  String get adminAuditFieldReadyDate => '可发货日期';

  @override
  String get adminAuditFieldDescription => '描述';

  @override
  String get adminAuditFieldName => '名称';

  @override
  String get adminAuditFieldNameRu => '名称（俄语）';

  @override
  String get adminAuditFieldCountry => '国家';

  @override
  String get adminAuditFieldCity => '城市';

  @override
  String get adminAuditFieldLegalAddress => '法定地址';

  @override
  String get adminAuditFieldTaxId => '税号';

  @override
  String get adminAuditFieldFullName => '姓名';

  @override
  String get adminAuditFieldPhone => '电话';

  @override
  String get adminAuditFieldHomeCity => '常驻城市';

  @override
  String get adminAuditFieldAnyCountry => '任意国家';

  @override
  String get adminAuditFieldCountries => '国家';

  @override
  String get adminAuditFieldPermits => '通行证';

  @override
  String get adminAuditFieldVehicle => '车辆';

  @override
  String get adminAuditFieldPlateNumber => '车牌号';

  @override
  String get adminAuditFieldCapacity => '载重量（吨）';

  @override
  String get adminAuditFieldLength => '长度（米）';

  @override
  String get adminAuditFieldBrand => '品牌';

  @override
  String get adminAuditFieldIsActive => '启用';

  @override
  String get adminAuditFieldSortOrder => '排序';

  @override
  String get adminAuditFieldStatus => '状态';

  @override
  String get postCargoVerificationRequired =>
      '发布货物功能将在公司验证通过后开放——请在公司资料中上传注册证书';

  @override
  String get companyNotVerifiedBannerText =>
      '公司尚未通过验证。您可以查看司机并与其联系，但无法发布货物——请在下方上传注册证书';

  @override
  String get companyEditTitle => '公司信息';

  @override
  String get companyEditCityLabel => '城市';

  @override
  String get companyEditLegalAddressLabel => '法定地址';

  @override
  String get companyEditTaxIdLabel => '注册号（统一社会信用代码 / БИН）';

  @override
  String get companyEditTaxIdError => '注册号格式不符合您所在国家的要求';

  @override
  String get myProfileTitle => '我的资料';

  @override
  String get myProfileNameLabel => '姓名';

  @override
  String get myProfilePhoneLabel => '司机联系电话';

  @override
  String get myProfileWechatLabel => '微信';

  @override
  String get myProfileNameError => '请输入姓名';

  @override
  String get myProfileNotSetYet => '请完善资料';

  @override
  String get companyVerificationTitle => '验证公司';

  @override
  String get companyVerificationHint =>
      '请上传注册证书——我们将与官方登记系统核对，并致电登记系统中的官方号码，通常在1个工作日内完成';

  @override
  String get companyVerificationStatusNone => '尚未上传文件';

  @override
  String get companyVerificationStatusPending => '审核中';

  @override
  String get companyVerificationStatusRejected => '需要重新拍摄';

  @override
  String get adminNavSearch => '搜索';

  @override
  String get adminNavMore => '更多';

  @override
  String get garageTitle => '我的车库';

  @override
  String get garageAddDocument => '添加证件';

  @override
  String get garageDocumentSent => '行驶证已提交审核';

  @override
  String get garageTractorsSection => '牵引车';

  @override
  String get garageTrailersSection => '挂车';

  @override
  String get garageVerified => '已核验';

  @override
  String get garagePending => '审核中';

  @override
  String get garageAddedYesterday => '昨天添加';

  @override
  String get garageAddVehicle => '添加车辆或挂车';

  @override
  String get garageEmptyTractors => '暂无牵引车';

  @override
  String get garageEmptyTrailers => '暂无挂车';

  @override
  String get garageOcrHint => '拍摄车辆登记证——车牌号和车架号将自动填写。请检查后提交。';

  @override
  String get garageArchive => '归档';

  @override
  String get garageArchived => '车辆已归档';

  @override
  String get garageKindTitle => '车辆类型？';

  @override
  String get garageKindTractor => '牵引车';

  @override
  String get garageKindTrailer => '挂车';

  @override
  String get garageVin => '车架号 (VIN)';

  @override
  String get garageLength => '长度（米）';

  @override
  String get garagePhotoRequired => '请拍摄车辆登记证';

  @override
  String get garageSubmit => '提交审核';

  @override
  String get garageAddFailed => '添加车辆失败';

  @override
  String get garageFieldRequired => '请填写此字段';

  @override
  String get garageComboTitle => '驾驶哪辆车？';

  @override
  String get garageComboTractorLabel => '牵引车';

  @override
  String get garageComboTrailerLabel => '挂车';

  @override
  String get garageComboPendingBadge => '审核中';

  @override
  String get garageComboEmpty => '车库是空的——请在个人资料中添加车辆';

  @override
  String get garageGoToGarage => '我的车库';

  @override
  String get cityPickerTitle => '选择城市';

  @override
  String get cityPickerSearchHint => '搜索城市';

  @override
  String get cityPickerNearby => '我附近';

  @override
  String get cityPickerNearbyNotFound => '附近没有合适的城市，请从列表中选择';

  @override
  String get cityPickerRecent => '最近使用';

  @override
  String get cityPickerAll => '所有城市';

  @override
  String get cityPickerNothingFound => '未找到';

  @override
  String get cityFieldPlaceholder => '选择城市';

  @override
  String get announceArrivalCityError => '请选择您空闲的城市';

  @override
  String get announceArrivalAddAnother => '再发布一条';

  @override
  String get announceArrivalOthers => '接下来的计划';

  @override
  String get announceArrivalLimit => '同时最多发布五条';

  @override
  String get arrivalQuestionDay => '到了吗？请点击“我已到达”';

  @override
  String get arrivalQuestionStill => '还在找货吗？';

  @override
  String get arrivalStillYes => '是，还在找';

  @override
  String get arrivalStillLeft => '已离开';

  @override
  String get feedBadgePartial => '可拼货';

  @override
  String get feedLoadMore => '显示更多';

  @override
  String cargoPartialHintFits(String committed, String cargo, String capacity) {
    return '可与当前货物拼装：$committed 吨 + $cargo 吨，共 $capacity 吨';
  }

  @override
  String cargoPartialHintFull(String committed, String cargo, String capacity) {
    return '无法与当前货物拼装：$committed 吨 + $cargo 吨，共 $capacity 吨';
  }

  @override
  String get cargoPartialHintNextTrip => '装货日期不同——这是下一趟，不是拼货';

  @override
  String get cargoPickupCityLabel => '装货城市';

  @override
  String get postCargoPickupCity => '装货城市';

  @override
  String get postCargoPickupCityError => '请选择装货城市';

  @override
  String get postCargoAllowPartial => '可拼货';

  @override
  String get postCargoAllowPartialHint => '货物不满载——司机可以再拼装其他货物';

  @override
  String get notificationGroupArrivalCheck => '发布提醒（“到了吗？”）';

  @override
  String get adminPointKind => '点位类型';

  @override
  String get adminPointKindCity => '城市';

  @override
  String get adminPointKindTerminal => '码头（地理围栏）';

  @override
  String get adminPointRadius => '围栏半径（米）';

  @override
  String get adminPointTerminalNeedsGeofence => '码头需要纬度、经度和半径';

  @override
  String get adminCityStatsTitle => '按城市';

  @override
  String get adminCityStatsArrivals => '公告';

  @override
  String get adminCityStatsCargos => '货物';

  @override
  String get adminCityStatsDeals => '交易';

  @override
  String get adminCityStatsEmpty => '暂无城市活动';

  @override
  String get consentUnderstood => '明白了';

  @override
  String get tripTrackingConsentTitle => '行程期间的位置';

  @override
  String get tripTrackingConsentBody => '行程期间，应用会向物流方共享您的位置。您可以在交易卡片中随时暂停。';

  @override
  String get tripTrackingSwitchTitle => '向物流方共享位置';

  @override
  String get tripTrackingSwitchOn => '行程期间已开启';

  @override
  String get tripTrackingSwitchPaused => '已暂停——物流方看不到您的位置';

  @override
  String get terminalWatchConsentTitle => '按位置自动标记“已离开”';

  @override
  String get terminalWatchConsentBody =>
      '当您在码头“已到达”期间，应用会检查您是否离开，并自动关闭公告。位置不会共享给物流方。';

  @override
  String get locationRationaleNearbyBody => '应用仅会定位一次，以查找最近的城市。位置不会被保存，也没有跟踪。';

  @override
  String get loginChannelTitle => '验证码发送到';

  @override
  String get loginChannelWhatsapp => 'WhatsApp';

  @override
  String get loginChannelTelegram => 'Telegram';

  @override
  String get loginChannelSms => '短信';

  @override
  String loginCodeSentVia(String channel) {
    return '验证码已通过$channel发送';
  }

  @override
  String get loginSendOtherWay => '没收到？换一种方式发送';

  @override
  String get adminLoginChannelsTitle => '登录验证码渠道';

  @override
  String get adminLoginChannelsHint => '顺序从上到下：第一个已启用的渠道默认提供给司机，发送失败时自动改用下一个。';

  @override
  String get adminLoginChannelsNoKeys => '未配置密钥';

  @override
  String get adminMoveUp => '上移';

  @override
  String get adminMoveDown => '下移';

  @override
  String get adminLoginChannelsSaved => '渠道已保存';

  @override
  String get pushChannelName => 'Lubao 通知';

  @override
  String get postCargoWeightError => '重量最多 60 吨（60 000 公斤）';

  @override
  String get companyLoginInvalidCredentials => '邮箱或密码错误';

  @override
  String get mapsOpen => '在地图中打开';

  @override
  String get mapsApple => '苹果地图';

  @override
  String get mapsGoogle => 'Google 地图';

  @override
  String get mapsYandex => 'Yandex 地图';

  @override
  String get maps2gis => '2GIS';

  @override
  String get mapsAmap => '高德地图';

  @override
  String get mapsBaidu => '百度地图';

  @override
  String get mapsCopyCoordinates => '复制坐标';

  @override
  String get mapsCoordinatesCopied => '坐标已复制';

  @override
  String get adminRatesTitle => '汇率（哈萨克斯坦国家银行）';

  @override
  String get adminRatesHint => '每天 10:00 按国家银行汇率自动更新。手动修改不会被自动覆盖。';

  @override
  String get adminRateEdit => '修改汇率';

  @override
  String chatSystemDriverSaysAgreed(String name) {
    return '$name：已谈妥 — 请选择该司机，交易将按步骤进行';
  }

  @override
  String get adminNavBlacklist => '黑名单';

  @override
  String get adminBlacklistAdd => '加入黑名单';

  @override
  String get adminBlacklistType => '封禁类型';

  @override
  String get adminBlacklistValue => '值';

  @override
  String get adminBlacklistLift => '解除封禁';

  @override
  String get adminBlacklistLifted => '已解除';

  @override
  String get adminBlacklistEmpty => '黑名单为空';

  @override
  String get adminBlacklistShowLifted => '显示已解除';

  @override
  String get adminIdentifierTypeBin => 'BIN';

  @override
  String get adminIdentifierTypeUscc => '统一社会信用代码';

  @override
  String get adminBlacklistInvalid => '该值不符合此类型';

  @override
  String get profileDeleteAccount => '删除账号';

  @override
  String get profileDeleteAccountTitle => '确定删除账号？';

  @override
  String get profileDeleteAccountBody =>
      '姓名、电话、邮箱、证件和车辆信息将被删除，所有设备上的登录将失效。已完成的交易和评价将保留，但不再显示您的名字。删除后无法恢复。';

  @override
  String get profileDeleteAccountConfirm => '删除';

  @override
  String get profileDeleteAccountActiveDeals => '请先完成或取消进行中的交易。';

  @override
  String get profileDeleteAccountOwnerHasMembers => '公司还有员工：请先转让所有权或移除员工。';

  @override
  String get pdConsentTitle => '个人数据处理同意书';

  @override
  String get pdConsentBody =>
      '为完成审核，我们会保存证件照片及其中的信息（姓名、身份证号、驾驶证号、车牌号、VIN）。数据存储在哈萨克斯坦境内的服务器上，仅审核管理员可见，不会提供给第三方。删除账号时证件一并删除。';

  @override
  String get pdConsentCheckbox => '我同意收集和处理我的个人数据';

  @override
  String get pdConsentContinue => '继续';

  @override
  String get legalTerms => '使用条款';

  @override
  String get legalPrivacy => '隐私政策';

  @override
  String get appUpdateTitle => '请更新应用';

  @override
  String get appUpdateBody => '此版本已不再支持。请安装新版本，只需一分钟。';

  @override
  String get appUpdateButton => '更新';

  @override
  String get legalOffer => '公司服务条款（要约）';

  @override
  String get companyRegisterOfferAccept =>
      '我接受要约：Lubao 是信息平台，不是承运人，也不是运输合同的当事方';

  @override
  String legalLoginNotice(String terms, String privacy) {
    return '继续即表示您接受$terms和$privacy';
  }

  @override
  String get legalTermsLink => '使用条款';

  @override
  String get legalPrivacyLink => '隐私政策';

  @override
  String get aboutTitle => '关于应用';

  @override
  String aboutVersion(String version) {
    return '版本 $version';
  }

  @override
  String get contactRespondFirst => '先对货源进行响应，即可看到物流人员的电话。证件审核通过后可直接拨打。';

  @override
  String get contactDailyLimit => '今天查看的号码过多。请明天再试，或在聊天中留言。';

  @override
  String get contactCompanyNotVerified => '公司审核通过后才能拨打司机电话。请先在聊天中联系。';

  @override
  String get contactNoPhone => '未填写号码，请在聊天中留言。';

  @override
  String get tooManyRequests => '请求过于频繁，请稍等一分钟。';

  @override
  String adminSuspiciousTitle(String name, int count) {
    return '疑似批量采集：$name — 24 小时内查看 $count 个号码';
  }

  @override
  String adminSuspiciousLimitHits(int count) {
    return '触达每日上限：$count 次';
  }

  @override
  String get adminSuspiciousOk => '正常';

  @override
  String get adminSuspiciousBlock => '封禁';

  @override
  String get vehiclePhotoFront => '正面（含车牌）';

  @override
  String get vehiclePhotoSide => '侧面';

  @override
  String get vehiclePhotoStepTitle => '拍摄车辆照片';

  @override
  String get vehiclePhotoStepHint => '物流人员会在您的资料卡和运输单据中看到车辆。可以跳过，稍后再添加。';

  @override
  String get commonSkip => '跳过';

  @override
  String get garagePhotosReminder => '添加车辆照片';

  @override
  String get vehiclePhotosNone => '无照片';

  @override
  String get driverDocsTitle => '司机证件';

  @override
  String get driverDocsLocked => '司机确认后开放';

  @override
  String get driverDocsDownloadPdf => '下载 PDF';

  @override
  String get driverDocsOpen => '证件';

  @override
  String get driverDocsVehiclePending => '车辆尚在审核中';

  @override
  String get driverDocsIin => '个人识别号 (IIN)';

  @override
  String get driverDocsLicense => '驾驶证';

  @override
  String get driverDocsSelfie => '司机照片';

  @override
  String get driverDocsPassport => '行驶证';

  @override
  String get driverDocsExpired => '证件已关闭：送达已超过 30 天';

  @override
  String cargoDealDriverConfirmed(String name) {
    return '司机：$name · 已确认';
  }

  @override
  String cargoDealDriverWaiting(String name) {
    return '司机：$name · 等待确认';
  }

  @override
  String dealConfirmDocsNotice(String company) {
    return '$company 的物流人员将看到您本次运输的证件：身份证、驾驶证、行驶证。仅限本次交易。';
  }

  @override
  String dealDocsOpenedAt(String when) {
    return '物流人员于 $when 查看了证件';
  }

  @override
  String get dealDocsAccessTitle => '证件查看记录';

  @override
  String get adminVehicleAutoVerified => '已自动审核';

  @override
  String get adminVehicleRevoke => '撤销审核';

  @override
  String get garageEmptyTitle => '添加车辆';

  @override
  String get garageEmptyBody => '拍摄行驶证，车牌号和 VIN 会自动填写。';

  @override
  String get garageNoPlate => '无车牌';

  @override
  String get feedStateResponded => '您已响应';

  @override
  String get feedStateInvited => '邀请您承运';

  @override
  String get feedStateSelected => '您已被选中——请确认';

  @override
  String feedStateOthers(int count) {
    return '已有 $count 人响应';
  }

  @override
  String homeMyResponsesSummary(int total) {
    return '您的响应：$total';
  }

  @override
  String homeMyResponsesPending(int count) {
    return '等待回复 $count';
  }

  @override
  String homeMyResponsesInvited(int count) {
    return '邀请 $count';
  }

  @override
  String homeMyResponsesSelected(int count) {
    return '已选中 $count';
  }

  @override
  String get driverSetupFirstName => '您怎么称呼';

  @override
  String get directionRegionsAll => '全国';

  @override
  String directionRegionsCount(int count) {
    return '地区：$count';
  }

  @override
  String directionRegionsTitle(String country) {
    return '$country 境内的目的地';
  }

  @override
  String get driverSetupPermitsOptional => '许可证（如有）';

  @override
  String licenseNameBanner(String name) {
    return '驾驶证上的姓名：$name。是否填入资料？';
  }

  @override
  String get licenseNameAccept => '是的，是我';

  @override
  String statusLookingFrom(String city) {
    return '在$city找货';
  }

  @override
  String statusOnTheWay(String city, String day) {
    return '在路上，$day到$city';
  }

  @override
  String get statusInTrip => '运输中';

  @override
  String get statusNotLooking => '暂不找货';

  @override
  String get whereNowTitle => '您现在在哪里？';

  @override
  String get whereNowGoing => '在路上，将到达…';

  @override
  String get whereNowNotLooking => '暂时不找';

  @override
  String get whereNowOtherCity => '我在其他城市';

  @override
  String whereNowGpsHint(String city) {
    return '您现在在$city吗？';
  }

  @override
  String deliveredAskTitle(String city) {
    return '您在$city。要从这里找货吗？';
  }

  @override
  String get unitM => '米';

  @override
  String get unitLiters => '升';

  @override
  String get unitCelsius => '°C';

  @override
  String get unitCars => '辆';

  @override
  String get unitSlots => '个';

  @override
  String get unitSections => '仓';

  @override
  String get bodySpecsTitle => '车厢参数';

  @override
  String get cargoSpecsTitle => '货物参数';

  @override
  String get cargoExtraBodyTypes => '也可使用';

  @override
  String get specYes => '是';

  @override
  String get specNo => '否';

  @override
  String get adminBodyTypeNameEdit => '名称与排序';

  @override
  String get adminBodyTypeProfileEdit => '类型与字段';

  @override
  String get adminBodyTypeProfile => '类型';

  @override
  String get adminBodyTypeFieldsJson => '字段（JSON）';

  @override
  String adminBodyTypeFieldsInvalid(String errors) {
    return '字段未保存：$errors';
  }

  @override
  String get dealStatusCancelRequested => '已申请取消';

  @override
  String get dealStatusDisputed => '取消有争议';

  @override
  String get cancelReasonVehicleBreakdown => '车辆故障';

  @override
  String get cancelReasonCargoNotReady => '货物未备好';

  @override
  String get cancelReasonOtherPartyUnresponsive => '对方无回应';

  @override
  String get cancelReasonTermsChanged => '条件变更';

  @override
  String get cancelReasonOther => '其他';

  @override
  String get dealCancelReasonPick => '取消原因？';

  @override
  String get dealCancelOtherHint => '请说明原因';

  @override
  String get dealCancelRequestNotice => '货物已在途中——取消需经对方同意。24小时内无回应将自动取消。';

  @override
  String get dealCancelRequestSend => '发送申请';

  @override
  String dealCancelRequestedByMe(String time) {
    return '您已申请取消，等待对方在 $time 前回复';
  }

  @override
  String dealCancelRequestedByOther(String name, String reason, String time) {
    return '$name 申请取消交易：$reason。如在 $time 前未回复，将自动取消';
  }

  @override
  String get dealCancelConfirm => '确认取消';

  @override
  String get dealCancelDispute => '提出异议';

  @override
  String get dealDisputeReasonLabel => '您为何不同意？';

  @override
  String get dealDisputedNotice => '取消有争议——由管理员处理';

  @override
  String cancelStatsLine(int cancelled, int total) {
    return '取消 $cancelled/$total';
  }

  @override
  String cancelStatsAfterLoad(int count) {
    return '装货后 $count';
  }

  @override
  String get complaintOfferTitle => '要投诉吗？';

  @override
  String get complaintOfferBody => '货物已装车后交易被取消。请告诉管理员发生了什么。';

  @override
  String get complaintReasonLabel => '发生了什么';

  @override
  String get complaintSend => '投诉';

  @override
  String get complaintSent => '投诉已提交';

  @override
  String chatSystemCancelRequested(String reason) {
    return '已申请取消交易：$reason。24小时内无回复将自动取消';
  }

  @override
  String get chatSystemCancelConfirmed => '已确认取消——交易已取消';

  @override
  String get chatSystemCancelDisputed => '取消有争议——由管理员处理';

  @override
  String get chatSystemCancelResolved => '管理员已取消交易';

  @override
  String get chatSystemCancelResumed => '管理员已将交易恢复为“运输中”';

  @override
  String get chatSystemCancelAuto => '取消申请24小时未获回复——交易已取消';

  @override
  String get adminDisputesTitle => '取消争议';

  @override
  String adminDisputeRequested(String who, String reason) {
    return '$who 申请取消：$reason';
  }

  @override
  String adminDisputeObjection(String reason) {
    return '异议：$reason';
  }

  @override
  String get adminDisputeCancelDriver => '取消——司机责任';

  @override
  String get adminDisputeCancelCompany => '取消——公司责任';

  @override
  String get adminDisputeCancelNeutral => '取消——无责';

  @override
  String get adminDisputeResume => '恢复为“运输中”';

  @override
  String get adminCancellationsTitle => '取消记录';

  @override
  String get cancelStageBeforeConfirm => '确认前';

  @override
  String get cancelStageAfterConfirm => '确认后';

  @override
  String get cancelStageAfterLoad => '装货后';

  @override
  String get cancelStageInTransit => '运输中';

  @override
  String get cancelAtFault => '本方责任';

  @override
  String get unitKm => '公里';

  @override
  String get feedLoadToday => '今天装货';

  @override
  String get feedLoadTomorrow => '明天装货';

  @override
  String feedLoadOn(String date) {
    return '$date 装货';
  }

  @override
  String perKmKzt(String value) {
    return '$value ₸/公里';
  }

  @override
  String feedRespondedCount(int count) {
    return '$count 人已响应';
  }

  @override
  String cargoMarketMonth(String from, String to) {
    return '近一个月行情：$from–$to ₸/公里';
  }

  @override
  String get postCargoCategory => '货物类别';

  @override
  String get postCargoCategoryRequired => '请选择货物类别';

  @override
  String postCargoMarketHint(String median, int deals) {
    return '该线路近一个月：中位数 $median ₸/公里，成交 $deals 笔';
  }

  @override
  String postCargoDistanceHint(String km) {
    return '公路里程约 $km 公里';
  }

  @override
  String postCargoDistancePerKm(String km, String perKm) {
    return '公路里程约 $km 公里 · 您的报价约 $perKm ₸/公里';
  }

  @override
  String get postCargoDistanceCounting => '正在计算里程…';

  @override
  String get adminRoutePricesTitle => '线路价格';

  @override
  String get adminRoutePricesEmpty => '数据不足：线路一个月内有5个以上数据点才显示统计';

  @override
  String get adminColBucket => '方向';

  @override
  String get adminColTonnage => '吨位';

  @override
  String get adminColMedian => '中位数 ₸/公里';

  @override
  String get adminColRange => 'P25–P75';

  @override
  String get adminColPoints => '数据点';

  @override
  String get adminColDealPoints => '其中成交';

  @override
  String get adminExportCsv => '导出 CSV';

  @override
  String get adminAllFilter => '全部';

  @override
  String get bucketKz => '哈国境内';

  @override
  String get bucketCis => '独联体';

  @override
  String get bucketCnFar => '中国/远程';

  @override
  String tonnageUpTo(int tons) {
    return '$tons 吨以内';
  }

  @override
  String get tonnageOver => '10 吨以上';

  @override
  String get adminCargoCategoriesTitle => '货物类别';

  @override
  String get adminCsvSaved => 'CSV 已保存';

  @override
  String get dealVehicleOneDealTitle => '车辆已占用';

  @override
  String get dealVehicleOneDealBody => '该车辆一次只能承运一单——请先完成当前运输。';

  @override
  String get adminSettingPartialLoads => '拼货（零担）';

  @override
  String get adminSettingPartialLoadsHint =>
      '关闭——每车一次一单，不显示“可拼货”。开启——仅篷布车、保温车和冷藏车可拼货。';

  @override
  String adminRecognitionDuplicateOf(String name) {
    return '与 $name 重复';
  }

  @override
  String get driverLoginTelegram => '通过 Telegram 登录';

  @override
  String get driverLoginTelegramWaiting =>
      '打开 Telegram，点击“开始”，再点击“分享号码”——将自动登录';

  @override
  String get driverLoginTelegramExpired => '登录链接已过期——请再次点击“通过 Telegram 登录”';

  @override
  String get driverLoginOrPhone => '或使用手机号';

  @override
  String get loginChannelTelegramBot => 'Telegram 机器人（免验证码登录）';

  @override
  String get vehiclePhotoFrontTitle => '正面';

  @override
  String get vehiclePhotoFrontHint => '车牌号要清晰可读';

  @override
  String get vehiclePhotoSideTitle => '侧面';

  @override
  String get vehiclePhotoSideHint => '整车入镜，含挂车';

  @override
  String get vehiclePhotoTake => '拍照';

  @override
  String get vehiclePhotoRetake => '重拍';

  @override
  String get vehiclePhotoFailed => '未上传';

  @override
  String profileAddVehicleRegistered(String details) {
    return '注册时：$details。没有车牌号和行驶证，物流方看不到您的车辆，也不会派货。';
  }

  @override
  String get profileAddVehiclePlain => '没有车牌号和行驶证，物流方看不到您的车辆，也不会派货。';

  @override
  String get garageAddPhotoChip => '添加照片';

  @override
  String get avatarOfferTitle => '将这张照片设为头像？';

  @override
  String get avatarOfferBody => '物流方将能看到它';

  @override
  String get avatarOfferYes => '是';

  @override
  String get avatarOfferOther => '重新拍一张';

  @override
  String get avatarOfferLater => '以后再说';

  @override
  String get avatarAdd => '添加照片';

  @override
  String get avatarChange => '更换照片';

  @override
  String get avatarRemove => '移除照片';

  @override
  String get avatarHint => '物流方会在您的名字旁看到照片';

  @override
  String get adminAvatarRemoveReason => '原因（例如：照片被投诉）';

  @override
  String postCargoWeightLooksLikeKg(String kg, String tons) {
    return '是 $kg 公斤 = $tons 吨吗？';
  }

  @override
  String postCargoWeightLooksLikeTons(String tons) {
    return '是不是 $tons 吨？';
  }

  @override
  String get cargosTabActive => '进行中';

  @override
  String get cargosTabWork => '运输中';

  @override
  String get cargosTabArchive => '归档';

  @override
  String get cargosEmptyActive => '暂无进行中的货物 — 请发布货物';

  @override
  String get cargosEmptyWork => '目前没有运输中的货物';

  @override
  String get cargosEmptyArchive => '归档为空';

  @override
  String get cargoRepeat => '再发一次';

  @override
  String get cargosArchiveCity => '城市';

  @override
  String get cargosArchivePeriod => '时间段';

  @override
  String get cargosArchiveReset => '重置';

  @override
  String cargoResponsesCount(int count) {
    return '响应：$count';
  }

  @override
  String cargoResponsesNew(int count) {
    return '$count 个新';
  }

  @override
  String get navTrips => '我的行程';

  @override
  String get tripsTitle => '我的行程';

  @override
  String get tripsNeedAnswer => '需要回复';

  @override
  String get tripsWaiting => '等待物流方回复';

  @override
  String get tripsInWork => '运输中';

  @override
  String get tripsSelectedBadge => '您已被选中 — 请确认';

  @override
  String get tripsConfirm => '确认行程';

  @override
  String tripsInvitedBadge(int hours) {
    return '您被邀请 · 剩余 $hours 小时';
  }

  @override
  String get tripsAccept => '愿意承运';

  @override
  String get tripsDecline => '拒绝';

  @override
  String get tripsWithdraw => '撤回响应';

  @override
  String get tripsEmpty => '在货源列表中响应货物';

  @override
  String get tripsGoFeed => '去货源列表';

  @override
  String get historyTitle => '行程记录';

  @override
  String get historyAll => '全部';

  @override
  String get historyDelivered => '已送达';

  @override
  String get historyFailed => '未成交';

  @override
  String get historyEmpty => '已完成的行程会显示在这里';

  @override
  String get closeReasonTakenByOther => '货物已由他人承运';

  @override
  String get closeReasonRejectedByLogist => '物流方已拒绝';

  @override
  String get closeReasonWithdrawn => '您已撤回';

  @override
  String get closeReasonInviteExpired => '邀请已过期';

  @override
  String get closeReasonCargoClosed => '货物已下架';

  @override
  String get closeReasonCargoArchived => '货物已归档';

  @override
  String get closeReasonDealCancelled => '交易已取消';

  @override
  String get closeReasonAccountDeleted => '账户已删除';

  @override
  String homeActionSelected(String route, String price) {
    return '您已被选中：$route，$price';
  }

  @override
  String get homeActionSelectedCta => '在“我的行程”中确认 →';

  @override
  String homeActionInvited(String route, int hours) {
    return '您被邀请：$route · 剩余 $hours 小时';
  }

  @override
  String get homeActionInvitedCta => '回复 →';

  @override
  String get profileTripHistory => '行程记录';

  @override
  String responsesInactive(int count) {
    return '未激活 · $count';
  }

  @override
  String get responsesWaitingDriver => '等待司机回复';

  @override
  String get responsesNewDot => '新响应';

  @override
  String get shareButton => '分享';

  @override
  String get shareAllButton => '全部';

  @override
  String get shareAllWeb => '分享全部';

  @override
  String get shareDialogCargo => '分享货物';

  @override
  String get shareDialogAll => '分享全部货物';

  @override
  String get shareDialogDriver => '分享我的空车信息';

  @override
  String get shareCopyText => '复制文字';

  @override
  String get shareTextCopied => '文字已复制';

  @override
  String get shareLinkButton => '链接';

  @override
  String get shareLinkCopied => '链接已复制';

  @override
  String get shareWeChatQr => '微信 — 二维码';

  @override
  String get shareWeChatHint => '微信：用手机扫码 — 文字已复制，粘贴到聊天中';

  @override
  String get shareEditHint => '发送前可以修改文字';

  @override
  String shareCargoLoading(String date) {
    return '装货 $date';
  }

  @override
  String shareCargoRespond(String url) {
    return '响应：$url';
  }

  @override
  String shareAllTitle(String company) {
    return '$company — 今日货物';
  }

  @override
  String shareAllFooter(String url) {
    return '全部货物及响应：$url';
  }

  @override
  String get shareDriverTitle => '空车待货';

  @override
  String shareDriverFrom(String city, String date) {
    return '$city，$date 起';
  }

  @override
  String get shareDriverAnyDirection => '任意方向';

  @override
  String shareDriverDirection(String countries) {
    return '方向：$countries';
  }

  @override
  String shareDriverOffer(String url) {
    return '推荐货物：$url';
  }

  @override
  String get shareVerified => '已认证';

  @override
  String get shareOpenFailed => '链接无法打开 — 可能已失效';

  @override
  String get shareCompanyCargosTitle => '公司货物';

  @override
  String adminShareStats(int links, int opens, int came) {
    return '分享：$links · 打开：$opens · 通过链接加入：$came';
  }

  @override
  String get driverCardTitle => '司机';

  @override
  String get driverCardNotLooking => '目前不在找货';

  @override
  String driverCardTrips(int count) {
    return 'Lubao 行程：$count';
  }

  @override
  String get driverCardChat => '发消息';

  @override
  String get shareLinkPromptText => '是通过链接来的吗？';

  @override
  String get shareLinkPromptOpen => '打开货物';

  @override
  String get shareLinkPromptNotFound => '未找到链接 — 请从消息中再次打开';

  @override
  String get commonPaste => '粘贴';

  @override
  String get driversInvitePickHint => '选择货物后点击“邀请”';

  @override
  String driversInviteTitle(String name) {
    return '邀请 $name';
  }

  @override
  String get dealVehicleRequired => '此趟运输需要牵引车和挂车 — 请在车库中补充';
}
