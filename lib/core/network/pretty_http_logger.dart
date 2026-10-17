import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A pretty HTTP client logger for debug mode, mirroring the visual style of [pretty_dio_logger].
///
/// Intercepts all requests, responses, and errors, formatting them with clean ASCII box borders,
/// duration calculation, and formatted JSON bodies. In release/profile mode, logging is completely bypassed.
class PrettyHttpLogger extends http.BaseClient {
  final http.Client _innerClient;
  final bool request;
  final bool requestHeader;
  final bool requestBody;
  final bool responseHeader;
  final bool responseBody;
  final bool error;
  final int maxWidth;
  final void Function(String message)? logPrint;

  static const String _topBorder = '┌──────────────────────────────────────────────────────────────────────────────────────────';
  static const String _divider = '├──────────────────────────────────────────────────────────────────────────────────────────';
  static const String _bottomBorder = '└──────────────────────────────────────────────────────────────────────────────────────────';
  static const String _linePrefix = '│ ';

  PrettyHttpLogger({
    http.Client? innerClient,
    this.request = true,
    this.requestHeader = true,
    this.requestBody = true,
    this.responseHeader = false,
    this.responseBody = true,
    this.error = true,
    this.maxWidth = 90,
    this.logPrint,
  }) : _innerClient = innerClient ?? http.Client();

  void _print(String message) {
    if (logPrint != null) {
      logPrint!(message);
    } else {
      debugPrint(message);
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Zero overhead in release mode
    if (!kDebugMode) {
      return _innerClient.send(request);
    }

    final stopwatch = Stopwatch()..start();
    _logRequest(request);

    try {
      final streamedResponse = await _innerClient.send(request);
      final bytes = await streamedResponse.stream.toBytes();
      stopwatch.stop();

      _logResponse(
        request: request,
        response: streamedResponse,
        bodyBytes: bytes,
        durationMs: stopwatch.elapsedMilliseconds,
      );

      return http.StreamedResponse(
        http.ByteStream.fromBytes(bytes),
        streamedResponse.statusCode,
        contentLength: bytes.length,
        request: streamedResponse.request,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logException(
        request: request,
        errorObject: e,
        stackTrace: stackTrace,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      rethrow;
    }
  }

  String _line(String text) => '$_linePrefix$text';

  void _logRequest(http.BaseRequest req) {
    if (!request) return;

    final buffer = <String>[];
    buffer.add(_topBorder);
    buffer.add(_line('🌐 [HTTP REQUEST] ${req.method} ${req.url}'));

    if (requestHeader && req.headers.isNotEmpty) {
      buffer.add(_divider);
      buffer.add(_line('Headers:'));
      for (final entry in req.headers.entries) {
        buffer.add(_line('  ${entry.key}: ${_sanitizeHeader(entry.key, entry.value)}'));
      }
    }

    if (requestBody) {
      final bodyStr = _extractRequestBody(req);
      if (bodyStr != null && bodyStr.trim().isNotEmpty) {
        buffer.add(_divider);
        buffer.add(_line('Body:'));
        for (final line in _formatBodyLines(bodyStr)) {
          buffer.add(_line('  $line'));
        }
      }
    }

    buffer.add(_bottomBorder);
    _print(buffer.join('\n'));
  }

  void _logResponse({
    required http.BaseRequest request,
    required http.StreamedResponse response,
    required List<int> bodyBytes,
    required int durationMs,
  }) {
    final status = response.statusCode;
    final isSuccess = status >= 200 && status < 300;
    final isRedirect = status >= 300 && status < 400;
    final statusIcon = isSuccess ? '🟢' : (isRedirect ? '🟡' : '🔴');
    final reason = response.reasonPhrase ?? _defaultReasonPhrase(status);

    final buffer = <String>[];
    buffer.add(_topBorder);
    buffer.add(_line('$statusIcon [HTTP RESPONSE] $status $reason (${durationMs}ms)'));
    buffer.add(_line('URL: ${request.url}'));

    if (responseHeader && response.headers.isNotEmpty) {
      buffer.add(_divider);
      buffer.add(_line('Headers:'));
      for (final entry in response.headers.entries) {
        buffer.add(_line('  ${entry.key}: ${entry.value}'));
      }
    }

    if (responseBody && bodyBytes.isNotEmpty) {
      final decodedBody = _decodeBytes(bodyBytes);
      if (decodedBody.trim().isNotEmpty) {
        buffer.add(_divider);
        buffer.add(_line(isSuccess ? 'Body:' : 'Error Body:'));
        for (final line in _formatBodyLines(decodedBody)) {
          buffer.add(_line('  $line'));
        }
      }
    }

    buffer.add(_bottomBorder);
    _print(buffer.join('\n'));
  }

  void _logException({
    required http.BaseRequest request,
    required Object errorObject,
    required StackTrace stackTrace,
    required int durationMs,
  }) {
    if (!error) return;

    final buffer = <String>[];
    buffer.add(_topBorder);
    buffer.add(_line('💥 [HTTP EXCEPTION] (${durationMs}ms)'));
    buffer.add(_line('URL: ${request.url}'));
    buffer.add(_divider);
    buffer.add(_line('Error: $errorObject'));
    buffer.add(_bottomBorder);
    _print(buffer.join('\n'));
  }

  String? _extractRequestBody(http.BaseRequest req) {
    if (req is http.Request) {
      return req.body;
    }
    if (req is http.MultipartRequest) {
      final fields = req.fields;
      final files = req.files.map((f) => '${f.field}: ${f.filename} (${f.length} bytes)').toList();
      return jsonEncode({
        if (fields.isNotEmpty) 'fields': fields,
        if (files.isNotEmpty) 'files': files,
      });
    }
    return null;
  }

  String _decodeBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '<binary: ${bytes.length} bytes>';
    }
  }

  List<String> _formatBodyLines(String raw) {
    try {
      final parsed = jsonDecode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      final pretty = encoder.convert(parsed);
      return pretty.split('\n');
    } catch (_) {
      return raw.split('\n');
    }
  }

  String _sanitizeHeader(String key, String value) {
    final lowerKey = key.toLowerCase();
    if (lowerKey == 'authorization' && value.startsWith('Bearer ')) {
      final token = value.substring(7);
      if (token.length > 20) {
        return 'Bearer ${token.substring(0, 10)}...${token.substring(token.length - 6)}';
      }
    }
    if (lowerKey == 'apikey' && value.length > 20) {
      return '${value.substring(0, 10)}...${value.substring(value.length - 6)}';
    }
    return value;
  }

  String _defaultReasonPhrase(int statusCode) {
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 204:
        return 'No Content';
      case 301:
        return 'Moved Permanently';
      case 302:
        return 'Found';
      case 304:
        return 'Not Modified';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 409:
        return 'Conflict';
      case 422:
        return 'Unprocessable Entity';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return '';
    }
  }

  @override
  void close() {
    _innerClient.close();
    super.close();
  }
}
