class PhoneValidator {
  PhoneValidator._();

  static final RegExp _egMobileRegex = RegExp(r'^\+201[0125]\d{8}$');

  /// Normalizes an Egyptian phone string to E.164 (+201XXXXXXXXX).
  /// Returns null if the number is not a valid Egyptian mobile number.
  static String? normalizeEgyptianPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('00')) {
      digits = '+${digits.substring(2)}';
    } else if (digits.startsWith('0')) {
      digits = '+20${digits.substring(1)}';
    } else if (digits.startsWith('20')) {
      digits = '+$digits';
    }

    if (_egMobileRegex.hasMatch(digits)) {
      return digits;
    }
    return null;
  }

  static bool isValidEgyptianPhone(String raw) {
    return normalizeEgyptianPhone(raw) != null;
  }
}
