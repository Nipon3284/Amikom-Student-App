import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:amikom_student/core/models/presensi_model.dart';

void main() {
  test('Parse getabsenmhs HTML table and verify all 5 status and percentages', () {
    const sampleHtml = '''
<h3>Perkuliahan Teori </h3> <h4>Nama Dosen : Imam Tahyudin</h4><p>Mahasiswa diwajibkan melakukan validasi pada tombol <a class="btn btn-xs btn-primary" href="#" title="Edit">B </a>
    setelah melaksanakan perkuliahan teori ataupun perkuliahan praktek sehingga nilai pada prosentase kehadiran akan
    muncul ditabel keterangan dan di nilai akhir MK</p>
<table border='1' cellpadding='0' cellspacing='0' class='table table-hover table-bordered' ><thead><tr style='background-color:#c9d3ff;'><th style='text-align:center;'>Hari dan Tanggal Perkuliahan</th><th style='text-align:center;'>Materi Perkuliahan</th><th style='text-align:center;'>Status</th></tr></thead><tbody>
<tr><td>Kamis, 08 Oktober 2026</td><td>Pertemuan 1</td><td style='text-align:center;'>H</td></tr>
<tr><td>Kamis, 08 Oktober 2026</td><td>Pertemuan 1</td><td style='text-align:center;'>H</td></tr>
<tr><td>Kamis, 15 Oktober 2026</td><td>Pertemuan Ke 2</td><td style='text-align:center;'>H</td></tr>
<tr><td>Kamis, 15 Oktober 2026</td><td>Pertemuan Ke 2</td><td style='text-align:center;'>H</td></tr>
<tr><td>Kamis, 22 Oktober 2026</td><td>Pertemuan Ke 3</td><td style='text-align:center;'>I</td></tr>
<tr><td>Kamis, 22 Oktober 2026</td><td>Pertemuan Ke 3</td><td style='text-align:center;'>I</td></tr>
<tr><td>Kamis, 29 Oktober 2026</td><td>Pertemuan Ke 4</td><td style='text-align:center;'>H</td></tr>
<tr><td>Kamis, 29 Oktober 2026</td><td>Pertemuan Ke 4</td><td style='text-align:center;'>H</td></tr>
<tr><td>Kamis, 05 November 2026</td><td>Pertemuan Ke 5</td><td style='text-align:center;'>S</td></tr>
<tr><td>Kamis, 05 November 2026</td><td>Pertemuan Ke 5</td><td style='text-align:center;'>A</td></tr>
<tr><td>Jumat, 23 Oktober 2026</td><td>Teknologi Storage (penyimpanan)</td><td style="text-align: center;">
    <a class="btn btn-sm btn-primary" href="javascript:void(0)" title="Edit"
    onclick="edit_presensikehadiran(215349,'Infrastruktur Teknologi Informasi','19700','','teori')">
    B </a>
</td></tr>
<tr style="background-color:#c9d3ff; ">
    <td colspan="3"><b>Keterangan</b></td>
</tr>
<tr ><td colspan='2'>Prosentase Hadir (H)</td><td style='text-align:center;'>80</td></tr>
<tr><td colspan='2'>Prosentase Izin (I)</td><td style='text-align:center;'>20</td></tr>
<tr><td colspan='2'>Prosentase Tanpa Keterangan (A)</td><td style='text-align:center;'>0</td></tr>
<tr><td colspan='2'>Prosentase Sakit (S)</td><td style='text-align:center;'>0</td></tr>
<tr><td colspan='2'>Prosentase Belum Validasi (B)</td><td style='text-align:center;'>0</td></tr>
</tbody></table>
''';

    final document = html_parser.parse(sampleHtml);
    final rows = document.querySelectorAll('table tr');

    final items = <PresensiSessionItem>[];
    int prosentaseHadir = 0;
    int prosentaseIzin = 0;
    int prosentaseTanpaKeterangan = 0;
    int prosentaseSakit = 0;
    int prosentaseBelum = 0;

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
        String jenisPilih = '';

        if (link != null) {
          status = 'B';
          final onclick = link.attributes['onclick'] ?? '';
          final match = RegExp(r"edit_presensikehadiran\((\d+),\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)'\)")
              .firstMatch(onclick);
          if (match != null) {
            editId = int.tryParse(match.group(1)!);
            mkl = match.group(2)!;
            teori = match.group(3)!;
            praktek = match.group(4)!;
            jenisPilih = match.group(5)!;
          }
        } else {
          final upper = status.toUpperCase();
          if (upper.contains('H')) {
            status = 'H';
          } else if (upper.contains('I')) {
            status = 'I';
          } else if (upper.contains('S')) {
            status = 'S';
          } else if (upper.contains('A')) {
            status = 'A';
          } else if (upper.contains('B')) {
            status = 'B';
          }
        }

        items.add(PresensiSessionItem(
          tanggal: tanggal,
          materi: materi,
          status: status,
          editId: editId,
          namaMk: mkl,
          kuliahTeori: teori,
          kuliahPraktek: praktek,
          jenisPilih: jenisPilih,
        ));
      } else if (tds.length == 2) {
        final label = tds[0].text.trim().toLowerCase();
        final val = int.tryParse(tds[1].text.trim()) ?? 0;
        if (label.contains('prosentase hadir')) {
          prosentaseHadir = val;
        } else if (label.contains('prosentase izin') || label.contains('ijin')) {
          prosentaseIzin = val;
        } else if (label.contains('tanpa keterangan')) {
          prosentaseTanpaKeterangan = val;
        } else if (label.contains('prosentase sakit')) {
          prosentaseSakit = val;
        } else if (label.contains('belum validasi')) {
          prosentaseBelum = val;
        }
      }
    }

    expect(items.length, 11);
    // Hadir
    expect(items[0].status, 'H');
    expect(items[0].isPresent, isTrue);
    expect(items[0].statusDisplay, 'Hadir (H)');

    // Izin (I)
    expect(items[4].status, 'I');
    expect(items[4].isPermitted, isTrue);
    expect(items[4].isPresent, isFalse);
    expect(items[4].statusDisplay, 'Izin (I)');

    // Sakit (S)
    expect(items[8].status, 'S');
    expect(items[8].isSick, isTrue);
    expect(items[8].statusDisplay, 'Sakit (S)');

    // Alpa (A)
    expect(items[9].status, 'A');
    expect(items[9].isAlpha, isTrue);
    expect(items[9].statusDisplay, 'Alpa (A)');

    // Belum Validasi (B)
    expect(items[10].status, 'B');
    expect(items[10].isPending, isTrue);
    expect(items[10].editId, 215349);
    expect(items[10].statusDisplay, 'Belum Validasi (B)');

    // Verify all 5 percentages
    expect(prosentaseHadir, 80);
    expect(prosentaseIzin, 20);
    expect(prosentaseTanpaKeterangan, 0);
    expect(prosentaseSakit, 0);
    expect(prosentaseBelum, 0);
  });
}
