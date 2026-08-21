import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:tip_calculator/schemas/session.dart';
import 'package:tip_calculator/service/auth_service.dart';
import 'package:tip_calculator/service/session_code.dart';

/// Why a session operation failed, in terms the UI can explain to a user.
enum SessionError {
  notSignedIn,
  notFound,
  expired,
  closed,
  notOwner,
  invalidCode,
  connectionLimit,
  denied,
  network,
}

/// Result of an operation that can fail for a reason worth showing.
class SessionResult {
  final Session? session;
  final SessionError? error;

  const SessionResult.success(this.session) : error = null;
  const SessionResult.failure(this.error) : session = null;

  bool get isSuccess => error == null;
}

/// Every Realtime Database read and write for shared bills.
///
/// No widget touches Firebase directly: this is the only place that knows the
/// node layout, which keeps the schema and the security rules in one mental
/// model rather than scattered through the UI.
class SessionService {
  const SessionService._();

  /// Sessions are disposable. The permanent record is the local history entry
  /// each participant saves when the host closes it, so a short life costs
  /// nothing and keeps the free tier comfortable.
  static const Duration sessionLifetime = Duration(hours: 24);

  /// Bounded because each attempt is a network round trip; failing loudly
  /// beats spinning forever on a pathological collision rate.
  static const int _maxCodeAttempts = 5;

  static DatabaseReference _sessionRef(final String code) =>
      FirebaseDatabase.instance.ref('sessions/$code');

  /// Creates a session owned by the current user and returns its code.
  static Future<SessionResult> create({
    required final String displayName,
    required final String currency,
    required final int tipPercent,
  }) async {
    final uid = AuthService.uid;
    if (uid == null) return const SessionResult.failure(SessionError.notSignedIn);

    try {
      for (int attempt = 0; attempt < _maxCodeAttempts; attempt++) {
        final code = SessionCode.generate();
        final ref = _sessionRef(code);

        // Cheap existence check. A collision at 729 million combinations is
        // vanishingly rare, but a silent overwrite would destroy someone
        // else's table, so it is worth one read.
        final existing = await ref.get();
        if (existing.exists) continue;

        final now = DateTime.now();
        final session = Session(
          code: code,
          status: 'open',
          ownerUid: uid,
          createdAt: now,
          expiresAt: now.add(sessionLifetime),
          currency: currency,
          tipPercent: tipPercent,
        );

        await ref.set({
          ...session.toJson(),
          'members': {
            uid: SessionMember(
              uid: uid,
              name: displayName,
              joinedAt: now,
            ).toJson(),
          },
        });
        return SessionResult.success(session);
      }
      return const SessionResult.failure(SessionError.network);
    } catch (error) {
      return SessionResult.failure(_classify(error));
    }
  }

  /// Joins an existing session, adding the current user as a member.
  static Future<SessionResult> join({
    required final String code,
    required final String displayName,
  }) async {
    final uid = AuthService.uid;
    if (uid == null) return const SessionResult.failure(SessionError.notSignedIn);
    if (!SessionCode.isValid(code)) {
      return const SessionResult.failure(SessionError.invalidCode);
    }

    final normalized = SessionCode.normalize(code);
    try {
      final snapshot = await _sessionRef(normalized).get();
      if (!snapshot.exists) {
        return const SessionResult.failure(SessionError.notFound);
      }

      final session = Session.fromSnapshot(normalized, snapshot.value);
      // An unreadable node and a missing one are the same thing to a user.
      if (session == null) {
        return const SessionResult.failure(SessionError.notFound);
      }
      if (session.isExpired) {
        return const SessionResult.failure(SessionError.expired);
      }
      if (!session.isOpen) {
        return const SessionResult.failure(SessionError.closed);
      }

      await _sessionRef(normalized).child('members/$uid').set(
        SessionMember(
          uid: uid,
          name: displayName,
          joinedAt: DateTime.now(),
        ).toJson(),
      );
      return SessionResult.success(session);
    } catch (error) {
      return SessionResult.failure(_classify(error));
    }
  }

