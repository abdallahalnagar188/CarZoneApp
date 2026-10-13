
import '../../commons/models/pagination_model.dart';

class ApiResponseHandler<T> {
  final bool success;
  final String message;
  final T? data;
  final List<T>? dataList;
  final String? errorMessage;
  final String? rawStringData; // NEW: Handles `String` responses
  final Pagination? pagination; // NEW: Store pagination object

  ApiResponseHandler(
      {required this.success,
      required this.message,
      this.data,
      this.dataList,
      this.errorMessage,
      this.rawStringData,
      this.pagination});

  /// Handle success when `data` is an object
  factory ApiResponseHandler.successSingle(T? data, String message,
      {Pagination? pagination}) {
    return ApiResponseHandler<T>(
      success: true,
      message: message,
      data: data,
      pagination: pagination,
    );
  }

  /// Handle success when `data` is a String
  factory ApiResponseHandler.successString(
    String rawStringData,
    String message,
  ) {
    return ApiResponseHandler<T>(
      success: true,
      message: message,
      rawStringData: rawStringData, // NEW: Stores the raw string response
    );
  }

  /// Handle success when `data` is a list
  factory ApiResponseHandler.successList(List<T> dataList, String message,
      {Pagination? pagination}) {
    return ApiResponseHandler<T>(
      success: true,
      message: message,
      dataList: dataList,
      pagination: pagination,
    );
  }

  /// Handle success when `data` is `null`
  factory ApiResponseHandler.successWithoutData(String message) {
    return ApiResponseHandler<T>(
      success: true,
      message: message,
    );
  }

  /// Handle API failure
  factory ApiResponseHandler.failure(String errorMessage, String message) {
    return ApiResponseHandler<T>(
      success: false,
      message: message,
      errorMessage: errorMessage,
    );
  }
}
