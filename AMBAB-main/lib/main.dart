import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agriplant/widgets/auth_wrapper.dart';
import 'package:agriplant/pages/onboarding_page.dart';
import 'package:agriplant/pages/home_page.dart';
import 'package:agriplant/pages/orders_page.dart';
import 'package:agriplant/pages/vendor_orders_page.dart';
import 'package:agriplant/pages/login_page.dart';
import 'package:agriplant/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:agriplant/l10n/app_localizations.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const LocaleApp());
}

class LocaleApp extends StatefulWidget {
  const LocaleApp({super.key});
  static _LocaleAppState? of(BuildContext context) => context.findAncestorStateOfType<_LocaleAppState>();
  @override
  State<LocaleApp> createState() => _LocaleAppState();
}

class _LocaleAppState extends State<LocaleApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainApp(locale: _locale, setLocale: setLocale);
  }
}

class MainApp extends StatelessWidget {
  final Locale? locale;
  final void Function(Locale) setLocale;
  const MainApp({super.key, this.locale, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const HomePage(),
        '/orders': (context) => const OrdersPage(),
        '/vendor-orders': (context) => const VendorOrdersPage(),
        '/login': (context) => const LoginPage(),
      },
      onGenerateTitle: (context) => AppLocalizations.of(context)?.appTitle ?? 'AMBAB Marketplace',
    );
  }
}

// Helper to show language picker dialog anywhere
Future<void> showLanguagePicker(BuildContext context) async {
  final appState = LocaleApp.of(context);
  final currentLocale = Localizations.localeOf(context);
  final selected = await showDialog<Locale>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)?.language ?? 'Language'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<Locale>(
            value: const Locale('en'),
            groupValue: currentLocale,
            title: Text(AppLocalizations.of(context)?.english ?? 'English'),
            onChanged: (val) => Navigator.of(context).pop(val),
          ),
          RadioListTile<Locale>(
            value: const Locale('ar'),
            groupValue: currentLocale,
            title: Text(AppLocalizations.of(context)?.arabic ?? 'Arabic'),
            onChanged: (val) => Navigator.of(context).pop(val),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    ),
  );
  if (selected != null && appState != null) {
    appState.setLocale(selected);
    final snack = selected.languageCode == 'ar'
        ? (AppLocalizations.of(context)?.switchToArabic ?? 'Switched to Arabic')
        : (AppLocalizations.of(context)?.switchToEnglish ?? 'Switched to English');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack)));
  }
}
