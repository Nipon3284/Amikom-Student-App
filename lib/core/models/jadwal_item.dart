class JadwalItem {
  final int no;
  final String kodeMk;
  final String namaMk;
  final String kelas;
  final String dosen;
  final int sks;
  final String statusBu; // B atau U (Baru/Ulang)
  final String tipe;     // Teori atau Praktek
  final String hari;     // SENIN, SELASA, RABU, KAMIS, JUMAT, SABTU
  final String ruang;    // GEDUNG 1 - R.2.3
  final String jam;      // 12.30-14.10

  const JadwalItem({
    required this.no,
    required this.kodeMk,
    required this.namaMk,
    required this.kelas,
    required this.dosen,
    required this.sks,
    required this.statusBu,
    required this.tipe,
    required this.hari,
    required this.ruang,
    required this.jam,
  });

  Map<String, dynamic> toJson() => {
        'no': no,
        'kodeMk': kodeMk,
        'namaMk': namaMk,
        'kelas': kelas,
        'dosen': dosen,
        'sks': sks,
        'statusBu': statusBu,
        'tipe': tipe,
        'hari': hari,
        'ruang': ruang,
        'jam': jam,
      };

  factory JadwalItem.fromJson(Map<String, dynamic> json) => JadwalItem(
        no: (json['no'] as num?)?.toInt() ?? 0,
        kodeMk: json['kodeMk'] as String? ?? '',
        namaMk: json['namaMk'] as String? ?? '',
        kelas: json['kelas'] as String? ?? '',
        dosen: json['dosen'] as String? ?? '',
        sks: (json['sks'] as num?)?.toInt() ?? 0,
        statusBu: json['statusBu'] as String? ?? 'B',
        tipe: json['tipe'] as String? ?? 'Teori',
        hari: json['hari'] as String? ?? '',
        ruang: json['ruang'] as String? ?? '',
        jam: json['jam'] as String? ?? '-',
      );
}
