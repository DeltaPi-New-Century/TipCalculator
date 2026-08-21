/// Endpoints the app talks to.
///
/// Nothing here is a secret. The Gemini credentials that used to live in this
/// file (and in `assets/.env`) are gone: an API key compiled into a mobile app
/// is extractable from the bundle, so it can never be kept private. The tip
/// recommendation will come back through Firebase AI Logic, which authenticates
/// via the Firebase SDK and App Check instead of a shipped key.
class Config {
  const Config._();

  /// IP geolocation, used to pick the country's currency and tipping norms.
  static const String ipApiUrl =
      'http://ip-api.com/json/?fields=status,country,countryCode';

  /// Country/currency/translation database.
  static const String dbPath =
      'https://gist.githubusercontent.com/eastanganelli/f36853425b3b58a064d44f4920b8a588/raw/';
}
