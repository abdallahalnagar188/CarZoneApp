import 'localized_text.dart';

/// A country Wash Up can work in, from the `countries` table: its currency,
/// time zone and a centre to measure from when nothing nearer is known.
class CountryModel {
  final String code;
  final LocalizedText name;
  final String currency;
  final LocalizedText currencySymbol;
  final int currencyDecimals;
  final String timezone;
  final double lat;
  final double lng;

  const CountryModel({
    required this.code,
    required this.name,
    required this.currency,
    required this.currencySymbol,
    required this.currencyDecimals,
    required this.timezone,
    required this.lat,
    required this.lng,
  });

  /// Egypt, used until the countries arrive (and for anything without one).
  static const egypt = CountryModel(
    code: 'EG',
    name: LocalizedText('مصر', 'Egypt'),
    currency: 'EGP',
    currencySymbol: LocalizedText('ج.م', 'EGP'),
    currencyDecimals: 2,
    timezone: 'Africa/Cairo',
    lat: 30.0444,
    lng: 31.2357,
  );

  /// Regional-indicator emoji built from the two-letter code.
  String get flag => String.fromCharCodes(code.toUpperCase().codeUnits.map((c) => c - 0x41 + 0x1F1E6));

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
        code: json['code']?.toString() ?? 'EG',
        name: LocalizedText.fromJson(json['name']),
        currency: json['currency']?.toString() ?? 'EGP',
        currencySymbol: LocalizedText.fromJson(json['currency_symbol'] ?? json['currency']),
        currencyDecimals: (json['currency_decimals'] as num?)?.toInt() ?? 2,
        timezone: json['timezone']?.toString() ?? 'Africa/Cairo',
        lat: (json['lat'] as num?)?.toDouble() ?? egypt.lat,
        lng: (json['lng'] as num?)?.toDouble() ?? egypt.lng,
      );
}
