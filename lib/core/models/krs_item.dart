class KrsItem {
  final int idKrs;
  final String kode;
  final String mkl;
  final int sks;
  final int ambilKe;
  final int aktivasi;

  const KrsItem({
    required this.idKrs,
    required this.kode,
    required this.mkl,
    required this.sks,
    required this.ambilKe,
    required this.aktivasi,
  });

  Map<String, dynamic> toJson() => {
        'idKrs': idKrs,
        'kode': kode,
        'mkl': mkl,
        'sks': sks,
        'ambilKe': ambilKe,
        'aktivasi': aktivasi,
      };

  factory KrsItem.fromJson(Map<String, dynamic> json) => KrsItem(
        idKrs: (json['ID_KRS'] ?? json['idKrs'] as num?)?.toInt() ?? 0,
        kode: (json['KODE'] ?? json['kode'] as String? ?? '').trim(),
        mkl: (json['MKL'] ?? json['mkl'] as String? ?? '').trim(),
        sks: (json['SKS'] ?? json['sks'] as num?)?.toInt() ?? 0,
        ambilKe: (json['AMBILKE'] ?? json['ambilKe'] as num?)?.toInt() ?? 1,
        aktivasi: (json['AKTIVASI'] ?? json['aktivasi'] as num?)?.toInt() ?? 0,
      );
}
