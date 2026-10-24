class NilaiItem {
  final String kode;
  final String mkl;
  final int sks;
  final String ambilKe;
  final String nilai;
  final double bobot;

  const NilaiItem({
    required this.kode,
    required this.mkl,
    required this.sks,
    required this.ambilKe,
    required this.nilai,
    required this.bobot,
  });

  Map<String, dynamic> toJson() => {
        'kode': kode,
        'mkl': mkl,
        'sks': sks,
        'ambilKe': ambilKe,
        'nilai': nilai,
        'bobot': bobot,
      };

  factory NilaiItem.fromJson(Map<String, dynamic> json) => NilaiItem(
        kode: (json['KODE'] ?? json['kode'] as String? ?? '').trim(),
        mkl: (json['MKL'] ?? json['mkl'] as String? ?? '').trim(),
        sks: (json['SKS'] ?? json['sks'] as num?)?.toInt() ?? 0,
        ambilKe: (json['AMBILKE'] ?? json['ambilKe'] ?? 'B').toString(),
        nilai: (json['NILAI'] ?? json['nilai'] as String? ?? '-').trim(),
        bobot: (json['BOBOT'] ?? json['bobot'] as num?)?.toDouble() ?? 0.0,
      );
}

class KhsResult {
  final String tahunAkademik;
  final int semester;
  final bool finishEvaluasi;
  final bool canViewSkripsi;
  final List<NilaiItem> items;
  final double ips;
  final int totalSks;

  const KhsResult({
    required this.tahunAkademik,
    required this.semester,
    required this.finishEvaluasi,
    required this.canViewSkripsi,
    required this.items,
    required this.ips,
    required this.totalSks,
  });

  Map<String, dynamic> toJson() => {
        'tahunAkademik': tahunAkademik,
        'semester': semester,
        'finishEvaluasi': finishEvaluasi,
        'canViewSkripsi': canViewSkripsi,
        'items': items.map((e) => e.toJson()).toList(),
        'ips': ips,
        'totalSks': totalSks,
      };

  factory KhsResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['items'] as List<dynamic>? ?? [];
    final items = rawList.map((e) => NilaiItem.fromJson(e as Map<String, dynamic>)).toList();
    return KhsResult(
      tahunAkademik: json['tahunAkademik'] as String? ?? '',
      semester: (json['semester'] as num?)?.toInt() ?? 1,
      finishEvaluasi: json['finishEvaluasi'] as bool? ?? true,
      canViewSkripsi: json['canViewSkripsi'] as bool? ?? true,
      items: items,
      ips: (json['ips'] as num?)?.toDouble() ?? 0.0,
      totalSks: (json['totalSks'] as num?)?.toInt() ?? 0,
    );
  }
}
