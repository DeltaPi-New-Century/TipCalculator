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

  /// Where the web build is hosted, used to build shareable join links.
  ///
  /// Never hardcode a deployment into the source: this moves between local
  /// testing, a staging host and production, and the phone app has no way to
  /// discover it. Pass it at build time instead:
  ///
  ///     --dart-define=WEB_BASE_URL=https://tip.example.com
  ///
  /// Empty means "no web deployment": sharing then falls back to the code on
  /// its own, which is still everything a person needs to join from the app.
  static const String webBaseUrl = String.fromEnvironment('WEB_BASE_URL');

  /// The join URL for [code], or null when no web deployment is configured.
  static String? joinUrl(final String code) {
    if (webBaseUrl.isEmpty) return null;
    // Tolerates a trailing slash in the define rather than producing '//?'.
    final base = webBaseUrl.endsWith('/')
        ? webBaseUrl.substring(0, webBaseUrl.length - 1)
        : webBaseUrl;
    return '$base/?code=$code';
  }

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
