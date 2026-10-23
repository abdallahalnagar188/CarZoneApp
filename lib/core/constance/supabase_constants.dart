class SupabaseConstants {
  static const String supabaseUrl = 'https://tbcmgdwzarfdgzzmmele.supabase.co';

  static const String supabasePublishableKey =
      'sb_publishable_V2x5ol2_CW7z_cuLmpOv1g_UWn41sh7';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiY21nZHd6YXJmZGd6em1tZWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4MjE2NjUsImV4cCI6MjEwNzM5NzY2NX0.OBkKC0Qudh-hN_uVeB8oappJ4YY9bZzy77QSswWCmP4';

  /// Google Web Client ID from Google Cloud Console (OAuth 2.0 Client ID for Web Application)
  /// Configured in Supabase Dashboard -> Auth -> Providers -> Google.
  static const String googleWebClientId =
      '995916581459-633gqn8celnqlprln9ejt2oorblqiobl.apps.googleusercontent.com';

  /// Google iOS Client ID (OAuth 2.0 Client ID of type iOS, bundle id com.alnagar.washup).
  /// Leave empty until it exists: iOS then signs in through the browser instead.
  /// When set, ios/Runner/Info.plist must also list its reversed form
  /// (com.googleusercontent.apps.ID) under CFBundleURLSchemes, or Google
  /// Sign-In crashes the app. test/qa/ios_config_test.dart checks this.
  static const String googleIosClientId =
      '995916581459-16prakedukbmm60b8alm79009fkksv0l.apps.googleusercontent.com';

  /// Google Android Client ID from Google Cloud Console (OAuth 2.0 Client ID for Android)
  /// Linked to package name com.alnagar.washup and debug keystore SHA-1.
  static const String googleAndroidClientId =
      '995916581459-1pgjogapou9cdnfhhjs3bdki4vinqkgk.apps.googleusercontent.com';
}
