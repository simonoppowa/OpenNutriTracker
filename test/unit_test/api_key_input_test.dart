import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/api_key_input.dart';

// Every key here is an obviously fake string. None is, or was ever, a real
// credential.
const _legacyKey = 'AIzaSyFAKE-fake_FAKEfakeFAKEfakeFAKEfake0';
const _authKey = 'AQ.FAKE-fake_FAKE.fakeFAKEfakeFAKEfake0123';

void main() {
  group('cleanApiKey', () {
    test('leaves a legacy AIza key as it is', () {
      expect(cleanApiKey(_legacyKey), _legacyKey);
    });

    test('leaves a new AQ. auth key as it is (#1253)', () {
      expect(cleanApiKey(_authKey), _authKey);
    });

    test('drops whitespace and a newline picked up while pasting', () {
      expect(cleanApiKey('  $_authKey\n'), _authKey);
      expect(cleanApiKey('\t$_legacyKey\r\n'), _legacyKey);
    });

    test('drops invisible characters a copy can carry (#1253)', () {
      // U+2060 WORD JOINER is what the #1253 report itself has around every
      // "AQ...", and `String.trim` keeps it. Zero-width space, the BOM and a
      // soft hyphen arrive the same way from notes apps and web pages.
      expect(cleanApiKey('\u2060$_authKey\u2060'), _authKey);
      expect(cleanApiKey('\u200B$_authKey'), _authKey);
      expect(cleanApiKey('AQ.\u2060FAKE-fake'), 'AQ.FAKE-fake');
      expect(cleanApiKey('\uFEFF$_legacyKey\u00AD'), _legacyKey);
    });

    test('an empty or blank key cleans to empty', () {
      expect(cleanApiKey(''), '');
      expect(cleanApiKey('   \n'), '');
      expect(cleanApiKey('\u2060\u200B'), '');
    });

    test('keeps what it cannot safely remove, for the check to refuse', () {
      expect(cleanApiKey('AQ.FAKE fake'), 'AQ.FAKE fake');
      expect(cleanApiKey('AQ.FAKE\nfake'), 'AQ.FAKE\nfake');
    });
  });

  group('isWellFormedApiKey', () {
    test('accepts both Google key formats without asking for a prefix', () {
      expect(isWellFormedApiKey(_legacyKey), isTrue);
      expect(isWellFormedApiKey(_authKey), isTrue);
    });

    test('accepts the other providers and a proxy token', () {
      expect(isWellFormedApiKey('sk-ant-api03-FAKEfakeFAKE'), isTrue);
      expect(isWellFormedApiKey('sk-or-v1-0123456789abcdef'), isTrue);
      expect(isWellFormedApiKey('fake/proxy+token=='), isTrue);
    });

    test('refuses an empty key', () {
      expect(isWellFormedApiKey(''), isFalse);
    });

    test('refuses what cannot travel in an HTTP header', () {
      // Two keys pasted together, a key broken over two lines, and a
      // character outside ASCII: each makes the request fail before it
      // leaves the phone, which the app reported as a connection problem.
      expect(isWellFormedApiKey('AQ.FAKE fake'), isFalse);
      expect(isWellFormedApiKey('AQ.FAKE\nfake'), isFalse);
      expect(isWellFormedApiKey('AQ.FAKE\u2060fake'), isFalse);
      expect(isWellFormedApiKey('AQ.FAKÉ'), isFalse);
      expect(isWellFormedApiKey('“$_authKey”'), isFalse);
    });
  });
}
