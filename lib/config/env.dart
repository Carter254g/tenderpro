class Env {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCAJPiNNna0AQOj7giAela6E24cz69npy8',
  );

  static const String geminiModel = 'gemini-2.0-flash';
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static const double vatRate = 0.16;
  static const double defaultProfitMargin = 0.10;
}
