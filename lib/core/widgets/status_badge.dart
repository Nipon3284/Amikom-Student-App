import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum BadgeVariant { success, warning, danger, info, neutral, primary, gold }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    switch (variant) {
      case BadgeVariant.success:
        bg = isDark ? const Color(0xFF064E3B) : AppColors.successContainer;
        fg = isDark ? const Color(0xFF6EE7B7) : AppColors.successText;
        border = isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0);
        break;
      case BadgeVariant.gold:
      case BadgeVariant.warning:
        bg = isDark ? AppColors.amikomGoldDarkContainer : AppColors.amikomGoldContainer;
        fg = isDark ? AppColors.amikomGoldDarkText : AppColors.amikomGoldText;
        border = isDark ? AppColors.amikomGoldDark : const Color(0xFFFDE68A);
        break;
      case BadgeVariant.danger:
        bg = isDark ? const Color(0xFF7F1D1D) : AppColors.dangerContainer;
        fg = isDark ? const Color(0xFFFCA5A5) : AppColors.dangerText;
        border = isDark ? const Color(0xFFB91C1C) : const Color(0xFFFECACA);
        break;
      case BadgeVariant.info:
        bg = isDark ? const Color(0xFF1E3A8A) : AppColors.infoContainer;
        fg = isDark ? const Color(0xFF93C5FD) : AppColors.infoText;
        border = isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE);
        break;
      case BadgeVariant.primary:
        bg = isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer;
        fg = isDark ? AppColors.amikomPurpleLight : AppColors.amikomPurple;
        border = isDark ? AppColors.amikomPurple : AppColors.purple200;
        break;
      case BadgeVariant.neutral:
        bg = isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle;
        fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.caption(isDark).copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
