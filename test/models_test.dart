import 'package:flutter_test/flutter_test.dart';
import 'package:amikom_student/core/models/student_profile.dart';
import 'package:amikom_student/core/models/jadwal_item.dart';
import 'package:amikom_student/core/models/krs_item.dart';
import 'package:amikom_student/core/models/khs_item.dart';
import 'package:amikom_student/core/theme/app_colors.dart';

void main() {
  group('Amikom Student Models Test', () {
    test('StudentProfile JSON roundtrip', () {
      const profile = StudentProfile(
        npm: '23SA21A088',
        nama: 'FATHAN GHUFRON AMANI',
        noHp: '089696291025',
        email: 'student@amikompurwokerto.ac.id',
        fakultas: 'Ilmu Komputer',
        prodi: 'SISTEM INFORMASI S1',
        angkatan: '2023',
        dpa: 'Argiyan Dwi Pritama,S.Kom., M.MSI.',
        fotoUrl: 'https://student.amikompurwokerto.ac.id/foto_siswa/23SA21A088.jpg',
        ipk: 3.51,
        totalSks: 126,
        sksSekarang: 20,
        status: 'Aktif',
      );

      final json = profile.toJson();
      final decoded = StudentProfile.fromJson(json);

      expect(decoded.npm, '23SA21A088');
      expect(decoded.nama, 'FATHAN GHUFRON AMANI');
      expect(decoded.ipk, 3.51);
      expect(decoded.totalSks, 126);
      expect(decoded.status, 'Aktif');
    });

    test('JadwalItem JSON roundtrip', () {
      const item = JadwalItem(
        no: 1,
        kodeMk: 'PSSIW034',
        namaMk: 'Arsitektur Enterprise',
        kelas: 'SI23C AE',
        dosen: 'Andi Dwi Riyanto',
        sks: 3,
        statusBu: 'B',
        tipe: 'Teori',
        hari: 'SENIN',
        ruang: 'GEDUNG 1 - R.2.3',
        jam: '12.30-14.10',
      );

      final json = item.toJson();
      final decoded = JadwalItem.fromJson(json);

      expect(decoded.kodeMk, 'PSSIW034');
      expect(decoded.hari, 'SENIN');
      expect(decoded.ruang, 'GEDUNG 1 - R.2.3');
      expect(decoded.jam, '12.30-14.10');
    });

    test('KrsItem JSON parsing from API', () {
      final raw = {
        'ID_KRS': 2136376,
        'SKS': 3,
        'KODE': 'PSSIW013  ',
        'MKL': 'Infrastruktur Teknologi Informasi',
        'AKTIVASI': 1,
        'AMBILKE': 1,
      };

      final item = KrsItem.fromJson(raw);
      expect(item.idKrs, 2136376);
      expect(item.kode, 'PSSIW013');
      expect(item.mkl, 'Infrastruktur Teknologi Informasi');
      expect(item.sks, 3);
      expect(item.aktivasi, 1);
    });

    test('KhsResult JSON parsing and IPS calculation', () {
      final raw = {
        'data': [
          {'KODE': 'PSSIP051', 'MKL': 'Audit Sistem Informasi', 'SKS': 3, 'AMBILKE': 'B', 'NILAI': 'A-', 'BOBOT': 11.25},
          {'KODE': 'PSSIW015', 'MKL': 'Pemrograman Web', 'SKS': 3, 'AMBILKE': 'B', 'NILAI': 'A', 'BOBOT': 12.0},
        ],
        'finish_evaluasi': true,
        'can_view_skripsi': true,
      };

      final items = (raw['data'] as List).map((e) => NilaiItem.fromJson(e as Map<String, dynamic>)).toList();
      expect(items.length, 2);
      expect(items[0].nilai, 'A-');
      expect(items[1].nilai, 'A');

      final totalSks = items.fold<int>(0, (sum, e) => sum + e.sks);
      final totalBobot = items.fold<double>(0, (sum, e) => sum + e.bobot);
      final ips = totalBobot / totalSks;

      expect(totalSks, 6);
      expect(double.parse(ips.toStringAsFixed(2)), 3.88);
    });

    test('AppColors brand anchor matches Amikom purple', () {
      expect(AppColors.amikomPurple.toARGB32(), 0xFF7706C7);
      expect(AppColors.amikomGold.toARGB32(), 0xFFF7A600);
      expect(AppColors.lightPrimary, AppColors.amikomPurple);
    });
  });
}
