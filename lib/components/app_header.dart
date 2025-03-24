import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool centerTitle;
  final VoidCallback? onBackPressed;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.centerTitle = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final iconColor = isDarkMode ? Colors.white : AppTheme.marineBlue;

    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: iconColor,
          fontSize: ResponsiveGuidelines.headlineSmall,
        ),
      ),
      centerTitle: centerTitle,
      leading:
          showBackButton
              ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: iconColor,
                  size: ResponsiveGuidelines.iconM,
                ),
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              )
              : null,
      backgroundColor: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
      elevation: 0,
      titleSpacing: ResponsiveGuidelines.spacingS,
      actions: [
        // Theme toggle
        IconButton(
          icon: Icon(
            isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: iconColor,
            size: ResponsiveGuidelines.iconM,
          ),
          tooltip: 'Toggle theme',
          onPressed: () {
            final newTheme =
                isDarkMode
                    ? ThemeProvider.LIGHT_THEME
                    : ThemeProvider.DARK_THEME;
            themeProvider.setThemeMode(newTheme);
          },
        ),
        // Custom actions with correct color
        if (actions != null)
          ...actions!.map((action) {
            if (action is IconButton) {
              return IconButton(
                icon: Icon(
                  (action.icon as Icon).icon,
                  color: iconColor,
                  size: ResponsiveGuidelines.iconM,
                ),
                onPressed: action.onPressed,
                tooltip: action.tooltip,
              );
            }
            return action;
          }),
        SizedBox(width: ResponsiveGuidelines.spacingS),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight.h);
}
