import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/firebase_bootstrap.dart';
import 'package:tip_calculator/service/history_data.dart';
import 'package:tip_calculator/service/session_data.dart';
import 'package:tip_calculator/service/settings_data.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_theme.dart';
import 'package:tip_calculator/web/web_home_screen.dart';

/// Web entrypoint: the guest half of the app, nothing else.
///
///     flutter run -d chrome -t lib/main_web.dart
///     flutter build web -t lib/main_web.dart --release \
///       --dart-define=RECAPTCHA_SITE_KEY=...
///
/// One codebase, two entrypoints. `lib/main.dart` stays the full mobile app;
/// this one reaches only the join flow and the shared bill, so everything else
/// -- history, sharing, the tip advisor, the standalone calculator -- is
/// unreachable from here and is dropped from the web bundle by tree shaking.
///
/// Keep it that way: importing a screen here is what pulls it into the
/// download, not whether the user can see it.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Never fatal on mobile, but on the web a failure here means no sessions at
  // all -- so the join screen checks [FirebaseBootstrap.isReady] and says so
  // rather than letting the user type a code into a dead form.
  await FirebaseBootstrap.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TipData()),
        // Reached from the session screen's "save a copy" only. On the web it
        // is backed by browser storage, so it survives a reload and nothing
        // more; the phone app remains the place a bill is kept.
        ChangeNotifierProvider(create: (_) => HistoryData()),
        ChangeNotifierProvider(create: (_) => SettingsData()),
        ChangeNotifierProvider(
          create: (context) => SessionData(context.read<TipData>()),
        ),
      ],
      child: const TipCalculatorWebApp(),
    ),
  );
}

class TipCalculatorWebApp extends StatelessWidget {
  const TipCalculatorWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsData>();

    return MaterialApp(
      title: context.watch<TipData>().t('app_title'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const WebHomeScreen(),
    );
  }
}
