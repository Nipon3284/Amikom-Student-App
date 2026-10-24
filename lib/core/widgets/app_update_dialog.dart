import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/app_update_info.dart';
import '../providers/app_update_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppUpdateDialog extends ConsumerWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
  });

  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppUpdateDialog(updateInfo: info),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(appUpdateProvider);
    final notifier = ref.read(appUpdateProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isDownloading = updateState.status == UpdateStatus.downloading;
    final isReadyToInstall = updateState.status == UpdateStatus.readyToInstall;

    return PopScope(
      canPop: !isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon & Title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.purple700.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.arrowUpCircle,
                        color: AppColors.purple700,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembaruan Tersedia',
                          style: AppTextStyles.titleMedium(isDark).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Versi ${updateInfo.latestVersion}',
                          style: AppTextStyles.bodySmall(isDark).copyWith(
                            color: AppColors.purple700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Version Comparison & Size Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
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
                        Text(
                          'Versi Saat Ini',
                          style: AppTextStyles.caption(isDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v${updateInfo.currentVersion}',
                          style: AppTextStyles.bodySmall(isDark).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.arrowRight, size: 16, color: AppColors.neutral400),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Ukuran Berkas',
                          style: AppTextStyles.caption(isDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          updateInfo.formattedSize.isNotEmpty
                              ? updateInfo.formattedSize
                              : 'APK Android',
                          style: AppTextStyles.bodySmall(isDark).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Release Notes / Changelog
              if (updateInfo.releaseNotes.isNotEmpty) ...[
                Text(
                  'Catatan Rilis:',
                  style: AppTextStyles.labelBold(isDark),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      updateInfo.releaseNotes,
                      style: AppTextStyles.bodySmall(isDark).copyWith(height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Downloading Progress Section
              if (isDownloading) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mengunduh pembaruan...',
                          style: AppTextStyles.caption(isDark).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(updateState.downloadProgress * 100).toInt()}%',
                          style: AppTextStyles.caption(isDark).copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.purple700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: updateState.downloadProgress > 0 ? updateState.downloadProgress : null,
                        minHeight: 8,
                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.neutral200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple700),
                      ),
                    ),
                    if (updateState.totalBytes > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(updateState.downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(updateState.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                        style: AppTextStyles.caption(isDark),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // Ready to install notice
              if (isReadyToInstall) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.checkCircle, size: 18, color: AppColors.successText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Berkas siap dipasang di perangkat.',
                          style: AppTextStyles.caption(isDark).copyWith(
                            color: AppColors.successText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Action Buttons
              Row(
                children: [
                  if (!isDownloading) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          notifier.dismissUpdate();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Nanti',
                          style: AppTextStyles.labelBold(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: isDownloading ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: isDownloading
                          ? () => notifier.cancelDownload()
                          : () => notifier.startDownloadAndInstall(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDownloading ? AppColors.danger : AppColors.purple700,
                        foregroundColor: AppColors.neutral0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isDownloading
                            ? 'Batalkan'
                            : (isReadyToInstall ? 'Pasang Pembaruan' : 'Perbarui Sekarang'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
