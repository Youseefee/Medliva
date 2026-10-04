import 'package:careelder/core/utils/phone_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneValidator', () {
    test('normalizes standard local Egyptian mobile numbers', () {
      expect(
        PhoneValidator.normalizeEgyptianPhone('01012345678'),
        '+201012345678',
      );
      expect(
        PhoneValidator.normalizeEgyptianPhone('01112345678'),
        '+201112345678',
      );
      expect(
        PhoneValidator.normalizeEgyptianPhone('01212345678'),
        '+201212345678',
      );
      expect(
        PhoneValidator.normalizeEgyptianPhone('01512345678'),
        '+201512345678',
      );
    });

    test('normalizes international formats and handles symbols', () {
      expect(
        PhoneValidator.normalizeEgyptianPhone('+201012345678'),
        '+201012345678',
      );
      expect(
        PhoneValidator.normalizeEgyptianPhone('00201012345678'),
        '+201012345678',
      );
      expect(
        PhoneValidator.normalizeEgyptianPhone(' 010-1234-5678 '),
        '+201012345678',
      );
    });

    test('rejects invalid numbers', () {
      expect(PhoneValidator.normalizeEgyptianPhone('01312345678'), isNull);
      expect(PhoneValidator.normalizeEgyptianPhone('12345'), isNull);
      expect(PhoneValidator.normalizeEgyptianPhone('abcdef'), isNull);
    });
  });
}
