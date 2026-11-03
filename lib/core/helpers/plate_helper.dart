import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import 'format_helper.dart';
import 'phone_helper.dart';

/// Plates across the Arab countries, in two parts:
/// - lettered plates (Egypt, Saudi Arabia, Jordan…): one to three Arabic
///   letters and one to four digits, stored "ب ط ع 1234";
/// - coded plates (UAE, Kuwait, Qatar…): an optional short code (an emirate
///   letter or number) and a number of up to six digits, stored "A 12345".
/// The country only picks the rules and labels; the stored plate is the text.
class PlateHelper {
  PlateHelper._();

  static final _arabicLetter = RegExp('[\\u0621-\\u064A]');
  static final _lettersRule = RegExp('^[\\u0621-\\u064A]{1,3}\$');
  static final _codeRule = RegExp('^[A-Z0-9]{0,3}\$');

  /// Countries whose plates carry Arabic letters with the number.
  static const _lettered = {IsoCode.EG, IsoCode.SA, IsoCode.JO, IsoCode.IQ, IsoCode.LY, IsoCode.SD, IsoCode.YE};

  static bool lettered(PhoneCountry country) => _lettered.contains(country.iso);

  static int maxDigits(PhoneCountry country) => lettered(country) ? 4 : 6;

  static String _squash(String s) => FormatHelper.latinDigits(s).replaceAll(RegExp(r'\s'), '').toUpperCase();

  static String format(String code, String digits) {
    final c = _squash(code);
    final d = _squash(digits);
    // Arabic letters stay apart ("ب ط ع"), as printed; a Latin code stays whole.
    final shown = _arabicLetter.hasMatch(c) ? c.split('').join(' ') : c;
    return shown.isEmpty ? d : '$shown $d';
  }

  static bool isValid(PhoneCountry country, String code, String digits) {
    final c = _squash(code);
    final d = _squash(digits);
    if (!RegExp('^\\d{1,${maxDigits(country)}}\$').hasMatch(d)) return false;
    return lettered(country) ? _lettersRule.hasMatch(c) : _codeRule.hasMatch(c);
  }

  /// Code (or letters) and number of a stored plate, either order; null for
  /// text that is not a code and a number.
  static ({String code, String digits})? parse(String plate) {
    final text = FormatHelper.latinDigits(plate).trim().toUpperCase();
    final m = RegExp('^([A-Z\\u0621-\\u064A0-9\\s]*?)\\s*(\\d+)\$').firstMatch(text);
    final r = m == null ? RegExp('^(\\d+)\\s*([A-Z\\u0621-\\u064A\\s]+)\$').firstMatch(text) : null;
    if (m == null && r == null) return null;
    final code = _squash(m?[1] ?? r![2]!);
    final digits = m?[2] ?? r![1]!;
    if (code.length > 3 || digits.length > 6) return null;
    return (code: code, digits: digits);
  }

  /// The country to show [plate] under: [preferred] when the plate fits its
  /// rules, else the first country whose rules fit (Egypt for lettered plates).
  static PhoneCountry countryFor(String plate, PhoneCountry preferred) {
    final p = parse(plate);
    if (p == null || isValid(preferred, p.code, p.digits)) return preferred;
    for (final c in PhoneHelper.countries) {
      if (isValid(c, p.code, p.digits)) return c;
    }
    return preferred;
  }

  /// Right-to-left for plates with Arabic letters, so the letters sit on the
  /// right and the digits on the left, as on the car.
  static bool isArabic(String plate) => _arabicLetter.hasMatch(plate);
}

/// Turns Arabic-Indic digits into 0-9 as they are typed.
class LatinDigitsFormatter extends TextInputFormatter {
  const LatinDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = FormatHelper.latinDigits(newValue.text);
    return text == newValue.text ? newValue : newValue.copyWith(text: text);
  }
}

/// The letter part of a plate: up to three Arabic letters kept apart
/// ("ب ط ع", joined letters would read as a word), or, for coded plates, up to
/// three Latin letters or digits in capitals.
class PlateCodeFormatter extends TextInputFormatter {
  final bool arabicLetters;

  const PlateCodeFormatter({required this.arabicLetters});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = FormatHelper.latinDigits(newValue.text).toUpperCase();
    final String out;
    if (arabicLetters) {
      out = PlateHelper._arabicLetter.allMatches(text).map((m) => m[0]!).take(3).join(' ');
    } else {
      out = RegExp('[A-Z0-9]').allMatches(text).map((m) => m[0]!).take(3).join();
    }
    return TextEditingValue(text: out, selection: TextSelection.collapsed(offset: out.length));
  }
}
