import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;

void main() {
  test('Parse getabsenmhs HTML table', () {
    const sampleHtml = '''
<h3>Perkuliahan Teori </h3> <h4>Nama Dosen : Jeffri Prayitno Bangkit Saputra</h4><p>Mahasiswa diwajibkan melakukan validasi pada tombol <a class="btn btn-xs btn-primary" href="#" title="Edit">B </a>
    setelah melaksanakan perkuliahan teori ataupun perkuliahan praktek sehingga nilai pada prosentase kehadiran akan
    muncul ditabel keterangan dan di nilai akhir MK</p>
<table border='1' cellpadding='0' cellspacing='0' class='table table-hover table-bordered' ><thead><tr style='background-color:#c9d3ff;'><th style='text-align:center;'>Hari dan Tanggal Perkuliahan</th><th style='text-align:center;'>Materi Perkuliahan</th><th style='text-align:center;'>Status</th></tr></thead><tbody><tr><td>Jumat, 16 Oktober 2026</td><td>Pengantar Infrastruktur Teknologi Informasi </td><td style='text-align:center;'>H</td></tr><tr><td>Jumat, 16 Oktober 2026</td><td>Pengantar Infrastruktur Teknologi Informasi </td><td style='text-align:center;'>H</td></tr><tr><td>Jumat, 23 Oktober 2026</td><td>Teknologi Storage (penyimpanan)</td><td style="text-align: center;">
    <!-- disable validasi presensi -->
        <a class="btn btn-sm btn-primary" href="javascript:void(0)" title="Edit"
        onclick="edit_presensikehadiran(215349,'Infrastruktur Teknologi Informasi','19700','','teori')">
        B </a>
    </td>
</tr><tr><td>Jumat, 23 Oktober 2026</td><td>Teknologi Storage (penyimpanan)</td><td style="text-align: center;">
    <!-- disable validasi presensi -->
        <a class="btn btn-sm btn-primary" href="javascript:void(0)" title="Edit"
        onclick="edit_presensikehadiran(215350,'Infrastruktur Teknologi Informasi','19700','','teori')">
        B </a>
    </td>
</tr><tr style="background-color:#c9d3ff; ">
    <td colspan="3"><b>Keterangan</b></td>
</tr>
<tr ><td colspan='2'>Prosentase Hadir (H)</td><td style='text-align:center;'>50</td></tr>
  <tr><td colspan='2'>Prosentase Izin (I)</td><td style='text-align:center;'>0</td></tr>
  <tr><td colspan='2'>Prosentase Tanpa Keterangan (A)</td><td style='text-align:center;'>0</td></tr>
  <tr><td colspan='2'>Prosentase Sakit (S)</td><td style='text-align:center;'>0</td></tr>
  <tr><td colspan='2'>Prosentase Belum Validasi (B)</td><td style='text-align:center;'>50</td></tr>
  </tbody></table>
''';

    final document = html_parser.parse(sampleHtml);
    final rows = document.querySelectorAll('table tr');

    final items = <Map<String, dynamic>>[];
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
        }

        items.add({
          'tanggal': tanggal,
          'materi': materi,
          'status': status,
          'editId': editId,
          'mkl': mkl,
          'teori': teori,
          'praktek': praktek,
          'jenisPilih': jenisPilih,
        });
      }
    }

    expect(items.length, 4);
    expect(items[0]['status'], 'H');
    expect(items[2]['status'], 'B');
    expect(items[2]['editId'], 215349);
    expect(items[2]['mkl'], 'Infrastruktur Teknologi Informasi');
    expect(items[2]['teori'], '19700');
    expect(items[2]['jenisPilih'], 'teori');
  });
}
