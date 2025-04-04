import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppTheme.textDark;
    final subtitleColor = isDarkMode ? Colors.white70 : AppTheme.textGrey;
    final iconColor =
        isDarkMode ? AppTheme.marineBlueLight : AppTheme.marineBlue;

    return Container(
      margin: EdgeInsets.only(bottom: 8.r),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8.r, horizontal: 4.r),
        leading: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: iconColor, size: 22.r),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
            color: textColor,
          ),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle!,
                  style: TextStyle(fontSize: 14.sp, color: subtitleColor),
                )
                : null,
        trailing:
            trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16.r,
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
        onTap: onTap,
      ),
    );
  }
}
