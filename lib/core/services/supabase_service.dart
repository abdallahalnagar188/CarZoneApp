import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constance/api_paths.dart';
import '../constance/supabase_constants.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        publishableKey: SupabaseConstants.supabasePublishableKey,
      );
    } catch (e) {
      log('Supabase init error: $e');
    }
  }

  static Future<bool> healthCheck() async {
    try {
      final rows = await client.from(ApiEndPoints.appHealth).select().limit(1);
      return rows.isNotEmpty;
    } catch (e) {
      log('Supabase health error: $e');
      return false;
    }
  }
}
