import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// Widget personalizado para la barra de navegación inferior
/// Este widget se usará en todas las pantallas de la aplicación
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      height: 80,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            index: 0,
            isDarkMode: isDarkMode,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.inventory_outlined,
            activeIcon: Icons.inventory,
            label: 'Inventory',
            index: 1,
            isDarkMode: isDarkMode,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.favorite_outline,
            activeIcon: Icons.favorite,
            label: 'Wishlist',
            index: 2,
            isDarkMode: isDarkMode,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view,
            label: 'Library',
            index: 3,
            isDarkMode: isDarkMode,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.palette_outlined,
            activeIcon: Icons.palette,
            label: 'My Palettes',
            index: 4,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDarkMode,
  }) {
    final isSelected = currentIndex == index;

    // Colores según el tema y selección
    final Color activeColor =
        isDarkMode
            ? Colors
                .white // Blanco en modo oscuro
            : AppTheme
                .marineBlue; // Azul marino en modo claro (igual que el side menu)

    final Color inactiveColor =
        isDarkMode
            ? Colors.white.withOpacity(
              0.6,
            ) // Blanco con opacidad en modo oscuro
            : AppTheme.marineBlue.withOpacity(
              0.6,
            ); // Azul marino con opacidad en modo claro

    return InkWell(
      onTap: () {
        // Safely handle tap with a small delay to prevent framework errors
        Future.microtask(() {
          if (context.mounted) {
            onItemSelected(index);
          }
        });
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isSelected ? activeColor : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 12,
                fontWeight:
                    isSelected || isDarkMode
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
