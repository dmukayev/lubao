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
  String get companyLoginTitle => '公司登录';

  @override
  String get companyLoginEmailLabel => '邮箱';

  @override
  String get companyLoginSendCode => '获取验证码';

  @override
  String get companyLoginVerify => '登录';

  @override
  String companyOtpSubtitle(String email) {
    return '验证码已发送至 $email';
  }

  @override
  String get companyOtpCodeLabel => '邮箱验证码';

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
  String get driverHomeCheckInEmpty => '到达霍尔果斯后请签到，物流公司将能看到您';

  @override
  String get driverHomeCheckInButton => '我已到达';

  @override
  String get driverHomeLeaveButton => '我已离开';

  @override
  String driverHomeFeedCount(int count) {
    return '匹配货源 $count';
  }

  @override
  String get feedEmpty => '暂无合适的货源';

  @override
  String get feedSectionHome => '回程方向';

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
  String get profileLanguage => '语言';

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
  String get driversAtPointTitle => '谁将抵达霍尔果斯';

  @override
  String get driversAtPointSubtitle => '已提前通知到达的司机';

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
  String get adminVerificationEmpty => '暂无待审核文件';

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
}
