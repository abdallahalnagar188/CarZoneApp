import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:washup/core/helpers/phone_helper.dart';

PhoneCountry _c(IsoCode iso) => PhoneHelper.byIso(iso)!;

void main() {
  test('every country example is a valid mobile for that country', () {
    for (final c in PhoneHelper.countries) {
      final parsed = PhoneHelper.parse(c.example, c);
      expect(parsed, isNotNull, reason: '${c.nameEn} example ${c.example}');
      expect(parsed!.country, c);
      expect(parsed.e164, startsWith(c.dialCode));
    }
  });

  test('dial codes match the parser metadata', () {
    for (final c in PhoneHelper.countries) {
      final parsed = PhoneHelper.parse(c.example, c)!;
      expect('+${parsed.number.countryCode}', c.dialCode, reason: c.nameEn);
    }
  });

  test('Egyptian numbers in every form the old field accepted', () {
    final eg = _c(IsoCode.EG);
    for (final input in ['01001234567', '1001234567', '201001234567', '+20 100 123 4567', '00201001234567']) {
      expect(PhoneHelper.parse(input, eg)?.e164, '+201001234567', reason: input);
    }
    expect(PhoneHelper.parse('01001234567', eg)!.pretty, '+20 100 123 4567');
  });

  test('rejects landlines, short numbers and other countries\' numbers', () {
    final eg = _c(IsoCode.EG);
    expect(PhoneHelper.parse('0223456789', eg), isNull); // Cairo landline
    expect(PhoneHelper.parse('0100123', eg), isNull);
    expect(PhoneHelper.parse('0501234567', eg), isNull); // Saudi number, Egypt picked
    expect(PhoneHelper.parse('', eg), isNull);
    expect(PhoneHelper.parse('+447700900123', eg), isNull); // UK, not offered
  });

  test('Gulf numbers with or without the trunk 0', () {
    final sa = _c(IsoCode.SA);
    expect(PhoneHelper.parse('0501234567', sa)?.e164, '+966501234567');
    expect(PhoneHelper.parse('501234567', sa)?.e164, '+966501234567');
    expect(PhoneHelper.parse('0501234567', _c(IsoCode.AE))?.e164, '+971501234567');
    expect(PhoneHelper.parse('50012345', _c(IsoCode.KW))?.e164, '+96550012345');
  });

  test('a full international number switches to its country', () {
    final parsed = PhoneHelper.parse('+966 50 123 4567', _c(IsoCode.EG));
    expect(parsed?.country.iso, IsoCode.SA);
    expect(parsed?.e164, '+966501234567');
  });

  test('fromE164 finds the country of a saved number', () {
    expect(PhoneHelper.fromE164('+966501234567')?.iso, IsoCode.SA);
    expect(PhoneHelper.fromE164('+201001234567')?.iso, IsoCode.EG);
  });

  test('flag emoji', () {
    expect(_c(IsoCode.EG).flag, '🇪🇬');
  });
}
