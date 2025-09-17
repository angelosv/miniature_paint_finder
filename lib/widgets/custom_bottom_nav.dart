import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/widgets/guest_promo_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final double itemWidth = 90.0; // Ancho fijo para cada item
    
    // Lista de items de navegación
    final List<Map<String, dynamic>> navItems = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Home',
        'index': 0,
        'isRestricted': false,
      },
      {
        'icon': Icons.grid_view_outlined,
        'activeIcon': Icons.grid_view,
        'label': 'Library',
        'index': 1,
        'isRestricted': false,
      },
      {
        'icon': Icons.art_track_outlined,
        'activeIcon': Icons.art_track,
        'label': 'Projects',
        'index': 5,
        'isRestricted': true,
        'featureName': 'Projects',
      },
      {
        'icon': Icons.inventory_outlined,
        'activeIcon': Icons.inventory,
        'label': 'Inventory',
        'index': 2,
        'isRestricted': true,
        'featureName': 'Inventory',
      },
      {
        'icon': Icons.favorite_outline,
        'activeIcon': Icons.favorite,
        'label': 'Wishlist',
        'index': 3,
        'isRestricted': true,
        'featureName': 'Wishlist',
      },
      {
        'icon': Icons.palette_outlined,
        'activeIcon': Icons.palette,
        'label': 'Palettes',
        'index': 4,
        'isRestricted': true,
        'featureName': 'Palettes',
      },
    ];

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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: navItems.map((item) {
            return _buildNavItem(
              context: context,
              icon: item['icon'],
              activeIcon: item['activeIcon'],
              label: item['label'],
              index: item['index'],
              isDarkMode: isDarkMode,
              width: itemWidth,
              isRestricted: item['isRestricted'],
              featureName: item['featureName'],
            );
          }).toList(),
        ),
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
          final currentUser = FirebaseAuth.instance.currentUser;
          final isGuestUser = currentUser == null || currentUser.isAnonymous;
          if (isGuestUser) {
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