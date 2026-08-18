import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/session_data.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';
import 'package:tip_calculator/widgets/ui.dart';

/// Tip percentage: presets first, fine-tuning second.
///
/// Nobody arrives at 18% by pressing plus eighteen times, so the common cases
/// are one tap. The country suggestion is a hint, not a button competing with
/// the controls.
class MyTippingWidget extends StatelessWidget {
  const MyTippingWidget({super.key});

  static const List<int> presets = [10, 15, 18, 20, 25];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    // Guests in a session see the host's tip and cannot move it: one bill,
    // one percentage.
    final locked = tipData.isTipLocked;
    final symbol = tipData.currencySymbol;

    return AppCard(
      rail: colors.tip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: FieldLabel(tipData.t('tip_title'))),
              AppStepper(
                value: '${tipData.tipPercent}%',
                decrementLabel: tipData.t('tip_title'),
                incrementLabel: tipData.t('tip_title'),
                onDecrement: (locked || tipData.tipPercent <= 0)
                    ? null
                    : () => _setTip(context, tipData.tipPercent - 1),
                onIncrement: (locked || tipData.tipPercent >= 100)
                    ? null
                    : () => _setTip(context, tipData.tipPercent + 1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final preset in presets)
                _PresetChip(
                  percent: preset,
                  selected: tipData.tipPercent == preset,
                  enabled: !locked,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${tipData.t('tip_total')} $symbol ${tipData.tip.toStringAsFixed(2)}'
            '${tipData.people > 1 ? '   ·   $symbol ${tipData.tipPerson.toStringAsFixed(2)} ${tipData.t('tip_total_per_person')}' : ''}',
            style: AppTheme.figure(
              size: 12,
              color: colors.ink2,
              weight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          if (locked) ...[
            const SizedBox(height: 8),
            Text(
              tipData.t('session_tip_locked'),
              style: TextStyle(fontSize: 11.5, color: colors.ink3),
            ),
          ],
          if (!locked && tipData.hasTipAdvice) ...[
            const SizedBox(height: 10),
            const _SuggestionRow(),
          ],
        ],
      ),
    );
  }
}

/// Applies a tip percentage locally, and mirrors it to the table when this
/// device is hosting a session.
void _setTip(final BuildContext context, final int percent) {
  context.read<TipData>().setTipPercent(percent);
  context.read<SessionData>().updateTip(percent);
}

class _PresetChip extends StatelessWidget {
  final int percent;
  final bool selected;
  final bool enabled;

  const _PresetChip({
    required this.percent,
    required this.selected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.tipBg : colors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? colors.tip : colors.line2),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: enabled ? () => _setTip(context, percent) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            '$percent%',
            style: AppTheme.figure(
              size: 12,
              color: selected ? colors.tip : colors.ink2,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Country-specific tipping advice, fetched through Firebase AI Logic.
///
/// Tap to fetch; once an answer arrives it shows the customary range and the
/// tip percentage has already been set to the average.
class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();

    // Deliberately constant: the label stays "Recommended for <country>" even
    // after an answer arrives. The result is visible where it matters -- the
    // percentage and the selected preset chip both update -- so rewriting the
    // control's own text would only make it harder to tap again.
    final label = tipData
        .t('tip_button_text')
        .replaceAll('\$countryName', tipData.countryName);

    return Material(
      color: colors.sunk,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: tipData.isFetchingAdvice
            ? null
            : () => context.read<TipData>().fetchTipAdvice(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (tipData.isFetchingAdvice)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.tip,
                  ),
                )
              else
                Icon(Icons.auto_awesome, size: 14, color: colors.tip),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: colors.ink2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
