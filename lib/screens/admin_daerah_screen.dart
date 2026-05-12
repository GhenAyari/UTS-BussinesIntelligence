import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class AdminDaerahScreen extends StatefulWidget {
  const AdminDaerahScreen({super.key});

  @override
  State<AdminDaerahScreen> createState() => _AdminDaerahScreenState();
}

class _AdminDaerahScreenState extends State<AdminDaerahScreen> {
  // Hanya menarik data gempa besar untuk prioritas mitigasi BPBD
  Future<List<Map<String, dynamic>>> _fetchDataMitigasi() async {
    final response = await Supabase.instance.client
        .schema('gold')
        .from('fact_gempa')
        .select('''
          magnitudo, 
          kedalaman, 
          status_gempa,
          dim_waktu (tanggal), 
          dim_lokasi (wilayah)
        ''')
        .gte('magnitudo', 5.0) // FILTER: Hanya tampilkan magnitudo 5.0 ke atas!
        .order('id_fakta', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }

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
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text('Panel Operasional BPBD'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[200],
            width: double.infinity,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚨 PRIORITAS MITIGASI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                ),
                Text(
                  'Menampilkan data historis gempa M >= 5.0 untuk alokasi sumber daya.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchDataMitigasi(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
                }

                final dataGempa = snapshot.data;

                if (dataGempa == null || dataGempa.isEmpty) {
                  return const Center(child: Text('Tidak ada peringatan mitigasi saat ini.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: dataGempa.length,
                  itemBuilder: (context, index) {
                    final gempa = dataGempa[index];
                    final magnitudo = gempa['magnitudo'];
                    final wilayah = gempa['dim_lokasi']['wilayah'];
                    final tanggal = gempa['dim_waktu']['tanggal'];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.redAccent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
                        title: Text(
                          wilayah,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text('Tanggal: $tanggal \nKedalaman: ${gempa['kedalaman']} km'),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'M $magnitudo',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}