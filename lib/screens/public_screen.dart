import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'analytics_view.dart'; // Sesuaikan folder jika berbeda

// --- THEME COLORS ---
class SeismicColors {
  static const Color navyDark = Color(0xFF0F172A);
  static const Color navyAccent = Color(0xFF1E293B);
  static const Color redAlert = Color(0xFFE11D48);
  static const Color orangeAlert = Color(0xFFF97316);
  static const Color greenAlert = Color(0xFF22C55E);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color bgLight = Color(0xFFF1F5F9);
}

// --- MODEL DATA SERAGAM ---
class GempaModel {
  final String source;
  final String magnitude;
  final String wilayah;
  final String waktu;
  final String kedalaman;

  GempaModel({
    required this.source,
    required this.magnitude,
    required this.wilayah,
    required this.waktu,
    required this.kedalaman,
  });
}

class PublicScreen extends StatefulWidget {
  const PublicScreen({super.key});

  @override
  State<PublicScreen> createState() => _PublicScreenState();
}

class _PublicScreenState extends State<PublicScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    const LiveMapView(), // INI BARU DITAMBAHKAN
    const AnalyticsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeismicColors.bgLight,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: SeismicColors.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Live Map'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Analytics'),
        ],
      ),
    );
  }
}

// --- DASHBOARD VIEW ---
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // 1. Tarik Data BMKG Real-time (Untuk Hero Card)
  Future<Map<String, dynamic>?> _fetchBMKGLatest() async {
    try {
      final response = await http.get(Uri.parse('https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['Infogempa']['gempa'];
      }
    } catch (e) {
      debugPrint('Error BMKG Latest: $e');
    }
    return null;
  }

  // 2. Tarik Data Gabungan BMKG, USGS, EMSC (Untuk Recent Activity)
  // 2. Tarik Data Gabungan dari Data Warehouse (Supabase)
  Future<List<GempaModel>> _fetchAllSeismicData() async {
    try {
      // Ambil data langsung dari tabel penampung ETL kita
      final response = await Supabase.instance.client
          .from('gempa_live')
          .select('*')
          .order('magnitude', ascending: false) // Tampilkan gempa paling besar di atas
          .limit(20); // Ambil 20 data saja biar list tidak terlalu panjang

      List<GempaModel> combinedData = [];
      for (var item in response) {
        combinedData.add(GempaModel(
          source: item['source'] ?? 'Unknown',
          magnitude: item['magnitude'].toString(),
          wilayah: item['wilayah'] ?? '-',
          waktu: item['waktu'] ?? '-',
          kedalaman: item['kedalaman'] ?? '-',
        ));
      }
      return combinedData;
    } catch (e) {
      debugPrint("Supabase Fetch Error: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const Icon(Icons.menu, color: SeismicColors.navyDark),
          title: const Text('SEISMIC.PRO', style: TextStyle(color: SeismicColors.navyDark, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.notifications_none_rounded, color: SeismicColors.navyDark), onPressed: () {})
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ALERT BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: SeismicColors.redAlert, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tsunami Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Active monitoring. Follow local authorities instructions.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text('LATEST EARTHQUAKE (BMKG)', style: TextStyle(fontWeight: FontWeight.w800, color: SeismicColors.textMuted, letterSpacing: 1)),
              const SizedBox(height: 12),

              // --- FUTURE BUILDER: HERO CARD (BMKG) ---
              FutureBuilder<Map<String, dynamic>?>(
                future: _fetchBMKGLatest(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Gagal memuat data BMKG')));
                  }

                  final bmkg = snapshot.data!;
                  double mag = double.tryParse(bmkg['Magnitude'] ?? '0') ?? 0;
                  Color badgeColor = mag >= 5.0 ? SeismicColors.redAlert : SeismicColors.orangeAlert;
                  String badgeText = mag >= 5.0 ? 'STRONG' : 'MODERATE';

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Image.network(
                              'https://data.bmkg.go.id/DataMKG/TEWS/${bmkg['Shakemap']}',
                              height: 200, width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Container(height: 200, color: SeismicColors.navyDark, child: const Center(child: Text('Peta tidak tersedia', style: TextStyle(color: Colors.white)))),
                            ),
                            Positioned(
                              top: 12, left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
                                child: Text(badgeText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                                alignment: Alignment.center,
                                child: Text(bmkg['Magnitude'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(bmkg['Wilayah'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SeismicColors.navyDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    Text('Kedalaman: ${bmkg['Kedalaman']} • ${bmkg['Jam']}', style: const TextStyle(color: SeismicColors.textMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('RECENT ACTIVITY (GLOBAL FEED)', style: TextStyle(fontWeight: FontWeight.w800, color: SeismicColors.textMuted, letterSpacing: 1)),
                  TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: Colors.blueAccent))),
                ],
              ),

              // --- FUTURE BUILDER: RECENT ACTIVITY (GABUNGAN 3 API) ---
              FutureBuilder<List<GempaModel>>(
                future: _fetchAllSeismicData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Gagal sinkronisasi API.'));
                  }

                  return Column(
                    children: snapshot.data!.map((gempa) {
                      
                      // Logika warna berdasarkan Magnitudo
                      Color color = SeismicColors.greenAlert;
                      double magVal = double.tryParse(gempa.magnitude) ?? 0;
                      if (magVal >= 5.0) {
                        color = SeismicColors.redAlert;
                      } else if (magVal >= 4.0) {
                        color = SeismicColors.orangeAlert;
                      }

                      // Label sumber API
                      Widget sourceBadge = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: gempa.source == 'BMKG' ? Colors.blue : (gempa.source == 'USGS' ? Colors.purple : Colors.teal),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(gempa.source, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Text(gempa.magnitude, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gempa.wilayah, style: const TextStyle(fontWeight: FontWeight.bold, color: SeismicColors.navyDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      sourceBadge,
                                      const SizedBox(width: 8),
                                      Expanded(child: Text('${gempa.waktu} • ${gempa.kedalaman}', style: const TextStyle(color: SeismicColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ],
    );
  }
}
 // Pastikan import ini ditambahkan di paling atas file!

// --- LIVE MAP VIEW ---


// --- LIVE MAP VIEW (PAKAI OPENSTREETMAP - GRATIS 100%) ---
class LiveMapView extends StatefulWidget {
  const LiveMapView({super.key});

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    try {
      final response = await Supabase.instance.client.from('gempa_live').select('*');

      List<Marker> newMarkers = [];
      for (var item in response) {
        if (item['koordinat'] != null) {
          List<String> coords = item['koordinat'].toString().split(',');
          if (coords.length == 2) {
            double lat = double.tryParse(coords[0]) ?? 0;
            double lng = double.tryParse(coords[1]) ?? 0;
            double mag = item['magnitude'] != null ? double.tryParse(item['magnitude'].toString()) ?? 0 : 0;

            // Logika Warna Marker
            Color markerColor = SeismicColors.greenAlert;
            if (mag >= 5.0) markerColor = SeismicColors.redAlert;
            else if (mag >= 4.0) markerColor = SeismicColors.orangeAlert;

            newMarkers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    // Tampilkan pop-up kecil saat titik gempa diklik
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('M $mag • ${item['source']}\n${item['wilayah']}'),
                        backgroundColor: markerColor,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Icon(Icons.location_on, color: markerColor, size: 35),
                ),
              ),
            );
          }
        }
      }

      setState(() {
        _markers = newMarkers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error Map: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-2.5489, 118.0149), // Titik tengah Indonesia
            initialZoom: 4.5,
          ),
          children: [
            // Ini lapisan gambar petanya (TileLayer) dari OpenStreetMap
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.seismoguard.app', 
            ),
            // Ini lapisan titik-titik gempanya
            MarkerLayer(markers: _markers),
          ],
        ),
        
        // Floating Banner Info
        Positioned(
          top: 60, left: 20, right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Row(
              children: [
                const Icon(Icons.satellite_alt_rounded, color: SeismicColors.navyDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Menampilkan ${_markers.length} Titik Gempa Aktif', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: SeismicColors.navyDark)
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}