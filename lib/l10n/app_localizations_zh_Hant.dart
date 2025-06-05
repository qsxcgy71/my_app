// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

/// The translations for Chinese Traditional (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizations {
  AppLocalizationsZhHant([String locale = 'zh_Hant']) : super(locale);

  @override
  String get appTitle => '兒童檔案';

  @override
  String get welcomeBack => '歡迎回來';

  @override
  String get signInToContinue => '請登錄您的賬戶以繼續';

  @override
  String get email => '電子郵箱';

  @override
  String get password => '密碼';

  @override
  String get login => '登錄';

  @override
  String get phone => '手機';

  @override
  String get phoneNumber => '手機號碼';

  @override
  String get enterPhoneNumber => '請輸入手機號碼';

  @override
  String get sendCode => '發送驗證碼';

  @override
  String get smsCode => '簡訊驗證碼';

  @override
  String get verifyAndLogin => '驗證並登錄';

  @override
  String get continueWithGoogle => '使用Google賬號繼續';

  @override
  String get dontHaveAccount => '還沒有賬戶？';

  @override
  String get signUp => '註冊';

  @override
  String get forgotPassword => '忘記密碼？';

  @override
  String get pleaseEnterEmailAndPassword => '請輸入郵箱和密碼';

  @override
  String get pleaseEnterPhoneNumber => '請輸入手機號碼';

  @override
  String get pleaseEnterVerificationCode => '請輸入驗證碼';

  @override
  String get loginFailed => '登錄失敗';

  @override
  String get language => '語言';

  @override
  String get chinese => '中文';

  @override
  String get english => 'English';

  @override
  String get selectLanguage => '選擇語言';

  @override
  String get explore => '探索';

  @override
  String get lessons => '課程';

  @override
  String get messages => '訊息';

  @override
  String get profile => '會員';

  @override
  String get myLessons => '我的課程';

  @override
  String get searchLessons => '搜索課程';

  @override
  String get enrolledLessons => '已報名';

  @override
  String get completedLessons => '已完成';

  @override
  String get noEnrolledLessons => '暫無已報名課程';

  @override
  String get noCompletedLessons => '暫無已完成課程';

  @override
  String get searchCoursePlaceholder => '搜索課程名稱、類別或描述...';

  @override
  String get cancel => '取消';

  @override
  String get searchResults => '搜索結果';

  @override
  String get noSearchResults => '暫無相關課程';

  @override
  String get tryOtherKeywords => '試試其他關鍵詞';

  @override
  String get enterSearchKeywords => '請輸入搜索關鍵詞';

  @override
  String get canSearchCourses => '可以搜索課程名稱、類別或描述';

  @override
  String get enrolled => '已報名';

  @override
  String get completed => '已完成';

  @override
  String get exploreComingSoon => '探索功能即將上線';

  @override
  String get messagesComingSoon => '訊息功能即將上線';

  @override
  String get lessonDetails => '課程詳情';

  @override
  String get courseInfo => '課程資訊';

  @override
  String get courseIntroduction => '課程介紹';

  @override
  String get startTime => '開始時間';

  @override
  String get endTime => '結束時間';

  @override
  String get courseDate => '課程日期';

  @override
  String get courseStatus => '課程狀態';

  @override
  String get courseCategory => '課程類別';

  @override
  String welcomeBackUser(String userName) {
    return '歡迎回來，$userName！';
  }

  @override
  String get logout => '登出';

  @override
  String get confirmLogout => '確認登出';

  @override
  String get logoutMessage => '確定要登出嗎？';

  @override
  String get logoutSuccess => '已成功登出';

  @override
  String get logoutFailed => '登出失敗';

  @override
  String get hello => '您好';

  @override
  String get emailOrPhone => '電子郵箱或手機';

  @override
  String get signInWithGoogle => '使用Google登入';

  @override
  String welcome(String name) {
    return '歡迎，$name';
  }

  @override
  String get comingSoon => '即將推出';

  @override
  String get searchAllCourses => '搜索所有課程';

  @override
  String get popularCourses => '熱門課程';

  @override
  String get featuredCourses => '精選課程';

  @override
  String get allCourses => '所有課程';

  @override
  String get courseDetails => '課程詳情';

  @override
  String get instructor => '講師';

  @override
  String totalLessons(int count) {
    return '$count 堂課';
  }

  @override
  String get duration => '時長';

  @override
  String get rating => '評分';

  @override
  String get enrolledStudents => '已報名學生';

  @override
  String get courseCatalog => '課程目錄';

  @override
  String get preview => '預覽';

  @override
  String get enroll => '立即報名';

  @override
  String get goodMorning => '早安';

  @override
  String get goodAfternoon => '午安';

  @override
  String get goodEvening => '晚安';

  @override
  String get profileLogoutSuccess => '登出成功';

  @override
  String get profileLogoutFailed => '登出失敗';

  @override
  String get selectTheme => '選擇主題';

  @override
  String get themeOceanBlue => '海洋藍';

  @override
  String get themeMysteryPurple => '神秘紫';

  @override
  String get themeForestGreen => '森林綠';

  @override
  String get themeVibrantOrange => '活力橙';

  @override
  String get themePassionRed => '熱情紅';

  @override
  String get themeRomanticPink => '浪漫粉';

  @override
  String get themeTealGreen => '青綠色';

  @override
  String get themeIndigoBlue => '靛藍色';

  @override
  String get themeEarthBrown => '大地棕';

  @override
  String get themeElegantGrey => '優雅灰';

  @override
  String get themeFreshCyan => '清新青';

  @override
  String get themeGoldenAmber => '金琥珀';

  @override
  String get themeReduce => '冷卻';

  @override
  String get themeTepid => '暖和';

  @override
  String get themeDefence => '防禦';

  @override
  String daysAgo(int days) {
    return '$days 天前';
  }

  @override
  String get createAccount => '創建賬戶';

  @override
  String get signUpTitle => '註冊';

  @override
  String get confirmPassword => '確認密碼';

  @override
  String get alreadyHaveAccount => '已有賬戶？';

  @override
  String get signIn => '登入';

  @override
  String get pleaseEnterAllFields => '請填寫所有欄位';

  @override
  String get passwordsDoNotMatch => '密碼不匹配';

  @override
  String get passwordTooShort => '密碼至少需要6個字符';

  @override
  String get registrationFailed => '註冊失敗';

  @override
  String get forgetPasswordTitle => '重置密碼';

  @override
  String get forgetPasswordDescription => '輸入您的電子郵箱，我們將發送重置密碼的說明';

  @override
  String get resetPassword => '重置密碼';

  @override
  String get resetPasswordSuccess => '重置密碼郵件已發送';

  @override
  String get resetPasswordFailed => '發送重置郵件失敗';

  @override
  String get backToLogin => '返回登入';

  @override
  String get pleaseEnterEmail => '請輸入您的電子郵箱';

  @override
  String get emailLogin => '使用郵箱登入';

  @override
  String get googleLogin => '使用Google登入';

  @override
  String get phoneLogin => '使用手機登入';

  @override
  String get noAccount => '還沒有賬戶？註冊';
} 