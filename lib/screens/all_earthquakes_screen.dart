import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isLoading = true; // Loading pertama kali
  bool _isLoadingMore = false; // Loading saat scroll ke bawah
  bool _hasMoreData = true; // Penanda apakah masih ada sisa data di database
  
  // Variabel Pagination
  int _limit = 20; // Jumlah data per tarikan
  int _offset = 0; // Titik mulai tarikan data
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData(isRefresh: true); // Tarik data pertama kali

    // Pasang pendengar scroll
    _scrollController.addListener(() {
      // Jika scroll sudah mencapai batas bawah dan tidak sedang loading data lain
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreData) {
          _fetchData(isRefresh: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Wajib dibersihkan saat pindah halaman
    super.dispose();
  }

  // Fungsi sakti untuk Refresh DAN Infinite Loading
  Future<void> _fetchData({required bool isRefresh}) async {
    if (isRefresh) {
      // Jika refresh dari atas, kembalikan semuanya ke awal
      _offset = 0;
      _hasMoreData = true;
      setState(() => _isLoading = true);
    } else {
      // Jika infinite scroll, nyalakan loading bawah
      setState(() => _isLoadingMore = true);
    }

    try {
      // Menarik data dengan batasan limit dan offset
      final data = await Supabase.instance.client
          .from('gempa_live')
          .select('*')
          .order('waktu', ascending: false)
          .range(_offset, _offset + _limit - 1); 

      setState(() {
        if (isRefresh) {
          _earthquakes = data; // Timpa data lama
        } else {
          _earthquakes.addAll(data); // Sambung ke bawah data yang sudah ada
        }

        _offset += data.length; // Geser titik mulai untuk tarikan berikutnya

        // Jika data yang didapat lebih sedikit dari limit, berarti data sudah habis
        if (data.length < _limit) {
          _hasMoreData = false;
        }

        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
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
            Text('${_earthquakes.length} Events Loaded', style: const TextStyle(color: SeismicColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchData(isRefresh: true),
              color: SeismicColors.navyDark,
              child: ListView.builder(
                controller: _scrollController, // Sambungkan ke controller
                padding: const EdgeInsets.all(16),
                // Tambah 1 item ekstra di bawah khusus untuk indikator loading
                itemCount: _earthquakes.length + (_hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  // Jika index mencapai ujung list, tampilkan loading spinner
                  if (index == _earthquakes.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator(color: SeismicColors.blueLight)),
                    );
                  }

                  final item = _earthquakes[index];
                  double mag = double.tryParse(item['magnitude'].toString()) ?? 0;
                  
                  Color magColor = SeismicColors.blueLight; 
                  if (mag >= 6.0) magColor = SeismicColors.redAlert;
                  else if (mag >= 5.0) magColor = SeismicColors.orangeAlert;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
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