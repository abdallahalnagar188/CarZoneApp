class CustomerModel {
  final String id;
  String name;
  final String phone;

  CustomerModel({required this.id, required this.name, required this.phone});

  String get firstName => name.trim().split(' ').first;
}
