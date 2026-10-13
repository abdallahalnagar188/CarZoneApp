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
}
