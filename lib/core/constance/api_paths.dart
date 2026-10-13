import 'supabase_constants.dart';

class ApiEndPoints {
  static const String baseUrl = '${SupabaseConstants.supabaseUrl}/rest/v1';

  static const String appHealth = 'app_health';
  static const String customers = 'customers';
  static const String vehicles = 'vehicles';
  static const String branches = 'branches';
  static const String services = 'services';
  static const String offers = 'offers';
  static const String orders = 'orders';
  static const String reviews = 'reviews';
  static const String favorites = 'favorites';
  static const String notifications = 'notifications';
  static const String complaints = 'complaints';
}
