// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ميدليفا';

  @override
  String get appTagline => 'رعاية ذكية لكبار السن ومتابعة لحظية للأهل';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle =>
      'سجّل الدخول أو أنشئ حساباً بالبريد الإلكتروني وكلمة المرور';

  @override
  String get phoneLabel => 'رقم الهاتف المحمول';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get signInButton => 'تسجيل الدخول';

  @override
  String get signUpButton => 'إنشاء حساب';

  @override
  String get switchToSignUp => 'ليس لديك حساب؟ أنشئ حساباً';

  @override
  String get switchToSignIn => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get confirmationEmailSent =>
      'افتح رابط التأكيد المرسل إلى بريدك، ثم سجّل الدخول';

  @override
  String get nameLabel => 'الاسم بالكامل';

  @override
  String get nameHint => 'مثال: أحمد محمد';

  @override
  String get roleLabel => 'نوع الحساب';

  @override
  String get rolePatient => 'مريض / كبير سن';

  @override
  String get roleCaregiver => 'مرافق / ابن أو ابنة';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String welcomeUser(String name) {
    return 'أهلاً بك، $name';
  }

  @override
  String userRoleLabel(String role) {
    return 'الدور: $role';
  }

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get errorOccurred => 'حدث خطأ ما';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get patientShellTitle => 'واجهة المريض';

  @override
  String get caregiverShellTitle => 'لوحة متابعة المرافق';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get saveButton => 'حفظ التغييرات';

  @override
  String get profileSaved => 'تم حفظ التغييرات بنجاح';

  @override
  String get todayDosesTitle => 'جرعات اليوم';

  @override
  String get noDosesToday => 'لا توجد جرعات مجدولة لليوم';

  @override
  String doseAmountLabel(String amount) {
    return '$amount قرص';
  }

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusTaken => 'تم التناول';

  @override
  String get statusSkipped => 'تم التخطي';

  @override
  String get statusMissed => 'فائتة';

  @override
  String get statusSnoozed => 'مؤجلة';

  @override
  String get takeDoseButton => 'تناولت الدواء';

  @override
  String get skipDoseButton => 'تخطي';

  @override
  String get medicationsTitle => 'قائمة الأدوية';

  @override
  String get addMedicationTitle => 'إضافة دواء';

  @override
  String get editMedicationTitle => 'تعديل الدواء';

  @override
  String get deleteMedicationTitle => 'حذف الدواء';

  @override
  String get deleteMedicationConfirm => 'هل أنت متأكد من حذف هذا الدواء؟';

  @override
  String get deleteButton => 'حذف';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get medicationNameLabel => 'اسم الدواء';

  @override
  String get medicationStrengthLabel => 'التركيز (مثال: 5mg)';

  @override
  String get medicationFormLabel => 'الشكل الدوائي';

  @override
  String get medicationStockLabel => 'الكمية المتاحة (عدد الأقراص)';

  @override
  String get medicationNameRequired => 'يرجى إدخال اسم الدواء';

  @override
  String get schedulesSectionTitle => 'مواعيد الجرعات';

  @override
  String get addScheduleButton => 'إضافة موعد';

  @override
  String get timeOfDayLabel => 'الوقت (HH:MM)';

  @override
  String get mealBefore => 'قبل الأكل';

  @override
  String get mealAfter => 'بعد الأكل';

  @override
  String get mealWith => 'مع الأكل';

  @override
  String get mealAnytime => 'في أي وقت';

  @override
  String get noMedicationsYet => 'لم يتم إضافة أدوية بعد';

  @override
  String get daysOfWeekLabel => 'أيام الأسبوع';

  @override
  String get daySat => 'السبت';

  @override
  String get daySun => 'الأحد';

  @override
  String get dayMon => 'الإثنين';

  @override
  String get dayTue => 'الثلاثاء';

  @override
  String get dayWed => 'الأربعاء';

  @override
  String get dayThu => 'الخميس';

  @override
  String get dayFri => 'الجمعة';

  @override
  String get pairingCodeTitle => 'رمز ربط المرافق';

  @override
  String get pairingCodeSubtitle =>
      'أعطِ هذا الرمز للمرافق لربط حسابه ومتابعة مواعيدك';

  @override
  String get generatePairingCodeButton => 'توليد رمز جديد';

  @override
  String get pairPatientTitle => 'ربط حساب مريض';

  @override
  String get pairPatientSubtitle =>
      'أدخل الرمز المكون من 6 أرقام من تطبيق المريض';

  @override
  String get pairCodeInputLabel => 'رمز الاقتران';

  @override
  String get pairSubmitButton => 'ربط الحساب';

  @override
  String get pairSuccessMessage => 'تم ربط حساب المريض بنجاح';

  @override
  String get noLinkedPatients => 'لا يوجد مرضى مرتبطين بحسابك بعد';

  @override
  String takenMissedSummary(int taken, int missed) {
    return 'تم تناول $taken • فائتة $missed';
  }

  @override
  String alertsBadgeLabel(int count) {
    return '$count تنبيه';
  }

  @override
  String get vitalsTitle => 'القياسات الحيوية';

  @override
  String get vitalTypeBp => 'ضغط الدم';

  @override
  String get vitalTypeGlucose => 'السكر';

  @override
  String get vitalTypePulse => 'النبض';

  @override
  String get vitalValuePrimaryLabel => 'القراءة الأساسية';

  @override
  String get vitalValueSecondaryLabel => 'القراءة الصغرى (للضغط)';

  @override
  String get addVitalButton => 'تسجيل القراءة';

  @override
  String get triageNormal => 'طبيعي';

  @override
  String get triageBorderline => 'حدودي / يحتاج متابعة';

  @override
  String get triageCritical => 'حرج / خطر';

  @override
  String get voiceVitalButton => 'إدخال صوتي';

  @override
  String get voiceVitalConfirmTitle => 'تأكيد القراءة الصوتية';

  @override
  String get confirmSaveButton => 'تأكيد وحفظ';

  @override
  String get noVitalsRecorded => 'لا توجد قياسات مسجلة بعد';

  @override
  String get scanPrescriptionTitle => 'مسح الروشتة';

  @override
  String get pickFromCameraButton => 'التقاط صورة بالكاميرا';

  @override
  String get pickFromGalleryButton => 'اختيار من المعرض';

  @override
  String get confirmPrescriptionButton => 'اعتماد وإضافة الأدوية';

  @override
  String get emergencyContactsTitle => 'جهات اتصال الطوارئ';

  @override
  String get contactNameLabel => 'اسم جهة الاتصال';

  @override
  String get contactRelationLabel => 'صلة القرابة';

  @override
  String get addContactButton => 'إضافة جهة اتصال';

  @override
  String get sosButtonLabel => 'استغاثة طوارئ SOS';

  @override
  String get sosConfirmTitle => 'تأكيد إرسال نداء استغاثة';

  @override
  String get sosConfirmBody =>
      'هل تريد إرسال نداء استغاثة عاجل إلى عائلتك الآن؟';

  @override
  String get sosConfirmSendButton => 'إرسال استغاثة الآن';

  @override
  String get sosSentMessage => 'تم إرسال نداء الاستغاثة بنجاح';

  @override
  String get inventoryTitle => 'مخزون الأدوية';

  @override
  String daysLeftLabel(int days) {
    return 'متبقي $days يوم';
  }

  @override
  String get lowStockWarning => 'تحذير: المخزون يكفي لأقل من 7 أيام';

  @override
  String get refillOrderButton => 'طلب إعادة التعبئة';

  @override
  String get doctorReportTitle => 'تقرير الطبيب (PDF)';

  @override
  String get shareReportButton => 'مشاركة / طباعة التقرير';

  @override
  String get reportDisclaimer =>
      'هذا التقرير صادر آلياً من تطبيق ميدليفا للمتابعة الطبية ولا يغني عن الاستشارة الطبية المباشرة.';

  @override
  String get emailRequiredError => 'يرجى إدخال البريد الإلكتروني';

  @override
  String get emailInvalidError => 'البريد الإلكتروني غير صحيح';

  @override
  String get passwordRequiredError => 'يرجى إدخال كلمة المرور';

  @override
  String get passwordShortError => 'كلمة المرور يجب ألا تقل عن 6 أحرف';

  @override
  String get nameRequiredError => 'يرجى إدخال الاسم بالكامل';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navMedications => 'الأدوية';

  @override
  String get navVitals => 'القياسات';

  @override
  String get navMore => 'المزيد';

  @override
  String get navTimeline => 'الجدول الزمني';

  @override
  String get navTrends => 'اتجاهات القياسات';

  @override
  String get navInventoryComm => 'المخزون والتواصل';

  @override
  String get navVoiceVitals => 'القياس بالصوت';

  @override
  String get navSos => 'استغاثة';

  @override
  String get navNotifications => 'الإشعارات';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodMorningGreeting => 'نتمنى لك يوماً صحياً وسعيداً';

  @override
  String get todayMedicationCardTitle => 'دواء اليوم';

  @override
  String get weeklyAdherenceTitle => 'الالتزام بالأدوية هذا الأسبوع';

  @override
  String weeklyAdherenceSub(int taken, int total) {
    return '$taken من $total جرعات';
  }

  @override
  String get weeklyAdherenceKeepUp => 'أحسنت، استمر';

  @override
  String get timeForMedicationTitle => 'حان وقت الدواء';

  @override
  String get timeForMedicationTip => 'حافظ على التزامك بموعد الدواء لصحة أفضل';

  @override
  String get tookItButton => 'أخذته';

  @override
  String get snoozeButton => 'بعدين';

  @override
  String get stockAvailableBadge => 'متوفر';

  @override
  String stockRemainingPillsBadge(int count) {
    return 'متبقي $count حبات';
  }

  @override
  String get stockLowBadge => 'مخزون منخفض';

  @override
  String get onceDaily => 'مرة يومياً';

  @override
  String get twiceDaily => 'مرتين يومياً';

  @override
  String get unitMmHg => 'مم زئبق';

  @override
  String get unitMgDl => 'مجم/دسل';

  @override
  String get lastReadingToday => 'آخر قياس: اليوم';

  @override
  String get escalationReminder15m => '+15 دقيقة: تم إرسال تذكير';

  @override
  String get escalationFamily30m => '+30 دقيقة: تم إشعار أفراد العائلة';

  @override
  String get escalationDoctor60m =>
      '+60 دقيقة: التصعيد للطبيب إذا استمرت الجرعة مفقودة';

  @override
  String get upcomingDoseLabel => 'الجرعة القادمة';

  @override
  String get bpLast7Days => 'ضغط الدم (آخر 7 أيام)';

  @override
  String get glucoseLast7Days => 'سكر الدم (آخر 7 أيام)';

  @override
  String get withinNormalCount => 'ضمن الطبيعي';

  @override
  String get slightlyHighCount => 'مرتفع قليلاً';

  @override
  String get highCount => 'مرتفع';

  @override
  String get currentInventoryHeader => 'المخزون الحالي';

  @override
  String get manageMedicationsLink => 'إدارة الأدوية';

  @override
  String get remoteAdjustDosesButton => 'تعديل الجرعات عن بُعد';

  @override
  String get communicationHeader => 'التواصل';

  @override
  String get messagePharmacyButton => 'رسالة للصيدلية';

  @override
  String get voiceMessageGrandchildrenTitle => 'رسالة صوتية من الأحفاد';

  @override
  String get voiceMessageGrandchildrenQuote => '\"جدّي الحبيب .. نحبك كثيراً\"';

  @override
  String get callNowUrgentButton => 'اتصال الآن — تنبيه عاجل';

  @override
  String get aiExtractedNotice =>
      'تم استخراج البيانات بواسطة الذكاء الاصطناعي — يرجى مراجعة وتعديل أي بيانات غير دقيقة';

  @override
  String get highConfidenceBadge => 'ثقة عالية';

  @override
  String get needsReviewBadge => 'يحتاج مراجعة';

  @override
  String get secureShareTitle => 'مشاركة آمنة';

  @override
  String get secureShareSubtitle =>
      'مشاركة مؤقتة وآمنة لتقرير المريض عبر رمز QR';

  @override
  String get expiresIn24Hours => 'ينتهي خلال 24 ساعة';

  @override
  String get expiresIn24HoursSub =>
      'سينتهي الرابط تلقائياً بعد 24 ساعة لحماية خصوصية المريض';

  @override
  String get shareLinkButton => 'مشاركة الرابط';

  @override
  String get downloadPdfButton => 'تحميل PDF';

  @override
  String get voiceVitalTitle => 'القياس بالصوت';

  @override
  String get voiceVitalSubtitle => 'تحدث لإدخال قياساتك بسهولة';

  @override
  String get pressAndSpeak => 'اضغط وتكلم';

  @override
  String get vitalLoggedSuccess => 'تم تسجيل القياس';

  @override
  String get reassuringStatusTitle => 'الحالة مطمئنة';

  @override
  String get reassuringStatusSub => 'قياسك ضمن المعدل الطبيعي';

  @override
  String get sosScreenTitle => 'استغاثة';

  @override
  String get sosScreenSubtitle => 'للحصول على المساعدة فوراً';

  @override
  String get sosHold3Seconds => 'اضغط مطولاً 3 ثواني';

  @override
  String get sosLocationSharingNotice =>
      'سيتم الاتصال بالمرافقين ومشاركة موقعك الحالي';

  @override
  String get currentLocationShareTitle => 'مشاركة الموقع الحالي';

  @override
  String get caregiversSectionTitle => 'المرافقون';

  @override
  String get callNowButton => 'اتصال الآن';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterMedications => 'الأدوية';

  @override
  String get filterCaregivers => 'المرافقون';

  @override
  String get filterAlerts => 'التنبيهات';

  @override
  String get notifDoseTimeTitle => 'موعد الدواء';

  @override
  String get notifCaregiverMsgTitle => 'رسالة من المرافق';

  @override
  String get notifLowStockTitle => 'انخفاض كمية الدواء';

  @override
  String get notifHighVitalTitle => 'ارتفاع في القياس';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get fontSizeLabel => 'تكبير الخط';

  @override
  String get fontSizeNormal => 'عادي';

  @override
  String get fontSizeLarge => 'كبير';

  @override
  String get fontSizeExtraLarge => 'كبير جداً';

  @override
  String get caregiversSettingsTitle => 'المرافقون';

  @override
  String get caregiversSettingsSub => 'إدارة المرافقين والتواصل معهم';

  @override
  String get notificationSoundTitle => 'صوت الإشعارات';

  @override
  String get notificationSoundSub => 'نغمة واضحة';

  @override
  String get offlineSyncTitle => 'المزامنة بدون إنترنت';

  @override
  String get offlineSyncSub => 'تتم المزامنة عند توفر الإنترنت';

  @override
  String get reminderNotificationBody => 'موعد تناول الجرعة الآن';

  @override
  String get reminderChannelName => 'منبهات الأدوية';

  @override
  String get reminderChannelDescription =>
      'تنبيهات مواعيد جرعات الأدوية لكبار السن';

  @override
  String get alertSosTitle => 'نداء استغاثة';

  @override
  String get alertSosBody => 'تم إطلاق نداء استغاثة عاجل';

  @override
  String alertSosNote(String note) {
    return 'ملاحظة: $note';
  }

  @override
  String get alertCriticalVitalTitle => 'قياس حيوي يحتاج انتباهاً';

  @override
  String alertVitalReading(String value) {
    return 'تم رصد قراءة $value';
  }

  @override
  String get alertLowStockTitle => 'انخفاض كمية الدواء';

  @override
  String alertLowStockBody(String name) {
    return 'كمية دواء ($name) قاربت على النفاد';
  }

  @override
  String get alertMissedDoseTitle => 'جرعة فائتة';

  @override
  String alertMissedDoseBody(String name) {
    return 'جرعة ($name) لم تُتناول في موعدها';
  }

  @override
  String get alertExpiryTitle => 'انتهاء صلاحية الدواء';

  @override
  String alertExpiryBody(String name) {
    return 'انتهت صلاحية دواء ($name)';
  }

  @override
  String get alertGenericBody => 'تنبيه جديد من تطبيق ميدليفا';

  @override
  String get alertCaregiversNotified => 'تم إبلاغ المرافقين';

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String timeHoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String timeDaysAgo(int count) {
    return 'منذ $count يوم';
  }

  @override
  String notifDoseBody(String name) {
    return 'حان وقت تناول دواء ($name)';
  }

  @override
  String notifDoseSub(String time) {
    return 'الموعد $time';
  }

  @override
  String notifLowStockBody(String name) {
    return 'كمية دواء ($name) قاربت على النفاد';
  }

  @override
  String notifLowStockSub(int days) {
    return 'متبقي $days يوم';
  }

  @override
  String notifHighVitalBody(String value) {
    return 'تم رصد قراءة في القياس $value';
  }

  @override
  String get notifCaregiverMonitorSub => 'يتابعون حالتك يومياً';

  @override
  String notifCaregiversBody(String names) {
    return 'المرافقون: $names';
  }

  @override
  String get notifEmptyTitle => 'لا توجد إشعارات';

  @override
  String get notifEmptySub => 'ستظهر التنبيهات الجديدة هنا فور وصولها';

  @override
  String get noEmergencyContacts =>
      'لا توجد جهات اتصال مسجلة بعد — أضف جهة اتصال ليتم إبلاغها فور الاستغاثة';

  @override
  String locationCoordinatesLabel(String lat, String lng) {
    return 'الموقع: $lat, $lng';
  }

  @override
  String get locationUnavailable =>
      'لم يتم تحديد الموقع — سيتم إبلاغ جهات الاتصال بدون موقع';

  @override
  String get scanFrameHint => 'ضع الروشتة داخل الإطار والتقط الصورة';

  @override
  String get scanNoMedicationsFound => 'لم يتم التعرف على أي دواء في الصورة';

  @override
  String get scanNoMedicationsFoundHint =>
      'جرّب التقاط صورة أوضح للعلبة أو الروشتة';

  @override
  String get doseFrequencyOnce => 'مرة واحدة يومياً';

  @override
  String get doseFrequencyTwice => 'مرتين يومياً';

  @override
  String timeAt(String time) {
    return 'الساعة $time';
  }

  @override
  String reportActiveMedsVitalsSummary(int meds, int vitals) {
    return '$meds أدوية حالية • $vitals قراءات حيوية';
  }

  @override
  String get defaultSampleTime => '8:00 صباحاً';

  @override
  String get defaultSampleVitalTime => '7:30 صباحاً';

  @override
  String get defaultSampleMedication => 'أملوديبين 5 مجم';
}
