class GempaModel {
  final String source; // BMKG, USGS, atau EMSC
  final String magnitude;
  final String wilayah;
  final String waktu;
  final String kedalaman;
  final String koordinat;

  GempaModel({
    required this.source,
    required this.magnitude,
    required this.wilayah,
    required this.waktu,
    required this.kedalaman,
    required this.koordinat,
  });
}