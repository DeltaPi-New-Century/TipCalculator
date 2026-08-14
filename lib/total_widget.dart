import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';
import 'package:tip_calculator/widgets/ui.dart';

/// The pinned bottom bar: total, per-person, and the split-mode toggle.
///
/// It never scrolls away, so the answer to "what do I owe" is on screen while
/// the user is still editing the inputs above it. The mode toggle lives here
/// because this is where its consequence shows.
class MyTotalWidget extends StatelessWidget {
  /// Hidden on the itemized screen: the mode is already chosen and visible in
  /// the content, so offering the switch there is redundant -- and switching
  /// to Evenly from a list of people would strand the user on a dead screen.
  final bool showModeToggle;

  const MyTotalWidget({super.key, this.showModeToggle = true});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    final symbol = tipData.currencySymbol;

    return Container(
      decoration: BoxDecoration(
        color: colors.totalBg,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FieldLabel(tipData.t('total_title')),
                      Text(
                        '$symbol ${tipData.total.toStringAsFixed(2)}',
                        style: AppTheme.figure(size: 30, color: colors.ink),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (tipData.people > 1)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FieldLabel(tipData.t('total_per_person')),
                        Text(
                          '$symbol ${tipData.totalPerPerson.toStringAsFixed(2)}',
                          style: AppTheme.figure(size: 16, color: colors.ink),
                        ),
                      ],
                    ),
                ],
              ),
              if (showModeToggle) ...[
                const SizedBox(height: 10),
                const _ModeToggle(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              icon: Icons.groups_outlined,
              label: tipData.t('split_evenly'),
              selected: !tipData.isSplitByItems,
              onTap: () =>
                  context.read<TipData>().setSplitMode(SplitMode.evenly),
            ),
          ),
          Expanded(
            child: _ModeButton(
              icon: Icons.receipt_long_outlined,
              label: tipData.t('split_by_items'),
              selected: tipData.isSplitByItems,
              // Selecting the mode does not navigate. The people list is opened
              // deliberately, from the button the mode reveals on the home
              // screen, so switching modes never yanks the user off the page.
              onTap: () =>
                  context.read<TipData>().setSplitMode(SplitMode.byItems),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? colors.surface : colors.ink2,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? colors.surface : colors.ink2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
