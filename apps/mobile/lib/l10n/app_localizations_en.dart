// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Medliva';

  @override
  String get appTagline => 'Smart Elderly Care & Real-time Family Monitoring';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginSubtitle =>
      'Sign in or create an account with your email and password';

  @override
  String get phoneLabel => 'Mobile Number';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInButton => 'Sign In';

  @override
  String get signUpButton => 'Create Account';

  @override
  String get switchToSignUp => 'New here? Create an account';

  @override
  String get switchToSignIn => 'Already have an account? Sign in';

  @override
  String get confirmationEmailSent =>
      'Open the confirmation link sent to your email, then sign in';

  @override
  String get nameLabel => 'Full Name';

  @override
  String get nameHint => 'e.g., Ahmed Mohamed';

  @override
  String get roleLabel => 'Account Type';

  @override
  String get rolePatient => 'Patient / Senior';

  @override
  String get roleCaregiver => 'Caregiver / Family';

  @override
  String get homeTitle => 'Home';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String userRoleLabel(String role) {
    return 'Role: $role';
  }

  @override
  String get logoutButton => 'Log Out';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get patientShellTitle => 'Patient Home';

  @override
  String get caregiverShellTitle => 'Caregiver Dashboard';

  @override
  String get profileTitle => 'Profile';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get saveButton => 'Save Changes';

  @override
  String get profileSaved => 'Changes saved successfully';

  @override
  String get todayDosesTitle => 'Today\'s Doses';

  @override
  String get noDosesToday => 'No doses scheduled for today';

  @override
  String doseAmountLabel(String amount) {
    return '$amount pill(s)';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusTaken => 'Taken';

  @override
  String get statusSkipped => 'Skipped';

  @override
  String get statusMissed => 'Missed';

  @override
  String get statusSnoozed => 'Snoozed';

  @override
  String get takeDoseButton => 'Mark Taken';

  @override
  String get skipDoseButton => 'Skip';

  @override
  String get medicationsTitle => 'Medications';

  @override
  String get addMedicationTitle => 'Add Medication';

  @override
  String get editMedicationTitle => 'Edit Medication';

  @override
  String get deleteMedicationTitle => 'Delete Medication';

  @override
  String get deleteMedicationConfirm =>
      'Are you sure you want to delete this medication?';

  @override
  String get deleteButton => 'Delete';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get medicationNameLabel => 'Medication Name';

  @override
  String get medicationStrengthLabel => 'Strength (e.g. 5mg)';

  @override
  String get medicationFormLabel => 'Form';

  @override
  String get medicationStockLabel => 'Current Stock (pills)';

  @override
  String get medicationNameRequired => 'Please enter medication name';

  @override
  String get schedulesSectionTitle => 'Dose Schedules';

  @override
  String get addScheduleButton => 'Add Time';

  @override
  String get timeOfDayLabel => 'Time (HH:MM)';

  @override
  String get mealBefore => 'Before meal';

  @override
  String get mealAfter => 'After meal';

  @override
  String get mealWith => 'With meal';

  @override
  String get mealAnytime => 'Anytime';

  @override
  String get noMedicationsYet => 'No medications added yet';

  @override
  String get daysOfWeekLabel => 'Days of Week';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get pairingCodeTitle => 'Caregiver Pairing Code';

  @override
  String get pairingCodeSubtitle =>
      'Share this code with your caregiver to link accounts';

  @override
  String get generatePairingCodeButton => 'Generate New Code';

  @override
  String get pairPatientTitle => 'Link Patient Account';

  @override
  String get pairPatientSubtitle =>
      'Enter the 6-digit code shown on the patient\'s app';

  @override
  String get pairCodeInputLabel => 'Pairing Code';

  @override
  String get pairSubmitButton => 'Link Account';

  @override
  String get pairSuccessMessage => 'Patient linked successfully';

  @override
  String get noLinkedPatients => 'No patients linked to your account yet';

  @override
  String takenMissedSummary(int taken, int missed) {
    return 'Taken: $taken • Missed: $missed';
  }

  @override
  String alertsBadgeLabel(int count) {
    return '$count alert(s)';
  }

  @override
  String get vitalsTitle => 'Vital Signs';

  @override
  String get vitalTypeBp => 'Blood Pressure';

  @override
  String get vitalTypeGlucose => 'Blood Glucose';

  @override
  String get vitalTypePulse => 'Heart Rate';

  @override
  String get vitalValuePrimaryLabel => 'Primary Value';

  @override
  String get vitalValueSecondaryLabel => 'Diastolic Value (BP)';

  @override
  String get addVitalButton => 'Log Reading';

  @override
  String get triageNormal => 'Normal';

  @override
  String get triageBorderline => 'Borderline';

  @override
  String get triageCritical => 'Critical';

  @override
  String get confirmSaveButton => 'Confirm & Save';

  @override
  String get noVitalsRecorded => 'No readings recorded yet';

  @override
  String get scanPrescriptionTitle => 'Scan Prescription';

  @override
  String get pickFromCameraButton => 'Take Photo';

  @override
  String get pickFromGalleryButton => 'Pick from Gallery';

  @override
  String get confirmPrescriptionButton => 'Confirm & Add Medications';

  @override
  String get emergencyContactsTitle => 'Emergency Contacts';

  @override
  String get contactNameLabel => 'Contact Name';

  @override
  String get contactRelationLabel => 'Relationship';

  @override
  String get addContactButton => 'Add Contact';

  @override
  String get sosButtonLabel => 'Emergency SOS';

  @override
  String get sosConfirmTitle => 'Confirm SOS Alert';

  @override
  String get sosConfirmBody =>
      'Do you want to send an urgent SOS alert to your family now?';

  @override
  String get sosConfirmSendButton => 'Send SOS Now';

  @override
  String get sosSentMessage => 'SOS alert sent successfully';

  @override
  String get inventoryTitle => 'Medication Inventory';

  @override
  String daysLeftLabel(int days) {
    return '$days day(s) left';
  }

  @override
  String get lowStockWarning => 'Warning: Less than 7 days left';

  @override
  String get refillOrderButton => 'Order Refill';

  @override
  String get doctorReportTitle => 'Doctor Report (PDF)';

  @override
  String get shareReportButton => 'Share / Print Report';

  @override
  String get reportDisclaimer =>
      'This report is automatically generated by Medliva for clinical follow-up and does not replace direct medical advice.';

  @override
  String get emailRequiredError => 'Please enter your email address';

  @override
  String get emailInvalidError => 'Enter a valid email address';

  @override
  String get passwordRequiredError => 'Please enter your password';

  @override
  String get passwordShortError => 'Password must be at least 6 characters';

  @override
  String get nameRequiredError => 'Please enter your full name';

  @override
  String get navHome => 'Home';

  @override
  String get navMedications => 'Medications';

  @override
  String get navVitals => 'Vitals';

  @override
  String get navMore => 'More';

  @override
  String get navTimeline => 'Timeline';

  @override
  String get navTrends => 'Trends';

  @override
  String get navInventoryComm => 'Inventory & Care';

  @override
  String get navSos => 'SOS';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navSettings => 'Settings';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodMorningGreeting => 'Wishing you a healthy and happy day';

  @override
  String get todayMedicationCardTitle => 'Today\'s Medication';

  @override
  String get weeklyAdherenceTitle => 'Today\'s Medication Adherence';

  @override
  String weeklyAdherenceSub(int taken, int total) {
    return '$taken of $total doses';
  }

  @override
  String get weeklyAdherenceKeepUp => 'Great job, keep it up';

  @override
  String get noPendingDose => 'No dose is pending right now';

  @override
  String get timeForMedicationTitle => 'Time for Medication';

  @override
  String get timeForMedicationTip =>
      'Stay consistent with your medication schedule for better health';

  @override
  String get tookItButton => 'I Took It';

  @override
  String get snoozeButton => 'Snooze';

  @override
  String get stockAvailableBadge => 'Available';

  @override
  String stockRemainingPillsBadge(int count) {
    return '$count pills left';
  }

  @override
  String get stockLowBadge => 'Low Stock';

  @override
  String get onceDaily => 'Once daily';

  @override
  String get twiceDaily => 'Twice daily';

  @override
  String get unitMmHg => 'mmHg';

  @override
  String get unitMgDl => 'mg/dL';

  @override
  String lastReadingAt(String time) {
    return 'Last reading: $time';
  }

  @override
  String get escalationReminder15m => '+15 min: Reminder sent';

  @override
  String get escalationFamily30m => '+30 min: Family members notified';

  @override
  String get escalationDoctor60m =>
      '+60 min: Escalate to doctor if dose remains missed';

  @override
  String get upcomingDoseLabel => 'Upcoming Dose';

  @override
  String get bpLast7Days => 'Blood Pressure (Last 7 Days)';

  @override
  String get glucoseLast7Days => 'Blood Glucose (Last 7 Days)';

  @override
  String get withinNormalCount => 'Normal';

  @override
  String get slightlyHighCount => 'Slightly High';

  @override
  String get highCount => 'High';

  @override
  String get currentInventoryHeader => 'Current Inventory';

  @override
  String get manageMedicationsLink => 'Manage Medications';

  @override
  String get remoteAdjustDosesButton => 'Adjust Doses Remotely';

  @override
  String get communicationHeader => 'Communication';

  @override
  String get messagePharmacyButton => 'Message Pharmacy';

  @override
  String get voiceMessageGrandchildrenTitle => 'Voice Message from Family';

  @override
  String get voiceMessageGrandchildrenQuote =>
      '\"Dear Grandpa .. we love you very much\"';

  @override
  String get callNowUrgentButton => 'Call Now — Urgent Alert';

  @override
  String get aiExtractedNotice =>
      'Data extracted by AI — please review and edit any inaccurate details';

  @override
  String get highConfidenceBadge => 'High Confidence';

  @override
  String get needsReviewBadge => 'Needs Review';

  @override
  String get secureShareTitle => 'Secure Share';

  @override
  String get secureShareSubtitle =>
      'Temporary secure sharing of patient report via QR code';

  @override
  String get expiresIn24Hours => 'Expires in 24 hours';

  @override
  String get expiresIn24HoursSub =>
      'The link will automatically expire after 24 hours to protect patient privacy';

  @override
  String get shareLinkButton => 'Share Link';

  @override
  String get downloadPdfButton => 'Download PDF';

  @override
  String get vitalLoggedSuccess => 'Reading Logged';

  @override
  String get reassuringStatusTitle => 'Status Reassuring';

  @override
  String get reassuringStatusSub => 'Your reading is within normal range';

  @override
  String get sosScreenTitle => 'Emergency SOS';

  @override
  String get sosScreenSubtitle => 'Get help immediately';

  @override
  String get sosHold3Seconds => 'Hold for 3 seconds';

  @override
  String get sosLocationSharingNotice =>
      'Caregivers will be contacted and your current location shared';

  @override
  String get currentLocationShareTitle => 'Share Current Location';

  @override
  String get caregiversSectionTitle => 'Caregivers';

  @override
  String get callNowButton => 'Call Now';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get filterAll => 'All';

  @override
  String get filterMedications => 'Medications';

  @override
  String get filterCaregivers => 'Caregivers';

  @override
  String get filterAlerts => 'Alerts';

  @override
  String get notifDoseTimeTitle => 'Medication Time';

  @override
  String get notifCaregiverMsgTitle => 'Message from Caregiver';

  @override
  String get notifLowStockTitle => 'Low Medication Stock';

  @override
  String get notifHighVitalTitle => 'High Vital Reading';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get fontSizeLabel => 'Font Size';

  @override
  String get fontSizeNormal => 'Normal';

  @override
  String get fontSizeLarge => 'Large';

  @override
  String get fontSizeExtraLarge => 'Extra Large';

  @override
  String get caregiversSettingsTitle => 'Caregivers';

  @override
  String get caregiversSettingsSub => 'Manage and communicate with caregivers';

  @override
  String get notificationSoundTitle => 'Notification Sound';

  @override
  String get notificationSoundSub => 'Clear tone';

  @override
  String get offlineSyncTitle => 'Offline Sync';

  @override
  String get offlineSyncSub => 'Syncs automatically when online';

  @override
  String get reminderNotificationBody => 'It is time to take your dose';

  @override
  String get reminderChannelName => 'Medication reminders';

  @override
  String get reminderChannelDescription =>
      'Alerts for the medication schedule of elderly patients';

  @override
  String get alertSosTitle => 'Emergency SOS';

  @override
  String get alertSosBody => 'An emergency SOS was triggered';

  @override
  String alertSosNote(String note) {
    return 'Note: $note';
  }

  @override
  String get alertCriticalVitalTitle => 'A vital reading needs attention';

  @override
  String alertVitalReading(String value) {
    return 'A reading of $value was recorded';
  }

  @override
  String get alertLowStockTitle => 'Low medication stock';

  @override
  String alertLowStockBody(String name) {
    return 'Stock of ($name) is running low';
  }

  @override
  String get alertMissedDoseTitle => 'Missed dose';

  @override
  String alertMissedDoseBody(String name) {
    return 'The dose of ($name) was not taken on time';
  }

  @override
  String get alertExpiryTitle => 'Medication expired';

  @override
  String alertExpiryBody(String name) {
    return 'The medication ($name) has expired';
  }

  @override
  String get alertGenericBody => 'A new alert from Medliva';

  @override
  String get alertCaregiversNotified => 'Caregivers have been notified';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String notifDoseBody(String name) {
    return 'It is time to take ($name)';
  }

  @override
  String notifDoseSub(String time) {
    return 'Scheduled at $time';
  }

  @override
  String notifLowStockBody(String name) {
    return 'Stock of ($name) is running low';
  }

  @override
  String notifLowStockSub(int days) {
    return '$days days left';
  }

  @override
  String notifHighVitalBody(String value) {
    return 'A reading of $value was recorded';
  }

  @override
  String get notifCaregiverMonitorSub => 'They monitor your condition daily';

  @override
  String notifCaregiversBody(String names) {
    return 'Caregivers: $names';
  }

  @override
  String get notifEmptyTitle => 'No notifications';

  @override
  String get notifEmptySub =>
      'New alerts will show up here as soon as they arrive';

  @override
  String get noEmergencyContacts =>
      'No emergency contacts yet — add one so they can be reached during an emergency';

  @override
  String locationCoordinatesLabel(String lat, String lng) {
    return 'Location: $lat, $lng';
  }

  @override
  String get locationUnavailable =>
      'Location not detected — contacts will be notified without a location';

  @override
  String get scanFrameHint =>
      'Place the prescription inside the frame and take the photo';

  @override
  String get scanNoMedicationsFound =>
      'No medication was recognized in the photo';

  @override
  String get scanNoMedicationsFoundHint =>
      'Try a clearer photo of the box or the prescription';

  @override
  String get doseFrequencyOnce => 'Once daily';

  @override
  String get doseFrequencyTwice => 'Twice daily';

  @override
  String timeAt(String time) {
    return 'At $time';
  }

  @override
  String reportActiveMedsVitalsSummary(int meds, int vitals) {
    return '$meds active medication(s) • $vitals vital reading(s)';
  }

  @override
  String get prescriptionPatientRequired =>
      'Select a patient before scanning a prescription.';

  @override
  String get pillImageTitle => 'Medication photo';

  @override
  String get pillImageEmpty => 'No medication photo added yet';

  @override
  String get pillImageUnavailable => 'Medication photo is unavailable';

  @override
  String get pillImageUploadButton => 'Add or change photo';

  @override
  String get pillImageUploadSuccess => 'Medication photo saved securely';

  @override
  String get pillImageUploadFailed => 'Could not save the medication photo';
}
