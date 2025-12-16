import 'package:flutter/material.dart';
import 'splash_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hbmcsggewzdxheujqctb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhibWNzZ2dld3pkeGhldWpxY3RiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3NDUwNjIsImV4cCI6MjA4MTMyMTA2Mn0.T0VcdchF6XOJFon4pdHyKb0GZDQMChqiYLfeWheSvC4',
  );

  runApp(const KanavuConnectApp());
}

class KanavuConnectApp extends StatelessWidget {
  const KanavuConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanavu Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF5350), // Light Red
          primary: const Color(0xFFEF5350),
          secondary: const Color(0xFFFFCDD2),
          background: const Color(0xFFFFEBEE), // Very light red background
        ),
        scaffoldBackgroundColor: const Color(0xFFFFEBEE),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default, but explicit is good
        // Input Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade100, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),

        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF5350),
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.red.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
