import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:washup/core/helpers/format_helper.dart';
import 'package:washup/core/helpers/phone_helper.dart';
import 'package:washup/core/helpers/plate_helper.dart';

void main() {
  final eg = PhoneHelper.byIso(IsoCode.EG)!;
  final sa = PhoneHelper.byIso(IsoCode.SA)!;
  final ae = PhoneHelper.byIso(IsoCode.AE)!;
  final kw = PhoneHelper.byIso(IsoCode.KW)!;

  test('Arabic-Indic and Persian digits become 0-9', () {
    expect(FormatHelper.latinDigits('١٨٠٠'), '1800');
    expect(FormatHelper.latinDigits('۲۰۲۴'), '2024');
    expect(FormatHelper.latinDigits('ب ط ع ١٢٣٤'), 'ب ط ع 1234');
  });

  test('plates typed differently compare the same', () {
    expect(FormatHelper.normalizePlate('أ ب ج ١٢٣'), FormatHelper.normalizePlate('ا ب ج 123'));
    expect(FormatHelper.normalizePlate('hhhh-4444'), 'HHHH4444');
    expect(FormatHelper.normalizePlate('ى ة 12'), FormatHelper.normalizePlate('ي ه12'));
  });

  test('format keeps Arabic letters apart and a Latin code whole', () {
    expect(PlateHelper.format('بطع', '١٢٣٤'), 'ب ط ع 1234');
    expect(PlateHelper.format('a', '12345'), 'A 12345');
    expect(PlateHelper.format('', '٤٥٦٧٨'), '45678');
  });

  test('lettered countries need Arabic letters and up to 4 digits', () {
    expect(PlateHelper.isValid(eg, 'بطع', '1234'), isTrue);
    expect(PlateHelper.isValid(sa, 'ا ب ج', '١٢٣٤'), isTrue);
    expect(PlateHelper.isValid(eg, '', '123'), isFalse);
    expect(PlateHelper.isValid(eg, 'ب', '12345'), isFalse);
  });

  test('coded countries take an optional code and up to 6 digits', () {
    expect(PlateHelper.isValid(ae, 'A', '12345'), isTrue);
    expect(PlateHelper.isValid(ae, '', '123456'), isTrue);
    expect(PlateHelper.isValid(kw, '12', '34567'), isTrue);
    expect(PlateHelper.isValid(ae, 'ABCD', '1'), isFalse);
    expect(PlateHelper.isValid(ae, 'A', '1234567'), isFalse);
  });

  test('parse reads stored plates in either order', () {
    expect(PlateHelper.parse('ب ط ع 1234'), (code: 'بطع', digits: '1234'));
    expect(PlateHelper.parse('١٢٣ اسد'), (code: 'اسد', digits: '123'));
    expect(PlateHelper.parse('A 12345'), (code: 'A', digits: '12345'));
    expect(PlateHelper.parse('45678'), (code: '', digits: '45678'));
    expect(PlateHelper.parse('HHHH4444'), isNull);
  });

  test('a stored plate opens under a country whose rules fit it', () {
    expect(PlateHelper.countryFor('A 12345', eg).iso, isNot(IsoCode.EG));
    expect(PlateHelper.countryFor('ب ط ع 1234', ae).iso, IsoCode.EG);
    expect(PlateHelper.countryFor('ب ط ع 1234', sa).iso, IsoCode.SA);
  });
}
