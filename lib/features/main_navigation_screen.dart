import '../core/widgets/network_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/providers/portal_provider.dart';
import 'dashboard_screen.dart';
import 'jadwal_screen.dart';
import 'nilai_screen.dart';
import 'krs_screen.dart';
import 'profile_screen.dart';
import 'presensi/presensi_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    JadwalScreen(),
    NilaiScreen(),
    KrsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amikom Student',
                  style: AppTextStyles.titleMedium(isDark).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Purwokerto',
                  style: AppTextStyles.caption(isDark).copyWith(
                    fontSize: 11,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Network Connection Status Chip
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 4),
              child: NetworkStatusChip(),
            ),
          ),

          // Presensi Button with Unvalidated Badge
          Consumer(
            builder: (context, ref, _) {
              final unvalAsync = ref.watch(unvalidatedPresensiProvider);
              final totalUnval = unvalAsync.maybeWhen(
                data: (list) => list.fold<int>(0, (sum, c) => sum + c.count),
                orElse: () => 0,
              );

              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(LucideIcons.clipboardCheck, size: 21),
                    if (totalUnval > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$totalUnval',
                            style: const TextStyle(
                              color: AppColors.neutral900,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Presensi Kehadiran',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PresensiScreen()),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 4),

          // Profile Avatar Button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: profileAsync.when(
                data: (profile) => CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.purple200,
                  backgroundImage: profile.fotoUrl.isNotEmpty
                      ? NetworkImage(profile.fotoUrl)
                      : null,
                  child: profile.fotoUrl.isEmpty
                      ? Text(
                          profile.nama.isNotEmpty ? profile.nama[0] : 'M',
                          style: const TextStyle(
                            color: AppColors.purple900,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                loading: () => const CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.lightSurfaceSubtle,
                ),
                error: (_, _) => const CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.purple700,
                  child: Icon(LucideIcons.user, size: 16, color: AppColors.neutral0),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const NetworkStatusBar(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.layoutDashboard, 'Beranda', isDark),
                _buildNavItem(1, LucideIcons.calendarDays, 'Jadwal', isDark),
                _buildNavItem(2, LucideIcons.graduationCap, 'Nilai', isDark),
                _buildNavItem(3, LucideIcons.bookMarked, 'KRS', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? AppColors.amikomPurpleLight : AppColors.amikomPurple;
    final inactiveColor = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return InkWell(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.amikomPurple.withValues(alpha: 0.22)
                  : AppColors.amikomPurpleTint)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
