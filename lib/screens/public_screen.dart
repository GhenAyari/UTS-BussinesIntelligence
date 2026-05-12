import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart'; // Pastikan path ini benar untuk fitur Logout

class PublicScreen extends StatefulWidget {
  const PublicScreen({super.key});

  @override
  State<PublicScreen> createState() => _PublicScreenState();
}

class _PublicScreenState extends State<PublicScreen> {
  // Fungsi untuk menarik data dari lapisan GOLD (Star Schema)
  Future<List<Map<String, dynamic>>> _fetchGempaTerbaru() async {
    // Kita melakukan JOIN dari fact_gempa ke dim_waktu dan dim_lokasi
    final response = await Supabase.instance.client
        .schema('gold') // Memilih schema gold
        .from('fact_gempa')
        .select('''
          magnitudo, 
          kedalaman, 
          status_gempa,
          dim_waktu (tanggal), 
          dim_lokasi (wilayah)
        ''')
        .order('id_fakta', ascending: false) // Ambil yang paling baru
        .limit(20); // Batasi 20 data terbaru biar tidak berat

    return List<Map<String, dynamic>>.from(response);
  }

  // Fungsi Logout
  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Informasi Gempa Terkini'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchGempaTerbaru(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
          }

          final dataGempa = snapshot.data;

          if (dataGempa == null || dataGempa.isEmpty) {
            return const Center(child: Text('Belum ada data gempa.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: dataGempa.length,
            itemBuilder: (context, index) {
              final gempa = dataGempa[index];
              final magnitudo = gempa['magnitudo'];
              final status = gempa['status_gempa'];
              final tanggal = gempa['dim_waktu']['tanggal'];
              final wilayah = gempa['dim_lokasi']['wilayah'];

              // Bikin warna indikator bahaya berdasarkan status
              // Bikin warna indikator bahaya berdasarkan status
              Color statusColor = Colors.grey;
              String statusKecil = status.toString().toLowerCase();

              if (statusKecil.contains('terasa') || magnitudo >= 5.0) {
                statusColor = Colors.red;
              } else if (statusKecil.contains('sedang')) {
                statusColor = Colors.orange;
              } else {
                statusColor = Colors.green;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    radius: 30,
                    child: Text(
                      magnitudo.toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  title: Text(wilayah, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('📅 $tanggal'),
                      Text('⚠️ Status: $status'),
                      Text('🔻 Kedalaman: ${gempa['kedalaman']} km'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}