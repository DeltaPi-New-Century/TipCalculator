import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                onDecrement: tipData.tipPercent <= 0
                    ? null
                    : () => context.read<TipData>().decrementTipPorcent(),
                onIncrement: tipData.tipPercent >= 100
                    ? null
                    : () => context.read<TipData>().incrementTipPorcent(),
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
          if (tipData.countryName.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SuggestionRow(),
          ],
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final int percent;
  final bool selected;

  const _PresetChip({required this.percent, required this.selected});

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
        onTap: () => context.read<TipData>().setTipPercent(percent),
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

/// The Gemini recommendation. Tappable to fetch, quiet until it has something
/// to say.
class _SuggestionRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    final hasAdvice = tipData.recommendedTip.isNotEmpty;
    final label = hasAdvice
        ? tipData.recommendedTip
        : tipData
              .t('tip_button_text')
              .replaceAll('\$countryName', tipData.countryName);

    return Material(
      color: colors.sunk,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.read<TipData>().getRecommendedTip(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
