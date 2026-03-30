import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_pulse/features/dashboard/presentation/main_layout.dart';
import 'features/dashboard/presentation/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database connection before the app starts
  // await DatabaseHelper.instance.database;

  runApp(
    // ProviderScope is MANDATORY for Riverpod to work
    const ProviderScope(child: WalletPulseApp()),
  );
}

class WalletPulseApp extends StatelessWidget {
  const WalletPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WalletPulse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // Temporarily use a placeholder until we build the HomeScreen
      home: const MainLayout(),
    );
  }
}
