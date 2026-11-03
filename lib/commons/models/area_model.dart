import 'localized_text.dart';

class AreaModel {
  final String id;
  final LocalizedText name;
  final String countryCode;

  /// The area's centre; null for an area nobody has placed on the map yet.
  final double? lat;
  final double? lng;

  const AreaModel({
    required this.id,
    required this.name,
    this.countryCode = 'EG',
    this.lat,
    this.lng,
  });

  bool get placed => lat != null && lng != null;

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id']?.toString() ?? '',
      name: LocalizedText.fromJson(json['name']),
      countryCode: json['country_code']?.toString() ?? 'EG',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name.toJson(),
    'country_code': countryCode,
    'lat': lat,
    'lng': lng,
  };
}
