import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:carzone/core/network/pretty_http_logger.dart';

void main() {
  test('PrettyHttpLogger logs request and response in pretty box format', () async {
    final printedLogs = <String>[];

    // Mock HTTP client returning 200 JSON response
    final mockInner = MockClient((request) async {
      return http.Response(
        jsonEncode({'success': true, 'data': {'name': 'CarZone'}}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final logger = PrettyHttpLogger(
      innerClient: mockInner,
      logPrint: (msg) => printedLogs.add(msg),
    );

    final req = http.Request('POST', Uri.parse('https://api.carzone.com/v1/auth/login'));
    req.headers['content-type'] = 'application/json';
    req.headers['apikey'] = 'sb_test_apikey_12345678901234567890';
    req.body = jsonEncode({'phone': '+201012345678'});

    final response = await logger.send(req);
    final responseBody = await response.stream.bytesToString();

    // Verify response integrity
    expect(response.statusCode, 200);
    expect(jsonDecode(responseBody)['success'], true);

    // Verify printed logs
    expect(printedLogs.length, 2); // 1 request box + 1 response box

    final requestLog = printedLogs[0];
    expect(requestLog, contains('[HTTP REQUEST] POST https://api.carzone.com/v1/auth/login'));
    expect(requestLog, contains('Headers:'));
    expect(requestLog, contains('Body:'));
    expect(requestLog, contains('+201012345678'));
    expect(requestLog, contains('┌'));
    expect(requestLog, contains('└'));

    final responseLog = printedLogs[1];
    expect(responseLog, contains('🟢 [HTTP RESPONSE] 200 OK'));
    expect(responseLog, contains('CarZone'));
    expect(responseLog, contains('┌'));
    expect(responseLog, contains('└'));
  });
}
