import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// A widget that displays a placeholder for palettes based on faction name
class PaletteFactionPlaceholder extends StatelessWidget {
  /// The name of the palette/faction
  final String paletteName;

  /// Creates a faction-specific placeholder for palettes
  const PaletteFactionPlaceholder({Key? key, required this.paletteName})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine background and foreground colors based on faction name
    final (backgroundColor, foregroundColor, icon) = _getFactionTheme(
      paletteName,
      isDarkMode,
    );

    return Container(
      height: double.infinity,
      width: double.infinity,
      color: backgroundColor,
      child: Stack(
        children: [
          // Faction icon in the center
          Center(
            child: Icon(
              icon,
              size: 60,
              color: foregroundColor.withOpacity(0.2),
            ),
          ),

          // Faction name
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                paletteName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns appropriate colors and icon for each faction
  (Color, Color, IconData) _getFactionTheme(
    String paletteName,
    bool isDarkMode,
  ) {
    final name = paletteName.toLowerCase();

    // Space Marines (blue theme)
    if (name.contains('space marine') || name.contains('ultramarine')) {
      return (
        const Color(0xFF0D407F), // Macragge Blue
        Colors.white,
        Icons.shield,
      );
    }
    // Blood Angels (red theme)
    else if (name.contains('blood angel')) {
      return (
        const Color(0xFF9A1115), // Mephiston Red
        const Color(0xFFFFD700), // Gold
        Icons.bloodtype,
      );
    }
    // Orks (green theme)
    else if (name.contains('ork')) {
      return (
        const Color(0xFF00401A), // Caliban Green
        const Color(0xFFFBB81C), // Averland Sunset
        Icons.sports_kabaddi,
      );
    }
    // Imperial Guard (khaki theme)
    else if (name.contains('imperial guard') ||
        name.contains('astra militarum')) {
      return (
        const Color(0xFFB7975F), // Zandri Dust
        const Color(0xFF2A3439), // Dark Grey
        Icons.person_4,
      );
    }
    // Necrons (silver theme)
    else if (name.contains('necron')) {
      return (
        const Color(0xFF2A3439), // Dark Grey
        const Color(0xFFC0C0C0), // Silver
        Icons.android,
      );
    }
    // Eldar (yellow/blue theme)
    else if (name.contains('eldar') || name.contains('craftworld')) {
      return (
        const Color(0xFFFBB81C), // Averland Sunset
        const Color(0xFF0D407F), // Macragge Blue
        Icons.flash_on,
      );
    }
    // T'au (grey/red theme)
    else if (name.contains('tau') || name.contains('t\'au')) {
      return (
        const Color(0xFF2A3439), // Dark Grey
        const Color(0xFF9A1115), // Mephiston Red
        Icons.radar,
      );
    }
    // Death Guard (khaki/green theme)
    else if (name.contains('death guard')) {
      return (
        const Color(0xFFB7975F), // Zandri Dust
        const Color(0xFF00401A), // Caliban Green
        Icons.coronavirus,
      );
    }
    // Tyranids (purple theme)
    else if (name.contains('tyranid')) {
      return (
        const Color(0xFF69385C), // Druchii Violet
        const Color(0xFF9A1115), // Mephiston Red
        Icons.bug_report,
      );
    }

    // Default theme for unknown factions
    return (
      isDarkMode ? AppTheme.marineBlueDark : AppTheme.marineBlue,
      isDarkMode ? AppTheme.drawerOrange : AppTheme.marineOrange,
      Icons.palette,
    );
  }
}
