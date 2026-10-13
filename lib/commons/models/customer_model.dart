class CustomerModel {
  final String id;
  String name;
  final String phone;

  CustomerModel({required this.id, required this.name, required this.phone});

  String get firstName => name.trim().split(' ').first;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
  };
}
