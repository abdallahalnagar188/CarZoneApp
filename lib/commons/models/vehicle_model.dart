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

  static const Map<String, List<String>> makes = {
    'Toyota': ['Corolla', 'Camry', 'Yaris', 'Fortuner'],
    'Hyundai': ['Elantra', 'Tucson', 'Accent', 'Creta'],
    'Kia': ['Sportage', 'Cerato', 'Picanto', 'Sorento'],
    'Nissan': ['Sunny', 'Qashqai', 'Sentra'],
    'Chevrolet': ['Optra', 'Captiva', 'Aveo'],
    'MG': ['MG 5', 'HS', 'ZS'],
    'Mercedes': ['C 200', 'E 200', 'GLC'],
    'BMW': ['320i', 'X3', 'X5'],
  };

  Color get swatch => colors[color] ?? colors['white']!;
}
