import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 3 seconds then navigate to Dashboard
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/LOGO.png',
                height: 150,
                cacheHeight: 450, // Added to prevent excessive memory usage
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'MANJU MEDICAL STORES\n& DIGITAL CLINIC',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
