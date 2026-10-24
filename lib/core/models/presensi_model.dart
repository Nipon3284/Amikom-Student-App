class UnvalidatedCourse {
  final String kode;
  final String makul;
  final int count;
  final List<String> idPresensiMhsList;
  final List<String> kelasgabList;

  const UnvalidatedCourse({
    required this.kode,
    required this.makul,
    required this.count,
    required this.idPresensiMhsList,
    required this.kelasgabList,
  });

  factory UnvalidatedCourse.fromJson(String kode, Map<String, dynamic> json) {
    final rawIds = json['id_presensi_mhs'] as List<dynamic>? ?? [];
    final rawKelas = json['kelasgab'] as List<dynamic>? ?? [];

    return UnvalidatedCourse(
      kode: kode.trim(),
      makul: (json['makul'] as String? ?? '').trim(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      idPresensiMhsList: rawIds.map((e) => e.toString()).toList(),
      kelasgabList: rawKelas.map((e) => e.toString()).toList(),
    );
  }
}

class PresensiSessionItem {
  final String tanggal;
  final String materi;
  final String status; // 'H' atau 'B'
  final int? editId;
  final String namaMk;
  final String kuliahTeori;
  final String kuliahPraktek;
  final String jenisPilih;

  const PresensiSessionItem({
    required this.tanggal,
    required this.materi,
    required this.status,
    this.editId,
    this.namaMk = '',
    this.kuliahTeori = '',
    this.kuliahPraktek = '',
    this.jenisPilih = 'teori',
  });

  bool get isPending => status.toUpperCase() == 'B';
  bool get isPresent => status.toUpperCase() == 'H';
}

class PresensiDetailData {
  final String tipe;
  final String namaDosen;
  final List<PresensiSessionItem> items;
  final int prosentaseHadir;
  final int prosentaseBelumValidasi;
  final int akumulasiNilai;

  const PresensiDetailData({
    required this.tipe,
    required this.namaDosen,
    required this.items,
    required this.prosentaseHadir,
    required this.prosentaseBelumValidasi,
    required this.akumulasiNilai,
  });

  factory PresensiDetailData.empty() => const PresensiDetailData(
        tipe: '',
        namaDosen: '',
        items: [],
        prosentaseHadir: 0,
        prosentaseBelumValidasi: 0,
        akumulasiNilai: 0,
      );
}

class PresensiModalDetail {
  final String nik;
  final String namaDosen;
  final String tanggal;
  final String jam;
  final String judulMateri;
  final String idPresensiMhs;
  final String idPresensiDosen;
  final String kuliahTpId;
  final String jenisPilih;

  const PresensiModalDetail({
    required this.nik,
    required this.namaDosen,
    required this.tanggal,
    required this.jam,
    required this.judulMateri,
    required this.idPresensiMhs,
    required this.idPresensiDosen,
    required this.kuliahTpId,
    required this.jenisPilih,
  });

  factory PresensiModalDetail.fromJson(Map<String, dynamic> json, {String jenisPilih = 'teori'}) {
    return PresensiModalDetail(
      nik: json['nik']?.toString() ?? '',
      namaDosen: json['nama']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      jam: json['jam']?.toString() ?? '',
      judulMateri: json['judul_materi']?.toString() ?? '',
      idPresensiMhs: json['id_presensi_mhs']?.toString() ?? '',
      idPresensiDosen: json['id_presensi_dosen']?.toString() ?? '',
      kuliahTpId: json['kuliah_tp_id']?.toString() ?? '',
      jenisPilih: jenisPilih,
    );
  }
}
