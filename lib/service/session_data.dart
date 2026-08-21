import 'dart:async';

import 'package:flutter/foundation.dart';
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

  SessionData(this._tipData);

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
    final owned = isHost;
    _detach();
    if (owned) await SessionService.destroy(code);
  }
}
