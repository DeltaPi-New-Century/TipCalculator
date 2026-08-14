import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/split_screen.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';

/// Opens the itemized people list.
///
/// Only present while [SplitMode.byItems] is selected. Choosing the mode is a
/// setting; opening the list is a navigation, and keeping them separate means
/// the toggle never pushes a screen the user did not ask for.
class ManagePeopleButton extends StatelessWidget {
  const ManagePeopleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    final count = tipData.persons.length;
    final itemCount = tipData.persons.fold<int>(
      0,
      (sum, person) => sum + person.items.length,
    );

    return Material(
      color: colors.amountBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MySplitScreen())),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 13, 13),
          child: Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 20, color: colors.amount),
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
                      '$count ${tipData.t('people_title').toLowerCase()}'
                      '  ·  $itemCount ${tipData.t('item_label').toLowerCase()}',
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
    );
  }
}
