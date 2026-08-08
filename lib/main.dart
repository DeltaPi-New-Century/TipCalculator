import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:tip_calculator/service/shared_data.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/service/history_data.dart';
import 'package:tip_calculator/history_screen.dart';
import 'package:tip_calculator/split_screen.dart';
import 'package:tip_calculator/amount_widget.dart';
import 'package:tip_calculator/people_widget.dart';
import 'package:tip_calculator/tipping_widget.dart';
import 'package:tip_calculator/total_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:tip_calculator/components/modal_language.dart';

Future main() async {
  // Binding must be initialized before any plugin/asset access (dotenv reads
  // from the asset bundle). Newer Flutter versions assert on the wrong order.
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  // await MobileAds.instance.initialize();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
    (value) => {
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TipData()),
            ChangeNotifierProvider(create: (_) => HistoryData()),
          ],
          child: const MyApp(),
        ),
      ),
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TipData>(
      builder: (context, shareddata, child) {
        return MaterialApp(
          title: '${shareddata.translations['app_title']}',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
            useMaterial3: true,
          ),
          home: MyHomePage(title: '${shareddata.translations['app_title']}'),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // bool isBannerLoaded = false;
  // late BannerAd bannerAd;

  // Future<void> inilizeBannerAd() async {
  // bannerAd = BannerAd(
  //   size: AdSize.banner,
  //   adUnitId: 'ca-app-pub-2237199373273098/8606613360',
  //   listener: BannerAdListener(
  //     onAdLoaded: (ad) {
  //       setState(() {
  //         isBannerLoaded = true;
  //         print("Banner has been loaded!");
  //       });sdkm
  //     },
  //     onAdFailedToLoad: (ad, error) {
  //       ad.dispose();
  //       isBannerLoaded = false;
  //       print(error);
  //     },
  //   ),
  //   request: const AdRequest(),
  // );

  // bannerAd.load();
  // }

  @override
  void initState() {
    super.initState();
    /* inilizeBannerAd(); */
  }

  String _text(final String key, final String fallback) =>
      context.read<TipData>().translations[key] ?? fallback;

  Future<void> _saveCurrent() async {
    final tipData = context.read<TipData>();
    final messenger = ScaffoldMessenger.of(context);

    // Nothing to save before an amount is entered.
    if (tipData.amount <= 0) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _text('history_nothing_to_save', 'Enter an amount first'),
          ),
        ),
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
      SnackBar(content: Text(_text('history_saved', 'Saved to history'))),
    );
  }

  Widget _buildSplitControls() {
    return Consumer<TipData>(
      builder: (context, tipData, child) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SegmentedButton<SplitMode>(
                segments: [
                  ButtonSegment(
                    value: SplitMode.evenly,
                    icon: const Icon(Icons.groups_outlined, size: 18),
                    label: Text(_text('split_evenly', 'Evenly')),
                  ),
                  ButtonSegment(
                    value: SplitMode.byItems,
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: Text(_text('split_by_items', 'By items')),
                  ),
                ],
                selected: {tipData.splitMode},
                onSelectionChanged: (selection) =>
                    tipData.setSplitMode(selection.first),
              ),
              if (tipData.isSplitByItems) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    '${_text('split_manage', 'Manage people')}'
                    ' (${tipData.persons.length})',
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MySplitScreen()),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyHistoryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: _text('history_save', 'Save'),
            onPressed: _saveCurrent,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: _text('history_title', 'History'),
            onPressed: _openHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(child: MyAmountWidget()),
                        Expanded(child: MyPeopleWidget()),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: MyTippingWidget()),
                ],
              ),
            ),
            const Expanded(
              //flex: 1,
              child: MyTotalWidget(),
            ),
            Expanded(flex: 2, child: _buildSplitControls()),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton.small(
      //   child: const Icon(Icons.language_rounded),
      //   onPressed: () async {
      //     bool? confirmed =
      //         await showMyLanguageDialog(context); // Wait for the result

      //     if (confirmed == true) {
      //       // Perform action if confirmed
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         const SnackBar(content: Text('Action Confirmed!')),
      //       );
      //     }
      //   },
      // ),
    );
  }
}
