import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constance/api_paths.dart';
import '../constance/supabase_constants.dart';
import '../enums/enums.dart';
import '../local/cache_helper.dart';

class DioHelper {
  static final Dio dio = Dio();

  static Future<void> init() async {
    dio.options = BaseOptions(
      baseUrl: ApiEndPoints.baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      validateStatus: (status) => status! < 500,
    );
    await _updateHeaders();
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: false,
          maxWidth: 90,
        ),
      );
    }
  }

  static Future<void> _updateHeaders() async {
    final token = await CacheHelper.safeRead(key: CacheKeys.userToken.name);
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'apikey': SupabaseConstants.supabasePublishableKey,
      'Accept-Language': CacheHelper.getData(key: 'langCode') ?? 'ar',
      'Authorization': token != null && token.isNotEmpty
          ? 'Bearer $token'
          : 'Bearer ${SupabaseConstants.supabasePublishableKey}',
    };
  }

  static Future<void> updateHeadersManually() => _updateHeaders();

  static Future<Response> getData({
    required String url,
    Map<String, dynamic>? query,
  }) async {
    try {
      await _updateHeaders();
      return await dio.get(url, queryParameters: query);
    } catch (e) {
      log('GET Error [$url]: $e');
      rethrow;
    }
  }

  static Future<Response> postData({required String url, dynamic data}) async {
    try {
      await _updateHeaders();
      return await dio.post(url, data: data);
    } catch (e) {
      log('POST Error [$url]: $e');
      rethrow;
    }
  }

  static Future<Response> putData({required String url, dynamic data}) async {
    try {
      await _updateHeaders();
      return await dio.put(url, data: data);
    } catch (e) {
      log('PUT Error [$url]: $e');
      rethrow;
    }
  }

  static Future<Response> patchData({required String url, dynamic data}) async {
    try {
      await _updateHeaders();
      return await dio.patch(url, data: data);
    } catch (e) {
      log('PATCH Error [$url]: $e');
      rethrow;
    }
  }

  static Future<Response> deleteData({
    required String url,
    Map<String, dynamic>? query,
  }) async {
    try {
      await _updateHeaders();
      return await dio.delete(url, queryParameters: query);
    } catch (e) {
      log('DELETE Error [$url]: $e');
      rethrow;
    }
  }
}
