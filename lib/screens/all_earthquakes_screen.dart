import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeismicColors {
  static const Color navyDark = Color(0xFF0F172A);
  static const Color navyAccent = Color(0xFF1E293B);
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
  bool _isLoadingMore = false; 
  bool _hasMoreData = true; 
  int _totalDataTersedia = 0; 
  
  // Variabel Pagination & Search
  final int _limit = 15; 
  int _offset = 0; 
  String _searchQuery = ""; 
  
  // Variabel Filter Waktu
  String _activeTimeFilter = 'Semua Waktu'; 
  DateTime _startDate = DateTime(2000); 
  DateTime _endDate = DateTime.now();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData(isRefresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreData) {
          _fetchData(isRefresh: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _searchQuery = value;
    });
    _fetchData(isRefresh: true);
  }

  void _applyTimeFilter(String preset) {
    final now = DateTime.now();
    DateTime start;

    switch (preset) {
      case '7 Hari Terakhir':
        start = now.subtract(const Duration(days: 7));
        break;
      case '30 Hari Terakhir':
        start = now.subtract(const Duration(days: 30));
        break;
      case 'Bulan Ini':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Tahun Ini':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = DateTime(2000); 
    }

    setState(() {
      _activeTimeFilter = preset;
      _startDate = start;
      _endDate = now;
    });
    _fetchData(isRefresh: true);
  }

  String _fmtDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _fetchData({required bool isRefresh}) async {
    if (isRefresh) {
      _offset = 0;
      _hasMoreData = true;
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      // ==============================================================
      // 1. CARI TOTAL DATA (NATIVE COUNT) - ANTI MENTOK 1000 BARIS
      // ==============================================================
      var countBuilder = Supabase.instance.client
          .schema('gold')
          .from('gold_gempa_analytics')
          .count(CountOption.exact); // Nyuruh Database yang ngitung!

      if (_searchQuery.isNotEmpty) {
        countBuilder = countBuilder.ilike('wilayah', '%$_searchQuery%');
      }
      
      if (_activeTimeFilter != 'Semua Waktu') {
        countBuilder = countBuilder.gte('waktu', _fmtDate(_startDate))
                                   .lte('waktu', '${_fmtDate(_endDate)} 23:59:59');
      }

      // Ini outputnya bakal tembus angka 93.000 karena ga narik isi datanya
      final int totalCount = await countBuilder;

      // ==============================================================
      // 2. TARIK DATA ASLI (LIST) PAKE LIMIT 15
      // ==============================================================
      var dataQuery = Supabase.instance.client
          .schema('gold')
          .from('gold_gempa_analytics')
          .select('*');

      if (_searchQuery.isNotEmpty) {
        dataQuery = dataQuery.ilike('wilayah', '%$_searchQuery%');
      }
      
      if (_activeTimeFilter != 'Semua Waktu') {
        dataQuery = dataQuery.gte('waktu', _fmtDate(_startDate))
                             .lte('waktu', '${_fmtDate(_endDate)} 23:59:59');
      }

      final data = await dataQuery
          .order('id_fakta', ascending: false)
          .range(_offset, _offset + _limit - 1);

      setState(() {
        _totalDataTersedia = totalCount;

        if (isRefresh) {
          _earthquakes = data;
        } else {
          _earthquakes.addAll(data);
        }

        _offset += data.length;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menarik data dari server.')));
      }
    }
  }

  void _showDetailModal(dynamic item, Color magColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(color: magColor, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: Text(item['magnitude']?.toString() ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['waktu']?.toString() ?? '-', style: const TextStyle(color: SeismicColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(item['wilayah']?.toString() ?? 'Lokasi Tidak Diketahui', style: const TextStyle(color: SeismicColors.navyDark, fontWeight: FontWeight.w900, fontSize: 18), maxLines: 3),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDetailItem(Icons.waves_rounded, 'Kedalaman', '${item['kedalaman']} km'),
                  _buildDetailItem(Icons.warning_rounded, 'Kategori', item['kategori_bahaya']?.toString() ?? '-'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDetailItem(Icons.my_location_rounded, 'Koordinat', '${item['latitude']}, ${item['longitude']}'),
                  _buildDetailItem(Icons.source_rounded, 'Sumber', item['sumber_data']?.toString() ?? '-'),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SeismicColors.navyDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup Detail', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: SeismicColors.blueLight, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: SeismicColors.textMuted, fontSize: 12)),
                Text(value, style: const TextStyle(color: SeismicColors.navyDark, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
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
            Text('Menampilkan ${_earthquakes.length} dari $_totalDataTersedia Kejadian', style: const TextStyle(color: SeismicColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── SEARCH BAR & FILTER ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _onSearch, 
                    decoration: InputDecoration(
                      hintText: 'Cari wilayah...',
                      hintStyle: const TextStyle(color: SeismicColors.textMuted),
                      prefixIcon: const Icon(Icons.search, color: SeismicColors.navyDark),
                      suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear), 
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              }
                            ) 
                          : null,
                      filled: true,
                      fillColor: SeismicColors.bgLight,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // TOMBOL FILTER DROPDOWN
                Container(
                  decoration: BoxDecoration(
                    color: _activeTimeFilter != 'Semua Waktu' ? SeismicColors.blueLight : SeismicColors.bgLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.filter_alt_rounded, 
                      color: _activeTimeFilter != 'Semua Waktu' ? Colors.white : SeismicColors.navyDark
                    ),
                    onSelected: _applyTimeFilter,
                    itemBuilder: (BuildContext context) {
                      return ['Semua Waktu', '7 Hari Terakhir', '30 Hari Terakhir', 'Bulan Ini', 'Tahun Ini']
                          .map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Row(
                            children: [
                              Icon(
                                choice == _activeTimeFilter ? Icons.check_circle : Icons.circle_outlined,
                                color: choice == _activeTimeFilter ? SeismicColors.blueLight : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(choice),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ],
            ),
          ),

          if (_activeTimeFilter != 'Semua Waktu')
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 8, left: 16),
              child: Row(
                children: [
                  const Text('Filter Aktif: ', style: TextStyle(color: SeismicColors.textMuted, fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: SeismicColors.blueLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(_activeTimeFilter, style: const TextStyle(color: SeismicColors.blueLight, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // ── LIST VIEW (INFINITE SCROLL) ──
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: SeismicColors.redAlert))
              : _earthquakes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Tidak ada gempa di wilayah "$_searchQuery"', style: const TextStyle(color: SeismicColors.textMuted, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _fetchData(isRefresh: true),
                      color: SeismicColors.navyDark,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _earthquakes.length + (_hasMoreData ? 1 : 0),
                        itemBuilder: (context, index) {
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
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showDetailModal(item, magColor), 
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 55, height: 55,
                                      decoration: BoxDecoration(color: magColor, borderRadius: BorderRadius.circular(12)),
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
                                                decoration: BoxDecoration(color: SeismicColors.navyAccent, borderRadius: BorderRadius.circular(4)),
                                                child: Text(item['sumber_data'] ?? 'DATA', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  item['waktu'].toString(), 
                                                  style: const TextStyle(color: SeismicColors.textMuted, fontSize: 11), 
                                                  overflow: TextOverflow.ellipsis
                                                )
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: SeismicColors.textMuted),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}