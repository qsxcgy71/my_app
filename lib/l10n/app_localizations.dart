import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kids Profile'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue'**
  String get signInToContinue;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @smsCode.
  ///
  /// In en, this message translates to:
  /// **'SMS Code'**
  String get smsCode;

  /// No description provided for @verifyAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Verify & Login'**
  String get verifyAndLogin;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @pleaseEnterEmailAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter email and password'**
  String get pleaseEnterEmailAndPassword;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @pleaseEnterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter verification code'**
  String get pleaseEnterVerificationCode;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myLessons.
  ///
  /// In en, this message translates to:
  /// **'My Lessons'**
  String get myLessons;

  /// No description provided for @searchLessons.
  ///
  /// In en, this message translates to:
  /// **'Search Lessons'**
  String get searchLessons;

  /// No description provided for @enrolledLessons.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get enrolledLessons;

  /// No description provided for @completedLessons.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLessons;

  /// No description provided for @noEnrolledLessons.
  ///
  /// In en, this message translates to:
  /// **'No enrolled lessons'**
  String get noEnrolledLessons;

  /// No description provided for @noCompletedLessons.
  ///
  /// In en, this message translates to:
  /// **'No completed lessons'**
  String get noCompletedLessons;

  /// No description provided for @searchCoursePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search course name, category or description...'**
  String get searchCoursePlaceholder;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No courses found'**
  String get noSearchResults;

  /// No description provided for @tryOtherKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try using other keywords'**
  String get tryOtherKeywords;

  /// No description provided for @enterSearchKeywords.
  ///
  /// In en, this message translates to:
  /// **'Please enter search keywords'**
  String get enterSearchKeywords;

  /// No description provided for @canSearchCourses.
  ///
  /// In en, this message translates to:
  /// **'You can search course names, categories or descriptions'**
  String get canSearchCourses;

  /// No description provided for @enrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get enrolled;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @exploreComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Explore feature coming soon'**
  String get exploreComingSoon;

  /// No description provided for @messagesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Messages feature coming soon'**
  String get messagesComingSoon;

  /// No description provided for @lessonDetails.
  ///
  /// In en, this message translates to:
  /// **'Lesson Details'**
  String get lessonDetails;

  /// No description provided for @courseInfo.
  ///
  /// In en, this message translates to:
  /// **'Course Information'**
  String get courseInfo;

  /// No description provided for @courseIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Course Introduction'**
  String get courseIntroduction;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @courseDate.
  ///
  /// In en, this message translates to:
  /// **'Course Date'**
  String get courseDate;

  /// No description provided for @courseStatus.
  ///
  /// In en, this message translates to:
  /// **'Course Status'**
  String get courseStatus;

  /// No description provided for @courseCategory.
  ///
  /// In en, this message translates to:
  /// **'Course Category'**
  String get courseCategory;

  /// No description provided for @welcomeBackUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {userName}!'**
  String welcomeBackUser(String userName);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutMessage;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get logoutSuccess;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone'**
  String get emailOrPhone;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcome(String name);

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @searchAllCourses.
  ///
  /// In en, this message translates to:
  /// **'Search all courses'**
  String get searchAllCourses;

  /// No description provided for @popularCourses.
  ///
  /// In en, this message translates to:
  /// **'Popular Courses'**
  String get popularCourses;

  /// No description provided for @featuredCourses.
  ///
  /// In en, this message translates to:
  /// **'Featured Courses'**
  String get featuredCourses;

  /// No description provided for @allCourses.
  ///
  /// In en, this message translates to:
  /// **'All Courses'**
  String get allCourses;

  /// No description provided for @courseDetails.
  ///
  /// In en, this message translates to:
  /// **'Course Details'**
  String get courseDetails;

  /// No description provided for @instructor.
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get instructor;

  /// No description provided for @totalLessons.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons'**
  String totalLessons(int count);

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @enrolledStudents.
  ///
  /// In en, this message translates to:
  /// **'Enrolled Students'**
  String get enrolledStudents;

  /// No description provided for @courseCatalog.
  ///
  /// In en, this message translates to:
  /// **'Course Catalog'**
  String get courseCatalog;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @enroll.
  ///
  /// In en, this message translates to:
  /// **'Enroll Now'**
  String get enroll;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @profileLogoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logout successful'**
  String get profileLogoutSuccess;

  /// No description provided for @profileLogoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get profileLogoutFailed;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @themeOceanBlue.
  ///
  /// In en, this message translates to:
  /// **'Ocean Blue'**
  String get themeOceanBlue;

  /// No description provided for @themeMysteryPurple.
  ///
  /// In en, this message translates to:
  /// **'Mystery Purple'**
  String get themeMysteryPurple;

  /// No description provided for @themeForestGreen.
  ///
  /// In en, this message translates to:
  /// **'Forest Green'**
  String get themeForestGreen;

  /// No description provided for @themeVibrantOrange.
  ///
  /// In en, this message translates to:
  /// **'Vibrant Orange'**
  String get themeVibrantOrange;

  /// No description provided for @themePassionRed.
  ///
  /// In en, this message translates to:
  /// **'Passion Red'**
  String get themePassionRed;

  /// No description provided for @themeRomanticPink.
  ///
  /// In en, this message translates to:
  /// **'Romantic Pink'**
  String get themeRomanticPink;

  /// No description provided for @themeTealGreen.
  ///
  /// In en, this message translates to:
  /// **'Teal Green'**
  String get themeTealGreen;

  /// No description provided for @themeIndigoBlue.
  ///
  /// In en, this message translates to:
  /// **'Indigo Blue'**
  String get themeIndigoBlue;

  /// No description provided for @themeEarthBrown.
  ///
  /// In en, this message translates to:
  /// **'Earth Brown'**
  String get themeEarthBrown;

  /// No description provided for @themeElegantGrey.
  ///
  /// In en, this message translates to:
  /// **'Elegant Grey'**
  String get themeElegantGrey;

  /// No description provided for @themeFreshCyan.
  ///
  /// In en, this message translates to:
  /// **'Fresh Cyan'**
  String get themeFreshCyan;

  /// No description provided for @themeGoldenAmber.
  ///
  /// In en, this message translates to:
  /// **'Golden Amber'**
  String get themeGoldenAmber;

  /// No description provided for @themeReduce.
  ///
  /// In en, this message translates to:
  /// **'Cool Down'**
  String get themeReduce;

  /// No description provided for @themeTepid.
  ///
  /// In en, this message translates to:
  /// **'Warm Up'**
  String get themeTepid;

  /// No description provided for @themeDefence.
  ///
  /// In en, this message translates to:
  /// **'Defence'**
  String get themeDefence;

  /// No description provided for @themeDreams.
  ///
  /// In en, this message translates to:
  /// **'Dreams'**
  String get themeDreams;

  /// No description provided for @themeEnergize.
  ///
  /// In en, this message translates to:
  /// **'Energize'**
  String get themeEnergize;

  /// No description provided for @themeJoyful.
  ///
  /// In en, this message translates to:
  /// **'Joyful'**
  String get themeJoyful;

  /// No description provided for @themeFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get themeFresh;

  /// No description provided for @themePeaceful.
  ///
  /// In en, this message translates to:
  /// **'Peaceful'**
  String get themePeaceful;

  /// No description provided for @themeAgile.
  ///
  /// In en, this message translates to:
  /// **'Agile'**
  String get themeAgile;

  /// No description provided for @themeMelody.
  ///
  /// In en, this message translates to:
  /// **'Melody'**
  String get themeMelody;

  /// No description provided for @themeRespire.
  ///
  /// In en, this message translates to:
  /// **'Respire'**
  String get themeRespire;

  /// No description provided for @themeComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get themeComfort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
