import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';

/// The bill amount, as the headline of the screen.
///
/// It is the first thing typed and the most-read figure in the app, so it gets
/// the largest type and its own tinted field rather than sharing weight with
/// every other input.
class MyAmountWidget extends StatelessWidget {
  const MyAmountWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    final derived = tipData.isSplitByItems;

    return Container(
      decoration: BoxDecoration(
        color: colors.amountBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(tipData.t('amount_title'), style: AppTheme.fieldLabel(colors)),
              if (derived) ...[
                const Spacer(),
                Text(
                  tipData.t('split_by_items'),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.amount,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                tipData.currencySymbol,
                style: AppTheme.figure(
                  size: 20,
                  color: colors.amount,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: tipData.amountController,
                  // In item mode the bill is the sum of everyone's items, so a
                  // typed amount would be silently ignored.
                  enabled: !derived,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9]+[,|.]{0,1}[0-9]*'),
                    ),
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) => newValue.copyWith(
                        text: newValue.text.replaceAll('.', ','),
                      ),
                    ),
                  ],
                  style: AppTheme.figure(size: 38, color: colors.ink),
                  cursorColor: colors.amount,
                  decoration: InputDecoration(
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: '0,00',
                    hintStyle: AppTheme.figure(size: 38, color: colors.ink3),
                  ),
                  onChanged: (newAmount) {
                    // Clearing the field, or a lone separator, is not a number
                    // -- double.parse would throw on every keystroke.
                    final parsed = double.tryParse(
                      newAmount.replaceAll(",", "."),
                    );
                    context.read<TipData>().setAmount(parsed ?? 0.00);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
