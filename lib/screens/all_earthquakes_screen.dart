import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Kita pinjam palet warna yang sama biar seragam
class SeismicColors {
  static const Color navyDark = Color(0xFF0F172A);
  static const Color redAlert = Color(0xFFE11D48);
  static const Color orangeAlert = Color(0xFFF97316);
  static const Color blueLight = Color(0xFF38BDF8);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color bgLight = Color(0xFFF8FAFC);
}

class AllEarthquakesScreen extends StatefulWidget {
  const AllEarthquakesScreen({super.key});

  @override
  State<AllEarthquakesScreen> createState() => _AllEarthquakesScreenState();
}

class _AllEarthquakesScreenState extends State<AllEarthquakesScreen> {
  List<dynamic> _earthquakes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // Menarik SEMUA data tanpa dilimit, diurutkan dari yang terbaru
  Future<void> _fetchAllData() async {
    try {
      final data = await Supabase.instance.client
          .from('gempa_live')
          .select('*')
          .order('waktu', ascending: false); 

      setState(() {
        _earthquakes = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching all data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeismicColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: SeismicColors.navyDark),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Global Feed', style: TextStyle(color: SeismicColors.navyDark, fontWeight: FontWeight.w900)),
            Text('${_earthquakes.length} Events Recorded', style: const TextStyle(color: SeismicColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator( // <-- DITAMBAHKAN DI SINI
              onRefresh: _fetchAllData, // <-- Memanggil ulang fungsi fetch saat ditarik
              color: SeismicColors.navyDark,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _earthquakes.length,
                itemBuilder: (context, index) {
                  final item = _earthquakes[index];
                  double mag = double.tryParse(item['magnitude'].toString()) ?? 0;
                  
                  // Logika Warna Kotak Magnitudo
                  Color magColor = SeismicColors.blueLight; // Default untuk gempa kecil
                  if (mag >= 6.0) magColor = SeismicColors.redAlert;
                  else if (mag >= 5.0) magColor = SeismicColors.orangeAlert;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    // Menambahkan efek klik pada setiap item untuk melihat detail koordinat (opsional)
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Koordinat: ${item['koordinat']}')),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Kotak Magnitudo
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: magColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(mag.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                            ),
                            const SizedBox(width: 16),
                            
                            // Detail Wilayah dan Waktu
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['wilayah'] ?? 'Unknown Location', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SeismicColors.navyDark), 
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: SeismicColors.navyDark, borderRadius: BorderRadius.circular(4)),
                                        child: Text(item['source'] ?? 'USGS', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${item['waktu']} • Kedalaman: ${item['kedalaman']}', 
                                          style: const TextStyle(color: SeismicColors.textMuted, fontSize: 11), 
                                          overflow: TextOverflow.ellipsis
                                        )
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}