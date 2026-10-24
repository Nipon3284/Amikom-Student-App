import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/providers/portal_provider.dart';
import '../core/providers/app_update_provider.dart';
import '../core/widgets/app_update_dialog.dart';
import '../core/widgets/status_badge.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricEnabled = false;
  String _appVersion = '1.0.0';
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = info.version);
      }
    } catch (_) {}
  }

  Future<void> _loadBiometricState() async {
    final secureStorage = ref.read(secureStorageProvider);
    final enabled = await secureStorage.isBiometricEnabled();
    if (mounted) {
      setState(() => _biometricEnabled = enabled);
    }
  }

  Future<void> _toggleBiometric(bool val) async {
    HapticFeedback.selectionClick();
    if (val) {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final isSupported = await _localAuth.isDeviceSupported();
        if (canCheck && isSupported) {
          final didAuth = await _localAuth.authenticate(
            localizedReason: 'Verifikasi sidik jari untuk mengaktifkan login biometrik',
            biometricOnly: true,
          );
          if (didAuth) {
            await ref.read(secureStorageProvider).setBiometricEnabled(true);
            if (mounted) setState(() => _biometricEnabled = true);
            return;
          }
        }
      } catch (_) {}
    } else {
      await ref.read(secureStorageProvider).setBiometricEnabled(false);
      if (mounted) setState(() => _biometricEnabled = false);
    }
  }

  void _showLogoutDialog() {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi Keluar', style: AppTextStyles.titleMedium(isDark)),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Amikom Student di perangkat ini?',
          style: AppTextStyles.bodyMedium(isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.neutral0,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileNotifierProvider);
    final themeMode = ref.watch(themeProvider);
    final updateState = ref.watch(appUpdateProvider);

    ref.listen<AppUpdateState>(appUpdateProvider, (prev, next) {
      if (!next.isManualCheck) return;
      if (next.status == UpdateStatus.upToDate && prev?.status != UpdateStatus.upToDate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aplikasi sudah menggunakan versi terbaru (v$_appVersion)',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.status == UpdateStatus.error && prev?.status != UpdateStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Gagal memeriksa pembaruan.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if ((next.status == UpdateStatus.available || next.status == UpdateStatus.readyToInstall) &&
          prev?.status != next.status &&
          next.updateInfo != null) {
        AppUpdateDialog.show(context, next.updateInfo!);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Profil & Pengaturan', style: AppTextStyles.titleLarge(isDark)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Profile Card
          profileAsync.when(
            data: (profile) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.purple200,
                    backgroundImage: profile.fotoUrl.isNotEmpty
                        ? NetworkImage(profile.fotoUrl)
                        : null,
                    child: profile.fotoUrl.isEmpty
                        ? Text(
                            profile.nama.isNotEmpty ? profile.nama[0] : 'M',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple900,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.nama,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge(isDark).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.npm} • Angkatan ${profile.angkatan}',
                    style: AppTextStyles.bodySmall(isDark),
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(
                    label: profile.status,
                    variant: profile.status.toLowerCase().contains('aktif')
                        ? BadgeVariant.success
                        : BadgeVariant.warning,
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 12),

                  _buildDetailRow('Program Studi', profile.prodi, isDark),
                  _buildDetailRow('Fakultas', profile.fakultas, isDark),
                  _buildDetailRow('Dosen Pembimbing', profile.dpa, isDark),
                  if (profile.noHp.isNotEmpty) _buildDetailRow('No Handphone', profile.noHp, isDark),
                ],
              ),
            ),
            loading: () => Container(
              height: 240,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),
          Text('Pengaturan Aplikasi', style: AppTextStyles.titleMedium(isDark)),
          const SizedBox(height: 10),

          // Setting List
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                // Dark Mode Switch
                SwitchListTile(
                  title: Text('Mode Gelap (Dark Mode)', style: AppTextStyles.labelBold(isDark)),
                  subtitle: Text(
                    themeMode == ThemeMode.dark ? 'Aktif' : 'Non-aktif',
                    style: AppTextStyles.caption(isDark),
                  ),
                  secondary: const Icon(LucideIcons.moon, size: 20),
                  value: themeMode == ThemeMode.dark,
                  activeThumbColor: AppColors.purple700,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).setMode(
                          val ? ThemeMode.dark : ThemeMode.light,
                        );
                  },
                ),
                const Divider(height: 1),

                // Biometric Toggle
                SwitchListTile(
                  title: Text('Kunci Sidik Jari / Biometrik', style: AppTextStyles.labelBold(isDark)),
                  subtitle: Text(
                    _biometricEnabled ? 'Aktif saat membuka aplikasi' : 'Non-aktif',
                    style: AppTextStyles.caption(isDark),
                  ),
                  secondary: const Icon(LucideIcons.fingerprint, size: 20),
                  value: _biometricEnabled,
                  activeThumbColor: AppColors.purple700,
                  onChanged: _toggleBiometric,
                ),
                const Divider(height: 1),

                // Clear Cache / Sync
                ListTile(
                  leading: const Icon(LucideIcons.refreshCw, size: 20),
                  title: Text('Sinkronisasi Ulang Data', style: AppTextStyles.labelBold(isDark)),
                  subtitle: Text('Perbarui cache jadwal dan KHS lokal', style: AppTextStyles.caption(isDark)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final npm = ref.read(authProvider).npm;
                    if (npm != null) {
                      await ref.read(profileNotifierProvider.notifier).fetch(npm);
                    }
                    await ref.read(jadwalNotifierProvider.notifier).fetch();
                    await ref.read(krsNotifierProvider.notifier).fetch();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data berhasil disinkronisasi ulang'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),

                // Periksa Pembaruan
                ListTile(
                  leading: const Icon(LucideIcons.arrowUpCircle, size: 20),
                  title: Text('Periksa Pembaruan', style: AppTextStyles.labelBold(isDark)),
                  subtitle: Text(
                    'Versi v$_appVersion (Ketuk untuk memeriksa)',
                    style: AppTextStyles.caption(isDark),
                  ),
                  trailing: updateState.status == UpdateStatus.checking && updateState.isManualCheck
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.chevronRight, size: 16),
                  onTap: updateState.status == UpdateStatus.checking
                      ? null
                      : () async {
                          HapticFeedback.lightImpact();
                          await ref.read(appUpdateProvider.notifier).checkForUpdate(manual: true);
                        },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Action
          OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.danger),
            label: const Text('Keluar dari Akun', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.danger, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 28),
          Center(
            child: Text(
              'Amikom Student Android v$_appVersion\nUniversitas Amikom Purwokerto',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(isDark),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.caption(isDark)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall(isDark).copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
