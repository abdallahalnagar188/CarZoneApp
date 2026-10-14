class CustomerModel {
  final String id;
  String name;
  final String phone;
  String? accessToken;
  DateTime? tokenUpdatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.accessToken,
    this.tokenUpdatedAt,
  });

  String get firstName => name.trim().split(' ').first;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      accessToken: json['access_token']?.toString() ?? json['accessToken']?.toString(),
      tokenUpdatedAt: DateTime.tryParse(json['token_updated_at'] ?? json['tokenUpdatedAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'access_token': accessToken,
    if (tokenUpdatedAt != null) 'token_updated_at': tokenUpdatedAt!.toIso8601String(),
  };
}
