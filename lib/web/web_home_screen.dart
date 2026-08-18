import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/firebase_bootstrap.dart';
import 'package:tip_calculator/service/session_code.dart';
import 'package:tip_calculator/service/session_data.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/session_screen.dart';
import 'package:tip_calculator/split_screen.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';

/// Root of the web build: join a table, then live in it.
///
/// The web app is deliberately a guest client. Creating a session, local
/// history, sharing and the tip advisor stay on mobile -- the browser exists so
/// somebody without the app installed can still be part of a table someone
/// else is hosting. That is why there is no create button here.
///
/// It switches on [SessionData.isActive] rather than pushing a route, so the
/// user is returned to the join form automatically when the session ends,
/// whether they left it or the host closed it.
class WebHomeScreen extends StatelessWidget {
  const WebHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return context.watch<SessionData>().isActive
        ? const MySplitScreen()
        : const _WebJoinScreen();
  }
}

class _WebJoinScreen extends StatefulWidget {
  const _WebJoinScreen();

  @override
  State<_WebJoinScreen> createState() => _WebJoinScreenState();
}

class _WebJoinScreenState extends State<_WebJoinScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = context.read<TipData>().ownerName;
    // A host can paste the whole URL into the group chat rather than reading
    // six characters out loud: /?code=K7QM2X lands here prefilled.
    final shared = Uri.base.queryParameters['code'];
    if (shared != null && SessionCode.isValid(shared)) {
      _codeController.text = SessionCode.normalize(shared);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Falls back to the generic word for a person, so an empty field still
  /// produces a member the rest of the table can point at.
  String get _displayName {
    final typed = _nameController.text.trim();
    if (typed.isNotEmpty) return typed;
    return context.read<TipData>().t('person');
  }

  Future<void> _join() async {
    final tipData = context.read<TipData>();
    final sessionData = context.read<SessionData>();
    final messenger = ScaffoldMessenger.of(context);

    await tipData.setOwnerName(_nameController.text);
    final ok = await sessionData.join(
      code: _codeController.text,
      displayName: _displayName,
    );
    if (ok || !mounted) return;

    final error = sessionData.lastError;
    if (error == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(MySessionScreen.errorText(tipData, error))),
      );
    sessionData.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    final sessionData = context.watch<SessionData>();
    final codeReady = SessionCode.isValid(_codeController.text);
    final backendDown = !FirebaseBootstrap.isReady;

    return Scaffold(
      appBar: AppBar(title: Text(tipData.t('session_join'))),
      body: SafeArea(
        // Browsers are as wide as the monitor; the form is not. Without the
        // cap the fields stretch across a desktop screen and read as a
        // different app from the phone one.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                Text(
                  tipData.t('session_subtitle'),
                  style: TextStyle(fontSize: 14.5, color: colors.ink2),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: tipData.t('session_your_name'),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: SessionCode.length,
                  autofocus: true,
                  onChanged: (value) => setState(() {}),
                  onSubmitted: (_) {
                    if (codeReady && !sessionData.isBusy && !backendDown) {
                      _join();
                    }
                  },
                  style: AppTheme.figure(
                    size: 22,
                    color: colors.ink,
                    letterSpacing: 4,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) =>
                          newValue.copyWith(text: newValue.text.toUpperCase()),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: tipData.t('session_enter_code'),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.amount,
                    foregroundColor: colors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: sessionData.isBusy
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.surface,
                          ),
                        )
                      : const Icon(Icons.login, size: 20),
                  label: Text(tipData.t('session_join')),
                  onPressed: (sessionData.isBusy || !codeReady || backendDown)
                      ? null
                      : _join,
                ),
                if (backendDown) ...[
                  const SizedBox(height: 16),
                  // Without a backend there is nothing this build can do: the
                  // whole web app is the shared session.
                  Text(
                    tipData.t('session_error_network'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: colors.tip),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
