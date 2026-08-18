import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:tip_calculator/firebase_options.dart';
import 'package:tip_calculator/service/auth_service.dart';

/// Brings Firebase up at startup, without ever being able to stop the app.
///
/// The calculator is offline-first: tips, splitting and history all work with
/// no network and no backend. Firebase adds shared sessions and AI tip advice
/// on top. So every failure here -- missing config, no network, a disabled
/// provider -- degrades to [isReady] being false, never to a crash on launch.
///
/// Call [initialize] once from `main`, before `runApp`.
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool _ready = false;

  /// Whether Firebase-backed features may be offered.
  static bool get isReady => _ready;

  static Future<void> initialize() async {
    try {
      // Explicit options from the generated file rather than the platform
      // config files: it fails loudly on an unconfigured platform instead of
      // silently picking up whatever google-services.json happens to be there.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _activateAppCheck();
      await AuthService.ensureSignedIn();
      _ready = AuthService.isSignedIn;
      debugPrint(
        _ready
            ? 'Firebase ready, uid ${AuthService.uid}'
            : 'Firebase initialised but not signed in; '
                  'check the Anonymous provider is enabled.',
      );
    } catch (error) {
      _ready = false;
      debugPrint('Firebase unavailable, continuing offline: $error');
    }
  }

  /// Attests that requests come from a genuine build of this app.
  ///
  /// This must happen even before App Check is *enforced*: merely having the
  /// package installed makes the SDK attach a token to every request, and an
  /// unactivated provider attaches a placeholder one. Firebase AI Logic
  /// rejects that outright with "App Check token is invalid" -- so an
  /// unconfigured App Check is worse than no App Check at all.
  ///
  /// Debug builds use the debug provider, which prints a token that has to be
  /// registered once per machine under App Check > Apps > Manage debug tokens.
  /// Release builds use Play Integrity, which needs no manual step.
  static Future<void> _activateAppCheck() async {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    } catch (error) {
      // Leaving App Check inactive still lets unenforced services work; it is
      // the placeholder token that breaks them, not the absence of one.
      debugPrint('App Check activation failed: $error');
    }
  }
}
