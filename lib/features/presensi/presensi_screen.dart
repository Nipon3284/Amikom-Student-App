import '../../core/network/network_status.dart';
import '../../core/widgets/network_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/portal_provider.dart';
import '../../core/models/presensi_model.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/empty_state_view.dart';
import 'widgets/presensi_validation_modal.dart';

class PresensiScreen extends ConsumerStatefulWidget {
  final String? initialMakulCode;

  const PresensiScreen({super.key, this.initialMakulCode});

  @override
  ConsumerState<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends ConsumerState<PresensiScreen> {
  final List<String> _tahunList = ['2026/2027', '2025/2026', '2024/2025'];
  String _selectedTahun = '2026/2027';
  int _selectedSemester = 1;

  List<Map<String, String>> _courseList = [];
  String? _selectedCourseKey;

  bool _isLoadingCourses = true;
  bool _isLoadingTable = false;
  PresensiDetailData? _detailData;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final client = ref.read(portalClientProvider);

    setState(() {
      _isLoadingCourses = true;
    });

    final courses = await client.fetchPresensiCourses(_selectedTahun, _selectedSemester);

    if (mounted) {
      String? defaultKey;
      if (widget.initialMakulCode != null) {
        final match = courses.firstWhere(
          (c) => c['value']!.contains(widget.initialMakulCode!),
          orElse: () => courses.isNotEmpty ? courses.first : {},
        );
        defaultKey = match['value'];
      } else if (courses.isNotEmpty) {
        defaultKey = courses.first['value'];
      }

      setState(() {
        _courseList = courses;
        _selectedCourseKey = defaultKey;
        _isLoadingCourses = false;
      });

      if (_selectedCourseKey != null) {
        _loadTableData(_selectedCourseKey!);
      }
    }
  }

  Future<void> _loadTableData(String makulKey) async {
    setState(() {
      _isLoadingTable = true;
    });

    final client = ref.read(portalClientProvider);
    final data = await client.fetchPresensiDetails(
      thnAkademik: _selectedTahun,
      semester: _selectedSemester,
      makulKey: makulKey,
    );

    if (mounted) {
      setState(() {
        _detailData = data;
        _isLoadingTable = false;
      });
    }
  }

