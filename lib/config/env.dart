// lib/config/env.dart
// Environment configuration — API keys and feature flags
//
// SETUP:
//   1. Copy this file to lib/config/env_local.dart
//   2. Replace 'YOUR_ANTHROPIC_API_KEY' with your actual key
//   3. env_local.dart is in .gitignore — it will NEVER be committed
//
// IN PRODUCTION (CI / app stores):
//   Set ANTHROPIC_API_KEY as a secret environment variable
//   and inject it at build time via --dart-define:
//
//     flutter build apk --dart-define=ANTHROPIC_API_KEY=sk-ant-...

class Env {
  /// Anthropic API key.
  /// Reads from --dart-define at build time; falls back to the compile-time
  /// constant below for local development only.
  static const String anthropicApiKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: 'YOUR_ANTHROPIC_API_KEY', // ← replace for local dev only
  );

  /// Claude model to use for BOQ extraction
  static const String claudeModel = 'claude-sonnet-4-20250514';

  /// Anthropic Messages API endpoint
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';

  /// VAT rate for Kenya (16%)
  static const double vatRate = 0.16;

  /// Default profit margin (10%)
  static const double defaultProfitMargin = 0.10;
}
