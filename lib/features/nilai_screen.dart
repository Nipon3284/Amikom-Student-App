import '../core/network/network_status.dart';
import '../core/widgets/amikom_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/providers/portal_provider.dart';
import '../core/models/khs_item.dart';
import '../core/widgets/shimmer_loading.dart';
import '../core/widgets/status_badge.dart';
import '../core/widgets/empty_state_view.dart';

class NilaiScreen extends ConsumerStatefulWidget {
  const NilaiScreen({super.key});

  @override
  ConsumerState<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends ConsumerState<NilaiScreen> {
  final List<String> _tahunOptions = ['2024/2025', '2023/2024', '2025/2026'];
  String _selectedTahun = '2024/2025';
  int _selectedSemester = 1; // 1 = Gasal, 2 = Genap

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final isOnline = ref.read(networkStatusProvider).isOnline;
    if (!isOnline && mounted) {
      ensureOnline(context, ref, message: 'Tidak dapat mengambil KHS terbaru saat offline.');
    }
    ref.read(khsNotifierProvider.notifier).fetch(
          thn: _selectedTahun,
          smt: _selectedSemester,
        );
  }

  BadgeVariant _getGradeVariant(String grade) {
    final clean = grade.toUpperCase().trim();
    if (clean.startsWith('A')) return BadgeVariant.success;
    if (clean.startsWith('B')) return BadgeVariant.info;
    if (clean.startsWith('C')) return BadgeVariant.warning;
    if (clean.startsWith('D') || clean.startsWith('E')) return BadgeVariant.danger;
    return BadgeVariant.neutral;
  }

  void _showGpaSimulator(KhsResult khs) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GpaSimulatorSheet(khs: khs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final khsAsync = ref.watch(khsNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: AmikomBackground(
        child: Column(
        children: [
          // Filter Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Academic Year Dropdown
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTahun,
                        isExpanded: true,
                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        style: AppTextStyles.labelBold(isDark),
                        items: _tahunOptions.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedTahun = val);
                            _loadData();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Semester Selector Toggle
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_selectedSemester != 1) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedSemester = 1);
                                _loadData();
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedSemester == 1
                                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                'Gasal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedSemester == 1
                                      ? (isDark ? AppColors.neutral950 : AppColors.neutral0)
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_selectedSemester != 2) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedSemester = 2);
                                _loadData();
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedSemester == 2
                                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                'Genap',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedSemester == 2
                                      ? (isDark ? AppColors.neutral950 : AppColors.neutral0)
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: khsAsync.when(
              data: (khs) {
                if (khs.items.isEmpty) {
                  return EmptyStateView(
                    title: 'Nilai Belum Tersedia',
                    description: 'Belum ada data nilai pada semester $_selectedTahun (${_selectedSemester == 1 ? 'Gasal' : 'Genap'}).',
                    icon: LucideIcons.fileSpreadsheet,
                    actionLabel: 'Refresh',
                    onAction: _loadData,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Semester Summary Card
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
                              Text(
                                'Indeks Prestasi Semester (IPS)',
                                style: AppTextStyles.caption(isDark),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    khs.ips.toStringAsFixed(2),
                                    style: AppTextStyles.displayMedium(isDark).copyWith(
                                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${khs.totalSks} SKS',
                                    style: AppTextStyles.labelBold(isDark),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showGpaSimulator(khs),
                            icon: const Icon(LucideIcons.calculator, size: 15),
                            label: const Text('Simulasi'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text('Rincian Mata Kuliah (${khs.items.length})', style: AppTextStyles.titleMedium(isDark)),
                    const SizedBox(height: 12),

                    // Grade List
                    ...khs.items.map((item) {
                      final variant = _getGradeVariant(item.nilai);
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
                            // Grade Chip
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  item.nilai,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: variant == BadgeVariant.success
                                        ? AppColors.success
                                        : variant == BadgeVariant.info
                                            ? AppColors.info
                                            : variant == BadgeVariant.warning
                                                ? AppColors.warning
                                                : AppColors.danger,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Course Title and Info
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
                                    '${item.kode} • ${item.sks} SKS • Bobot: ${item.bobot}',
                                    style: AppTextStyles.bodySmall(isDark),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              label: item.ambilKe == 'B' ? 'Baru' : 'Ulang',
                              variant: BadgeVariant.neutral,
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
                title: 'Gagal Memuat KHS',
                description: 'Terjadi kendala saat mengambil data kartu hasil studi.',
                icon: LucideIcons.alertTriangle,
                actionLabel: 'Coba Lagi',
                onAction: _loadData,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

/// Interactive GPA Simulator Sheet
class _GpaSimulatorSheet extends StatefulWidget {
  final KhsResult khs;
  const _GpaSimulatorSheet({required this.khs});

  @override
  State<_GpaSimulatorSheet> createState() => _GpaSimulatorSheetState();
}

class _GpaSimulatorSheetState extends State<_GpaSimulatorSheet> {
  late Map<String, String> _simulatedGrades;
  final Map<String, double> _gradeWeight = {
    'A': 4.0,
    'A-': 3.75,
    'B+': 3.5,
    'B': 3.0,
    'B-': 2.75,
    'C+': 2.5,
    'C': 2.0,
    'D': 1.0,
    'E': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _simulatedGrades = {
      for (final item in widget.khs.items) item.kode: item.nilai.isNotEmpty ? item.nilai : 'A'
    };
  }

  double _calculateSimulatedIps() {
    double totalBobot = 0;
    int totalSks = 0;

    for (final item in widget.khs.items) {
      final grade = _simulatedGrades[item.kode] ?? 'B';
      final weight = _gradeWeight[grade] ?? 3.0;
      totalBobot += weight * item.sks;
      totalSks += item.sks;
    }

    return totalSks > 0 ? (totalBobot / totalSks) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final simulatedIps = _calculateSimulatedIps();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
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

          // Header & Real-time Simulated Score
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Simulator Target IPS', style: AppTextStyles.titleMedium(isDark)),
                    const SizedBox(height: 2),
                    Text('Ubah target nilai untuk melihat simulasi IPS', style: AppTextStyles.caption(isDark)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        simulatedIps.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.purple300 : AppColors.purple800,
                        ),
                      ),
                      Text(
                        'Target IPS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.purple300 : AppColors.purple800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),

          // Course grade tweaks
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: widget.khs.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = widget.khs.items[index];
                final currentGrade = _simulatedGrades[item.kode] ?? 'B';

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.mkl, style: AppTextStyles.labelBold(isDark)),
                          Text('${item.sks} SKS', style: AppTextStyles.caption(isDark)),
                        ],
                      ),
                    ),
                    DropdownButton<String>(
                      value: _gradeWeight.containsKey(currentGrade) ? currentGrade : 'A',
                      items: _gradeWeight.keys.map((g) {
                        return DropdownMenuItem(value: g, child: Text(g));
                      }).toList(),
                      onChanged: (newGrade) {
                        if (newGrade != null) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _simulatedGrades[item.kode] = newGrade;
                          });
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
