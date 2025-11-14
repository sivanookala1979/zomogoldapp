import 'package:flutter/material.dart';

import 'screens/otp_verification_screen.dart';
import 'screens/phone_login_screen.dart';
import 'theme/app_theme.dart';

void main() {
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
      initialRoute: '/',
      routes: {
        '/': (context) => const PhoneLoginScreen(),
        '/otp': (context) => const OtpVerificationScreen(),
      },
    );
  }
}
