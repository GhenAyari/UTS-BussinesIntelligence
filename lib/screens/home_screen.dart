import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_pusat_screen.dart';
import 'admin_daerah_screen.dart';
import 'public_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Fungsi ini mengambil role dari database Supabase
  Future<Widget> _checkUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const LoginScreen();

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final role = response['role'] as String;

      // LOGIKA MELEMPAR HALAMAN (ROUTING)
      if (role == 'admin_pusat') {
        return const AdminPusatScreen();
      } else if (role == 'admin_daerah') {
        return const AdminDaerahScreen();
      } else {
        return const PublicScreen(); // Default lempar ke halaman Public (Gempa Terkini)
      }
    } catch (e) {
      // Jika terjadi error, lempar ke Public
      return const PublicScreen(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Widget>(
        future: _checkUserRole(),
        builder: (context, snapshot) {
          // Selagi nunggu balasan dari database, tampilkan animasi loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengecek Hak Akses...')
                ],
              ),
            );
          }

          // Kalau pengecekan selesai, tampilkan layarnya!
          if (snapshot.hasData) {
            return snapshot.data!;
          }

          // Fallback kalau error
          return const PublicScreen();
        },
      ),
    );
  }
}