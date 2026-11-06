class SupabaseConfig {
  SupabaseConfig._();

  // URL e chave publicável do projeto Supabase
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ohzqfjpioggsvsczdadg.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_54yIdqRGF8pGKNgtl-288Q_DxPSHa_h',
  );

  // Fallback legacy caso necessário
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9oenFmanBpb2dnc3ZzY3pkYWRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM1NzUxMDIsImV4cCI6MjEwOTE1MTEwMn0.bVTdcykkYHXuQeIQ4mXB1MSkxfYEN5OUXcomV12qHLs',
  );
}