  /// Live view of a session, emitting null when it is deleted or unreadable.
  static Stream<Session?> watch(final String code) => _sessionRef(code)
      .onValue
      .map((event) => Session.fromSnapshot(code, event.snapshot.value));

  static Future<void> addItem({
    required final String code,
    required final String label,
    required final double price,
  }) async {
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final ref = _sessionRef(code).child('items').push();
      await ref.set(
        SessionItem(id: ref.key!, uid: uid, label: label, price: price)
            .toJson(),
      );
    } catch (error) {
      debugPrint('Could not add item: $error');
    }
  }

  /// Removes one of the current user's own items. The rules reject anyone
  /// else's, so this is a UI convenience, not the enforcement point.
  static Future<void> removeItem({
    required final String code,
    required final String itemId,
  }) async {
    try {
      await _sessionRef(code).child('items/$itemId').remove();
    } catch (error) {
      debugPrint('Could not remove item: $error');
    }
  }

  /// Host-only: the tip applies to the whole table, so one person owns it.
  /// The rules reject this from anyone but the owner.
  static Future<void> updateTipPercent({
    required final String code,
    required final int tipPercent,
  }) async {
    try {
      await _sessionRef(code).child('tipPercent').set(tipPercent.clamp(0, 100));
    } catch (error) {
      debugPrint('Could not update tip: $error');
    }
  }

  static Future<void> rename({
    required final String code,
    required final String displayName,
  }) async {
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      await _sessionRef(code).child('members/$uid/name').set(displayName);
    } catch (error) {
      debugPrint('Could not rename: $error');
    }
  }

  /// Leaves a session, removing this user's membership and their items.
  ///
  /// Their items go too: an ownerless line on someone else's bill is worse
  /// than a missing one, and nobody else is permitted to delete them.
  static Future<void> leave(final String code) async {
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final snapshot = await _sessionRef(code).child('items').get();
      final value = snapshot.value;
      if (value is Map) {
        for (final entry in value.entries) {
          final item = entry.value;
          if (item is Map && item['uid'] == uid) {
            await _sessionRef(code).child('items/${entry.key}').remove();
          }
        }
      }
      await _sessionRef(code).child('members/$uid').remove();
    } catch (error) {
      debugPrint('Could not leave session: $error');
    }
  }

  /// Closes the session. Only the owner may do this; the rules enforce it.
  static Future<SessionResult> close(final String code) async {
    final uid = AuthService.uid;
    if (uid == null) return const SessionResult.failure(SessionError.notSignedIn);
    try {
      final snapshot = await _sessionRef(code).get();
      final session = Session.fromSnapshot(code, snapshot.value);
      if (session == null) {
        return const SessionResult.failure(SessionError.notFound);
      }
      if (!session.isOwnedBy(uid)) {
        return const SessionResult.failure(SessionError.notOwner);
      }
      await _sessionRef(code).child('status').set('closed');
      return SessionResult.success(session);
    } catch (error) {
      return SessionResult.failure(_classify(error));
    }
  }

  /// Deletes a session the current user owns, once everyone has their copy.
  ///
  /// Best effort: nothing sweeps orphans on the Spark plan, so this is the
  /// only cleanup that happens. Expired nodes become unreadable regardless.
  static Future<void> destroy(final String code) async {
    try {
      await _sessionRef(code).remove();
    } catch (error) {
      debugPrint('Could not delete session: $error');
    }
  }

  /// Maps a Firebase failure onto something the UI can put into words.
  static SessionError _classify(final Object error) {
    // Logged unconditionally: a rules rejection used to return silently, which
    // is indistinguishable from a button that never fired.
    debugPrint('Session operation failed: $error');
    final text = error.toString().toLowerCase();
    // Deliberately NOT reported as "closed": a rules rejection and a finished
    // session are different problems, and conflating them sent everyone
    // looking at the host's screen instead of at the rules.
    if (text.contains('permission')) return SessionError.denied;
    // The Spark plan caps simultaneous connections; at peak this is the
    // failure users will actually hit, and it must not look like a crash.
    if (text.contains('maxretries') || text.contains('disconnect')) {
      return SessionError.connectionLimit;
    }
    return SessionError.network;
  }
}
