import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/widgets/guest_promo_modal.dart';
import 'package:provider/provider.dart';

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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth =
        screenWidth / 4; // Dividir el ancho entre 4 elementos

    // Obtener el padding inferior para evitar que se oculte por la barra de navegación
    final EdgeInsets viewPadding = MediaQuery.of(context).viewPadding;
    final double bottomPadding =
        viewPadding.bottom > 0 ? viewPadding.bottom : 10.0;

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
      height: 72 + bottomPadding, // Altura total incluyendo margen inferior
      padding: EdgeInsets.only(
        bottom: bottomPadding,
      ), // Aplicar padding inferior
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
            width: itemWidth,
            isRestricted: false,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.inventory_outlined,
            activeIcon: Icons.inventory,
            label: 'My Inventory',
            index: 1,
            isDarkMode: isDarkMode,
            width: itemWidth,
            isRestricted: true,
            featureName: 'Inventory',
          ),
          _buildNavItem(
            context: context,
            icon: Icons.favorite_outline,
            activeIcon: Icons.favorite,
            label: 'Wishlist',
            index: 2,
            isDarkMode: isDarkMode,
            width: itemWidth,
            isRestricted: true,
            featureName: 'Wishlist',
          ),
          _buildNavItem(
            context: context,
            icon: Icons.palette_outlined,
            activeIcon: Icons.palette,
            label: 'My Palettes',
            index: 3, // Cambiado de 4 a 3 ya que eliminamos Library
            isDarkMode: isDarkMode,
            width: itemWidth,
            isRestricted: true,
            featureName: 'Palettes',
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
    required double width,
    bool isRestricted = false,
    String? featureName,
  }) {
    final isSelected = currentIndex == index;

    // Colores según el tema y selección
    final Color activeColor =
        isDarkMode
            ? Colors
                .white // Blanco en modo oscuro
            : AppTheme.marineBlue; // Azul marino en modo claro

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
        if (isRestricted) {
          // Check if user is a guest
          final authService = Provider.of<IAuthService>(context, listen: false);
          if (authService.isGuestUser) {
            // Show guest promo modal for this feature
            GuestPromoModal.showForRestrictedFeature(
              context,
              featureName ?? 'Premium Features',
            );
            return;
          }
        }

        // Continue with normal navigation if user is not a guest or feature is not restricted
        Future.microtask(() {
          if (context.mounted) {
            onItemSelected(index);
          }
        });
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26, // Aumentado ligeramente para mejor visibilidad
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11, // Aumentado ligeramente para mejor legibilidad
                fontWeight:
                    isSelected || isDarkMode
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
