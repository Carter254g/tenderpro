// lib/config/env.dart
class Env {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyC7jhGxXIV4TXvb0ViqhadtqzJ8VADPrP4', // ← paste your AIzaSy... key here
  );

  static const String geminiModel = 'gemini-1.5-flash';
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static const double vatRate = 0.16;
  static const double defaultProfitMargin = 0.10;
}