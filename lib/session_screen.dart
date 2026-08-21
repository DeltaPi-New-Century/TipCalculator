import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/auth_service.dart';
import 'package:tip_calculator/service/history_data.dart';
import 'package:tip_calculator/service/session_code.dart';
import 'package:tip_calculator/service/session_data.dart';
import 'package:tip_calculator/service/session_service.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';
import 'package:tip_calculator/widgets/ui.dart';

/// Shared session: create one and read out the code, or join with a code.
///
/// Only reachable from itemized mode -- splitting evenly needs no coordination
/// between phones, so a session there would be ceremony with no payoff.
class MySessionScreen extends StatelessWidget {
  const MySessionScreen({super.key});

  /// Turns a failure into something a person can act on.
  static String errorText(final TipData tipData, final SessionError error) {
    switch (error) {
      case SessionError.notFound:
        return tipData.t('session_error_not_found');
      case SessionError.expired:
        return tipData.t('session_error_expired');
      case SessionError.closed:
        return tipData.t('session_error_closed');
      case SessionError.invalidCode:
        return tipData.t('session_error_invalid_code');
      case SessionError.notOwner:
        return tipData.t('session_error_not_owner');
      case SessionError.connectionLimit:
        return tipData.t('session_error_limit');
      case SessionError.denied:
        return tipData.t('session_error_denied');
      case SessionError.notSignedIn:
        return tipData.t('session_error_signin');
      case SessionError.network:
        return tipData.t('session_error_network');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipData = context.watch<TipData>();
    final sessionData = context.watch<SessionData>();

    return Scaffold(
      appBar: AppBar(title: Text(tipData.t('session_title'))),
      body: SafeArea(
        child: sessionData.isActive
            ? const _ActiveSessionView()
            : const _StartSessionView(),
      ),
    );
  }
}

/// Create-or-join, shown when no session is attached.
class _StartSessionView extends StatefulWidget {
  const _StartSessionView();

  @override
  State<_StartSessionView> createState() => _StartSessionViewState();
}

class _StartSessionViewState extends State<_StartSessionView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefilled from the remembered name, so joining a table is one tap for
    // anyone who has used the app before.
    _nameController.text = context.read<TipData>().ownerName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _displayName {
    final typed = _nameController.text.trim();
    if (typed.isNotEmpty) return typed;
    return context.read<TipData>().t('person');
  }

  void _report(final SessionError? error) {
    if (error == null || !mounted) return;
    final tipData = context.read<TipData>();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(MySessionScreen.errorText(tipData, error))),
      );
    context.read<SessionData>().clearError();
  }

  Future<void> _create() async {
    final tipData = context.read<TipData>();
    final sessionData = context.read<SessionData>();
    await tipData.setOwnerName(_nameController.text);
    final ok = await sessionData.create(
      displayName: _displayName,
      currency: tipData.currencySymbol,
      tipPercent: tipData.tipPercent,
    );
    if (!ok) _report(sessionData.lastError);
  }

  Future<void> _join() async {
    final sessionData = context.read<SessionData>();
    await context.read<TipData>().setOwnerName(_nameController.text);
    final ok = await sessionData.join(
      code: _codeController.text,
      displayName: _displayName,
    );
    if (!ok) _report(sessionData.lastError);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    final sessionData = context.watch<SessionData>();
    final codeReady = SessionCode.isValid(_codeController.text);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          tipData.t('session_subtitle'),
          style: TextStyle(fontSize: 14.5, color: colors.ink2),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          maxLength: 40,
          decoration: InputDecoration(
            labelText: tipData.t('session_your_name'),
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
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
              : const Icon(Icons.add_circle_outline, size: 20),
          label: Text(tipData.t('session_create')),
          onPressed: sessionData.isBusy ? null : _create,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: colors.line)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                tipData.t('session_join').toUpperCase(),
                style: AppTheme.fieldLabel(colors),
              ),
            ),
            Expanded(child: Divider(color: colors.line)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          maxLength: SessionCode.length,
          onChanged: (value) => setState(() {}),
          style: AppTheme.figure(size: 22, color: colors.ink, letterSpacing: 4),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            TextInputFormatter.withFunction(
              (oldValue, newValue) => newValue.copyWith(
                text: newValue.text.toUpperCase(),
              ),
            ),
          ],
          decoration: InputDecoration(
            labelText: tipData.t('session_enter_code'),
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.login, size: 20),
          label: Text(tipData.t('session_join')),
          onPressed: (sessionData.isBusy || !codeReady) ? null : _join,
        ),
      ],
    );
  }
}

