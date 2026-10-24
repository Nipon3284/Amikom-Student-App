class StudentProfile {
  final String npm;
  final String nama;
  final String noHp;
  final String email;
  final String fakultas;
  final String prodi;
  final String angkatan;
  final String dpa;
  final String fotoUrl;
  final double ipk;
  final int totalSks;
  final int sksSekarang;
  final String status;

  const StudentProfile({
    required this.npm,
    required this.nama,
    required this.noHp,
    required this.email,
    required this.fakultas,
    required this.prodi,
    required this.angkatan,
    required this.dpa,
    required this.fotoUrl,
    required this.ipk,
    required this.totalSks,
    required this.sksSekarang,
    required this.status,
  });

  factory StudentProfile.empty() {
    return const StudentProfile(
      npm: '',
      nama: '',
      noHp: '',
      email: '',
      fakultas: '',
      prodi: '',
      angkatan: '',
      dpa: '',
      fotoUrl: '',
      ipk: 0.0,
      totalSks: 0,
      sksSekarang: 0,
      status: 'Tidak Aktif',
    );
  }

  Map<String, dynamic> toJson() => {
        'npm': npm,
        'nama': nama,
        'noHp': noHp,
        'email': email,
        'fakultas': fakultas,
        'prodi': prodi,
        'angkatan': angkatan,
        'dpa': dpa,
        'fotoUrl': fotoUrl,
        'ipk': ipk,
        'totalSks': totalSks,
        'sksSekarang': sksSekarang,
        'status': status,
      };

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        npm: json['npm'] as String? ?? '',
        nama: json['nama'] as String? ?? '',
        noHp: json['noHp'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fakultas: json['fakultas'] as String? ?? '',
        prodi: json['prodi'] as String? ?? '',
        angkatan: json['angkatan'] as String? ?? '',
        dpa: json['dpa'] as String? ?? '',
        fotoUrl: json['fotoUrl'] as String? ?? '',
        ipk: (json['ipk'] as num?)?.toDouble() ?? 0.0,
        totalSks: (json['totalSks'] as num?)?.toInt() ?? 0,
        sksSekarang: (json['sksSekarang'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'Aktif',
      );
}
