import 'package:dio/dio.dart';

import '../enums/enums.dart';
import 'api_response_handler.dart';
import 'dio_helper.dart';

class ApiService {
  static Future<ApiResponseHandler<T>> sendRequest<T>({
    required String url,
    required T Function(Map<String, dynamic>) fromJson,
    dynamic body,
    Map<String, dynamic>? query,
    RequestMethod method = RequestMethod.get,
  }) async {
    try {
      final Response response = switch (method) {
        RequestMethod.get => await DioHelper.getData(url: url, query: query),
        RequestMethod.post => await DioHelper.postData(url: url, data: body),
        RequestMethod.put => await DioHelper.putData(url: url, data: body),
        RequestMethod.patch => await DioHelper.patchData(url: url, data: body),
        RequestMethod.delete =>
          await DioHelper.deleteData(url: url, query: query),
      };
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        final data = response.data;
        if (data is List) {
          return ApiResponseHandler.successList(
            data.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
            'success',
          );
        }
        if (data is Map<String, dynamic>) {
          return ApiResponseHandler.successSingle(fromJson(data), 'success');
        }
        return ApiResponseHandler.successWithoutData('success');
      }
      return ApiResponseHandler.failure(_handleStatusCode(code), 'error');
    } on DioException catch (e) {
      return ApiResponseHandler.failure(_handleDioError(e), 'network');
    }
  }

  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      default:
        return 'Unexpected error';
    }
  }

  static String _handleDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (e.response != null) return _handleStatusCode(e.response!.statusCode);
    return 'No internet connection';
  }
}
