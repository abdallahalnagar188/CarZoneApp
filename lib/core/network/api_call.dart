import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/connectivity_service.dart';

enum ApiErrorType { offline, timeout, server, unauthorized }

/// A request that failed on the way to or from the server (no connection,
/// timeout, 5xx, expired session), as opposed to a refusal the server sent
/// on purpose (RLS, validation, RPC `raise`), which keeps its own type.
class ApiException implements Exception {
  final ApiErrorType type;
  final Object? cause;

  const ApiException(this.type, [this.cause]);

  /// Worth trying again: the same request may succeed in a moment.
  bool get isTransient => type != ApiErrorType.unauthorized;

  String get message => switch (type) {
        ApiErrorType.offline => 'error.offline'.tr,
        ApiErrorType.timeout => 'error.timeout'.tr,
        ApiErrorType.server => 'error.server'.tr,
        ApiErrorType.unauthorized => 'error.session'.tr,
      };

  /// Classifies [error] as a transport failure, or returns null when the
  /// server answered and the caller should read the error itself.
  static ApiException? from(Object error) {
    if (error is ApiException) return error;
    if (error is TimeoutException) return ApiException(ApiErrorType.timeout, error);
    if (error is SocketException ||
        error is HandshakeException ||
        error is HttpException ||
        error is http.ClientException) {
      return ApiException(ApiErrorType.offline, error);
    }
    if (error is PostgrestException) {
      final status = int.tryParse(error.code ?? '');
      if (status != null && status >= 500) return ApiException(ApiErrorType.server, error);
      // statement_timeout
      if (error.code == '57014') return ApiException(ApiErrorType.timeout, error);
      // JWT expired / invalid
      if (error.code == 'PGRST301' || error.code == 'PGRST303') {
        return ApiException(ApiErrorType.unauthorized, error);
      }
      return null;
    }
    if (error is AuthRetryableFetchException) {
      // gotrue raises it for network errors (no status) and for 5xx answers.
      return ApiException(
        error.statusCode == null ? ApiErrorType.offline : ApiErrorType.server,
        error,
      );
    }
    if (error is FunctionException && error.status >= 500) {
      return ApiException(ApiErrorType.server, error);
    }
    if (error is StorageException && (int.tryParse(error.statusCode ?? '') ?? 0) >= 500) {
      return ApiException(ApiErrorType.server, error);
    }
    return null;
  }

  /// User-facing text for any error a request can end with.
  static String messageFor(Object error, {String? fallback}) =>
      from(error)?.message ?? fallback ?? 'error.body'.tr;

  @override
  String toString() => 'ApiException(${type.name}${cause == null ? '' : ': $cause'})';
}

/// One way to call the backend: every request gets a timeout, transport
/// failures become [ApiException], and the connectivity state is kept up to
/// date. Wrap the request in a closure so a retry builds a fresh query:
///
/// ```dart
/// final rows = await ApiCall.read(() => client.from('areas').select(), tag: 'areas');
/// ```
class ApiCall {
  ApiCall._();

  static const readTimeout = Duration(seconds: 15);
  static const writeTimeout = Duration(seconds: 20);

  /// Idempotent request (select, read-only RPC): retried with a short
  /// backoff when it fails on the way.
  static Future<T> read<T>(
    Future<T> Function() request, {
    String? tag,
    int retries = 2,
    Duration timeout = readTimeout,
  }) =>
      _run(request, tag: tag, retries: retries, timeout: timeout);

  /// Request that changes data: never retried, since a timed-out write may
  /// still have reached the server.
  static Future<T> write<T>(
    Future<T> Function() request, {
    String? tag,
    Duration timeout = writeTimeout,
  }) =>
      _run(request, tag: tag, retries: 0, timeout: timeout);

  static Future<T> _run<T>(
    Future<T> Function() request, {
    required String? tag,
    required int retries,
    required Duration timeout,
  }) async {
    final connectivity = ConnectivityService.maybe;
    for (var attempt = 0;; attempt++) {
      // No network interface at all: fail now instead of waiting for a timeout.
      if (connectivity != null && !connectivity.hasNetwork) {
        throw const ApiException(ApiErrorType.offline);
      }
      try {
        final result = await request().timeout(timeout);
        connectivity?.reportSuccess();
        return result;
      } catch (e) {
        final failure = ApiException.from(e);
        if (failure == null) {
          // The server answered: we are online, the caller handles the refusal.
          connectivity?.reportSuccess();
          rethrow;
        }
        if (failure.type == ApiErrorType.offline || failure.type == ApiErrorType.timeout) {
          connectivity?.reportFailure();
        }
        dev.log('[ApiCall] ${tag ?? 'request'} failed (attempt ${attempt + 1}): '
            '${failure.type.name} ${failure.cause ?? ''}');
        final canRetry = attempt < retries && failure.isTransient && (connectivity?.hasNetwork ?? true);
        if (!canRetry) throw failure;
        await Future.delayed(_backoff(attempt));
      }
    }
  }

  static final _random = Random();

  static Duration _backoff(int attempt) =>
      Duration(milliseconds: 600 * (1 << attempt) + _random.nextInt(300));
}
