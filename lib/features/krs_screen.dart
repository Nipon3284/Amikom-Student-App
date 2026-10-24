import '../core/network/network_status.dart';
import '../core/widgets/amikom_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/providers/portal_provider.dart';
import '../core/widgets/shimmer_loading.dart';
import '../core/widgets/status_badge.dart';
import '../core/widgets/empty_state_view.dart';

class KrsScreen extends ConsumerWidget {
  const KrsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final krsAsync = ref.watch(krsNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: AmikomBackground(
        child: RefreshIndicator(
        color: AppColors.purple700,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          if (!ensureOnline(context, ref, message: 'Gagal memperbarui KRS: Perangkat sedang offline.')) {
            return;
          }
          await ref.read(krsNotifierProvider.notifier).fetch();
        },
        child: krsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyStateView(
                title: 'KRS Belum Terisi',
                description: 'Tidak ada mata kuliah yang terdaftar dalam rencana studi semester ini.',
                icon: LucideIcons.bookX,
                actionLabel: 'Refresh KRS',
                onAction: () => ref.read(krsNotifierProvider.notifier).fetch(),
              );
            }

            final totalSks = items.fold<int>(0, (sum, item) => sum + item.sks);

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // KRS Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rencana Studi Semester Aktif', style: AppTextStyles.caption(isDark)),
                          const SizedBox(height: 4),
                          Text(
                            '$totalSks SKS Diambil',
                            style: AppTextStyles.titleLarge(isDark).copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(
                        label: '${items.length} Mata Kuliah',
                        variant: BadgeVariant.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text('Daftar Mata Kuliah', style: AppTextStyles.titleMedium(isDark)),
                const SizedBox(height: 12),

                ...items.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                        // Number circle
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$index',
                              style: AppTextStyles.labelBold(isDark).copyWith(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & SKS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.mkl,
                                style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.kode} • ${item.sks} SKS',
                                style: AppTextStyles.bodySmall(isDark),
                              ),
                            ],
                          ),
                        ),

                        // Status Badge
                        StatusBadge(
                          label: item.aktivasi == 1 ? 'Teraktivasi' : 'Pending',
                          variant: item.aktivasi == 1 ? BadgeVariant.success : BadgeVariant.warning,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, _) => const ShimmerSkeleton(width: double.infinity, height: 75, borderRadius: 14),
          ),
          error: (err, _) => EmptyStateView(
            title: 'Gagal Memuat KRS',
            description: 'Tidak dapat memuat rencana studi mahasiswa dari portal.',
            icon: LucideIcons.alertTriangle,
            actionLabel: 'Coba Lagi',
            onAction: () => ref.read(krsNotifierProvider.notifier).fetch(),
          ),
        ),
      ),
    ),
  );
}
}
