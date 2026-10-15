import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'providers/theme_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'config/responsive_config.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: SirfBillApp()));
}

class SirfBillApp extends ConsumerWidget {
  const SirfBillApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'SirfBill Bill Karo, Befikar Raho',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
        cardColor: const Color(0xFF1E293B),
        useMaterial3: true,
      ),
      routerConfig: goRouter,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: ResponsiveConfig.breakpoints,
      ),
    );
  }
}
