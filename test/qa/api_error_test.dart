import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:washup/core/network/api_call.dart';

ApiErrorType? typeOf(Object error) => ApiException.from(error)?.type;

void main() {
  test('a Postgres refusal is not reported as the server being down', () {
    // SQLSTATE codes are numbers too; they used to read as HTTP 5xx.
    expect(typeOf(const PostgrestException(message: 'duplicate', code: '23505')), isNull);
    expect(typeOf(const PostgrestException(message: 'denied', code: '42501')), isNull);
    expect(typeOf(const PostgrestException(message: 'raise', code: 'P0001')), isNull);
  });

  test('real outages and timeouts still are', () {
    expect(typeOf(const PostgrestException(message: 'bad gateway', code: '502')), ApiErrorType.server);
    expect(typeOf(const PostgrestException(message: 'too many', code: '53300')), ApiErrorType.server);
    expect(typeOf(const PostgrestException(message: 'canceled', code: '57014')), ApiErrorType.timeout);
  });
}
