import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/session_data.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/split_screen.dart';
import 'package:tip_calculator/theme/app_theme.dart';

void main() {
  Widget wrap(final TipData tipData) => MultiProvider(
    providers: [
      ChangeNotifierProvider<TipData>.value(value: tipData),
      ChangeNotifierProvider<SessionData>(
        create: (context) => SessionData(tipData),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const MySplitScreen(),
    ),
  );

  testWidgets('adding an item to a person does not crash', (tester) async {
    final tipData = TipData()..setSplitMode(SplitMode.byItems);
    await tester.pumpWidget(wrap(tipData));
    await tester.pumpAndSettle();

    expect(find.text('Add item'), findsWidgets);

    await tester.tap(find.text('Add item').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Steak');
    await tester.enterText(find.byType(TextField).last, '20');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Steak'), findsOneWidget);
    expect(tipData.amount, 20.00);
  });

  testWidgets('cancelling the item dialog does not crash', (tester) async {
    final tipData = TipData()..setSplitMode(SplitMode.byItems);
    await tester.pumpWidget(wrap(tipData));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add item').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Steak');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tipData.amount, 0.00);
  });

  testWidgets('renaming a person does not crash', (tester) async {
    final tipData = TipData()..setSplitMode(SplitMode.byItems);
    await tester.pumpWidget(wrap(tipData));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Person 1'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Ana');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(tipData.persons.first.name, 'Ana');
  });
}
