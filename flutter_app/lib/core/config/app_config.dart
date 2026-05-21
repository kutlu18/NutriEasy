class AppConfig {
  static const appName = 'NutriEasy';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ifjghwsdpujzopppurdr.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY',
  );

  static const supabaseAuthRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'nutrieasy://reset-password',
  );

  static const analyticsEnabled = bool.fromEnvironment(
    'ANALYTICS_ENABLED',
    defaultValue: true,
  );
}
