import '../../core/enums/enums.dart';
import 'localized_text.dart';

class WashServiceModel {
  final String id;
  final String branchId;
  final ServiceType type;
  final String category;
  final LocalizedText name;
  final LocalizedText description;
  final int price;
  final int durationMin;
  final bool active;

  const WashServiceModel({
    required this.id,
    required this.branchId,
    required this.type,
    required this.category,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMin,
    this.active = true,
  });

  bool get isPrimary => type == ServiceType.primary;

  factory WashServiceModel.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type']?.toString() ?? 'primary').toLowerCase();
    final type = typeStr == 'addon' ? ServiceType.addon : ServiceType.primary;

    return WashServiceModel(
      id: json['id']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? json['branchId']?.toString() ?? '',
      type: type,
      category: json['category']?.toString() ?? '',
      name: LocalizedText.fromJson(json['name']),
      description: LocalizedText.fromJson(json['description']),
      price: (json['price'] as num?)?.toInt() ?? 0,
      durationMin: (json['duration_min'] ?? json['durationMin'] as num?)?.toInt() ?? 30,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_id': branchId,
    'type': type == ServiceType.addon ? 'addon' : 'primary',
    'category': category,
    'name': name.toJson(),
    'description': description.toJson(),
    'price': price,
    'duration_min': durationMin,
    'active': active,
  };
}
