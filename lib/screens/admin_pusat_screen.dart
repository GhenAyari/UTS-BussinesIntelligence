import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';

class AdminPusatScreen extends StatefulWidget {
  const AdminPusatScreen({super.key});

  @override
  State<AdminPusatScreen> createState() => _AdminPusatScreenState();
}

class _AdminPusatScreenState extends State<AdminPusatScreen> {
  // Mengambil ringkasan data dari layer Gold untuk chart
  Future<Map<String, int>> _fetchRingkasanGempa() async {
    final response = await Supabase.instance.client
        .schema('gold')
        .from('fact_gempa')
        .select('status_gempa');

    Map<String, int> ringkasan = {
      'Kecil': 0,
      'Sedang': 0,
      'Terasa': 0,
    };

    for (var row in response) {
      String status = row['status_gempa'].toString().toLowerCase();
      if (status.contains('terasa')) {
        ringkasan['Terasa'] = (ringkasan['Terasa'] ?? 0) + 1;
      } else if (status.contains('sedang')) {
        ringkasan['Sedang'] = (ringkasan['Sedang'] ?? 0) + 1;
      } else {
        ringkasan['Kecil'] = (ringkasan['Kecil'] ?? 0) + 1;
      }
    }
    return ringkasan;
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
      appBar: AppBar(
        title: const Text('BI Dashboard - Eksekutif'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _fetchRingkasanGempa(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Gagal memuat grafik data.'));
          }

          final data = snapshot.data!;
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distribusi Kategori Gempa',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Analitik data gempa berdasarkan tingkat keparahan (Source: Gold Schema)', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                
                // Grafik Pie Chart
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: data['Kecil']!.toDouble(),
                          title: '${data['Kecil']}\nKecil',
                          radius: 80,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: data['Sedang']!.toDouble(),
                          title: '${data['Sedang']}\nSedang',
                          radius: 90,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.red,
                          value: data['Terasa']!.toDouble(),
                          title: '${data['Terasa']}\nTerasa',
                          radius: 100,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}