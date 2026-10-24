import '../core/network/network_status.dart';
import '../core/widgets/network_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/providers/portal_provider.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _npmController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _canBiometric = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkSavedAndBiometric();
  }

  Future<void> _checkSavedAndBiometric() async {
    final secureStorage = ref.read(secureStorageProvider);
    final savedNpm = await secureStorage.getNpm();
    if (savedNpm != null && mounted) {
      _npmController.text = savedNpm;
    }

    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (mounted) {
        setState(() {
          _canBiometric = isSupported && canCheck && savedNpm != null;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _npmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!ensureOnline(context, ref, message: 'Tidak dapat masuk saat offline. Periksa koneksi internet Anda.')) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    final npm = _npmController.text.trim();
    final password = _passwordController.text.trim();

    final success = await ref.read(authProvider.notifier).login(
          npm,
          password,
          remember: _rememberMe,
        );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (!ensureOnline(context, ref, message: 'Tidak dapat masuk saat offline. Periksa koneksi internet Anda.')) {
      return;
    }
    final secureStorage = ref.read(secureStorageProvider);
    final savedNpm = await secureStorage.getNpm();
    final savedPass = await secureStorage.getPassword();

    if (savedNpm == null || savedPass == null) return;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari atau Face ID untuk masuk',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated && mounted) {
        HapticFeedback.lightImpact();
        final success = await ref.read(authProvider.notifier).login(
              savedNpm,
              savedPass,
              remember: true,
            );
        if (success && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const NetworkStatusBar(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple700.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Masuk Mahasiswa',
                    style: AppTextStyles.headline(isDark).copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gunakan NPM dan password portal Student Service Center Amikom Purwokerto',
                    style: AppTextStyles.bodyMedium(isDark),
                  ),
                  const SizedBox(height: 32),

                  // Error Banner
                  if (authState.status == AuthStatus.error && authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF7F1D1D) : AppColors.dangerContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFFB91C1C) : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.alertCircle,
                            size: 18,
                            color: isDark ? const Color(0xFFFCA5A5) : AppColors.dangerText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: AppTextStyles.bodySmall(isDark).copyWith(
                                color: isDark ? const Color(0xFFFCA5A5) : AppColors.dangerText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // NPM Field
                  Text('NPM Mahasiswa', style: AppTextStyles.labelBold(isDark)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _npmController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTextStyles.bodyLarge(isDark),
                    decoration: InputDecoration(
                      hintText: 'Contoh: 23SA21A088',
                      prefixIcon: const Icon(LucideIcons.user, size: 18),
                      suffixIcon: _npmController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () => setState(() => _npmController.clear()),
                            )
                          : null,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'NPM tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password Field
                  Text('Password', style: AppTextStyles.labelBold(isDark)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: AppTextStyles.bodyLarge(isDark),
                    decoration: InputDecoration(
                      hintText: 'Masukkan password Anda',
                      prefixIcon: const Icon(LucideIcons.lock, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                          size: 18,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Remember Me
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: AppColors.purple700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _rememberMe = val ?? true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ingat saya di perangkat ini',
                        style: AppTextStyles.bodyMedium(isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.neutral0,
                            ),
                          )
                        : Text(
                            'Masuk ke Akun',
                            style: AppTextStyles.labelBold(isDark).copyWith(
                              color: isDark ? AppColors.neutral950 : AppColors.neutral0,
                              fontSize: 15,
                            ),
                          ),
                  ),

                  // Biometric Option
                  if (_canBiometric) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _handleBiometricLogin,
                      icon: const Icon(LucideIcons.fingerprint, size: 18),
                      label: const Text('Masuk dengan Biometrik'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  // Footer Help Text
                  Center(
                    child: Text(
                      'Portal Resmi: student.amikompurwokerto.ac.id',
                      style: AppTextStyles.caption(isDark),
                    ),
                  ),
                ],
              ),
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
