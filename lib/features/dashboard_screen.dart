import '../core/network/network_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/providers/portal_provider.dart';
import '../core/widgets/shimmer_loading.dart';
import '../core/widgets/status_badge.dart';
import '../core/widgets/amikom_background.dart';
import 'presensi/presensi_screen.dart';
import 'jadwal/widgets/jadwal_detail_presensi_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasPromptedValidation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptValidation();
    });
  }

  Future<void> _checkAndPromptValidation() async {
    if (_hasPromptedValidation) return;

    final unvalList = await ref.read(unvalidatedPresensiProvider.notifier).check();
    if (!mounted) return;

    if (unvalList.isNotEmpty && !_hasPromptedValidation) {
      _hasPromptedValidation = true;
      _showUnvalidatedPromptDialog();
    }
  }

  void _showUnvalidatedPromptDialog() {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.amikomGoldDarkContainer
                    : AppColors.amikomGoldContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.alertTriangle,
                size: 20,
                color: isDark
                    ? AppColors.amikomGoldDarkText
                    : AppColors.amikomGoldText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'student.amikompurwokerto.ac.id menyatakan',
                style: AppTextStyles.labelBold(isDark).copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
        content: Text(
          'Ada beberapa presensi yang belum di validasi! Silahkan validasi terlebih dahulu!',
          style: AppTextStyles.bodyMedium(isDark).copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!ensureOnline(context, ref, message: 'Tidak dapat melakukan validasi presensi saat offline.')) {
                return;
              }
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PresensiScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amikomPurple,
              foregroundColor: AppColors.neutral0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Validasi Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileNotifierProvider);
    final jadwalAsync = ref.watch(jadwalNotifierProvider);
    final unvalAsync = ref.watch(unvalidatedPresensiProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: AmikomBackground(
        child: RefreshIndicator(
          color: AppColors.amikomPurple,
          onRefresh: () async {
          HapticFeedback.lightImpact();
          if (!ensureOnline(context, ref, message: 'Gagal menyinkronkan data: Perangkat sedang offline.')) {
            return;
          }
          if (authState.npm != null) {
            await ref.read(profileNotifierProvider.notifier).fetch(authState.npm!);
          }
          await ref.read(jadwalNotifierProvider.notifier).fetch();
          await ref.read(krsNotifierProvider.notifier).fetch();
          await ref.read(unvalidatedPresensiProvider.notifier).check();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Student Greeting Header
            profileAsync.when(
              data: (profile) => Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hai, ${profile.nama.split(' ').first}',
                          style: AppTextStyles.headline(isDark).copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${profile.prodi} • ${profile.npm}',
                          style: AppTextStyles.bodySmall(isDark),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: profile.status,
                    variant: profile.status.toLowerCase().contains('aktif')
                        ? BadgeVariant.success
                        : BadgeVariant.warning,
                  ),
                ],
              ),
              loading: () => const ShimmerSkeleton(width: 200, height: 42),
              error: (_, _) => Text('Selamat Datang', style: AppTextStyles.headline(isDark)),
            ),

            const SizedBox(height: 16),

            // Prominent Unvalidated Presensi Alert Banner (if pending)
            unvalAsync.maybeWhen(
              data: (unvalidatedList) {
                if (unvalidatedList.isEmpty) return const SizedBox.shrink();

                final totalPending = unvalidatedList.fold<int>(0, (sum, c) => sum + c.count);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.amikomGoldDarkContainer : AppColors.amikomGoldContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.amikomGoldDark : const Color(0xFFFDE68A),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF241400) : const Color(0xFFFDF0D5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.clipboardCheck,
                          size: 22,
                          color: isDark ? AppColors.amikomGoldDarkText : AppColors.amikomGoldText,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalPending Presensi Belum Divalidasi',
                              style: AppTextStyles.labelBold(isDark).copyWith(
                                color: isDark ? AppColors.amikomGoldDarkText : AppColors.amikomGoldText,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Validasi sekarang agar kehadiran tercatat resmi',
                              style: AppTextStyles.caption(isDark).copyWith(
                                color: isDark ? AppColors.amikomGoldDarkText : AppColors.amikomGoldText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (!ensureOnline(context, ref, message: 'Tidak dapat melakukan validasi presensi saat offline.')) {
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PresensiScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amikomPurple,
                          foregroundColor: AppColors.neutral0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Validasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Hero Academic Stats Card with Amikom Official Website Gradient
            profileAsync.when(
              data: (profile) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amikomPurpleNight.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Indeks Prestasi Kumulatif',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.purple200,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Skala 4.00',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.neutral950,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          profile.ipk > 0 ? profile.ipk.toStringAsFixed(2) : '-',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                            color: AppColors.neutral0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          profile.ipk >= 3.5 ? 'Sangat Memuaskan' : 'Baik',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purple200,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 1,
                      color: AppColors.purple700.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total SKS Tempuh',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.purple200,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${profile.totalSks} SKS',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.neutral0,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'SKS Semester Ini',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.purple200,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${profile.sksSekarang} SKS',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.neutral0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              loading: () => const ShimmerSkeleton(width: double.infinity, height: 160, borderRadius: 20),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // Quick Actions Bar
            Row(
              children: [
                _buildQuickAction(
                  icon: LucideIcons.clipboardCheck,
                  label: 'Presensi',
                  badgeCount: unvalAsync.maybeWhen(
                    data: (list) => list.fold<int>(0, (sum, c) => sum + c.count),
                    orElse: () => 0,
                  ),
                  iconGradient: AppColors.fusionGradient,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PresensiScreen()),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _buildQuickAction(
                  icon: LucideIcons.calendarDays,
                  label: 'Jadwal',
                  iconGradient: AppColors.primaryGradient,
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _buildQuickAction(
                  icon: LucideIcons.graduationCap,
                  label: 'Nilai KHS',
                  iconColor: isDark ? AppColors.amikomGoldDarkText : AppColors.amikomGold,
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _buildQuickAction(
                  icon: LucideIcons.bookMarked,
                  label: 'KRS',
                  iconColor: isDark ? AppColors.amikomPurpleLight : AppColors.amikomPurple,
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Today's Upcoming Class Widget
            Text('Jadwal Kuliah Hari Ini', style: AppTextStyles.titleMedium(isDark)),
            const SizedBox(height: 12),
            jadwalAsync.when(
              data: (items) {
                final now = DateTime.now();
                final dayNames = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'];
                final currentDay = dayNames[now.weekday - 1];

                final todayClasses = items.where((e) => e.hari.toUpperCase() == currentDay).toList();

                if (todayClasses.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            LucideIcons.calendarCheck,
                            size: 20,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tidak Ada Kuliah Hari Ini',
                                style: AppTextStyles.labelBold(isDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Gunakan waktu untuk belajar mandiri atau tugas',
                                style: AppTextStyles.caption(isDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: todayClasses.map((item) {
                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => JadwalDetailPresensiSheet(item: item),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StatusBadge(
                                  label: item.jam,
                                  variant: BadgeVariant.primary,
                                  icon: LucideIcons.clock,
                                ),
                                StatusBadge(
                                  label: '${item.sks} SKS • ${item.tipe}',
                                  variant: BadgeVariant.gold,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.namaMk,
                              style: AppTextStyles.titleMedium(isDark),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.mapPin,
                                  size: 14,
                                  color: isDark ? AppColors.amikomPurpleLight : AppColors.amikomPurple,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.ruang.isNotEmpty ? item.ruang : 'Online / Menunggu Ruang',
                                    style: AppTextStyles.bodySmall(isDark),
                                  ),
                                ),
                              ],
                            ),
                            if (item.dosen.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.user,
                                    size: 14,
                                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.dosen,
                                      style: AppTextStyles.bodySmall(isDark),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.clipboardCheck,
                                      size: 13,
                                      color: isDark ? AppColors.amikomPurpleLight : AppColors.amikomPurple,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Presensi & Detail Kuliah',
                                      style: AppTextStyles.caption(isDark).copyWith(
                                        color: isDark ? AppColors.amikomPurpleLight : AppColors.amikomPurple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 14,
                                  color: isDark ? AppColors.amikomPurpleLight : AppColors.amikomPurple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const ShimmerSkeleton(width: double.infinity, height: 90, borderRadius: 14),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Academic Notice / Important Announcement
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 18,
                    color: isDark ? const Color(0xFF6EE7B7) : AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Akademik Terhubung',
                          style: AppTextStyles.labelBold(isDark).copyWith(
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Data disinkronisasi langsung dari server Student Service Center Amikom Purwokerto.',
                          style: AppTextStyles.bodySmall(isDark).copyWith(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    int badgeCount = 0,
    Color? iconColor,
    Gradient? iconGradient,
  }) {
    final effectiveColor = iconColor ?? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: badgeCount > 0
                  ? AppColors.warning
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: badgeCount > 0 ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: iconGradient ??
                          LinearGradient(
                            colors: [
                              effectiveColor.withValues(alpha: 0.16),
                              effectiveColor.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 22,
                        color: iconGradient != null ? AppColors.neutral0 : effectiveColor,
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.caption(isDark).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
