import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Anonymous identity, used only to tag which session items belong to whom.
///
/// There are no accounts in this app and there will not be: a uid exists so
/// security rules can say "you may edit your own items", nothing more. Nobody
/// signs up, signs in, or can be identified across devices.
///
/// Sign-in is best-effort. The calculator works entirely offline, so a failure
/// here must degrade to "no shared sessions", never to a broken app.
class AuthService {
  const AuthService._();

  static User? get currentUser => FirebaseAuth.instance.currentUser;

  /// The stable id for this install, or null when sign-in has not succeeded.
  static String? get uid => currentUser?.uid;

  static bool get isSignedIn => currentUser != null;

  /// Signs in anonymously if not already signed in.
  ///
  /// Firebase persists the anonymous credential, so this returns the same uid
  /// across restarts and only hits the network on first run.
  static Future<String?> ensureSignedIn() async {
    try {
      final existing = FirebaseAuth.instance.currentUser;
      if (existing != null) return existing.uid;

      final credential = await FirebaseAuth.instance.signInAnonymously();
      return credential.user?.uid;
    } on FirebaseAuthException catch (error) {
      // The most likely cause in a fresh project is the Anonymous provider
      // not being enabled in the console.
      debugPrint('Anonymous sign-in failed (${error.code}): ${error.message}');
      return null;
    } catch (error) {
      debugPrint('Anonymous sign-in failed: $error');
      return null;
    }
  }
}
