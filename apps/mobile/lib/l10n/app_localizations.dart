import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'ميدليفا'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ar, this message translates to:
  /// **'رعاية ذكية لكبار السن ومتابعة لحظية للأهل'**
  String get appTagline;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول أو أنشئ حساباً بالبريد الإلكتروني وكلمة المرور'**
  String get loginSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف المحمول'**
  String get phoneLabel;

  /// No description provided for @emailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In ar, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signInButton;

  /// No description provided for @signUpButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get signUpButton;

  /// No description provided for @switchToSignUp.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟ أنشئ حساباً'**
  String get switchToSignUp;

  /// No description provided for @switchToSignIn.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟ سجّل الدخول'**
  String get switchToSignIn;

  /// No description provided for @confirmationEmailSent.
  ///
  /// In ar, this message translates to:
  /// **'افتح رابط التأكيد المرسل إلى بريدك، ثم سجّل الدخول'**
  String get confirmationEmailSent;

  /// No description provided for @nameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالكامل'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: أحمد محمد'**
  String get nameHint;

  /// No description provided for @roleLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحساب'**
  String get roleLabel;

  /// No description provided for @rolePatient.
  ///
  /// In ar, this message translates to:
  /// **'مريض / كبير سن'**
  String get rolePatient;

  /// No description provided for @roleCaregiver.
  ///
  /// In ar, this message translates to:
  /// **'مرافق / ابن أو ابنة'**
  String get roleCaregiver;

  /// No description provided for @homeTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get homeTitle;

  /// No description provided for @welcomeUser.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك، {name}'**
  String welcomeUser(String name);

  /// No description provided for @userRoleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدور: {role}'**
  String userRoleLabel(String role);

  /// No description provided for @logoutButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logoutButton;

  /// No description provided for @errorOccurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما'**
  String get errorOccurred;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @patientShellTitle.
  ///
  /// In ar, this message translates to:
  /// **'واجهة المريض'**
  String get patientShellTitle;

  /// No description provided for @caregiverShellTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة متابعة المرافق'**
  String get caregiverShellTitle;

  /// No description provided for @profileTitle.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profileTitle;

  /// No description provided for @languageLabel.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageLabel;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @saveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get saveButton;

  /// No description provided for @profileSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ التغييرات بنجاح'**
  String get profileSaved;

  /// No description provided for @todayDosesTitle.
  ///
  /// In ar, this message translates to:
  /// **'جرعات اليوم'**
  String get todayDosesTitle;

  /// No description provided for @noDosesToday.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد جرعات مجدولة لليوم'**
  String get noDosesToday;

  /// No description provided for @doseAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'{amount} قرص'**
  String doseAmountLabel(String amount);

  /// No description provided for @statusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get statusPending;

  /// No description provided for @statusTaken.
  ///
  /// In ar, this message translates to:
  /// **'تم التناول'**
  String get statusTaken;

  /// No description provided for @statusSkipped.
  ///
  /// In ar, this message translates to:
  /// **'تم التخطي'**
  String get statusSkipped;

  /// No description provided for @statusMissed.
  ///
  /// In ar, this message translates to:
  /// **'فائتة'**
  String get statusMissed;

  /// No description provided for @statusSnoozed.
  ///
  /// In ar, this message translates to:
  /// **'مؤجلة'**
  String get statusSnoozed;

  /// No description provided for @takeDoseButton.
  ///
  /// In ar, this message translates to:
  /// **'تناولت الدواء'**
  String get takeDoseButton;

  /// No description provided for @skipDoseButton.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get skipDoseButton;

  /// No description provided for @medicationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الأدوية'**
  String get medicationsTitle;

  /// No description provided for @addMedicationTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة دواء'**
  String get addMedicationTitle;

  /// No description provided for @editMedicationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الدواء'**
  String get editMedicationTitle;

  /// No description provided for @deleteMedicationTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الدواء'**
  String get deleteMedicationTitle;

  /// No description provided for @deleteMedicationConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذا الدواء؟'**
  String get deleteMedicationConfirm;

  /// No description provided for @deleteButton.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteButton;

  /// No description provided for @cancelButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancelButton;

  /// No description provided for @medicationNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم الدواء'**
  String get medicationNameLabel;

  /// No description provided for @medicationStrengthLabel.
  ///
  /// In ar, this message translates to:
  /// **'التركيز (مثال: 5mg)'**
  String get medicationStrengthLabel;

  /// No description provided for @medicationFormLabel.
  ///
  /// In ar, this message translates to:
  /// **'الشكل الدوائي'**
  String get medicationFormLabel;

  /// No description provided for @medicationStockLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكمية المتاحة (عدد الأقراص)'**
  String get medicationStockLabel;

  /// No description provided for @medicationNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم الدواء'**
  String get medicationNameRequired;

  /// No description provided for @schedulesSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد الجرعات'**
  String get schedulesSectionTitle;

  /// No description provided for @addScheduleButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موعد'**
  String get addScheduleButton;

  /// No description provided for @timeOfDayLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوقت (HH:MM)'**
  String get timeOfDayLabel;

  /// No description provided for @mealBefore.
  ///
  /// In ar, this message translates to:
  /// **'قبل الأكل'**
  String get mealBefore;

  /// No description provided for @mealAfter.
  ///
  /// In ar, this message translates to:
  /// **'بعد الأكل'**
  String get mealAfter;

  /// No description provided for @mealWith.
  ///
  /// In ar, this message translates to:
  /// **'مع الأكل'**
  String get mealWith;

  /// No description provided for @mealAnytime.
  ///
  /// In ar, this message translates to:
  /// **'في أي وقت'**
  String get mealAnytime;

  /// No description provided for @noMedicationsYet.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم إضافة أدوية بعد'**
  String get noMedicationsYet;

  /// No description provided for @daysOfWeekLabel.
  ///
  /// In ar, this message translates to:
  /// **'أيام الأسبوع'**
  String get daysOfWeekLabel;

  /// No description provided for @daySat.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get daySun;

  /// No description provided for @dayMon.
  ///
  /// In ar, this message translates to:
  /// **'الإثنين'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get dayFri;

  /// No description provided for @pairingCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'رمز ربط المرافق'**
  String get pairingCodeTitle;

  /// No description provided for @pairingCodeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أعطِ هذا الرمز للمرافق لربط حسابه ومتابعة مواعيدك'**
  String get pairingCodeSubtitle;

  /// No description provided for @generatePairingCodeButton.
  ///
  /// In ar, this message translates to:
  /// **'توليد رمز جديد'**
  String get generatePairingCodeButton;

  /// No description provided for @pairPatientTitle.
  ///
  /// In ar, this message translates to:
  /// **'ربط حساب مريض'**
  String get pairPatientTitle;

  /// No description provided for @pairPatientSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المكون من 6 أرقام من تطبيق المريض'**
  String get pairPatientSubtitle;

  /// No description provided for @pairCodeInputLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز الاقتران'**
  String get pairCodeInputLabel;

  /// No description provided for @pairSubmitButton.
  ///
  /// In ar, this message translates to:
  /// **'ربط الحساب'**
  String get pairSubmitButton;

  /// No description provided for @pairSuccessMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم ربط حساب المريض بنجاح'**
  String get pairSuccessMessage;

  /// No description provided for @noLinkedPatients.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مرضى مرتبطين بحسابك بعد'**
  String get noLinkedPatients;

  /// No description provided for @takenMissedSummary.
  ///
  /// In ar, this message translates to:
  /// **'تم تناول {taken} • فائتة {missed}'**
  String takenMissedSummary(int taken, int missed);

  /// No description provided for @alertsBadgeLabel.
  ///
  /// In ar, this message translates to:
  /// **'{count} تنبيه'**
  String alertsBadgeLabel(int count);

  /// No description provided for @vitalsTitle.
  ///
  /// In ar, this message translates to:
  /// **'القياسات الحيوية'**
  String get vitalsTitle;

  /// No description provided for @vitalTypeBp.
  ///
  /// In ar, this message translates to:
  /// **'ضغط الدم'**
  String get vitalTypeBp;

  /// No description provided for @vitalTypeGlucose.
  ///
  /// In ar, this message translates to:
  /// **'السكر'**
  String get vitalTypeGlucose;

  /// No description provided for @vitalTypePulse.
  ///
  /// In ar, this message translates to:
  /// **'النبض'**
  String get vitalTypePulse;

  /// No description provided for @vitalValuePrimaryLabel.
  ///
  /// In ar, this message translates to:
  /// **'القراءة الأساسية'**
  String get vitalValuePrimaryLabel;

  /// No description provided for @vitalValueSecondaryLabel.
  ///
  /// In ar, this message translates to:
  /// **'القراءة الصغرى (للضغط)'**
  String get vitalValueSecondaryLabel;

  /// No description provided for @addVitalButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل القراءة'**
  String get addVitalButton;

  /// No description provided for @triageNormal.
  ///
  /// In ar, this message translates to:
  /// **'طبيعي'**
  String get triageNormal;

  /// No description provided for @triageBorderline.
  ///
  /// In ar, this message translates to:
  /// **'حدودي / يحتاج متابعة'**
  String get triageBorderline;

  /// No description provided for @triageCritical.
  ///
  /// In ar, this message translates to:
  /// **'حرج / خطر'**
  String get triageCritical;

  /// No description provided for @confirmSaveButton.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد وحفظ'**
  String get confirmSaveButton;

  /// No description provided for @noVitalsRecorded.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قياسات مسجلة بعد'**
  String get noVitalsRecorded;

  /// No description provided for @scanPrescriptionTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسح الروشتة'**
  String get scanPrescriptionTitle;

  /// No description provided for @pickFromCameraButton.
  ///
  /// In ar, this message translates to:
  /// **'التقاط صورة بالكاميرا'**
  String get pickFromCameraButton;

  /// No description provided for @pickFromGalleryButton.
  ///
  /// In ar, this message translates to:
  /// **'اختيار من المعرض'**
  String get pickFromGalleryButton;

  /// No description provided for @confirmPrescriptionButton.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد وإضافة الأدوية'**
  String get confirmPrescriptionButton;

  /// No description provided for @emergencyContactsTitle.
  ///
  /// In ar, this message translates to:
  /// **'جهات اتصال الطوارئ'**
  String get emergencyContactsTitle;

  /// No description provided for @contactNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم جهة الاتصال'**
  String get contactNameLabel;

  /// No description provided for @contactRelationLabel.
  ///
  /// In ar, this message translates to:
  /// **'صلة القرابة'**
  String get contactRelationLabel;

  /// No description provided for @addContactButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة جهة اتصال'**
  String get addContactButton;

  /// No description provided for @sosButtonLabel.
  ///
  /// In ar, this message translates to:
  /// **'استغاثة طوارئ SOS'**
  String get sosButtonLabel;

  /// No description provided for @sosConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد إرسال نداء استغاثة'**
  String get sosConfirmTitle;

  /// No description provided for @sosConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد إرسال نداء استغاثة عاجل إلى عائلتك الآن؟'**
  String get sosConfirmBody;

  /// No description provided for @sosConfirmSendButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال استغاثة الآن'**
  String get sosConfirmSendButton;

  /// No description provided for @sosSentMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال نداء الاستغاثة بنجاح'**
  String get sosSentMessage;

  /// No description provided for @inventoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'مخزون الأدوية'**
  String get inventoryTitle;

  /// No description provided for @daysLeftLabel.
  ///
  /// In ar, this message translates to:
  /// **'متبقي {days} يوم'**
  String daysLeftLabel(int days);

  /// No description provided for @lowStockWarning.
  ///
  /// In ar, this message translates to:
  /// **'تحذير: المخزون يكفي لأقل من 7 أيام'**
  String get lowStockWarning;

  /// No description provided for @refillOrderButton.
  ///
  /// In ar, this message translates to:
  /// **'طلب إعادة التعبئة'**
  String get refillOrderButton;

  /// No description provided for @doctorReportTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الطبيب (PDF)'**
  String get doctorReportTitle;

  /// No description provided for @shareReportButton.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة / طباعة التقرير'**
  String get shareReportButton;

  /// No description provided for @reportDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'هذا التقرير صادر آلياً من تطبيق ميدليفا للمتابعة الطبية ولا يغني عن الاستشارة الطبية المباشرة.'**
  String get reportDisclaimer;

  /// No description provided for @emailRequiredError.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال البريد الإلكتروني'**
  String get emailRequiredError;

  /// No description provided for @emailInvalidError.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صحيح'**
  String get emailInvalidError;

  /// No description provided for @passwordRequiredError.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال كلمة المرور'**
  String get passwordRequiredError;

  /// No description provided for @passwordShortError.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب ألا تقل عن 6 أحرف'**
  String get passwordShortError;

  /// No description provided for @nameRequiredError.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال الاسم بالكامل'**
  String get nameRequiredError;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navMedications.
  ///
  /// In ar, this message translates to:
  /// **'الأدوية'**
  String get navMedications;

  /// No description provided for @navVitals.
  ///
  /// In ar, this message translates to:
  /// **'القياسات'**
  String get navVitals;

  /// No description provided for @navMore.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get navMore;

  /// No description provided for @navTimeline.
  ///
  /// In ar, this message translates to:
  /// **'الجدول الزمني'**
  String get navTimeline;

  /// No description provided for @navTrends.
  ///
  /// In ar, this message translates to:
  /// **'اتجاهات القياسات'**
  String get navTrends;

  /// No description provided for @navInventoryComm.
  ///
  /// In ar, this message translates to:
  /// **'المخزون والتواصل'**
  String get navInventoryComm;

  /// No description provided for @navSos.
  ///
  /// In ar, this message translates to:
  /// **'استغاثة'**
  String get navSos;

  /// No description provided for @navNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get navNotifications;

  /// No description provided for @navSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get navSettings;

  /// No description provided for @goodMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير'**
  String get goodMorning;

  /// No description provided for @goodMorningGreeting.
  ///
  /// In ar, this message translates to:
  /// **'نتمنى لك يوماً صحياً وسعيداً'**
  String get goodMorningGreeting;

  /// No description provided for @todayMedicationCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'دواء اليوم'**
  String get todayMedicationCardTitle;

  /// No description provided for @weeklyAdherenceTitle.
  ///
  /// In ar, this message translates to:
  /// **'التزامك اليوم'**
  String get weeklyAdherenceTitle;

  /// No description provided for @weeklyAdherenceSub.
  ///
  /// In ar, this message translates to:
  /// **'{taken} من {total} جرعات'**
  String weeklyAdherenceSub(int taken, int total);

  /// No description provided for @weeklyAdherenceKeepUp.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت، استمر'**
  String get weeklyAdherenceKeepUp;

  /// No description provided for @noPendingDose.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد جرعة معلّقة الآن'**
  String get noPendingDose;

  /// No description provided for @timeForMedicationTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت الدواء'**
  String get timeForMedicationTitle;

  /// No description provided for @timeForMedicationTip.
  ///
  /// In ar, this message translates to:
  /// **'حافظ على التزامك بموعد الدواء لصحة أفضل'**
  String get timeForMedicationTip;

  /// No description provided for @tookItButton.
  ///
  /// In ar, this message translates to:
  /// **'أخذته'**
  String get tookItButton;

  /// No description provided for @snoozeButton.
  ///
  /// In ar, this message translates to:
  /// **'بعدين'**
  String get snoozeButton;

  /// No description provided for @stockAvailableBadge.
  ///
  /// In ar, this message translates to:
  /// **'متوفر'**
  String get stockAvailableBadge;

  /// No description provided for @stockRemainingPillsBadge.
  ///
  /// In ar, this message translates to:
  /// **'متبقي {count} حبات'**
  String stockRemainingPillsBadge(int count);

  /// No description provided for @stockLowBadge.
  ///
  /// In ar, this message translates to:
  /// **'مخزون منخفض'**
  String get stockLowBadge;

  /// No description provided for @onceDaily.
  ///
  /// In ar, this message translates to:
  /// **'مرة يومياً'**
  String get onceDaily;

  /// No description provided for @twiceDaily.
  ///
  /// In ar, this message translates to:
  /// **'مرتين يومياً'**
  String get twiceDaily;

  /// No description provided for @unitMmHg.
  ///
  /// In ar, this message translates to:
  /// **'مم زئبق'**
  String get unitMmHg;

  /// No description provided for @unitMgDl.
  ///
  /// In ar, this message translates to:
  /// **'مجم/دسل'**
  String get unitMgDl;

  /// No description provided for @lastReadingAt.
  ///
  /// In ar, this message translates to:
  /// **'آخر قياس: {time}'**
  String lastReadingAt(String time);

  /// No description provided for @escalationReminder15m.
  ///
  /// In ar, this message translates to:
  /// **'+15 دقيقة: تم إرسال تذكير'**
  String get escalationReminder15m;

  /// No description provided for @escalationFamily30m.
  ///
  /// In ar, this message translates to:
  /// **'+30 دقيقة: تم إشعار أفراد العائلة'**
  String get escalationFamily30m;

  /// No description provided for @escalationDoctor60m.
  ///
  /// In ar, this message translates to:
  /// **'+60 دقيقة: التصعيد للطبيب إذا استمرت الجرعة مفقودة'**
  String get escalationDoctor60m;

  /// No description provided for @upcomingDoseLabel.
  ///
  /// In ar, this message translates to:
  /// **'الجرعة القادمة'**
  String get upcomingDoseLabel;

  /// No description provided for @bpLast7Days.
  ///
  /// In ar, this message translates to:
  /// **'ضغط الدم (آخر 7 أيام)'**
  String get bpLast7Days;

  /// No description provided for @glucoseLast7Days.
  ///
  /// In ar, this message translates to:
  /// **'سكر الدم (آخر 7 أيام)'**
  String get glucoseLast7Days;

  /// No description provided for @withinNormalCount.
  ///
  /// In ar, this message translates to:
  /// **'ضمن الطبيعي'**
  String get withinNormalCount;

  /// No description provided for @slightlyHighCount.
  ///
  /// In ar, this message translates to:
  /// **'مرتفع قليلاً'**
  String get slightlyHighCount;

  /// No description provided for @highCount.
  ///
  /// In ar, this message translates to:
  /// **'مرتفع'**
  String get highCount;

  /// No description provided for @currentInventoryHeader.
  ///
  /// In ar, this message translates to:
  /// **'المخزون الحالي'**
  String get currentInventoryHeader;

  /// No description provided for @manageMedicationsLink.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الأدوية'**
  String get manageMedicationsLink;

  /// No description provided for @remoteAdjustDosesButton.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الجرعات عن بُعد'**
  String get remoteAdjustDosesButton;

  /// No description provided for @communicationHeader.
  ///
  /// In ar, this message translates to:
  /// **'التواصل'**
  String get communicationHeader;

  /// No description provided for @messagePharmacyButton.
  ///
  /// In ar, this message translates to:
  /// **'رسالة للصيدلية'**
  String get messagePharmacyButton;

  /// No description provided for @voiceMessageGrandchildrenTitle.
  ///
  /// In ar, this message translates to:
  /// **'رسالة صوتية من الأحفاد'**
  String get voiceMessageGrandchildrenTitle;

  /// No description provided for @voiceMessageGrandchildrenQuote.
  ///
  /// In ar, this message translates to:
  /// **'\"جدّي الحبيب .. نحبك كثيراً\"'**
  String get voiceMessageGrandchildrenQuote;

  /// No description provided for @callNowUrgentButton.
  ///
  /// In ar, this message translates to:
  /// **'اتصال الآن — تنبيه عاجل'**
  String get callNowUrgentButton;

  /// No description provided for @aiExtractedNotice.
  ///
  /// In ar, this message translates to:
  /// **'تم استخراج البيانات بواسطة الذكاء الاصطناعي — يرجى مراجعة وتعديل أي بيانات غير دقيقة'**
  String get aiExtractedNotice;

  /// No description provided for @highConfidenceBadge.
  ///
  /// In ar, this message translates to:
  /// **'ثقة عالية'**
  String get highConfidenceBadge;

  /// No description provided for @needsReviewBadge.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج مراجعة'**
  String get needsReviewBadge;

  /// No description provided for @secureShareTitle.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة آمنة'**
  String get secureShareTitle;

  /// No description provided for @secureShareSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة مؤقتة وآمنة لتقرير المريض عبر رمز QR'**
  String get secureShareSubtitle;

  /// No description provided for @expiresIn24Hours.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي خلال 24 ساعة'**
  String get expiresIn24Hours;

  /// No description provided for @expiresIn24HoursSub.
  ///
  /// In ar, this message translates to:
  /// **'سينتهي الرابط تلقائياً بعد 24 ساعة لحماية خصوصية المريض'**
  String get expiresIn24HoursSub;

  /// No description provided for @shareLinkButton.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الرابط'**
  String get shareLinkButton;

  /// No description provided for @downloadPdfButton.
  ///
  /// In ar, this message translates to:
  /// **'تحميل PDF'**
  String get downloadPdfButton;

  /// No description provided for @vitalLoggedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل القياس'**
  String get vitalLoggedSuccess;

  /// No description provided for @reassuringStatusTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحالة مطمئنة'**
  String get reassuringStatusTitle;

  /// No description provided for @reassuringStatusSub.
  ///
  /// In ar, this message translates to:
  /// **'قياسك ضمن المعدل الطبيعي'**
  String get reassuringStatusSub;

  /// No description provided for @sosScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'استغاثة'**
  String get sosScreenTitle;

  /// No description provided for @sosScreenSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'للحصول على المساعدة فوراً'**
  String get sosScreenSubtitle;

  /// No description provided for @sosHold3Seconds.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً 3 ثواني'**
  String get sosHold3Seconds;

  /// No description provided for @sosLocationSharingNotice.
  ///
  /// In ar, this message translates to:
  /// **'سيتم الاتصال بالمرافقين ومشاركة موقعك الحالي'**
  String get sosLocationSharingNotice;

  /// No description provided for @currentLocationShareTitle.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الموقع الحالي'**
  String get currentLocationShareTitle;

  /// No description provided for @caregiversSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'المرافقون'**
  String get caregiversSectionTitle;

  /// No description provided for @callNowButton.
  ///
  /// In ar, this message translates to:
  /// **'اتصال الآن'**
  String get callNowButton;

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @filterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterAll;

  /// No description provided for @filterMedications.
  ///
  /// In ar, this message translates to:
  /// **'الأدوية'**
  String get filterMedications;

  /// No description provided for @filterCaregivers.
  ///
  /// In ar, this message translates to:
  /// **'المرافقون'**
  String get filterCaregivers;

  /// No description provided for @filterAlerts.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get filterAlerts;

  /// No description provided for @notifDoseTimeTitle.
  ///
  /// In ar, this message translates to:
  /// **'موعد الدواء'**
  String get notifDoseTimeTitle;

  /// No description provided for @notifCaregiverMsgTitle.
  ///
  /// In ar, this message translates to:
  /// **'رسالة من المرافق'**
  String get notifCaregiverMsgTitle;

  /// No description provided for @notifLowStockTitle.
  ///
  /// In ar, this message translates to:
  /// **'انخفاض كمية الدواء'**
  String get notifLowStockTitle;

  /// No description provided for @notifHighVitalTitle.
  ///
  /// In ar, this message translates to:
  /// **'ارتفاع في القياس'**
  String get notifHighVitalTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @fontSizeLabel.
  ///
  /// In ar, this message translates to:
  /// **'تكبير الخط'**
  String get fontSizeLabel;

  /// No description provided for @fontSizeNormal.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get fontSizeNormal;

  /// No description provided for @fontSizeLarge.
  ///
  /// In ar, this message translates to:
  /// **'كبير'**
  String get fontSizeLarge;

  /// No description provided for @fontSizeExtraLarge.
  ///
  /// In ar, this message translates to:
  /// **'كبير جداً'**
  String get fontSizeExtraLarge;

  /// No description provided for @caregiversSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المرافقون'**
  String get caregiversSettingsTitle;

  /// No description provided for @caregiversSettingsSub.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المرافقين والتواصل معهم'**
  String get caregiversSettingsSub;

  /// No description provided for @notificationSoundTitle.
  ///
  /// In ar, this message translates to:
  /// **'صوت الإشعارات'**
  String get notificationSoundTitle;

  /// No description provided for @notificationSoundSub.
  ///
  /// In ar, this message translates to:
  /// **'نغمة واضحة'**
  String get notificationSoundSub;

  /// No description provided for @offlineSyncTitle.
  ///
  /// In ar, this message translates to:
  /// **'المزامنة بدون إنترنت'**
  String get offlineSyncTitle;

  /// No description provided for @offlineSyncSub.
  ///
  /// In ar, this message translates to:
  /// **'تتم المزامنة عند توفر الإنترنت'**
  String get offlineSyncSub;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'موعد تناول الجرعة الآن'**
  String get reminderNotificationBody;

  /// No description provided for @reminderChannelName.
  ///
  /// In ar, this message translates to:
  /// **'منبهات الأدوية'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات مواعيد جرعات الأدوية لكبار السن'**
  String get reminderChannelDescription;

  /// No description provided for @alertSosTitle.
  ///
  /// In ar, this message translates to:
  /// **'نداء استغاثة'**
  String get alertSosTitle;

  /// No description provided for @alertSosBody.
  ///
  /// In ar, this message translates to:
  /// **'تم إطلاق نداء استغاثة عاجل'**
  String get alertSosBody;

  /// No description provided for @alertSosNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة: {note}'**
  String alertSosNote(String note);

  /// No description provided for @alertCriticalVitalTitle.
  ///
  /// In ar, this message translates to:
  /// **'قياس حيوي يحتاج انتباهاً'**
  String get alertCriticalVitalTitle;

  /// No description provided for @alertVitalReading.
  ///
  /// In ar, this message translates to:
  /// **'تم رصد قراءة {value}'**
  String alertVitalReading(String value);

  /// No description provided for @alertLowStockTitle.
  ///
  /// In ar, this message translates to:
  /// **'انخفاض كمية الدواء'**
  String get alertLowStockTitle;

  /// No description provided for @alertLowStockBody.
  ///
  /// In ar, this message translates to:
  /// **'كمية دواء ({name}) قاربت على النفاد'**
  String alertLowStockBody(String name);

  /// No description provided for @alertMissedDoseTitle.
  ///
  /// In ar, this message translates to:
  /// **'جرعة فائتة'**
  String get alertMissedDoseTitle;

  /// No description provided for @alertMissedDoseBody.
  ///
  /// In ar, this message translates to:
  /// **'جرعة ({name}) لم تُتناول في موعدها'**
  String alertMissedDoseBody(String name);

  /// No description provided for @alertExpiryTitle.
  ///
  /// In ar, this message translates to:
  /// **'انتهاء صلاحية الدواء'**
  String get alertExpiryTitle;

  /// No description provided for @alertExpiryBody.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية دواء ({name})'**
  String alertExpiryBody(String name);

  /// No description provided for @alertGenericBody.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه جديد من تطبيق ميدليفا'**
  String get alertGenericBody;

  /// No description provided for @alertCaregiversNotified.
  ///
  /// In ar, this message translates to:
  /// **'تم إبلاغ المرافقين'**
  String get alertCaregiversNotified;

  /// No description provided for @timeJustNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} دقيقة'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} ساعة'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} يوم'**
  String timeDaysAgo(int count);

  /// No description provided for @notifDoseBody.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت تناول دواء ({name})'**
  String notifDoseBody(String name);

  /// No description provided for @notifDoseSub.
  ///
  /// In ar, this message translates to:
  /// **'الموعد {time}'**
  String notifDoseSub(String time);

  /// No description provided for @notifLowStockBody.
  ///
  /// In ar, this message translates to:
  /// **'كمية دواء ({name}) قاربت على النفاد'**
  String notifLowStockBody(String name);

  /// No description provided for @notifLowStockSub.
  ///
  /// In ar, this message translates to:
  /// **'متبقي {days} يوم'**
  String notifLowStockSub(int days);

  /// No description provided for @notifHighVitalBody.
  ///
  /// In ar, this message translates to:
  /// **'تم رصد قراءة في القياس {value}'**
  String notifHighVitalBody(String value);

  /// No description provided for @notifCaregiverMonitorSub.
  ///
  /// In ar, this message translates to:
  /// **'يتابعون حالتك يومياً'**
  String get notifCaregiverMonitorSub;

  /// No description provided for @notifCaregiversBody.
  ///
  /// In ar, this message translates to:
  /// **'المرافقون: {names}'**
  String notifCaregiversBody(String names);

  /// No description provided for @notifEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات'**
  String get notifEmptyTitle;

  /// No description provided for @notifEmptySub.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر التنبيهات الجديدة هنا فور وصولها'**
  String get notifEmptySub;

  /// No description provided for @noEmergencyContacts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد جهات اتصال مسجلة بعد — أضف جهة اتصال ليتم إبلاغها فور الاستغاثة'**
  String get noEmergencyContacts;

  /// No description provided for @locationCoordinatesLabel.
  ///
  /// In ar, this message translates to:
  /// **'الموقع: {lat}, {lng}'**
  String locationCoordinatesLabel(String lat, String lng);

  /// No description provided for @locationUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تحديد الموقع — سيتم إبلاغ جهات الاتصال بدون موقع'**
  String get locationUnavailable;

  /// No description provided for @scanFrameHint.
  ///
  /// In ar, this message translates to:
  /// **'ضع الروشتة داخل الإطار والتقط الصورة'**
  String get scanFrameHint;

  /// No description provided for @scanNoMedicationsFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم التعرف على أي دواء في الصورة'**
  String get scanNoMedicationsFound;

  /// No description provided for @scanNoMedicationsFoundHint.
  ///
  /// In ar, this message translates to:
  /// **'جرّب التقاط صورة أوضح للعلبة أو الروشتة'**
  String get scanNoMedicationsFoundHint;

  /// No description provided for @doseFrequencyOnce.
  ///
  /// In ar, this message translates to:
  /// **'مرة واحدة يومياً'**
  String get doseFrequencyOnce;

  /// No description provided for @doseFrequencyTwice.
  ///
  /// In ar, this message translates to:
  /// **'مرتين يومياً'**
  String get doseFrequencyTwice;

  /// No description provided for @timeAt.
  ///
  /// In ar, this message translates to:
  /// **'الساعة {time}'**
  String timeAt(String time);

  /// No description provided for @reportActiveMedsVitalsSummary.
  ///
  /// In ar, this message translates to:
  /// **'{meds} أدوية حالية • {vitals} قراءات حيوية'**
  String reportActiveMedsVitalsSummary(int meds, int vitals);

  /// No description provided for @prescriptionPatientRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر المريض قبل مسح الروشتة.'**
  String get prescriptionPatientRequired;

  /// No description provided for @pillImageTitle.
  ///
  /// In ar, this message translates to:
  /// **'صورة الدواء'**
  String get pillImageTitle;

  /// No description provided for @pillImageEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة صورة للدواء بعد'**
  String get pillImageEmpty;

  /// No description provided for @pillImageUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'صورة الدواء غير متاحة حاليًا'**
  String get pillImageUnavailable;

  /// No description provided for @pillImageUploadButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة أو تغيير الصورة'**
  String get pillImageUploadButton;

  /// No description provided for @pillImageUploadSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ صورة الدواء بأمان'**
  String get pillImageUploadSuccess;

  /// No description provided for @pillImageUploadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ صورة الدواء'**
  String get pillImageUploadFailed;

  /// No description provided for @appearanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearanceTitle;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get themeSystem;

  /// No description provided for @switchToLightTheme.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الوضع الفاتح'**
  String get switchToLightTheme;

  /// No description provided for @switchToDarkTheme.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الوضع الداكن'**
  String get switchToDarkTheme;

  /// No description provided for @signUpTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بياناتك لإنشاء حساب جديد على ميدليفا'**
  String get signUpSubtitle;

  /// No description provided for @showPassword.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get hidePassword;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailNotConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تأكيد بريدك الإلكتروني أولاً عبر الرابط المرسل إليك'**
  String get authErrorEmailNotConfirmed;

  /// No description provided for @authErrorUserAlreadyExists.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني مسجل مسبقاً، يرجى تسجيل الدخول بدلاً من ذلك'**
  String get authErrorUserAlreadyExists;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب ألا تقل عن 6 أحرف'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال، يرجى التحقق من اتصال الإنترنت'**
  String get authErrorNetwork;

  /// No description provided for @authErrorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تسجيل الدخول، يرجى المحاولة مرة أخرى'**
  String get authErrorGeneric;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من تسجيل الخروج من حسابك؟'**
  String get logoutConfirmMessage;

  /// No description provided for @greetingFallbackName.
  ///
  /// In ar, this message translates to:
  /// **'عزيزنا'**
  String get greetingFallbackName;

  /// No description provided for @offlineSyncPending.
  ///
  /// In ar, this message translates to:
  /// **'يوجد {count} إجراء بانتظار المزامنة'**
  String offlineSyncPending(int count);

  /// No description provided for @offlineSyncNow.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة الآن'**
  String get offlineSyncNow;

  /// No description provided for @offlineSyncSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت المزامنة بنجاح'**
  String get offlineSyncSuccess;

  /// No description provided for @reminderSoundEnabled.
  ///
  /// In ar, this message translates to:
  /// **'نغمة واضحة مفعّلة'**
  String get reminderSoundEnabled;

  /// No description provided for @reminderSoundMuted.
  ///
  /// In ar, this message translates to:
  /// **'صامت (بدون صوت)'**
  String get reminderSoundMuted;

  /// No description provided for @notificationsLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الإشعارات، اسحب للتحديث أو أعد المحاولة'**
  String get notificationsLoadError;

  /// No description provided for @retryAction.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryAction;

  /// No description provided for @doseLoggedOffline.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ محلياً — ستتم المزامنة عند عودة الإنترنت'**
  String get doseLoggedOffline;

  /// No description provided for @doseSnoozedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تأجيل الجرعة لمدة 15 دقيقة'**
  String get doseSnoozedSuccess;

  /// No description provided for @medicationSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الدواء بنجاح'**
  String get medicationSavedSuccess;

  /// No description provided for @scheduleAddedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة موعد الجرعة'**
  String get scheduleAddedSuccess;

  /// No description provided for @scheduleDeletedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف موعد الجرعة'**
  String get scheduleDeletedSuccess;

  /// No description provided for @deleteScheduleConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذا الموعد؟'**
  String get deleteScheduleConfirm;

  /// No description provided for @invalidTimeFormat.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال وقت صحيح بصيغة HH:MM'**
  String get invalidTimeFormat;

  /// No description provided for @invalidStockNumber.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم صحيح غير سالب'**
  String get invalidStockNumber;

  /// No description provided for @medicationNoSchedule.
  ///
  /// In ar, this message translates to:
  /// **'بدون مواعيد مجدولة'**
  String get medicationNoSchedule;

  /// No description provided for @medicationFreqCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} مرات يومياً'**
  String medicationFreqCount(int count);

  /// No description provided for @medicationStockCount.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد: {count} قرص'**
  String medicationStockCount(int count);

  /// No description provided for @medicationExpiryLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء'**
  String get medicationExpiryLabel;

  /// No description provided for @medicationAlertDaysLabel.
  ///
  /// In ar, this message translates to:
  /// **'التنبيه قبل النفاد (أيام)'**
  String get medicationAlertDaysLabel;

  /// No description provided for @expiredBadge.
  ///
  /// In ar, this message translates to:
  /// **'منتهي الصلاحية'**
  String get expiredBadge;

  /// No description provided for @expiringSoonBadge.
  ///
  /// In ar, this message translates to:
  /// **'قارب على الانتهاء'**
  String get expiringSoonBadge;

  /// No description provided for @prescriptionAddedCount.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة {count} أدوية بنجاح'**
  String prescriptionAddedCount(int count);

  /// No description provided for @prescriptionSelectAtLeastOne.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار دواء واحد على الأقل'**
  String get prescriptionSelectAtLeastOne;

  /// No description provided for @prescriptionAddManual.
  ///
  /// In ar, this message translates to:
  /// **'إضافة دواء يدوياً'**
  String get prescriptionAddManual;

  /// No description provided for @vitalSystolicLabel.
  ///
  /// In ar, this message translates to:
  /// **'الضغط الانقباضي (الكبير)'**
  String get vitalSystolicLabel;

  /// No description provided for @vitalDiastolicLabel.
  ///
  /// In ar, this message translates to:
  /// **'الضغط الانبساطي (الصغير)'**
  String get vitalDiastolicLabel;

  /// No description provided for @vitalGlucoseLabel.
  ///
  /// In ar, this message translates to:
  /// **'مستوى السكر (مجم/دسل)'**
  String get vitalGlucoseLabel;

  /// No description provided for @vitalPulseLabel.
  ///
  /// In ar, this message translates to:
  /// **'معدل النبض (نبضة/دقيقة)'**
  String get vitalPulseLabel;

  /// No description provided for @vitalInvalidValue.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال قيمة قياس صحيحة'**
  String get vitalInvalidValue;

  /// No description provided for @vitalSystolicGreaterError.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون الضغط الانقباضي أكبر من الانبساطي'**
  String get vitalSystolicGreaterError;

  /// No description provided for @mealContextFasting.
  ///
  /// In ar, this message translates to:
  /// **'صائم'**
  String get mealContextFasting;

  /// No description provided for @mealContextPostMeal.
  ///
  /// In ar, this message translates to:
  /// **'بعد الأكل'**
  String get mealContextPostMeal;

  /// No description provided for @mealContextRandom.
  ///
  /// In ar, this message translates to:
  /// **'عشوائي'**
  String get mealContextRandom;

  /// No description provided for @vitalPulseTab.
  ///
  /// In ar, this message translates to:
  /// **'النبض'**
  String get vitalPulseTab;

  /// No description provided for @inventoryEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أدوية في المخزون'**
  String get inventoryEmptyTitle;

  /// No description provided for @inventoryEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف أدويتك لمتابعة المخزون وتنبيهات إعادة التعبئة'**
  String get inventoryEmptySubtitle;

  /// No description provided for @inventoryRefillSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب إعادة تعبئة الدواء'**
  String get inventoryRefillSheetTitle;

  /// No description provided for @inventoryCopyMessage.
  ///
  /// In ar, this message translates to:
  /// **'نسخ رسالة الطلب'**
  String get inventoryCopyMessage;

  /// No description provided for @inventoryCopiedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رسالة الطلب'**
  String get inventoryCopiedMessage;

  /// No description provided for @inventoryUpdateStock.
  ///
  /// In ar, this message translates to:
  /// **'تحديث المخزون'**
  String get inventoryUpdateStock;

  /// No description provided for @inventoryAddStockTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كمية جديدة للمخزون'**
  String get inventoryAddStockTitle;

  /// No description provided for @inventoryMedicationsCategory.
  ///
  /// In ar, this message translates to:
  /// **'أدوية متاحة'**
  String get inventoryMedicationsCategory;

  /// No description provided for @pharmacyRefillGreeting.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً، أحتاج إعادة تعبئة الأدوية التالية:'**
  String get pharmacyRefillGreeting;

  /// No description provided for @copyCodeButton.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرمز'**
  String get copyCodeButton;

  /// No description provided for @codeCopiedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رمز الاقتران'**
  String get codeCopiedMessage;

  /// No description provided for @codeExpiresIn.
  ///
  /// In ar, this message translates to:
  /// **'صالح لمدة {minutes} دقيقة'**
  String codeExpiresIn(int minutes);

  /// No description provided for @pairingCodeInvalidLength.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال الرمز المكون من 6 أرقام'**
  String get pairingCodeInvalidLength;

  /// No description provided for @pairingErrorExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية هذا الرمز، اطلب رمزاً جديداً'**
  String get pairingErrorExpired;

  /// No description provided for @pairingErrorInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رمز الاقتران غير صحيح'**
  String get pairingErrorInvalid;

  /// No description provided for @pairingErrorAlreadyLinked.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب مرتبط بالفعل'**
  String get pairingErrorAlreadyLinked;

  /// No description provided for @pairingErrorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إتمام الربط، يرجى المحاولة مرة أخرى'**
  String get pairingErrorGeneric;

  /// No description provided for @caregiverSelectedBadge.
  ///
  /// In ar, this message translates to:
  /// **'المريض المختار'**
  String get caregiverSelectedBadge;

  /// No description provided for @caregiverMissedCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} فائتة'**
  String caregiverMissedCount(int count);

  /// No description provided for @contactEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل جهة الاتصال'**
  String get contactEditTitle;

  /// No description provided for @contactDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف جهة الاتصال هذه؟'**
  String get contactDeleteConfirm;

  /// No description provided for @contactSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ جهة الاتصال بنجاح'**
  String get contactSavedSuccess;

  /// No description provided for @contactDeletedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف جهة الاتصال'**
  String get contactDeletedSuccess;

  /// No description provided for @contactPrimaryLabel.
  ///
  /// In ar, this message translates to:
  /// **'جهة اتصال رئيسية'**
  String get contactPrimaryLabel;

  /// No description provided for @contactNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم جهة الاتصال'**
  String get contactNameRequired;

  /// No description provided for @contactPhoneRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم هاتف صحيح'**
  String get contactPhoneRequired;

  /// No description provided for @sosHoldHint.
  ///
  /// In ar, this message translates to:
  /// **'استمر بالضغط لمدة 2 ثانية لتأكيد الاستغاثة'**
  String get sosHoldHint;

  /// No description provided for @sosContactCallTitle.
  ///
  /// In ar, this message translates to:
  /// **'اتصل بجهة الاتصال'**
  String get sosContactCallTitle;

  /// No description provided for @sosCopyPhone.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرقم'**
  String get sosCopyPhone;

  /// No description provided for @sosPhoneCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رقم الهاتف'**
  String get sosPhoneCopied;

  /// No description provided for @reportRangeDays.
  ///
  /// In ar, this message translates to:
  /// **'آخر {days} يوم'**
  String reportRangeDays(int days);

  /// No description provided for @reportAdherenceSummary.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الالتزام: {rate}%'**
  String reportAdherenceSummary(int rate);

  /// No description provided for @reportLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات التقرير'**
  String get reportLoadError;

  /// No description provided for @reportLinkCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رابط التقرير الآمن'**
  String get reportLinkCopied;

  /// No description provided for @reportNoPatientSelected.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار مريض أولاً لإنشاء التقرير'**
  String get reportNoPatientSelected;

  /// No description provided for @reportQrHint.
  ///
  /// In ar, this message translates to:
  /// **'امسح الرمز لفتح التقرير الطبي المؤقت'**
  String get reportQrHint;

  /// No description provided for @reportPreviewPrintButton.
  ///
  /// In ar, this message translates to:
  /// **'معاينة وطباعة PDF'**
  String get reportPreviewPrintButton;

  /// No description provided for @reportPdfError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إنشاء ملف PDF'**
  String get reportPdfError;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
