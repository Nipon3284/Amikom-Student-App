import '../core/network/network_status.dart';
import '../core/widgets/amikom_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/providers/portal_provider.dart';
import '../core/models/jadwal_item.dart';
import '../core/models/presensi_model.dart';
import '../core/widgets/shimmer_loading.dart';
import '../core/widgets/status_badge.dart';
import '../core/widgets/empty_state_view.dart';
import 'jadwal/widgets/jadwal_detail_presensi_sheet.dart';

class JadwalScreen extends ConsumerStatefulWidget {
  const JadwalScreen({super.key});

  @override
  ConsumerState<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends ConsumerState<JadwalScreen> {
  final List<String> _days = ['SEMUA', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU'];
  String _selectedDay = 'SEMUA';

  @override
  void initState() {
    super.initState();
    // Default to today if weekday <= 6
    final weekday = DateTime.now().weekday;
    if (weekday <= 6) {
      _selectedDay = _days[weekday];
    }
  }

  void _copyClassInfo(JadwalItem item) {
    HapticFeedback.lightImpact();
    final text = '${item.namaMk} (${item.kodeMk})\n'
        'Hari: ${item.hari}, Jam: ${item.jam}\n'
        'Ruang: ${item.ruang}\n'
        'Dosen: ${item.dosen}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Info mata kuliah "${item.namaMk}" berhasil disalin'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCourseDetailAndPresensi(JadwalItem item) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JadwalDetailPresensiSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadwalAsync = ref.watch(jadwalNotifierProvider);
    final unvalAsync = ref.watch(unvalidatedPresensiProvider);
    final unvalList = unvalAsync.value ?? [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: AmikomBackground(
        child: Column(
        children: [
          // Day Selector Horizontal Bar with Amikom Website Palette
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = _days[index];
                  final isSelected = _selectedDay == day;

                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        color: isSelected
                            ? null
                            : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.amikomPurple
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.neutral0
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Course List View
          Expanded(
            child: RefreshIndicator(
              color: AppColors.amikomPurple,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                if (!ensureOnline(context, ref, message: 'Gagal memperbarui jadwal: Perangkat sedang offline.')) {
                  return;
                }
                await ref.read(jadwalNotifierProvider.notifier).fetch();
                await ref.read(unvalidatedPresensiProvider.notifier).check();
              },
              child: jadwalAsync.when(
                data: (items) {
                  final filtered = _selectedDay == 'SEMUA'
                      ? items
                      : items.where((e) => e.hari.toUpperCase() == _selectedDay).toList();

                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      title: 'Tidak Ada Jadwal',
                      description: 'Tidak ada jadwal kuliah yang terdaftar untuk hari $_selectedDay.',
                      icon: LucideIcons.calendarX,
                      actionLabel: 'Refresh Jadwal',
                      onAction: () => ref.read(jadwalNotifierProvider.notifier).fetch(),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];

                      // Check if course has pending unvalidated attendance
                      final pendingMatch = unvalList.firstWhere(
                        (u) {
                          final targetCode = item.kodeMk.toLowerCase();
                          final targetName = item.namaMk.toLowerCase();
                          return u.kode.toLowerCase() == targetCode ||
                              u.makul.toLowerCase().contains(targetName) ||
                              targetName.contains(u.makul.toLowerCase());
                        },
                        orElse: () => const UnvalidatedCourse(
                          kode: '',
                          makul: '',
                          count: 0,
                          idPresensiMhsList: [],
                          kelasgabList: [],
                        ),
                      );
                      final hasPending = pendingMatch.count > 0;

                      return InkWell(
                        onTap: () => _openCourseDetailAndPresensi(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: hasPending
                                  ? AppColors.amikomGold
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: hasPending ? 1.5 : 1,
                            ),
                            boxShadow: hasPending
                                ? [
                                    BoxShadow(
                                      color: AppColors.amikomGold.withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Unvalidated Presensi Notification Alert Bar (if pending for this course)
                              if (hasPending) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.amikomGoldDarkContainer
                                        : AppColors.amikomGoldContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.amikomGoldDark
                                          : const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.alertTriangle,
                                        size: 14,
                                        color: isDark
                                            ? AppColors.amikomGoldDarkText
                                            : AppColors.amikomGoldText,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${pendingMatch.count} Presensi Belum Divalidasi [ B ]',
                                          style: AppTextStyles.caption(isDark).copyWith(
                                            color: isDark
                                                ? AppColors.amikomGoldDarkText
                                                : AppColors.amikomGoldText,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Validasi',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? AppColors.amikomGoldDarkText
                                              : AppColors.amikomGoldText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Header Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      StatusBadge(
                                        label: item.hari.isNotEmpty ? item.hari : 'Online',
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
                                  Row(
                                    children: [
                                      StatusBadge(
                                        label: '${item.sks} SKS',
                                        variant: BadgeVariant.gold,
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(LucideIcons.copy, size: 15),
                                        tooltip: 'Salin Info',
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        onPressed: () => _copyClassInfo(item),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Course Title
                              Text(
                                item.namaMk,
                                style: AppTextStyles.titleMedium(isDark).copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.kodeMk} • ${item.tipe}${item.kelas.isNotEmpty ? ' (${item.kelas})' : ''}',
                                style: AppTextStyles.bodySmall(isDark),
                              ),
                              const SizedBox(height: 12),

                              // Location & Lecturer Details
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceSubtle
                                      : AppColors.lightSurfaceSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.mapPin,
                                          size: 14,
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
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.user,
                                            size: 14,
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
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Integrated Attendance Action Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.clipboardCheck,
                                        size: 14,
                                        color: hasPending
                                            ? AppColors.amikomGold
                                            : (isDark
                                                ? AppColors.amikomPurpleLight
                                                : AppColors.amikomPurple),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        hasPending
                                            ? 'Ada presensi butuh validasi'
                                            : 'Rekap Presensi & Kehadiran',
                                        style: AppTextStyles.caption(isDark).copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: hasPending
                                              ? (isDark
                                                  ? AppColors.amikomGoldDarkText
                                                  : AppColors.amikomGoldText)
                                              : (isDark
                                                  ? AppColors.amikomPurpleLight
                                                  : AppColors.amikomPurple),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Detail',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: hasPending
                                              ? AppColors.amikomGold
                                              : (isDark
                                                  ? AppColors.amikomPurpleLight
                                                  : AppColors.amikomPurple),
                                        ),
                                      ),
                                      Icon(
                                        LucideIcons.chevronRight,
                                        size: 14,
                                        color: hasPending
                                            ? AppColors.amikomGold
                                            : (isDark
                                                ? AppColors.amikomPurpleLight
                                                : AppColors.amikomPurple),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, _) => const ShimmerSkeleton(
                    width: double.infinity,
                    height: 140,
                    borderRadius: 16,
                  ),
                ),
                error: (err, _) => EmptyStateView(
                  title: 'Gagal Memuat Jadwal',
                  description: 'Tidak dapat mengambil jadwal kuliah dari portal kampus.',
                  icon: LucideIcons.alertTriangle,
                  actionLabel: 'Coba Lagi',
                  onAction: () => ref.read(jadwalNotifierProvider.notifier).fetch(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
