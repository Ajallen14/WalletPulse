import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_pulse/features/dashboard/presentation/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await DatabaseHelper.instance.database;

  runApp(
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
      home: const MainLayout(),
    );
  }
}
