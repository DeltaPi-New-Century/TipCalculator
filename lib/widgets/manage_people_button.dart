import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/firebase_bootstrap.dart';
import 'package:tip_calculator/service/session_data.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/session_screen.dart';
import 'package:tip_calculator/split_screen.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';

/// The itemized-mode row: the people list, with the shared session tucked in
/// beside it.
///
/// One row rather than two stacked buttons -- they are the same subject seen
/// two ways, and a second full-width card pushed the tip controls off screen.
/// The session is the secondary action, so it gets a compact button rather
/// than equal billing.
class ManagePeopleButton extends StatelessWidget {
  const ManagePeopleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    final sessionData = context.watch<SessionData>();

    final count = tipData.persons.length;
    final itemCount = tipData.persons.fold<int>(
      0,
      (sum, person) => sum + person.items.length,
    );
    final inSession = sessionData.isActive;

    return Container(
      decoration: BoxDecoration(
        color: colors.amountBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Primary action: the people and their items.
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MySplitScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 13, 8, 13),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 20,
                      color: colors.amount,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tipData.t('split_manage'),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: colors.ink,
                            ),
                          ),
                          Text(
                            '$count '
                            '${tipData.t('people_title').toLowerCase()}'
                            '  ·  $itemCount '
                            '${tipData.t('item_label').toLowerCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.figure(
                              size: 11.5,
                              color: colors.ink2,
                              weight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: colors.amount),
                  ],
                ),
              ),
            ),
          ),
          // Secondary action, only when a backend is actually available.
          if (FirebaseBootstrap.isReady) ...[
            Container(width: 1, height: 34, color: colors.line),
            _SessionAction(
              active: inSession,
              code: sessionData.code,
              tooltip: tipData.t('session_title'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact entry to the shared session.
///
/// Shows the code once joined, so the number people need to read aloud is
/// visible without opening anything.
class _SessionAction extends StatelessWidget {
  final bool active;
  final String? code;
  final String tooltip;

  const _SessionAction({
    required this.active,
    required this.code,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(14),
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MySessionScreen())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.link : Icons.group_add_outlined,
                size: 20,
                color: active ? colors.people : colors.ink2,
              ),
              if (active && code != null) ...[
                const SizedBox(height: 2),
                Text(
                  code!,
                  style: AppTheme.figure(
                    size: 10,
                    color: colors.people,
                    weight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
