import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'l10n.dart';
import 'screens/company_setup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'services/app_lock.dart';
import 'services/app_state.dart';
import 'widgets/lock_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppState()),
      ChangeNotifierProvider(create: (_) => AppLock()),
    ],
    child: const InvoicerApp(),
  ));
}

class InvoicerApp extends StatelessWidget {
  const InvoicerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    Lang.code = s.company?.lang ?? Lang.code;
    final dark = s.company?.dark ?? false;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invoicer',
      locale: Locale(Lang.code),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(false),
      darkTheme: buildTheme(true),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => LockOverlay(child: child ?? const SizedBox()),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (!s.authReady) return const _Loading();
    if (s.user == null) return const LoginScreen();
    if (!s.companyLoaded) return const _Loading();
    if (s.company == null) return const CompanySetupScreen();
    return const Shell();
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
