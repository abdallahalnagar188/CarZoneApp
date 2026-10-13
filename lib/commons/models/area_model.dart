import 'localized_text.dart';

class AreaModel {
  final String id;
  final LocalizedText name;
  final double lat;
  final double lng;

  const AreaModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id']?.toString() ?? '',
      name: LocalizedText.fromJson(json['name']),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name.toJson(),
    'lat': lat,
    'lng': lng,
  };
}
