import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart' as html_parser;
import '../models/student_profile.dart';
import '../models/jadwal_item.dart';
import '../models/krs_item.dart';
import '../models/khs_item.dart';
import '../models/presensi_model.dart';

class PortalClient {
  static const String baseUrl = 'https://student.amikompurwokerto.ac.id';
  late final Dio _dio;
  late final CookieJar _cookieJar;

  PortalClient({CookieJar? cookieJar}) {
    _cookieJar = cookieJar ?? CookieJar();
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
        },
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  /// Authenticate against Amikom Purwokerto Student Portal
  Future<bool> login(String npm, String password) async {
    try {
      final response = await _dio.post(
        '/auth/toenter',
        data: {
          'pengguna': npm.trim(),
          'passw': password.trim(),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final body = response.data.toString().trim();
      return body == '111';
    } catch (e) {
      return false;
    }
  }

  /// Scrape Dashboard & Profile details from /main
  Future<StudentProfile> fetchProfile(String npm) async {
    final response = await _dio.get('/main');
    final document = html_parser.parse(response.data);

    String nama = '';
    String noHp = '';
    String email = '';
    String fakultas = '';
    String prodi = '';
    String angkatan = '';
    String dpa = '';
    String status = 'Aktif';
    double ipk = 0.0;
    int totalSks = 0;
    int sksSekarang = 0;

    // Parse form groups inside profile panel
    final formGroups = document.querySelectorAll('.form-horizontal .form-group');
    for (final fg in formGroups) {
      final label = fg.querySelector('label.col-sm-4')?.text.trim() ?? '';
      final valEl = fg.querySelector('label.col-sm-8');
      String val = valEl?.text.trim() ?? '';
      if (val.startsWith(':')) {
        val = val.substring(1).trim();
      }

      if (label.contains('Nama')) {
        nama = val;
      } else if (label.contains('No Hp')) {
        noHp = val;
      } else if (label.contains('Email')) {
        email = val;
      } else if (label.contains('Fakultas')) {
        fakultas = val;
      } else if (label.contains('Prodi')) {
        prodi = val;
      } else if (label.contains('Angkatan')) {
        angkatan = val;
      } else if (label.contains('Pembimbing')) {
        dpa = val;
      }
    }

    // Parse Tile Stats (Total SKS, IPK, SKS Sekarang)
    final tiles = document.querySelectorAll('.tile-box');
    for (final tile in tiles) {
      final header = tile.querySelector('.tile-header')?.text.trim() ?? '';
      final content = tile.querySelector('.tile-content-wrapper')?.text.trim() ?? '';

      if (header.contains('Total SKS')) {
        totalSks = int.tryParse(content.replaceAll(RegExp(r'[^0-9]'), '')) ?? totalSks;
      } else if (header.contains('IPK')) {
        ipk = double.tryParse(content.trim()) ?? ipk;
      } else if (header.contains('SKS sekarang')) {
        sksSekarang = int.tryParse(content.replaceAll(RegExp(r'[^0-9]'), '')) ?? sksSekarang;
      }
    }

    // Parse Status
    final ribbon = document.querySelector('.ribbon .bg-primary');
    if (ribbon != null) {
      status = ribbon.text.trim();
    }

    final fotoUrl = '$baseUrl/foto_siswa/${npm.trim().toUpperCase()}.jpg';

    return StudentProfile(
      npm: npm.trim().toUpperCase(),
      nama: nama.isNotEmpty ? nama : 'Mahasiswa Amikom',
      noHp: noHp,
      email: email,
      fakultas: fakultas.isNotEmpty ? fakultas : 'Ilmu Komputer',
      prodi: prodi.isNotEmpty ? prodi : 'Sistem Informasi S1',
      angkatan: angkatan.isNotEmpty ? angkatan : '2023',
      dpa: dpa,
      fotoUrl: fotoUrl,
      ipk: ipk,
      totalSks: totalSks,
      sksSekarang: sksSekarang,
      status: status,
    );
  }

  /// Fetch Enrolled Course Plan (KRS)
  Future<List<KrsItem>> fetchKRS() async {
    final response = await _dio.get('/akademik/makul_pengajuan_diambil');
    final dynamic data = response.data is String ? jsonDecode(response.data) : response.data;
    if (data is List) {
      return data.map((e) => KrsItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Scrape Jadwal Kuliah table from /akademik/get_jadwal?mod=kuliah
  Future<List<JadwalItem>> fetchJadwal() async {
    final response = await _dio.get('/akademik/get_jadwal?mod=kuliah');
    final document = html_parser.parse(response.data);
    final rows = document.querySelectorAll('table.krsTable tr');

    final List<JadwalItem> result = [];
    int currentNo = 0;
    String currentKode = '';
    String currentNamaMk = '';
    String currentKelas = '';
    String currentDosen = '';
    int currentSks = 0;
    String currentBu = 'B';

    for (final row in rows) {
      final ths = row.querySelectorAll('th');
      if (ths.isNotEmpty) continue; // Skip header

      final tds = row.querySelectorAll('td');
      if (tds.isEmpty) continue;

      // Row with main course data (has rowspan)
      if (tds.length >= 10) {
        currentNo = int.tryParse(tds[0].text.trim()) ?? (result.length + 1);
        currentKode = tds[1].text.trim();
        final rawMk = tds[2].innerHtml;
        final mkParts = rawMk.split(RegExp(r'<br\s*/?>', caseSensitive: false));
        currentNamaMk = html_parser.parse(mkParts[0]).body?.text.trim() ?? tds[2].text.trim();
        currentKelas = mkParts.length > 1 ? html_parser.parse(mkParts[1]).body?.text.trim() ?? '' : '';
        currentDosen = tds[3].text.trim();
        currentSks = int.tryParse(tds[4].text.trim()) ?? 0;
        currentBu = tds[5].text.trim();

        final tipe = tds[6].text.trim();
        final hari = tds[7].text.trim();
        final ruang = tds[8].text.trim();
        final jam = tds[9].text.trim();

        result.add(
          JadwalItem(
            no: currentNo,
            kodeMk: currentKode,
            namaMk: currentNamaMk,
            kelas: currentKelas,
            dosen: currentDosen,
            sks: currentSks,
            statusBu: currentBu,
            tipe: tipe,
            hari: hari,
            ruang: ruang,
            jam: jam,
          ),
        );
      } else if (tds.length >= 4) {
        // Secondary row (e.g. Praktek row) inheriting from current course
        final tipe = tds[0].text.trim();
        final hari = tds[1].text.trim();
        final ruang = tds[2].text.trim();
        final jam = tds[3].text.trim();

        result.add(
          JadwalItem(
            no: currentNo,
            kodeMk: currentKode,
            namaMk: currentNamaMk,
            kelas: currentKelas,
            dosen: currentDosen,
            sks: currentSks,
            statusBu: currentBu,
            tipe: tipe,
            hari: hari,
            ruang: ruang,
            jam: jam,
          ),
        );
      }
    }

    return result;
  }

  /// Fetch KHS / Nilai for a given academic year and semester
  Future<KhsResult> fetchKHS({required String thn, required int smt}) async {
    final response = await _dio.post(
      '/akademik/get_khs',
      data: {
        'thn': thn,
        'smt': smt.toString(),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final dynamic body = response.data is String ? jsonDecode(response.data) : response.data;
    if (body is Map<String, dynamic>) {
      final finishEvaluasi = body['finish_evaluasi'] as bool? ?? true;
      final canViewSkripsi = body['can_view_skripsi'] as bool? ?? true;
      final rawList = body['data'] as List<dynamic>? ?? [];

      final items = rawList.map((e) => NilaiItem.fromJson(e as Map<String, dynamic>)).toList();

      double sumBobot = 0.0;
      int sumSks = 0;
      for (final item in items) {
        sumBobot += item.bobot;
        sumSks += item.sks;
      }
      final ips = sumSks > 0 ? (sumBobot / sumSks) : 0.0;

      return KhsResult(
        tahunAkademik: thn,
        semester: smt,
        finishEvaluasi: finishEvaluasi,
        canViewSkripsi: canViewSkripsi,
        items: items,
        ips: double.parse(ips.toStringAsFixed(2)),
        totalSks: sumSks,
      );
    }

    return KhsResult(
      tahunAkademik: thn,
      semester: smt,
      finishEvaluasi: true,
      canViewSkripsi: true,
      items: [],
      ips: 0.0,
      totalSks: 0,
    );
  }

  /// Check if there are any unvalidated courses
  Future<List<UnvalidatedCourse>> checkUnvalidatedPresensi() async {
    try {
      final response = await _dio.post(
        '/pembelajaran/list_makul_belum_validasi',
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final dynamic body = response.data is String ? jsonDecode(response.data) : response.data;
      if (body is Map<String, dynamic>) {
        final List<UnvalidatedCourse> list = [];
        body.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            list.add(UnvalidatedCourse.fromJson(key, val));
          }
        });
        return list;
      }
    } catch (_) {}
    return [];
  }

  /// Get semesters list for a given academic year
  Future<List<Map<String, dynamic>>> fetchPresensiSemesters(String thnAkademik) async {
    try {
      final response = await _dio.post(
        '/pembelajaran/getSem',
        data: {'thn_akademik': thnAkademik},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final document = html_parser.parse(response.data);
      final options = document.querySelectorAll('option');
      final list = <Map<String, dynamic>>[];
      for (final opt in options) {
        final val = int.tryParse(opt.attributes['value'] ?? '');
        final label = opt.text.trim();
        if (val != null) {
          list.add({'value': val, 'label': label.isNotEmpty ? label : (val == 1 ? 'Ganjil' : 'Genap')});
        }
      }
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return [
      {'value': 1, 'label': 'Ganjil'},
      {'value': 2, 'label': 'Genap'},
    ];
  }

  /// Get courses list for attendance
  Future<List<Map<String, String>>> fetchPresensiCourses(String thnAkademik, int semester) async {
    try {
      final response = await _dio.post(
        '/pembelajaran/getmakul',
        data: {
          'thn_akademik': thnAkademik,
          'semester': semester.toString(),
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final document = html_parser.parse(response.data);
      final options = document.querySelectorAll('option');
      final list = <Map<String, String>>[];
      for (final opt in options) {
        final val = opt.attributes['value']?.trim() ?? '';
        final label = opt.text.trim();
        if (val.isNotEmpty && !val.contains('--Pilih--')) {
          list.add({'value': val, 'label': label});
        }
      }
      return list;
    } catch (_) {}
    return [];
  }

  /// Fetch full attendance table for a course
  Future<PresensiDetailData> fetchPresensiDetails({
    required String thnAkademik,
    required int semester,
    required String makulKey,
  }) async {
    try {
      final response = await _dio.post(
        '/pembelajaran/getabsenmhs',
        data: {
          'thn_akademik': thnAkademik,
          'semester': semester.toString(),
          'makul': makulKey,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final document = html_parser.parse(response.data);
      final tipe = document.querySelector('h3')?.text.trim() ?? 'Perkuliahan Teori';
      String namaDosen = document.querySelector('h4')?.text.trim() ?? '';
      if (namaDosen.startsWith('Nama Dosen :')) {
        namaDosen = namaDosen.replaceFirst('Nama Dosen :', '').trim();
      }

      final items = <PresensiSessionItem>[];
      int prosentaseHadir = 0;
      int prosentaseBelum = 0;
      int akumulasiNilai = 0;

      final tables = document.querySelectorAll('table');
      if (tables.isNotEmpty) {
        final mainTable = tables[0];
        final rows = mainTable.querySelectorAll('tr');

        for (final row in rows) {
          final tds = row.querySelectorAll('td');
          if (tds.length == 3 && !row.text.contains('Keterangan')) {
            final tanggal = tds[0].text.trim();
            final materi = tds[1].text.trim();
            final statusTd = tds[2];
            final link = statusTd.querySelector('a');

            String status = statusTd.text.trim();
            int? editId;
            String mkl = '';
            String teori = '';
            String praktek = '';
            String jenisPilih = 'teori';

            if (link != null) {
              status = 'B';
              final onclick = link.attributes['onclick'] ?? '';
              final match = RegExp(
                r"edit_presensikehadiran\((\d+),\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)'\)",
              ).firstMatch(onclick);
              if (match != null) {
                editId = int.tryParse(match.group(1)!);
                mkl = match.group(2)!;
                teori = match.group(3)!;
                praktek = match.group(4)!;
                jenisPilih = match.group(5)!;
              }
            }

            items.add(
              PresensiSessionItem(
                tanggal: tanggal,
                materi: materi,
                status: status,
                editId: editId,
                namaMk: mkl,
                kuliahTeori: teori,
                kuliahPraktek: praktek,
                jenisPilih: jenisPilih,
              ),
            );
          } else if (tds.length == 2) {
            final label = tds[0].text.trim();
            final val = int.tryParse(tds[1].text.trim()) ?? 0;
            if (label.contains('Prosentase Hadir')) {
              prosentaseHadir = val;
            } else if (label.contains('Prosentase Belum Validasi')) {
              prosentaseBelum = val;
            }
          }
        }
      }

      if (tables.length > 1) {
        final summaryTable = tables[1];
        final rows = summaryTable.querySelectorAll('tr');
        for (final row in rows) {
          final tds = row.querySelectorAll('td');
          if (tds.length == 2 && tds[0].text.contains('Akumulasi Nilai Presensi')) {
            akumulasiNilai = int.tryParse(tds[1].text.trim()) ?? akumulasiNilai;
          }
        }
      }

      return PresensiDetailData(
        tipe: tipe,
        namaDosen: namaDosen,
        items: items,
        prosentaseHadir: prosentaseHadir,
        prosentaseBelumValidasi: prosentaseBelum,
        akumulasiNilai: akumulasiNilai,
      );
    } catch (e) {
      return PresensiDetailData.empty();
    }
  }

  /// Fetch modal detail when student taps [ B ] button
  Future<PresensiModalDetail?> fetchPresensiModalData(
    int idPresensiDosen, {
    String jenisPilih = 'teori',
  }) async {
    try {
      final response = await _dio.get('/pembelajaran/ajax_editpresensi/$idPresensiDosen');
      final dynamic body = response.data is String ? jsonDecode(response.data) : response.data;
      if (body is Map<String, dynamic>) {
        return PresensiModalDetail.fromJson(body, jenisPilih: jenisPilih);
      }
    } catch (_) {}
    return null;
  }

  /// Submit Presensi Validation (converts 'B' to 'H' in real-time)
  Future<bool> submitPresensiValidation({
    required String jenisPilih,
    required String idPresensiMhs,
    required String idPresensiDosen,
    required String kuliahTeori,
    required String kuliahPraktek,
    String kesesuaianPerkuliahan = '1',
    String kesesuaianMateri = '1',
    String penilaianMhs = '4',
    String kritikSaran = '',
  }) async {
    try {
      final response = await _dio.post(
        '/pembelajaran/update_presensimhs',
        data: {
          'jenispilih': jenisPilih,
          'idpresensimhstexs': idPresensiMhs,
          'idpresensidosen': idPresensiDosen,
          'kuliahteori': kuliahTeori,
          'kuliahpraktek': kuliahPraktek,
          'kesesuaian_perkuliahan': kesesuaianPerkuliahan,
          'kesesuaian_materi': kesesuaianMateri,
          'penilaianmhs': penilaianMhs,
          'kritiksaran': kritikSaran,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final dynamic body = response.data is String ? jsonDecode(response.data) : response.data;
      if (body is Map<String, dynamic>) {
        return body['status'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.get('/main/logout');
    } catch (_) {}
    await _cookieJar.deleteAll();
  }
}
