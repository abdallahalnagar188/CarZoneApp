// GAP-067: a Google/Apple sign-up must prove its phone number by a code.
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:washup/features/auth/data/repo/auth_repo.dart';

User _user({String? phone, String? confirmedAt}) => User.fromJson({
      'id': 'u-1',
      'app_metadata': {'provider': 'google'},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-11-01T00:00:00Z',
      if (phone != null) 'phone': phone,
      if (confirmedAt != null) 'phone_confirmed_at': confirmedAt,
    })!;

void main() {
  test('a Google account without a confirmed phone has to verify the number', () {
    expect(AuthRepo.hasConfirmedPhone(_user(), '+201001234567'), isFalse);
    expect(AuthRepo.hasConfirmedPhone(_user(phone: '201001234567'), '+201001234567'), isFalse);
  });

  test('a confirmed phone (Auth stores it without +) is accepted as is', () {
    final u = _user(phone: '201001234567', confirmedAt: '2026-11-01T00:00:00Z');
    expect(AuthRepo.hasConfirmedPhone(u, '+201001234567'), isTrue);
    expect(AuthRepo.hasConfirmedPhone(u, '+201009999999'), isFalse, reason: 'another number than the confirmed one');
  });

  test('a number owned by another account is recognised', () {
    expect(AuthRepo.isPhoneTaken(const AuthException('Phone already registered', code: 'phone_exists')), isTrue);
    expect(AuthRepo.isPhoneTaken(const AuthException('A user with this phone number has already been registered')), isTrue);
    expect(AuthRepo.isPhoneTaken(const AuthException('Rate limit exceeded')), isFalse);
  });
}
