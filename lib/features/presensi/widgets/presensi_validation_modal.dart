import '../../../core/network/network_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/portal_provider.dart';
import '../../../core/models/presensi_model.dart';

class PresensiValidationModal extends ConsumerStatefulWidget {
  final PresensiSessionItem sessionItem;
  final VoidCallback onSuccess;

  const PresensiValidationModal({
    super.key,
    required this.sessionItem,
    required this.onSuccess,
  });

  @override
  ConsumerState<PresensiValidationModal> createState() =>
      _PresensiValidationModalState();
}

class _PresensiValidationModalState
    extends ConsumerState<PresensiValidationModal> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  PresensiModalDetail? _detail;
  String? _errorMessage;

  // Form selections with positive defaults as requested
  String _kesesuaianPerkuliahan = '1'; // 1 = Benar, 2 = Tidak benar
  String _kesesuaianMateri = '1';       // 1 = Ya sesuai, 2 = Tidak sesuai
  String _penilaianMhs = '4';           // 4 = Sangat Baik
  final TextEditingController _kritikSaranController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _kritikSaranController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    final isOnline = ref.read(networkStatusProvider).isOnline;
    if (!isOnline) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Perangkat sedang offline. Hubungkan ke internet untuk memuat formulir validasi presensi.';
      });
      return;
    }
    final client = ref.read(portalClientProvider);
    final editId = widget.sessionItem.editId;
    if (editId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ID presensi tidak valid';
      });
      return;
    }

    final detail = await client.fetchPresensiModalData(
      editId,
      jenisPilih: widget.sessionItem.jenisPilih,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _detail = detail;
        if (detail == null) {
          _errorMessage = 'Gagal memuat detail presensi dari server';
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (_detail == null) return;
    if (!ensureOnline(context, ref, message: 'Tidak dapat menyimpan validasi presensi saat offline.')) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isSubmitting = true;
    });

    final client = ref.read(portalClientProvider);
    final ok = await client.submitPresensiValidation(
      jenisPilih: _detail!.jenisPilih,
      idPresensiMhs: _detail!.idPresensiMhs,
      idPresensiDosen: _detail!.idPresensiDosen,
      kuliahTeori: widget.sessionItem.kuliahTeori,
      kuliahPraktek: widget.sessionItem.kuliahPraktek,
      kesesuaianPerkuliahan: _kesesuaianPerkuliahan,
      kesesuaianMateri: _kesesuaianMateri,
      penilaianMhs: _penilaianMhs,
      kritikSaran: _kritikSaranController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (ok) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan validasi presensi. Silakan coba lagi.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
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
                    LucideIcons.checkSquare,
                    size: 20,
                    color: isDark ? AppColors.purple300 : AppColors.purple800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Validasi Kehadiran Dosen',
                        style: AppTextStyles.titleMedium(isDark).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Konfirmasi kehadiran perkuliahan secara real-time',
                        style: AppTextStyles.caption(isDark),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),

          // Body Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.purple700,
                      ),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.alertTriangle,
                                  size: 32, color: AppColors.warning),
                              const SizedBox(height: 12),
                              Text(_errorMessage!,
                                  style: AppTextStyles.bodyMedium(isDark)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchDetail,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        children: [
                          // Session Meta Information Box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceSubtle
                                  : AppColors.lightSurfaceSubtle,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                  'Mata Kuliah',
                                  widget.sessionItem.namaMk.isNotEmpty
                                      ? widget.sessionItem.namaMk
                                      : 'Infrastruktur Teknologi Informasi',
                                  isDark,
                                ),
                                _buildInfoRow(
                                  'Dosen Pengampu',
                                  _detail?.namaDosen ?? '',
                                  isDark,
                                ),
                                _buildInfoRow(
                                  'Tanggal & Jam',
                                  '${_detail?.tanggal ?? ''} (${_detail?.jam ?? ''})',
                                  isDark,
                                ),
                                _buildInfoRow(
                                  'Materi',
                                  _detail?.judulMateri ?? widget.sessionItem.materi,
                                  isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Question 1
                          _buildQuestionCard(
                            question:
                                '1. Apakah benar dosen pengampu pada tanggal dan jam tersebut ada perkuliahan?',
                            isDark: isDark,
                            child: Column(
                              children: [
                                _buildRadioTile(
                                  title: 'Benar',
                                  value: '1',
                                  groupValue: _kesesuaianPerkuliahan,
                                  onChanged: (val) => setState(
                                      () => _kesesuaianPerkuliahan = val!),
                                  isDark: isDark,
                                ),
                                _buildRadioTile(
                                  title: 'Tidak benar',
                                  value: '2',
                                  groupValue: _kesesuaianPerkuliahan,
                                  onChanged: (val) => setState(
                                      () => _kesesuaianPerkuliahan = val!),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Question 2
                          _buildQuestionCard(
                            question:
                                '2. Apakah dosen pengampu memberikan materi perkuliahan mengenai ${_detail?.judulMateri ?? 'materi ini'}?',
                            isDark: isDark,
                            child: Column(
                              children: [
                                _buildRadioTile(
                                  title: 'Ya sesuai',
                                  value: '1',
                                  groupValue: _kesesuaianMateri,
                                  onChanged: (val) =>
                                      setState(() => _kesesuaianMateri = val!),
                                  isDark: isDark,
                                ),
                                _buildRadioTile(
                                  title: 'Tidak sesuai',
                                  value: '2',
                                  groupValue: _kesesuaianMateri,
                                  onChanged: (val) =>
                                      setState(() => _kesesuaianMateri = val!),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Question 3
                          _buildQuestionCard(
                            question:
                                '3. Berikan penilaian saudara terhadap proses perkuliahan yang dilakukan oleh dosen pengampu?',
                            isDark: isDark,
                            child: Column(
                              children: [
                                _buildRadioTile(
                                  title: 'Sangat Baik',
                                  value: '4',
                                  groupValue: _penilaianMhs,
                                  onChanged: (val) =>
                                      setState(() => _penilaianMhs = val!),
                                  isDark: isDark,
                                ),
                                _buildRadioTile(
                                  title: 'Baik',
                                  value: '3',
                                  groupValue: _penilaianMhs,
                                  onChanged: (val) =>
                                      setState(() => _penilaianMhs = val!),
                                  isDark: isDark,
                                ),
                                _buildRadioTile(
                                  title: 'Cukup Baik',
                                  value: '2',
                                  groupValue: _penilaianMhs,
                                  onChanged: (val) =>
                                      setState(() => _penilaianMhs = val!),
                                  isDark: isDark,
                                ),
                                _buildRadioTile(
                                  title: 'Kurang Baik',
                                  value: '1',
                                  groupValue: _penilaianMhs,
                                  onChanged: (val) =>
                                      setState(() => _penilaianMhs = val!),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Question 4 (Kritik & Saran)
                          _buildQuestionCard(
                            question:
                                '4. Berikan kritik dan saran saudara untuk perbaikan perkuliahan (opsional):',
                            isDark: isDark,
                            child: TextField(
                              controller: _kritikSaranController,
                              maxLines: 3,
                              style: AppTextStyles.bodyMedium(isDark),
                              decoration: InputDecoration(
                                hintText: 'Tulis kritik dan saran di sini...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
          ),

          // Action Buttons Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Builder(
                    builder: (context) {
                      final isOnline = ref.watch(networkStatusProvider).isOnline;
                      if (!isOnline) {
                        return ElevatedButton.icon(
                          onPressed: () => ensureOnline(
                            context,
                            ref,
                            message: 'Tidak dapat menyimpan validasi presensi saat offline.',
                          ),
                          icon: const Icon(LucideIcons.wifiOff, size: 16),
                          label: const Text(
                            'Offline (Tidak Dapat Validasi)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: isDark
                                ? const Color(0xFF3B1219)
                                : const Color(0xFFFFECEF),
                            foregroundColor: isDark
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFF991B1B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF7F1D1D)
                                    : const Color(0xFFFCA5A5),
                              ),
                            ),
                          ),
                        );
                      }

                      return ElevatedButton(
                        onPressed:
                            (_isLoading || _isSubmitting || _detail == null)
                                ? null
                                : _handleSave,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.neutral0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.neutral0,
                                ),
                              )
                            : const Text(
                                'Simpan Validasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.caption(isDark)),
          ),
          Expanded(
            child: Text(
              value,
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
    );
  }

  Widget _buildQuestionCard({
    required String question,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: AppTextStyles.labelBold(isDark).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(value);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: groupValue,
              activeColor: AppColors.success,
              // ignore: deprecated_member_use
              onChanged: onChanged,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: AppTextStyles.bodyMedium(isDark).copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
