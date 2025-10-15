import 'dart:async';
import 'package:flutter/material.dart';
import 'Reset_password.dart'; // Make sure this import path is correct

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> controllers =
      List.generate(4, (_) => TextEditingController());

  Timer? _timer;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _confirmCode() {
    String code = controllers.map((c) => c.text).join();

    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all 4 digits")),
      );
    } else {
      // Accept any 4-digit code and navigate to ResetPasswordScreen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Code entered: $code')),
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = "00:${_secondsLeft.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 210, 189, 166),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 180, 150, 120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Get your code',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please enter the code that is sent\non your email address',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/forgot_password/library.png',
                width: 180,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 50,
                  child: TextField(
                    controller: controllers[index],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                if (_secondsLeft == 0) {
                  Navigator.pop(context);
                }
              },
              child: Text(
                "Resend code in : $formattedTime",
                style: TextStyle(
                  fontSize: 14,
                  color: _secondsLeft == 0 ? Colors.blue : Colors.black54,
                  decoration: _secondsLeft == 0
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  fontWeight: _secondsLeft == 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _confirmCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[900],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Confirm code"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
