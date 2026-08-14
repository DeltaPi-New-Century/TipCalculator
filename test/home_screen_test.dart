import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tip_calculator/main.dart';
import 'package:tip_calculator/service/history_data.dart';
import 'package:tip_calculator/service/settings_data.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';

void main() {
  setUp(() {
    // SettingsData and HistoryData both read shared_preferences on construction.
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap({
    required final TipData tipData,
    required final SettingsData settings,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TipData>.value(value: tipData),
        ChangeNotifierProvider<SettingsData>.value(value: settings),
        ChangeNotifierProvider<HistoryData>(create: (_) => HistoryData()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settings.themeMode,
        home: const MyHomePage(),
      ),
    );
  }

  testWidgets('shows the three inputs and the pinned total', (tester) async {
    final tipData = TipData();
    await tester.pumpWidget(
      wrap(tipData: tipData, settings: SettingsData()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);
    expect(find.text('Tip'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Evenly'), findsOneWidget);
    expect(find.text('Itemized'), findsOneWidget);
  });

  testWidgets('a tip preset updates the total', (tester) async {
    final tipData = TipData()..setAmount(100.00);
    await tester.pumpWidget(
      wrap(tipData: tipData, settings: SettingsData()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('20%'));
    await tester.pumpAndSettle();

    expect(tipData.tipPercent, 20);
    expect(tipData.total, 120.00);
  });

  testWidgets('the people stepper will not go below one', (tester) async {
    final tipData = TipData();
    await tester.pumpWidget(
      wrap(tipData: tipData, settings: SettingsData()),
    );
    await tester.pumpAndSettle();

    expect(tipData.people, 1);
    // Decrement is disabled at one, so the maths can never divide by zero.
    await tester.tap(find.bySemanticsLabel('People').first);
    await tester.pumpAndSettle();
    expect(tipData.people, greaterThanOrEqualTo(1));
  });

  testWidgets('the people list button is hidden until Itemized is chosen', (
    tester,
  ) async {
    final tipData = TipData();
    await tester.pumpWidget(
      wrap(tipData: tipData, settings: SettingsData()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manage people'), findsNothing);

    await tester.tap(find.text('Itemized'));
    await tester.pumpAndSettle();

    expect(tipData.isSplitByItems, isTrue);
    expect(find.text('Manage people'), findsOneWidget);
  });

  testWidgets('choosing Itemized does not navigate on its own', (tester) async {
    final tipData = TipData();
    await tester.pumpWidget(
      wrap(tipData: tipData, settings: SettingsData()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Itemized'));
    await tester.pumpAndSettle();

    // Still on the calculator: the mode is a setting, not a route.
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Itemized split'), findsNothing);
  });

  testWidgets('the button opens the people list', (tester) async {
    final tipData = TipData();
    await tester.pumpWidget(
      wrap(tipData: tipData, settings: SettingsData()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Itemized'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage people'));
    await tester.pumpAndSettle();

    expect(find.text('Itemized split'), findsOneWidget);
    // The mode toggle is not offered while the list is on screen.
    expect(find.text('Evenly'), findsNothing);
  });

  testWidgets('the appearance sheet switches to dark and persists it', (
    tester,
  ) async {
    final settings = SettingsData();
    await tester.pumpWidget(wrap(tipData: TipData(), settings: settings));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.system);

    await tester.tap(find.byIcon(Icons.contrast));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });

  testWidgets('a saved dark choice survives a restart', (tester) async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final settings = SettingsData();
    await tester.pumpWidget(wrap(tipData: TipData(), settings: settings));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);
  });

  test('both palettes define every token', () {
    // A token defined in one brightness but not the other is the classic
    // unreadable-theme bug; the const constructors make it a compile error,
    // this guards the values themselves being distinct.
    expect(AppColors.light.paper, isNot(AppColors.dark.paper));
    expect(AppColors.light.ink, isNot(AppColors.dark.ink));
    expect(AppColors.light.amount, isNot(AppColors.dark.amount));
    expect(AppColors.light.totalBg, isNot(AppColors.dark.totalBg));
  });

  test('lerp between the palettes stays on the token set', () {
    final mid = AppColors.light.lerp(AppColors.dark, 0.5);
    expect(mid.paper, isNot(AppColors.light.paper));
    expect(mid.paper, isNot(AppColors.dark.paper));
  });
}
