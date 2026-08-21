import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/widgets/ui.dart';

/// Head count. A stepper rather than a keyboard: parties are small numbers.
class MyPeopleWidget extends StatelessWidget {
  const MyPeopleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    // In item mode the count comes from the people list, so editing it here
    // would be discarded.
    final locked = tipData.isSplitByItems;

    return AppCard(
      rail: colors.people,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FieldLabel(tipData.t('people_title')),
                if (locked)
                  Text(
                    tipData.t('split_by_items'),
                    style: TextStyle(fontSize: 11.5, color: colors.ink3),
                  ),
              ],
            ),
          ),
          AppStepper(
            value: tipData.people.toString(),
            decrementLabel: tipData.t('people_title'),
            incrementLabel: tipData.t('people_title'),
            onDecrement: locked || tipData.people <= 1
                ? null
                : () => context.read<TipData>().decrementPeople(),
            onIncrement: locked
                ? null
                : () => context.read<TipData>().incrementPeople(),
          ),
        ],
      ),
    );
  }
}
