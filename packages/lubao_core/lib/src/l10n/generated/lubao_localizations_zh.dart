// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'lubao_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class LubaoLocalizationsZh extends LubaoLocalizations {
  LubaoLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '路宝';

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
  String get feedTitle => '霍尔果斯货源';

  @override
  String get driverHomeGreeting => '你好，';

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
  String get postCargoDestinationCountry => '目的国家';

  @override
  String get postCargoDestinationCity => '目的城市';

  @override
  String get postCargoBodyType => '车厢类型';

  @override
  String get postCargoVolume => '体积(m³)';

  @override
  String get postCargoWeight => '重量(kg)';

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
  String get chatAttachLocation => '附加位置';

  @override
  String get chatLocationMessagePrefix => '地图位置';

  @override
  String get chatLocationError => '无法获取位置';

  @override
  String get chatTranslatedBadge => '已翻译';

  @override
  String get chatShowOriginal => '原文';

  @override
  String chatWritesIn(String language) {
    return '使用$language书写';
  }

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
  String get chatQuickReplyAtPlace => '我已到达';

  @override
  String get chatQuickReplyLoaded => '已装货';

  @override
  String get chatQuickReplyLate1h => '将晚到1小时';

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
    return '谁将抵达$point';
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
}
