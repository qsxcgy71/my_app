// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '儿童档案';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get signInToContinue => '登录您的账户以继续';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get login => '登录';

  @override
  String get phone => '手机';

  @override
  String get phoneNumber => '手机号码';

  @override
  String get enterPhoneNumber => '输入手机号码';

  @override
  String get sendCode => '发送验证码';

  @override
  String get smsCode => '短信验证码';

  @override
  String get verifyAndLogin => '验证并登录';

  @override
  String get continueWithGoogle => '使用 Google 继续';

  @override
  String get dontHaveAccount => '还没有账户？';

  @override
  String get signUp => '注册';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get pleaseEnterEmailAndPassword => '请输入邮箱和密码';

  @override
  String get pleaseEnterPhoneNumber => '请输入手机号码';

  @override
  String get pleaseEnterVerificationCode => '请输入验证码';

  @override
  String get loginFailed => '登录失败';

  @override
  String get language => '语言';

  @override
  String get chinese => '中文';

  @override
  String get english => 'English';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get explore => '探索';

  @override
  String get lessons => '课程';

  @override
  String get messages => '消息';

  @override
  String get profile => '会员';

  @override
  String get myLessons => '我的课程';

  @override
  String get searchLessons => '搜索课程';

  @override
  String get enrolledLessons => '已报读课程';

  @override
  String get completedLessons => '已完成课程';

  @override
  String get noEnrolledLessons => '暂无已报读课程';

  @override
  String get noCompletedLessons => '暂无已完成课程';

  @override
  String get searchCoursePlaceholder => '搜索课程名称、类别或描述...';

  @override
  String get cancel => '取消';

  @override
  String get searchResults => '搜索结果';

  @override
  String get noSearchResults => '没有找到相关课程';

  @override
  String get tryOtherKeywords => '尝试使用其他关键词搜索';

  @override
  String get enterSearchKeywords => '请输入搜索关键词';

  @override
  String get canSearchCourses => '可搜索课程名称、类别或描述';

  @override
  String get enrolled => '已报读';

  @override
  String get completed => '已完成';

  @override
  String get exploreComingSoon => '探索功能即将上线';

  @override
  String get messagesComingSoon => '消息功能即将上线';

  @override
  String get lessonDetails => '课程详情';

  @override
  String get courseInfo => '课程信息';

  @override
  String get courseIntroduction => '课程介绍';

  @override
  String get startTime => '开始时间';

  @override
  String get endTime => '结束时间';

  @override
  String get courseDate => '课程日期';

  @override
  String get courseStatus => '课程状态';

  @override
  String get courseCategory => '课程类别';

  @override
  String welcomeBackUser(String userName) {
    return '欢迎回来，$userName！';
  }

  @override
  String get logout => '退出登录';

  @override
  String get confirmLogout => '确认退出';

  @override
  String get logoutMessage => '您确定要退出登录吗？';

  @override
  String get logoutSuccess => '退出登录成功';

  @override
  String get logoutFailed => '退出登录失败';

  @override
  String get hello => '你好';

  @override
  String get emailOrPhone => '邮箱或手机号';

  @override
  String get signInWithGoogle => '使用Google登录';

  @override
  String welcome(String name) {
    return '欢迎，$name';
  }

  @override
  String get comingSoon => '即将推出';

  @override
  String get searchAllCourses => '搜索所有课程';

  @override
  String get popularCourses => '热门课程';

  @override
  String get featuredCourses => '精选课程';

  @override
  String get allCourses => '全部课程';

  @override
  String get courseDetails => '课程详情';

  @override
  String get instructor => '讲师';

  @override
  String totalLessons(int count) {
    return '共$count节课';
  }

  @override
  String get duration => '时长';

  @override
  String get rating => '评分';

  @override
  String get enrolledStudents => '已报名学员';

  @override
  String get courseCatalog => '课程目录';

  @override
  String get preview => '预览';

  @override
  String get enroll => '立即报名';

  @override
  String get goodMorning => '早安';

  @override
  String get goodAfternoon => '下午好';

  @override
  String get goodEvening => '晚上好';

  @override
  String get profileLogoutSuccess => '退出登录成功';

  @override
  String get profileLogoutFailed => '退出登录失败';

  @override
  String get selectTheme => '选择主题';

  @override
  String get themeOceanBlue => '海洋蓝';

  @override
  String get themeMysteryPurple => '神秘紫';

  @override
  String get themeForestGreen => '森林绿';

  @override
  String get themeVibrantOrange => '活力橙';

  @override
  String get themePassionRed => '热情红';

  @override
  String get themeRomanticPink => '浪漫粉';

  @override
  String get themeTealGreen => '青碧绿';

  @override
  String get themeIndigoBlue => '靛青蓝';

  @override
  String get themeEarthBrown => '大地棕';

  @override
  String get themeElegantGrey => '优雅灰';

  @override
  String get themeFreshCyan => '清新青';

  @override
  String get themeGoldenAmber => '金秋黄';
}
