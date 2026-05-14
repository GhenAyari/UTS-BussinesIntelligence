import 'package:flutter/material.dart';
import 'package:sasimo_guard/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // KITA SUNTIK LANGSUNG URL & KEY-NYA DI SINI (TANPA .ENV)
  await Supabase.initialize(
    url: 'https://tdjmedsweejiwibzywtv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRkam1lZHN3ZWVqaXdpYnp5d3R2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NzI3ODksImV4cCI6MjA5NDA0ODc4OX0.ggSVpWwbvnSYbGJR6KuY9zrHtNbpqMhx9zKBVNBFxeE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeismoGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, // Gunakan Material 3 agar lebih modern
        colorSchemeSeed: Colors.blue,
      ),
      // Sekarang langsung ke HomeScreen tanpa paksa Login di awal
      home: const HomeScreen(), 
    );
  }
}