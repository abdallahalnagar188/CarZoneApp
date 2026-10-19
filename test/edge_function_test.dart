import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Live check against the deployed send-sms-whatsapp hook (QA-C2).
// Only Supabase Auth, signing with SEND_SMS_HOOK_SECRET, may call it:
// an unsigned request must be refused and must not send any message.
// Logic is unit-tested offline in supabase/functions/send-sms-whatsapp/handler_test.ts.
void main() {
  test('send-sms-whatsapp rejects unsigned requests', () async {
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('https://tbcmgdwzarfdgzzmmele.supabase.co/functions/v1/send-sms-whatsapp'),
    );
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({
      'user': {'id': 'qa-unsigned', 'phone': '+201001234567'},
      'sms': {'otp': '654321'},
    }));
    final response = await request.close();
    await response.drain<void>();
    client.close();

    expect(response.statusCode, anyOf(401, 500), reason: 'unsigned request was accepted');
  });
}
