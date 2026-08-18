import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/service/history_data.dart';
import 'package:tip_calculator/service/settings_data.dart';
import 'package:tip_calculator/service/firebase_bootstrap.dart';
import 'package:tip_calculator/history_screen.dart';
import 'package:tip_calculator/amount_widget.dart';
import 'package:tip_calculator/people_widget.dart';
import 'package:tip_calculator/tipping_widget.dart';
import 'package:tip_calculator/total_widget.dart';
import 'package:tip_calculator/theme/app_theme.dart';
import 'package:tip_calculator/widgets/theme_sheet.dart';
import 'package:tip_calculator/widgets/manage_people_button.dart';
import 'package:tip_calculator/widgets/share_sheet.dart';
import 'package:tip_calculator/service/session_data.dart';

Future main() async {
  // Binding must be initialized before any plugin or asset access.
  WidgetsFlutterBinding.ensureInitialized();
  // Never fatal: the calculator is fully usable without a backend.
  await FirebaseBootstrap.initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TipData()),
        ChangeNotifierProvider(create: (_) => HistoryData()),
        ChangeNotifierProvider(create: (_) => SettingsData()),
        // Depends on TipData: session updates are pushed straight into the
        // calculator, so the tip maths never learns Firebase exists.
        ChangeNotifierProvider(
          create: (context) => SessionData(context.read<TipData>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsData>();
    final title = context.watch<TipData>().t('app_title');

    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  Future<void> _saveCurrent(final BuildContext context) async {
    final tipData = context.read<TipData>();
    final messenger = ScaffoldMessenger.of(context);

    // Nothing to save before an amount is entered.
    if (tipData.amount <= 0) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(tipData.t('history_nothing_to_save'))),
      );
      return;
    }

    await context.read<HistoryData>().add(
      amount: tipData.amount,
      people: tipData.people,
      tipPercent: tipData.tipPercent,
      currencySymbol: tipData.currencySymbol,
      persons: tipData.isSplitByItems ? tipData.persons : null,
    );
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(tipData.t('history_saved'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipData = context.watch<TipData>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tipData.t('app_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: tipData.t('share'),
            onPressed: tipData.amount <= 0
                ? null
                : () => showShareSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: tipData.t('history_save'),
            onPressed: () => _saveCurrent(context),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: tipData.t('history_title'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.contrast),
            tooltip: tipData.t('theme_title'),
            onPressed: () => showThemeSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        // Scrolls rather than squeezing into fixed flex bands: the tip card
        // grows when a country suggestion arrives, and the keyboard must not
        // overflow the layout.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            const MyAmountWidget(),
            const SizedBox(height: 12),
            const MyPeopleWidget(),
            // Appears only in itemized mode: the head count and the bill are
            // edited in the people list rather than in the fields above.
            if (tipData.isSplitByItems) ...[
              const SizedBox(height: 12),
              const ManagePeopleButton(),
            ],
            const SizedBox(height: 12),
            const MyTippingWidget(),
          ],
        ),
      ),
      bottomNavigationBar: const MyTotalWidget(),
    );
  }
}
