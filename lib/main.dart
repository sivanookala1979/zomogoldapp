import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:zomogoldapp/screens/history_screen.dart';
import 'package:zomogoldapp/screens/product_view_page.dart';

import 'screens/phone_login_screen.dart';
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
        storageBucket: "zomo-1f300.firebasestorage.app",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();

    _appLinks = AppLinks();

    _appLinks.uriLinkStream.listen((uri) {
      if (uri.pathSegments.contains('product')) {
        final productId = uri.pathSegments.last;

        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsViewPage(productId: productId),
          ),
        );
      }
    });
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Phone Login Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US')],
      initialRoute: '/',
      routes: {
        '/': (context) => const PhoneLoginScreen(),
        // '/': (context) => const GoldRatesScreen(),
        '/history': (context) {
          final String type =
              ModalRoute.of(context)!.settings.arguments as String;
          return PriceHistoryScreen(productType: type);
        },
      },
    );
  }
}
