import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeismicColors {
  static const Color navyDark = Color(0xFF0F172A);
  static const Color navyAccent = Color(0xFF1E293B);
  static const Color redAlert = Color(0xFFE11D48);
  static const Color orangeAlert = Color(0xFFF97316);
  static const Color blueLight = Color(0xFF38BDF8); // Warna biru muda baru untuk chart
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color bgLight = Color(0xFFF8FAFC);
}

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  bool _isLoading = true;
  double _avgMagnitude = 0;
  int _totalEvents = 0;
  Map<String, int> _distribution = {'Minor': 0, 'Light': 0, 'Moderate': 0, 'Major': 0};
  List<double> _monthlyCounts = [0, 0, 0, 0, 0, 0]; // Jan - Jun
  
  // DEKLARASI VARIABEL HARUS DI SINI, DI TINGKAT CLASS
  double _maxBarValue = 50; 

  @override
  void initState() {
    super.initState();
    _calcStats();
  }

  Future<void> _calcStats() async {
    try {
      final data = await Supabase.instance.client.from('gempa_live').select('magnitude, waktu');
      
      if (data.isNotEmpty) {
        double totalMag = 0;
        Map<String, int> dist = {'Minor': 0, 'Light': 0, 'Moderate': 0, 'Major': 0};
        List<double> counts = [0, 0, 0, 0, 0, 0];

        for (var item in data) {
          double mag = double.tryParse(item['magnitude'].toString()) ?? 0;
          totalMag += mag;

          // Hitung Distribusi
          if (mag < 4.0) dist['Minor'] = dist['Minor']! + 1;
          else if (mag < 5.0) dist['Light'] = dist['Light']! + 1;
          else if (mag < 6.0) dist['Moderate'] = dist['Moderate']! + 1;
          else dist['Major'] = dist['Major']! + 1;

          // Hitung Bulanan
          String rawTime = item['waktu'].toString();
          if (rawTime.contains('-')) {
            int month = int.tryParse(rawTime.split('-')[1]) ?? 0;
            if (month >= 1 && month <= 6) {
              counts[month - 1]++;
            }
          }
        }

        // Kalkulasi batas maksimal sumbu Y sebelum masuk setState
        double highestCount = counts.reduce((curr, next) => curr > next ? curr : next);
        double calculatedMax = highestCount + (highestCount * 0.2);
        if (calculatedMax < 10) calculatedMax = 10;

        setState(() {
          _totalEvents = data.length;
          _avgMagnitude = totalMag / data.length;
          _distribution = dist;
          _monthlyCounts = counts; 
          _maxBarValue = calculatedMax; // Masukkan nilai yang sudah dihitung
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Analytics: $e");
      setState(() => _isLoading = false);
    }
  }

  // ... (Sisa kode Widget build(BuildContext context) ke bawah biarkan saja seperti milikmu) ...

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: SeismicColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('SEISMIC.PRO', style: TextStyle(color: SeismicColors.navyDark, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.notifications_none_rounded, color: SeismicColors.navyDark), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MINI STATS CARDS
            Row(
              children: [
                _buildMiniCard('GLOBAL AVG MAGNITUDE', _avgMagnitude.toStringAsFixed(2), '↑ +0.12 vs last mo.'),
                const SizedBox(width: 12),
                _buildMiniCard('MOST ACTIVE REGION', 'Ring of Fire', 'Asia Pacific Zone'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMiniCard('STATION UPTIME', '99.9%', 'Active monitoring', isPercentage: true),
                const SizedBox(width: 12),
                _buildMiniCard('24H ALERT STATUS', 'HIGH', '3 Severe Reports', isAlert: true),
              ],
            ),

            const SizedBox(height: 32),
            const Text('Seismic Event Frequency', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: SeismicColors.navyDark)),
            const Text('Monthly Historical (Jan - Jun 2024)', style: TextStyle(color: SeismicColors.textMuted, fontSize: 13)),
            const SizedBox(height: 24),

            // 2. REFINED BAR CHART
            Container(
              height: 220,
              padding: const EdgeInsets.only(top: 10, right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                 maxY: _maxBarValue,
                  barTouchData: BarTouchData(enabled: false), // Matikan efek klik biar bersih
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(color: SeismicColors.textMuted, fontWeight: FontWeight.bold, fontSize: 10);
                          String text;
                          switch (value.toInt()) {
                            case 0: text = 'JAN'; break;
                            case 1: text = 'FEB'; break;
                            case 2: text = 'MAR'; break;
                            case 3: text = 'APR'; break;
                            case 4: text = 'MAY'; break;
                            case 5: text = 'JUN'; break;
                            default: text = ''; break;
                          }
                          return SideTitleWidget(meta: meta, child: Text(text, style: style));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Sembunyikan angka di kiri
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Sembunyikan angka di atas
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Sembunyikan angka di kanan
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false, // Hilangkan garis vertikal
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false), // Hilangkan garis border luar chart
                  barGroups: _buildBarGroups(),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text('Magnitude Distribution', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: SeismicColors.navyDark)),
            const SizedBox(height: 24),

            // 3. REFINED DONUT CHART & LEGEND
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4, // Jarak antar potongan
                            centerSpaceRadius: 45, // Besarkan lubang tengah
                            startDegreeOffset: -90, // Putar mulai dari atas
                            sections: _buildPieSections(),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$_totalEvents', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: SeismicColors.navyDark)),
                              const Text('TOTAL', style: TextStyle(fontSize: 10, color: SeismicColors.textMuted, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Minor (2.0 - 3.9)', SeismicColors.navyDark, _distribution['Minor']!),
                        _buildLegendItem('Light (4.0 - 4.9)', SeismicColors.blueLight, _distribution['Light']!),
                        _buildLegendItem('Moderate (5.0 - 5.9)', SeismicColors.navyAccent, _distribution['Moderate']!),
                        _buildLegendItem('Major (6.0+)', SeismicColors.redAlert, _distribution['Major']!),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildMiniCard(String title, String val, String sub, {bool isPercentage = false, bool isAlert = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: SeismicColors.textMuted)),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isAlert ? SeismicColors.redAlert : SeismicColors.navyDark)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontSize: 11, color: isAlert ? SeismicColors.redAlert : SeismicColors.textMuted)),
            if (isPercentage) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(value: 0.99, backgroundColor: Color(0xFFE2E8F0), color: SeismicColors.blueLight, minHeight: 4),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    double pct = _totalEvents == 0 ? 0 : (count / _totalEvents) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: SeismicColors.navyDark, fontWeight: FontWeight.w500))),
          Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: SeismicColors.navyDark)),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(6, (i) {
      return _makeGroupData(i, _monthlyCounts[i], i % 2 == 0 ? SeismicColors.navyDark : SeismicColors.redAlert, 22);
    });
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color, double width) {
    return BarChartGroupData(
      x: x, 
      barRods: [BarChartRodData(toY: y, color: color, width: width, borderRadius: BorderRadius.circular(2))]
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    double radius = 18; // Ketebalan donat
    return [
      PieChartSectionData(color: SeismicColors.navyDark, value: _distribution['Minor']!.toDouble(), radius: radius, showTitle: false),
      PieChartSectionData(color: SeismicColors.blueLight, value: _distribution['Light']!.toDouble(), radius: radius, showTitle: false),
      PieChartSectionData(color: SeismicColors.navyAccent, value: _distribution['Moderate']!.toDouble(), radius: radius, showTitle: false),
      PieChartSectionData(color: SeismicColors.redAlert, value: _distribution['Major']!.toDouble(), radius: radius, showTitle: false),
    ];
  }
}