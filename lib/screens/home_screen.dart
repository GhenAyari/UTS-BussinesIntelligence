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
    
    // JIKA TIDAK LOGIN -> LANGSUNG KE PETA PUBLIK
    if (user == null) {
      return const PublicScreen();
    }

    try {
      // JIKA LOGIN -> CEK ROLE ADMIN/DAERAH
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final role = response['role'] as String;
      if (role == 'admin_pusat') return const AdminPusatScreen();
      if (role == 'admin_daerah') return const AdminDaerahScreen();
      
      return const PublicScreen();
    } catch (e) {
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