import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test send-sms-whatsapp Edge Function invocation', () async {
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse(
        'https://tbcmgdwzarfdgzzmmele.supabase.co/functions/v1/send-sms-whatsapp',
      ),
    );
    request.headers.set('Content-Type', 'application/json');

    final payload = {
      'user': {
        'id': 'test-customer-001',
        'phone': '+201001234567',
      },
      'sms': {
        'otp': '654321',
      },
    };

    request.write(jsonEncode(payload));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    expect(response.statusCode, equals(200));
    final json = jsonDecode(responseBody);
    expect(json['simulated'], isTrue);
  });
}
