import 'dart:async';
import 'dart:developer' as dev;

import 'package:app_links/app_links.dart';
import 'package:get/get.dart';

import '../routing/app_routes.dart';
import 'carzone_db_service.dart';

class DeepLinkService extends GetxService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  String? _lastHandledBranchId;
  DateTime? _lastHandledTime;

  static const String supabaseShareBaseUrl =
      'https://tbcmgdwzarfdgzzmmele.supabase.co/functions/v1/share-wash';

  static String buildShareUrl(String branchId) => '$supabaseShareBaseUrl?id=$branchId';

  static String buildAppSchemeUrl(String branchId) => 'carzone://wash?id=$branchId';

  Future<DeepLinkService> init() async {
    _initColdStart();
    _initWarmStream();
    return this;
  }

  Future<void> _initColdStart() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        dev.log('[DeepLinkService] Cold start link detected: $initialUri');
        // Give the UI a brief delay to finish booting splash/onboarding before deep routing
        Future.delayed(const Duration(milliseconds: 600), () {
          handleUri(initialUri);
        });
      }
    } catch (e) {
      dev.log('[DeepLinkService] Error getting initial deep link: $e');
    }
  }

  void _initWarmStream() {
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) {
        dev.log('[DeepLinkService] Warm link stream detected: $uri');
        handleUri(uri);
      },
      onError: (err) {
        dev.log('[DeepLinkService] Link stream error: $err');
      },
    );
  }

  /// Parses and navigates if the URI is a valid CarZone content deep link.
  bool handleUri(Uri uri) {
    // Ignore Supabase Auth links (login-callback, OAuth tokens, password reset)
    if (uri.host == 'login-callback' ||
        uri.fragment.contains('access_token') ||
        uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('token_hash')) {
      dev.log('[DeepLinkService] Supabase auth link passed to Supabase client.');
      return false;
    }

    final branchId = extractBranchId(uri);
    if (branchId != null && branchId.isNotEmpty) {
      // Prevent duplicate double-firings within 1.5 seconds
      final now = DateTime.now();
      if (_lastHandledBranchId == branchId &&
          _lastHandledTime != null &&
          now.difference(_lastHandledTime!).inMilliseconds < 1500) {
        return true;
      }
      _lastHandledBranchId = branchId;
      _lastHandledTime = now;

      _navigateToWash(branchId);
      return true;
    }

    return false;
  }

  /// Extracts the target branchId from various supported URI formats:
  /// - carzone://wash?id=br_oasis_nasr
  /// - carzone://wash/br_oasis_nasr
  /// - carzone://branch/br_oasis_nasr
  /// - https://.../share-wash?id=br_oasis_nasr
  /// - https://.../wash/br_oasis_nasr
  String? extractBranchId(Uri uri) {
    // 1. Check query parameter `id`
    final queryId = uri.queryParameters['id'];
    if (queryId != null && queryId.isNotEmpty) {
      return queryId;
    }

    // 2. Check path segments
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    if (host == 'wash' || host == 'branch') {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty && segments.first.isNotEmpty) {
        return segments.first;
      }
    }

    if (path.contains('/wash/') || path.contains('/branch/')) {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    }

    return null;
  }

  Future<void> _navigateToWash(String branchId) async {
    try {
      // Ensure DB master data is synced from Supabase before opening details
      if (Get.isRegistered<CarzoneDbService>()) {
        final db = Get.find<CarzoneDbService>();
        if (!db.isSynced.value) {
          await db.fetchFromSupabase();
        }
      }

      // Check if current route is already washDetails with the same branchId
      if (Get.currentRoute == Routes.washDetailsRoute && Get.arguments == branchId) {
        return;
      }

      Get.toNamed(Routes.washDetailsRoute, arguments: branchId);
    } catch (e) {
      dev.log('[DeepLinkService] Navigation to wash failed: $e');
    }
  }

  @override
  void onClose() {
    _linkSub?.cancel();
    super.onClose();
  }
}
