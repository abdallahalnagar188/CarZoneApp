import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// A country the phone field offers. [example] is a valid mobile number in
/// national form, shown as the field hint.
class PhoneCountry {
  final IsoCode iso;
  final String dialCode;
  final String nameAr;
  final String nameEn;
  final String example;

  const PhoneCountry(this.iso, this.dialCode, this.nameAr, this.nameEn, this.example);

  /// Regional-indicator emoji built from the two-letter ISO code.
  String get flag => String.fromCharCodes(iso.name.codeUnits.map((c) => c - 0x41 + 0x1F1E6));

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  /// [example] isolated left to right, so it reads correctly inside Arabic text.
  String get exampleLtr => '\u2066$example\u2069';
}

/// A number accepted by [PhoneHelper.parse].
class ParsedPhone {
  final PhoneCountry country;
  final PhoneNumber number;

  const ParsedPhone(this.country, this.number);

  /// E.164, e.g. +966501234567.
  String get e164 => number.international;

  /// For display, e.g. +966 50 123 4567. The parser groups Egyptian mobiles
  /// as "10 01234567", so Egypt keeps the 3-3-4 grouping used so far.
  String get pretty {
    final nsn = number.nsn;
    final grouped = country.iso == IsoCode.EG && nsn.length == 10
        ? '${nsn.substring(0, 3)} ${nsn.substring(3, 6)} ${nsn.substring(6)}'
        : number.formatNsn();
    return '${country.dialCode} $grouped';
  }
}

class PhoneHelper {
  PhoneHelper._();

  /// Every Arab League member: Egypt (the default) first, then the Gulf.
  static const countries = <PhoneCountry>[
    PhoneCountry(IsoCode.EG, '+20', 'مصر', 'Egypt', '010 1234 5678'),
    PhoneCountry(IsoCode.SA, '+966', 'السعودية', 'Saudi Arabia', '050 123 4567'),
    PhoneCountry(IsoCode.AE, '+971', 'الإمارات', 'UAE', '050 123 4567'),
    PhoneCountry(IsoCode.KW, '+965', 'الكويت', 'Kuwait', '500 12345'),
    PhoneCountry(IsoCode.QA, '+974', 'قطر', 'Qatar', '3312 3456'),
    PhoneCountry(IsoCode.BH, '+973', 'البحرين', 'Bahrain', '3600 1234'),
    PhoneCountry(IsoCode.OM, '+968', 'عُمان', 'Oman', '9212 3456'),
    PhoneCountry(IsoCode.JO, '+962', 'الأردن', 'Jordan', '07 9012 3456'),
    PhoneCountry(IsoCode.LB, '+961', 'لبنان', 'Lebanon', '71 123 456'),
    PhoneCountry(IsoCode.IQ, '+964', 'العراق', 'Iraq', '0791 234 5678'),
    PhoneCountry(IsoCode.SY, '+963', 'سوريا', 'Syria', '0944 567 890'),
    PhoneCountry(IsoCode.PS, '+970', 'فلسطين', 'Palestine', '0599 123 456'),
    PhoneCountry(IsoCode.YE, '+967', 'اليمن', 'Yemen', '712 345 678'),
    PhoneCountry(IsoCode.LY, '+218', 'ليبيا', 'Libya', '091 234 5678'),
    PhoneCountry(IsoCode.TN, '+216', 'تونس', 'Tunisia', '20 123 456'),
    PhoneCountry(IsoCode.DZ, '+213', 'الجزائر', 'Algeria', '0551 23 45 67'),
    PhoneCountry(IsoCode.MA, '+212', 'المغرب', 'Morocco', '0650 123456'),
    PhoneCountry(IsoCode.SD, '+249', 'السودان', 'Sudan', '091 123 1234'),
    PhoneCountry(IsoCode.MR, '+222', 'موريتانيا', 'Mauritania', '22 12 34 56'),
    PhoneCountry(IsoCode.SO, '+252', 'الصومال', 'Somalia', '7 1123456'),
    PhoneCountry(IsoCode.DJ, '+253', 'جيبوتي', 'Djibouti', '77 83 10 01'),
    PhoneCountry(IsoCode.KM, '+269', 'جزر القمر', 'Comoros', '321 23 45'),
  ];

  static PhoneCountry get defaultCountry => countries.first;

  static PhoneCountry? byIso(IsoCode iso) {
    for (final c in countries) {
      if (c.iso == iso) return c;
    }
    return null;
  }

  /// The country whose dial code starts [e164], e.g. a number saved earlier.
  static PhoneCountry? fromE164(String e164) {
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    for (final c in countries) {
      if (digits.startsWith(c.dialCode.substring(1))) return c;
    }
    return null;
  }

  /// Parses a mobile number typed for [country]. Accepts the national form
  /// with or without the trunk 0, the dial code without "+", or a full
  /// international number, which may switch to another supported country.
  /// Returns null when it is not a valid mobile number.
  static ParsedPhone? parse(String input, PhoneCountry country) {
    final trimmed = input.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    final international = trimmed.startsWith('+') || digits.startsWith('00');
    final candidates = international
        ? ['+${digits.replaceFirst(RegExp(r'^00'), '')}']
        : [digits, if (digits.startsWith(country.dialCode.substring(1))) '+$digits'];

    for (final candidate in candidates) {
      final PhoneNumber number;
      try {
        // A "+" number carries its own country; a destination would override it.
        number = candidate.startsWith('+')
            ? PhoneNumber.parse(candidate)
            : PhoneNumber.parse(candidate, destinationCountry: country.iso);
      } catch (_) {
        continue;
      }
      final match = byIso(number.isoCode);
      if (match == null || !number.isValid(type: PhoneNumberType.mobile)) continue;
      if (!international && match != country) continue;
      return ParsedPhone(match, number);
    }
    return null;
  }
}
