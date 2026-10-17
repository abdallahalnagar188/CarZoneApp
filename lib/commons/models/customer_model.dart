class CustomerModel {
  final String id;
  String? userId;
  String name;
  final String phone;
  String locale;
  String status;
  DateTime? lastActiveAt;
  String? accessToken;
  DateTime? tokenUpdatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.userId,
    this.locale = 'ar',
    this.status = 'active',
    this.lastActiveAt,
    this.accessToken,
    this.tokenUpdatedAt,
  });

  String get firstName => name.trim().split(' ').first;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      locale: json['locale']?.toString() ?? 'ar',
      status: json['status']?.toString() ?? 'active',
      lastActiveAt: DateTime.tryParse(json['last_active_at']?.toString() ?? ''),
      accessToken: json['access_token']?.toString() ?? json['accessToken']?.toString(),
      tokenUpdatedAt: DateTime.tryParse(json['token_updated_at']?.toString() ?? json['tokenUpdatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (userId != null) 'user_id': userId,
    'name': name,
    'phone': phone.replaceAll(' ', ''),
    'locale': locale,
    'status': status,
    if (lastActiveAt != null) 'last_active_at': lastActiveAt!.toIso8601String(),
  };

  Map<String, dynamic> toLocalJson() => {
    ...toJson(),
    'access_token': accessToken,
    if (tokenUpdatedAt != null) 'token_updated_at': tokenUpdatedAt!.toIso8601String(),
  };
}
