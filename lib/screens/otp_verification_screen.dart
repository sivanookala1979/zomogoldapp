import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final ConfirmationResult? confirmationResult;
  final String? verificationId;

  const OtpVerificationScreen({
    super.key,
    this.confirmationResult,
    this.verificationId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((e) => e.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter 6-digit OTP')));
      return;
    }

    try {
      if (widget.confirmationResult != null) {
        await widget.confirmationResult!.confirm(otp);
      } else if (widget.verificationId != null) {
        final credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId!,
          smsCode: otp,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Verified Successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context,
      ).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  void _resendOtp() {
    if (_secondsRemaining == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP resent successfully')));
      _startTimer();
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 60,
      height: 65,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.purple[600]!, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (RegExp(r'^[0-9]$').hasMatch(value)) {
                  if (index < 5) {
                    FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                  } else {
                    _focusNodes[index].unfocus();
                  }
                } else {
                  _otpControllers[index].clear();
                }
              } else if (index > 0) {
                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
              }
              setState(() {});
            },
          ),
          if (_otpControllers[index].text.isEmpty)
            const Text(
              "-",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String phoneNumber =
        ModalRoute.of(context)?.settings.arguments as String? ?? "";
    final String maskedPhone = phoneNumber.length > 4
        ? '*******${phoneNumber.substring(phoneNumber.length - 4)}'
        : phoneNumber;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 🔙 Back Icon
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            // 🟣 Main Content
            Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width > 600 ? size.width * 0.25 : 24,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "OTP verification",
                      style: TextStyle(
                        fontSize: AppText.heading,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter the verification code we sent you on: $maskedPhone",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppText.body,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => _buildOtpBox(index),
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Verify",
                          style: TextStyle(
                            fontSize: AppText.body,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Resend Timer / Button
                    Center(
                      child: _secondsRemaining > 0
                          ? Text(
                              "Resend OTP in $_secondsRemaining sec",
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: AppText.body,
                              ),
                            )
                          : GestureDetector(
                              onTap: _resendOtp,
                              child: Text(
                                "Resend OTP",
                                style: TextStyle(
                                  color: AppColors.purple[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppText.body,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
