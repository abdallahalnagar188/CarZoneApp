import 'package:carzone/core/services/deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DeepLinkService deepLinkService;

  setUp(() {
    deepLinkService = DeepLinkService();
  });

  group('DeepLinkService URI Parsing & Extraction', () {
    test('extracts branchId from custom scheme with query param (carzone://wash?id=br_oasis_nasr)', () {
      final uri = Uri.parse('carzone://wash?id=br_oasis_nasr');
      final branchId = deepLinkService.extractBranchId(uri);
      expect(branchId, equals('br_oasis_nasr'));
    });

    test('extracts branchId from custom scheme with path (carzone://wash/br_nasr)', () {
      final uri = Uri.parse('carzone://wash/br_nasr');
      final branchId = deepLinkService.extractBranchId(uri);
      expect(branchId, equals('br_nasr'));
    });

    test('extracts branchId from generic branch scheme (carzone://branch/br_tagamoa)', () {
      final uri = Uri.parse('carzone://branch/br_tagamoa');
      final branchId = deepLinkService.extractBranchId(uri);
      expect(branchId, equals('br_tagamoa'));
    });

    test('extracts branchId from Supabase Edge Function smart link (https://.../share-wash?id=br_maadi)', () {
      final uri = Uri.parse('https://tbcmgdwzarfdgzzmmele.supabase.co/functions/v1/share-wash?id=br_maadi');
      final branchId = deepLinkService.extractBranchId(uri);
      expect(branchId, equals('br_maadi'));
    });

    test('ignores Supabase Auth links (login-callback / token / code)', () {
      final loginCallback = Uri.parse('carzone://login-callback#access_token=xyz&refresh_token=abc');
      final handled = deepLinkService.handleUri(loginCallback);
      expect(handled, isFalse);

      final oauthCode = Uri.parse('carzone://login-callback?code=123456');
      final codeHandled = deepLinkService.handleUri(oauthCode);
      expect(codeHandled, isFalse);
    });

    test('buildShareUrl builds correct Supabase Edge Function HTTPS endpoint', () {
      final url = DeepLinkService.buildShareUrl('br_oasis_nasr');
      expect(
        url,
        equals('https://tbcmgdwzarfdgzzmmele.supabase.co/functions/v1/share-wash?id=br_oasis_nasr'),
      );
    });

    test('buildAppSchemeUrl builds correct custom scheme URL', () {
      final url = DeepLinkService.buildAppSchemeUrl('br_oasis_nasr');
      expect(url, equals('carzone://wash?id=br_oasis_nasr'));
    });
  });
}
