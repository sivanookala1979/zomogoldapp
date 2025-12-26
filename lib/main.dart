import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'screens/phone_login_screen.dart';
import 'screens/gold_rate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBFTAwxOc-aXanFqeRMKzmYKKJj5b_zdso",
        appId: "1:616832457082:web:9be2cc9543707eceff5ec3",
        messagingSenderId: "616832457082",
        projectId: "zomo-1f300",
        storageBucket: "zomo-1f300.firebasestorage.app"
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Login Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate, // Important for Quill
      ],
      supportedLocales: const [Locale('en', 'US')],
      initialRoute: '/',

      routes: {'/': (context) => const PhoneLoginScreen()},
      // routes: {'/': (context) => const GoldRatesScreen()},
    );
  }
}
