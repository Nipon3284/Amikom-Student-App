import '../../../core/network/network_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/jadwal_item.dart';
import '../../../core/models/presensi_model.dart';
import '../../../core/providers/portal_provider.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/status_badge.dart';
import '../../presensi/presensi_screen.dart';
import '../../presensi/widgets/presensi_validation_modal.dart';

class JadwalDetailPresensiSheet extends ConsumerStatefulWidget {
  final JadwalItem item;

  const JadwalDetailPresensiSheet({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<JadwalDetailPresensiSheet> createState() =>
      _JadwalDetailPresensiSheetState();
}

class _JadwalDetailPresensiSheetState
    extends ConsumerState<JadwalDetailPresensiSheet> {
  bool _isLoading = true;
  PresensiDetailData? _presensiData;
  String? _resolvedMakulKey;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourseAttendance();
  }

  Future<void> _loadCourseAttendance() async {
    final isOnline = ref.read(networkStatusProvider).isOnline;
    if (!isOnline) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Perangkat offline: Tidak dapat memuat rekap presensi terbaru.';
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = ref.read(portalClientProvider);

    try {
      // Step 1: Query course list from current semester
      final courses = await client.fetchPresensiCourses('2026/2027', 1);

      // Match by course code or course name
      final match = courses.firstWhere(
        (c) {
          final val = c['value'] ?? '';
          final label = c['label']?.toLowerCase() ?? '';
          final targetCode = widget.item.kodeMk.toLowerCase();
          final targetName = widget.item.namaMk.toLowerCase();
          return val.toLowerCase().contains(targetCode) ||
              label.contains(targetName) ||
              targetName.contains(label);
        },
        orElse: () => {},
      );

      if (match.isNotEmpty && match['value'] != null) {
        _resolvedMakulKey = match['value'];
        final details = await client.fetchPresensiDetails(
          thnAkademik: '2026/2027',
          semester: 1,
          makulKey: _resolvedMakulKey!,
        );

        if (mounted) {
          setState(() {
            _presensiData = details;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Rekap presensi belum tersedia untuk mata kuliah ini.';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat rekapitulasi presensi.';
        });
      }
    }
  }

  void _copyClassInfo() {
    HapticFeedback.lightImpact();
    final text = '${widget.item.namaMk} (${widget.item.kodeMk})\n'
        'Hari: ${widget.item.hari}, Jam: ${widget.item.jam}\n'
        'Ruang: ${widget.item.ruang}\n'
        'Dosen: ${widget.item.dosen}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detail perkuliahan berhasil disalin ke clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openValidationModal(PresensiSessionItem session) {
    if (!ensureOnline(context, ref, message: 'Tidak dapat membuka formulir validasi presensi saat offline.')) {
      return;
    }
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PresensiValidationModal(
        sessionItem: session,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presensi berhasil divalidasi menjadi Hadir (H)!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Real-time refresh of both attendance table and global pending list
          ref.read(unvalidatedPresensiProvider.notifier).check();
          if (_resolvedMakulKey != null) {
            _loadCourseAttendance();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorderStrong : AppColors.neutral300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Modal Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.lightPrimaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.calendar,
                        size: 18,
                        color: isDark
                            ? AppColors.amikomPurpleLight
                            : AppColors.amikomPurple,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Detail Jadwal & Presensi',
                      style: AppTextStyles.titleMedium(isDark).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Course Header Card with Amikom Gradient Border
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSubtle
                        : AppColors.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              StatusBadge(
                                label: item.hari,
                                variant: BadgeVariant.primary,
                              ),
                              const SizedBox(width: 6),
                              StatusBadge(
                                label: item.jam,
                                variant: BadgeVariant.neutral,
                                icon: LucideIcons.clock,
                              ),
                            ],
                          ),
                          StatusBadge(
                            label: '${item.sks} SKS • ${item.tipe}',
                            variant: BadgeVariant.gold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.namaMk,
                        style: AppTextStyles.titleMedium(isDark).copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.kodeMk} ${item.kelas.isNotEmpty ? "• Kelas ${item.kelas}" : ""}',
                        style: AppTextStyles.bodySmall(isDark),
                      ),
                      const SizedBox(height: 14),

                      // Location & Lecturer Rows
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 15,
                            color: isDark
                                ? AppColors.amikomPurpleLight
                                : AppColors.amikomPurple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.ruang.isNotEmpty
                                  ? item.ruang
                                  : 'Menunggu Penetapan Ruangan',
                              style: AppTextStyles.bodySmall(isDark).copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.dosen.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.user,
                              size: 15,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.dosen,
                                style: AppTextStyles.bodySmall(isDark),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                      // Copy Info Action
                      OutlinedButton.icon(
                        onPressed: _copyClassInfo,
                        icon: const Icon(LucideIcons.copy, size: 14),
                        label: const Text('Salin Informasi Kuliah'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.amikomPurpleLight
                              : AppColors.amikomPurple,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.amikomPurple
                                : AppColors.purple200,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Attendance Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clipboardCheck,
                          size: 18,
                          color: isDark
                              ? AppColors.amikomGoldDarkText
                              : AppColors.amikomGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rekapitulasi Presensi Matakuliah',
                          style: AppTextStyles.titleMedium(isDark).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      tooltip: 'Refresh Presensi',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _loadCourseAttendance();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Attendance Content
                if (_isLoading) ...[
                  const ShimmerSkeleton(
                    width: double.infinity,
                    height: 120,
                    borderRadius: 14,
                  ),
                  const SizedBox(height: 12),
                  const ShimmerSkeleton(
                    width: double.infinity,
                    height: 80,
                    borderRadius: 14,
                  ),
                ] else if (_errorMessage != null || _presensiData == null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceSubtle
                          : AppColors.lightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.helpCircle,
                          size: 28,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Data presensi belum tersedia.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall(isDark),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Attendance Summary Stat Boxes
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceSubtle
                          : AppColors.lightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Kehadiran',
                              '${_presensiData!.prosentaseHadir}%',
                              AppColors.success,
                              isDark,
                            ),
                            _buildStatItem(
                              'Belum Validasi',
                              '${_presensiData!.prosentaseBelumValidasi}%',
                              _presensiData!.prosentaseBelumValidasi > 0
                                  ? AppColors.amikomGold
                                  : (isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary),
                              isDark,
                            ),
                            _buildStatItem(
                              'Nilai Presensi',
                              '${_presensiData!.akumulasiNilai}',
                              isDark
                                  ? AppColors.amikomPurpleLight
                                  : AppColors.amikomPurple,
                              isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Linear Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _presensiData!.prosentaseHadir / 100,
                            minHeight: 8,
                            backgroundColor: isDark
                                ? AppColors.darkBorder
                                : AppColors.neutral200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _presensiData!.prosentaseHadir >= 75
                                  ? AppColors.success
                                  : AppColors.amikomGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Session List
                  Text(
                    'Riwayat Sesi Perkuliahan (${_presensiData!.items.length})',
                    style: AppTextStyles.labelBold(isDark).copyWith(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ..._presensiData!.items.map((session) {
                    final isPending = session.isPending;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPending
                              ? AppColors.amikomGold
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                          width: isPending ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.tanggal,
                                  style: AppTextStyles.labelBold(isDark)
                                      .copyWith(fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  session.materi,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall(isDark),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Status or Quick Validate Button
                          if (isPending) ...[
                            ElevatedButton(
                              onPressed: () => _openValidationModal(session),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.amikomGold,
                                foregroundColor: AppColors.neutral950,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'B',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Validasi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const StatusBadge(
                              label: 'Hadir (H)',
                              variant: BadgeVariant.success,
                              icon: LucideIcons.check,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 20),

                // Button to Open Full Historical Presensi Screen
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PresensiScreen(
                          initialMakulCode: widget.item.kodeMk,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.externalLink, size: 16),
                  label: const Text('Buka Menu Presensi Lengkap (Filter Tahun & Semester)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.amikomPurpleLight
                        : AppColors.amikomPurple,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption(isDark)),
      ],
    );
  }
}
