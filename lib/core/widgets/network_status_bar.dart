import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../network/network_status.dart';

/// Top sliding banner that alerts the user when the app is offline
/// or when connection is restored.
class NetworkStatusBar extends ConsumerWidget {
  const NetworkStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isOffline = !status.isOnline;
    final isReconnecting = status.isReconnecting;
    final isVisible = isOffline || isReconnecting;

    return AnimatedCrossFade(
      alignment: Alignment.topCenter,
      firstCurve: Curves.easeOutCubic,
      secondCurve: Curves.easeInCubic,
      duration: const Duration(milliseconds: 300),
      crossFadeState: isVisible
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOffline
              ? (isDark ? const Color(0xFF3B1219) : const Color(0xFFFFECEF))
              : (isDark ? const Color(0xFF0D331E) : const Color(0xFFE8F7ED)),
          border: Border(
            bottom: BorderSide(
              color: isOffline
                  ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5))
                  : (isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC)),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isOffline
                    ? AppColors.danger.withValues(alpha: 0.15)
                    : AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOffline ? LucideIcons.wifiOff : LucideIcons.wifi,
                size: 16,
                color: isOffline ? AppColors.danger : AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOffline
                        ? 'Mode Offline: Tidak Ada Koneksi Internet'
                        : 'Koneksi Terhubung Kembali',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isOffline
                          ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B))
                          : (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534)),
                    ),
                  ),
                  Text(
                    isOffline
                        ? 'Validasi presensi dan sinkronisasi dinonaktifkan sementara.'
                        : 'Data portal siap disinkronisasi.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOffline
                          ? (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C))
                          : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),
            if (isOffline) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(networkStatusProvider.notifier).refreshStatus();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF5A1A24) : const Color(0xFFFFD5DA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF991B1B) : const Color(0xFFF87171),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.refreshCw,
                        size: 11,
                        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cek Lagi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      secondChild: const SizedBox.shrink(),
    );
  }
}

/// Compact Network Status Badge / Chip for AppBar
class NetworkStatusChip extends ConsumerWidget {
  const NetworkStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = status.isOnline;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
                  color: AppColors.neutral0,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline
                      ? 'Status: ${status.label} - Server Terhubung'
                      : 'Status: Offline - Tidak Ada Akses Internet',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: isOnline ? AppColors.success : AppColors.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: isOnline
                ? null
                : SnackBarAction(
                    label: 'Coba Lagi',
                    textColor: AppColors.neutral0,
                    onPressed: () {
                      ref.read(networkStatusProvider.notifier).refreshStatus();
                    },
                  ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOnline
              ? (isDark
                  ? AppColors.success.withValues(alpha: 0.15)
                  : const Color(0xFFE8F7ED))
              : (isDark
                  ? AppColors.danger.withValues(alpha: 0.2)
                  : const Color(0xFFFFECEF)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOnline
                ? (isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC))
                : (isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5)),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? AppColors.success : AppColors.danger,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isOnline
                    ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534))
                    : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
