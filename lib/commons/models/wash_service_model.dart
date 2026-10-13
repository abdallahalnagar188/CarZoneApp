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
}