  void _openValidationModal(PresensiSessionItem item) {
    if (!ensureOnline(context, ref, message: 'Tidak dapat membuka formulir validasi presensi saat offline.')) {
      return;
    }
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PresensiValidationModal(
        sessionItem: item,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presensi berhasil divalidasi menjadi Hadir (H)!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Real-time refresh of table and unvalidated list
          ref.read(unvalidatedPresensiProvider.notifier).check();
          if (_selectedCourseKey != null) {
            _loadTableData(_selectedCourseKey!);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unvalAsync = ref.watch(unvalidatedPresensiProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Rekap Presensi Kehadiran', style: AppTextStyles.titleLarge(isDark)),
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 6),
              child: NetworkStatusChip(),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Refresh',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(unvalidatedPresensiProvider.notifier).check();
              if (_selectedCourseKey != null) {
                _loadTableData(_selectedCourseKey!);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const NetworkStatusBar(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.amikomPurple,
              onRefresh: () async {
                if (!ensureOnline(context, ref, message: 'Gagal memperbarui presensi: Perangkat sedang offline.')) {
                  return;
                }
                await ref.read(unvalidatedPresensiProvider.notifier).check();
                if (_selectedCourseKey != null) {
                  await _loadTableData(_selectedCourseKey!);
                }
              },
              child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          children: [
            // Warning Alert Box for Unvalidated Presensi (matching web portal screenshot)
            unvalAsync.when(
              data: (unvalidatedList) {
                if (unvalidatedList.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.amikomGoldDarkContainer : AppColors.amikomGoldContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.amikomGoldDark : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.alertCircle,
                            size: 18,
                            color: isDark ? AppColors.amikomGoldDarkText : AppColors.amikomGoldText,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mata Kuliah Belum Validasi Kehadiran',
                            style: AppTextStyles.labelBold(isDark).copyWith(
                              color: isDark ? AppColors.amikomGoldDarkText : AppColors.amikomGoldText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...unvalidatedList.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 4),
                          child: Text(
                            '• ${c.count} Kehadiran Mata Kuliah ${c.makul}',
                            style: AppTextStyles.bodySmall(isDark).copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.amikomGoldDarkText : AppColors.amikomGoldText,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // Filter Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row for Tahun Ajaran & Semester
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tahun Ajaran', style: AppTextStyles.caption(isDark)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceSubtle
                                    : AppColors.lightSurfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedTahun,
                                  isExpanded: true,
                                  dropdownColor: isDark
                                      ? AppColors.darkSurface
                                      : AppColors.lightSurface,
                                  style: AppTextStyles.labelBold(isDark),
                                  items: _tahunList.map((t) {
                                    return DropdownMenuItem(value: t, child: Text(t));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedTahun = val);
                                      _initData();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Semester', style: AppTextStyles.caption(isDark)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceSubtle
                                    : AppColors.lightSurfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedSemester,
                                  isExpanded: true,
                                  dropdownColor: isDark
                                      ? AppColors.darkSurface
                                      : AppColors.lightSurface,
                                  style: AppTextStyles.labelBold(isDark),
                                  items: const [
                                    DropdownMenuItem(value: 1, child: Text('Ganjil')),
                                    DropdownMenuItem(value: 2, child: Text('Genap')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedSemester = val);
                                      _initData();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Mata Kuliah Selector
                  Text('Mata Kuliah', style: AppTextStyles.caption(isDark)),
                  const SizedBox(height: 6),
                  _isLoadingCourses
                      ? const ShimmerSkeleton(width: double.infinity, height: 46)
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceSubtle
                                : AppColors.lightSurfaceSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCourseKey,
                              isExpanded: true,
                              hint: const Text('--Pilih Mata Kuliah--'),
                              dropdownColor: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                              style: AppTextStyles.labelBold(isDark),
                              items: _courseList.map((c) {
                                return DropdownMenuItem(
                                  value: c['value'],
                                  child: Text(
                                    c['label']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCourseKey = val);
                                  _loadTableData(val);
                                }
                              },
                            ),
                          ),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Attendance Table Content
            if (_isLoadingTable) ...[
              const ShimmerSkeleton(width: double.infinity, height: 180, borderRadius: 16),
            ] else if (_detailData == null || _detailData!.items.isEmpty) ...[
              const EmptyStateView(
                title: 'Data Presensi Tidak Ditemukan',
                description: 'Pilih mata kuliah di atas untuk melihat rekap kehadiran.',
                icon: LucideIcons.calendarCheck,
              ),
            ] else ...[
              // Course Lecturer Header
              if (_detailData!.namaDosen.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.userCheck,
                        size: 20,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _detailData!.tipe,
                              style: AppTextStyles.caption(isDark),
                            ),
                            Text(
                              _detailData!.namaDosen,
                              style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Session List Items
              Text(
                'Sesi Perkuliahan (${_detailData!.items.length})',
                style: AppTextStyles.titleMedium(isDark),
              ),
              const SizedBox(height: 10),

              ..._detailData!.items.map((session) {
                final isPending = session.isPending;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPending
                          ? AppColors.warning
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                              style: AppTextStyles.labelBold(isDark).copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.materi,
                              style: AppTextStyles.bodyMedium(isDark).copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Status Badge / Action Button
                      if (isPending) ...[
                        ElevatedButton(
                          onPressed: () => _openValidationModal(session),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.amikomGold,
                            foregroundColor: AppColors.neutral950,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text('Validasi', style: TextStyle(fontSize: 12)),
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

              const SizedBox(height: 16),

              // Summary Stats Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rekapitulasi Kehadiran', style: AppTextStyles.titleMedium(isDark)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatBox(
                          'Persentase Hadir',
                          '${_detailData!.prosentaseHadir}%',
                          AppColors.success,
                          isDark,
                        ),
                        _buildStatBox(
                          'Belum Validasi',
                          '${_detailData!.prosentaseBelumValidasi}%',
                          _detailData!.prosentaseBelumValidasi > 0
                              ? AppColors.warning
                              : AppColors.neutral600,
                          isDark,
                        ),
                        _buildStatBox(
                          'Nilai Presensi',
                          '${_detailData!.akumulasiNilai}',
                          isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    ),
  ],
),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
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
      ),
    );
  }
}
