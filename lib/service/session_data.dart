import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tip_calculator/schemas/session.dart';
import 'package:tip_calculator/service/auth_service.dart';
import 'package:tip_calculator/service/session_service.dart';
import 'package:tip_calculator/service/tip_data.dart';

/// Live state of a shared bill, and the bridge into the calculator.
///
/// Owns the subscription to the session node and pushes every update into
/// [TipData], so the tip maths never learns that Firebase exists -- it just
/// sees a list of people.
class SessionData with ChangeNotifier {
  final TipData _tipData;

  Session? _session;
  String? _code;
  StreamSubscription<Session?>? _subscription;
  SessionError? _lastError;
  bool _busy = false;

  /// Where the attached code is remembered across launches.
  static const String _codeKey = 'session_active_code';

  SessionData(this._tipData) {
    _restore();
  }

  /// Reattaches to the session this device was in when it last closed.
  ///
  /// Closing the app -- or, in the browser, reloading the tab -- used to strand
  /// the user: the session, their membership and their items were all still in
  /// the database, but the app had forgotten the code, and a host who had not
  /// written it down could not get back to their own table.
  ///
  /// Silent by design. Every failure means "start on the join screen", which is
  /// where the user already expected to be.
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_codeKey);
      if (saved == null) return;

      final result = await SessionService.resume(saved);
      if (!result.isSuccess) {
        await prefs.remove(_codeKey);
        return;
      }
      _attach(saved);
    } catch (error) {
      debugPrint('Could not restore session: $error');
    }
  }

  /// Fire and forget: remembering the code must never delay attaching to it.
  Future<void> _remember(final String? code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (code == null) {
        await prefs.remove(_codeKey);
      } else {
        await prefs.setString(_codeKey, code);
      }
    } catch (error) {
      debugPrint('Could not persist session code: $error');
    }
  }

  Session? get session => _session;
  String? get code => _code;
  SessionError? get lastError => _lastError;
  bool get isBusy => _busy;

  bool get isActive => _session != null && _code != null;
  bool get isHost => _session?.isOwnedBy(AuthService.uid) ?? false;
  bool get isClosed => _session != null && !_session!.isOpen;

  /// Members, host first, for the participant list.
  List<SessionMember> get members => _session?.members ?? const [];

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setBusy(final bool value) {
    _busy = value;
    notifyListeners();
  }

  /// Clears a surfaced error once the user has seen it.
  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  Future<bool> create({
    required final String displayName,
    required final String currency,
    required final int tipPercent,
  }) async {
    _setBusy(true);
    final result = await SessionService.create(
      displayName: displayName,
      currency: currency,
      tipPercent: tipPercent,
    );
    _busy = false;

    if (!result.isSuccess) {
      _lastError = result.error;
      notifyListeners();
      return false;
    }
    _attach(result.session!.code);
    return true;
  }

  Future<bool> join({
    required final String code,
    required final String displayName,
  }) async {
    _setBusy(true);
    final result = await SessionService.join(
      code: code,
      displayName: displayName,
    );
    _busy = false;

    if (!result.isSuccess) {
      _lastError = result.error;
      notifyListeners();
      return false;
    }
    _attach(result.session!.code);
    return true;
  }

  /// Subscribes to the session node and mirrors it into [TipData].
  void _attach(final String code) {
    _subscription?.cancel();
    _code = code;
    _lastError = null;
    _remember(code);

    _subscription = SessionService.watch(code).listen(
      (session) {
        // A null snapshot means the host deleted it, or it expired out of
        // readability. Either way this device is no longer in a session.
        if (session == null) {
          _detach();
          return;
        }
        _session = session;
        _tipData.setSessionPersons(session.toPersons());
        _tipData.applySessionTip(
          session.tipPercent,
          locked: !session.isOwnedBy(AuthService.uid),
        );
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Session stream failed: $error');
        _lastError = SessionError.network;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  /// Stops mirroring and hands the calculator back its local table.
  void _detach() {
    _subscription?.cancel();
    _subscription = null;
    _session = null;
    _code = null;
    _remember(null);
    _tipData.setSessionPersons(null);
    _tipData.releaseTipLock();
    notifyListeners();
  }

  Future<void> addItem(final String label, final double price) async {
    final code = _code;
    if (code == null) return;
    await SessionService.addItem(code: code, label: label, price: price);
  }

  Future<void> removeItem(final String itemId) async {
    final code = _code;
    if (code == null) return;
    await SessionService.removeItem(code: code, itemId: itemId);
  }

  /// Moves an item onto another member. Host only; the rules enforce it too.
  Future<bool> transferItem({
    required final String itemId,
    required final String toUid,
  }) async {
    final code = _code;
    if (code == null || !isHost) return false;
    return SessionService.transferItem(
      code: code,
      itemId: itemId,
      toUid: toUid,
    );
  }

  /// Moves several items onto another member at once. Host only.
  Future<bool> transferItems({
    required final Iterable<String> itemIds,
    required final String toUid,
  }) async {
    final code = _code;
    if (code == null || !isHost) return false;
    return SessionService.transferItems(
      code: code,
      itemIds: itemIds,
      toUid: toUid,
    );
  }

  /// Deletes several items outright. Host only.
  Future<bool> removeItems(final Iterable<String> itemIds) async {
    final code = _code;
    if (code == null || !isHost) return false;
    return SessionService.removeItems(code: code, itemIds: itemIds);
  }

  /// Removes someone from the table. Host only, and only once their items
  /// have been moved elsewhere.
  ///
  /// Returns the reason it failed, or null on success.
  Future<SessionError?> removeMember(final String uid) async {
    final code = _code;
    if (code == null) return SessionError.notFound;
    if (!isHost) return SessionError.notOwner;
    return SessionService.removeMember(code: code, uid: uid);
  }

  /// Items belonging to one member, for deciding what a removal would strand.
  List<SessionItem> itemsOf(final String uid) =>
      _session?.items.where((item) => item.uid == uid).toList() ?? const [];

  /// Pushes the host's tip choice to the table. No-op for guests, whose
  /// controls are disabled anyway.
  Future<void> updateTip(final int percent) async {
    final code = _code;
    if (code == null || !isHost) return;
    await SessionService.updateTipPercent(code: code, tipPercent: percent);
  }

  Future<void> rename(final String displayName) async {
    final code = _code;
    if (code == null) return;
    await SessionService.rename(code: code, displayName: displayName);
  }

  /// Host-only. Guests get a disabled control, and the rules reject them too.
  Future<bool> closeSession() async {
    final code = _code;
    if (code == null) return false;

    _setBusy(true);
    final result = await SessionService.close(code);
    _busy = false;

    if (!result.isSuccess) {
      _lastError = result.error;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  /// Leaves without ending the session for everyone else.
  Future<void> leave() async {
    final code = _code;
    if (code == null) return;
    await SessionService.leave(code);
    _detach();
  }

  /// Leaves and, if this device owns it, deletes the node.
  ///
  /// Called after everyone has had the chance to save their copy: the session
  /// has served its purpose and nothing sweeps orphans on the Spark plan.
  Future<void> finish() async {
    final code = _code;
    if (code == null) return;

    // "Everyone has had the chance" was an assumption, not a fact. The host is
    // usually first to tap save, and destroying the node here pulled it out
    // from under everyone still reading it: their stream emitted null, the
    // table emptied, and the copy they were about to save was gone. Nobody
    // but the host could ever save a shared bill.
    //
    // So the node is only deleted once this device is the last one in it.
    // Otherwise it is left to expire, which costs nothing -- expired sessions
    // are already unreadable by rule, and nothing sweeps them anyway.
    final lastOneHere = members.length <= 1;
    final owned = isHost;
    _detach();
    if (owned && lastOneHere) await SessionService.destroy(code);
  }
}
