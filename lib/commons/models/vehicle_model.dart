import 'package:flutter/material.dart';

class VehicleModel {
  final String id;
  final String customerId;
  String make;
  String model;
  int? year;
  String color;
  String plate;
  bool isDefault;

  VehicleModel({
    required this.id,
    required this.customerId,
    required this.make,
    required this.model,
    required this.color,
    required this.plate,
    this.year,
    this.isDefault = false,
  });

  String get title => '$make $model';

  static const Map<String, Color> colors = {
    'white': Color(0xFFF4F7FB),
    'black': Color(0xFF1B2430),
    'silver': Color(0xFFC0C8D2),
    'gray': Color(0xFF7B8794),
    'blue': Color(0xFF1689C9),
    'red': Color(0xFFD94848),
    'green': Color(0xFF2E9E6A),
    'beige': Color(0xFFE5D3B3),
  };

  /// Spoken names for the swatches, so a selected white is not just an empty circle.
  static const colorNames = {
    'white': 'color.white',
    'black': 'color.black',
    'silver': 'color.silver',
    'gray': 'color.gray',
    'blue': 'color.blue',
    'red': 'color.red',
    'green': 'color.green',
    'beige': 'color.beige',
  };

  Color get swatch => colors[color] ?? colors['white']!;

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: (json['year'] as num?)?.toInt(),
      color: json['color']?.toString() ?? 'white',
      plate: json['plate']?.toString() ?? '',
      isDefault: json['is_default'] ?? json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'make': make,
    'model': model,
    'year': year,
    'color': color,
    'plate': plate,
    'is_default': isDefault,
  };
}
