class BaseApiResponse<T> {
  final bool status;
  final String? message;
  final T? data;

  BaseApiResponse({
    required this.status,
    this.message,
    this.data,
  });

  bool get isSuccess => status;

  String get displayMessage => message?.trim().isNotEmpty == true ? message! : '';

  factory BaseApiResponse.fromBody(
    dynamic body, {
    T Function(dynamic json)? fromData,
  }) {
    if (body is! Map<String, dynamic>) {
      return BaseApiResponse<T>(status: false);
    }
    return BaseApiResponse.fromJson(body, fromData: fromData);
  }

  factory BaseApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json)? fromData,
  }) {
    final rawData = json['data'];
    T? parsed;
    if (fromData != null && rawData != null) {
      try {
        parsed = fromData(rawData);
      } catch (_) {
        parsed = null;
      }
    }
    return BaseApiResponse<T>(
      status: json['status'] == true,
      message: json['message']?.toString(),
      data: parsed,
    );
  }
}