/// The live table, once a session is attached.
class _ActiveSessionView extends StatelessWidget {
  const _ActiveSessionView();

  Future<void> _confirmClose(final BuildContext context) async {
    final tipData = context.read<TipData>();
    final sessionData = context.read<SessionData>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tipData.t('session_close')),
        content: Text(tipData.t('session_close_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tipData.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(tipData.t('session_close')),
          ),
        ],
      ),
    );
    if (confirmed == true) await sessionData.closeSession();
  }

  Future<void> _saveAndLeave(final BuildContext context) async {
    final tipData = context.read<TipData>();
    final sessionData = context.read<SessionData>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Everyone writes their own copy: the session node is disposable, the
    // local history entry is the permanent record.
    if (tipData.amount > 0) {
      await context.read<HistoryData>().add(
        amount: tipData.amount,
        people: tipData.people,
        tipPercent: tipData.tipPercent,
        currencySymbol: tipData.currencySymbol,
        persons: tipData.persons,
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(tipData.t('history_saved'))),
        );
    }
    await sessionData.finish();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    final sessionData = context.watch<SessionData>();
    final code = sessionData.code ?? '';
    final uid = AuthService.uid;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: colors.amountBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              FieldLabel(tipData.t('session_code')),
              const SizedBox(height: 4),
              SelectableText(
                code,
                style: AppTheme.figure(
                  size: 40,
                  color: colors.amount,
                  weight: FontWeight.w700,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sessionData.isClosed
                    ? tipData.t('session_closed')
                    : tipData.t('session_code_hint'),
                style: TextStyle(fontSize: 12, color: colors.ink2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: Text(tipData.t('session_code')),
            onPressed: () => Clipboard.setData(ClipboardData(text: code)),
          ),
        ),
        const SizedBox(height: 8),
        FieldLabel(tipData.t('session_members')),
        const SizedBox(height: 8),
        if (sessionData.members.length < 2 && !sessionData.isClosed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              tipData.t('session_waiting'),
              style: TextStyle(fontSize: 13, color: colors.ink3),
            ),
          ),
        for (final member in sessionData.members)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  member.uid == sessionData.session?.ownerUid
                      ? Icons.star
                      : Icons.person_outline,
                  size: 16,
                  color: colors.ink3,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    member.name,
                    style: TextStyle(fontSize: 14, color: colors.ink),
                  ),
                ),
                if (member.uid == uid)
                  Text(
                    tipData.t('session_you'),
                    style: TextStyle(fontSize: 12, color: colors.ink3),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        if (sessionData.isClosed) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.people,
              foregroundColor: colors.surface,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.bookmark_add_outlined, size: 20),
            label: Text(tipData.t('session_save_copy')),
            onPressed: () => _saveAndLeave(context),
          ),
        ] else ...[
          if (sessionData.isHost)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colors.ink,
                foregroundColor: colors.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.lock_outline, size: 20),
              label: Text(tipData.t('session_close')),
              onPressed: sessionData.isBusy
                  ? null
                  : () => _confirmClose(context),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: colors.tip,
            ),
            icon: const Icon(Icons.logout, size: 20),
            label: Text(tipData.t('session_leave')),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await context.read<SessionData>().leave();
              navigator.pop();
            },
          ),
        ],
      ],
    );
  }
}
