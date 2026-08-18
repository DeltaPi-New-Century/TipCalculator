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

  /// reCAPTCHA v3 site key, used by App Check on the web build only.
  ///
  /// Not a secret -- a reCAPTCHA site key is public by design and is meant to
  /// be readable in the page. It is passed at build time rather than hardcoded
  /// so the key can differ per deployment:
  ///
  ///     flutter build web -t lib/main_web.dart \
  ///       --dart-define=RECAPTCHA_SITE_KEY=6Lxxxxxxxxxxxxxxxxxx
  ///
  /// Empty means "no key configured": App Check activation is then skipped
  /// entirely, which is correct, because an unactivated provider attaches a
  /// placeholder token that Firebase rejects outright.
  static const String recaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
  );
}
