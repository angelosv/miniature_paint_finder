import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/components/palette_selector.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/components/add_to_wishlist_modal.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/utils/auth_utils.dart';
import 'package:provider/provider.dart';

class PaintGridCard extends StatelessWidget {
  final Paint paint;
  final Color color;
  final Function(String) onAddToWishlist;
  final Function(Paint) onAddToInventory;
  final Function(String, String, String)? onAddToPalette;
  final bool isInWishlist;
  final String? paletteName;

  const PaintGridCard({
    Key? key,
    required this.paint,
    required this.color,
    required this.onAddToWishlist,
    required this.onAddToInventory,
    this.onAddToPalette,
    this.isInWishlist = false,
    this.paletteName,
  }) : super(key: key);

  // Helper para obtener el color de la pintura
  Color _getPaintColor() {
    return Color(int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  // Helper para obtener la URL de la imagen del color desde el JSON de la API
  String _getColorImageUrl() {
    // Este es el campo 'color' que devuelve la API
    return 'https://placehold.co/40/${paint.hex.substring(1)}/000000';
  }

  // Helper para obtener la URL del logo de la marca directamente del parámetro logo_url
  String _getBrandLogoUrl() {
    if (paint.brandLogo != null && paint.brandLogo!.isNotEmpty) {
      return paint.brandLogo!;
    }
    // En una implementación real, esto vendría directamente de la respuesta de la API
    // como un campo "logo_url" en el objeto Paint
    // Aquí simulamos la URL basándonos en la marca
    return 'https://raw.githubusercontent.com/Arcturus5404/miniature-paints/refs/heads/main/logos/${paint.brand.toUpperCase()}.png';
  }

  // Determina si se debe usar texto oscuro o claro basado en el color de fondo
  bool _shouldUseWhiteText(Color backgroundColor) {
    // Calcular el brillo del color (fórmula general: 0.299*R + 0.587*G + 0.114*B)
    final luminance =
        (0.299 * backgroundColor.red +
            0.587 * backgroundColor.green +
            0.114 * backgroundColor.blue) /
        255;

    // Si la luminancia es mayor a 0.5, el color es considerado "claro" y debe usar texto oscuro
    return luminance < 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;

    final paintColor = _getPaintColor();
    final colorImageUrl = _getColorImageUrl();
    final brandLogoUrl = _getBrandLogoUrl();

    // Determinar color de texto basado en el color de fondo
    final useWhiteText = _shouldUseWhiteText(paintColor);
    final textColor = useWhiteText ? Colors.white : Colors.black87;
    final subtextColor =
        useWhiteText ? Colors.white.withOpacity(0.8) : Colors.black54;

    return GestureDetector(
      onTap: () {
        _showPaintOptions(context);
      },
      child: Stack(
        children: [
          // Card principal
          Card(
            elevation: 0,
            color: isDarkMode ? AppTheme.darkSurface : Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Imagen del color que cubre toda la tarjeta (sin adulterar)
                Positioned.fill(
                  child: Image.network(
                    colorImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Si la imagen no carga, mostrar un contenedor con el color puro
                      return Container(color: paintColor);
                    },
                  ),
                ),

                // Contenido de la tarjeta
                Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre de la pintura en la parte superior
                      Text(
                        paint.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Código de la pintura
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: paintColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            paint.hex,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: subtextColor,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      Spacer(),

                      // Fila inferior con logo y nombre de marca
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo de la marca (círculo con iniciales como fallback)
                          Container(
                            width: 28.r,
                            height: 28.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: Image.network(
                                brandLogoUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Center(
                                      child: Text(
                                        paint.brand
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),

                          SizedBox(width: 8.r),

                          // Nombre de la marca y categoría en columna
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paint.brand,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  paint.category,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Indicador de wishlist
          if (isInWishlist)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.r),
                    bottomLeft: Radius.circular(8.r),
                  ),
                ),
                child: Icon(Icons.favorite, size: 14.r, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // Helper para obtener el color según la categoría
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'base':
        return AppTheme.marineBlue;
      case 'layer':
        return AppTheme.marineOrange;
      case 'shade':
      case 'wash':
        return AppTheme.purpleColor;
      case 'dry':
        return AppTheme.greenColor;
      case 'technical':
        return AppTheme.marineGold;
      default:
        return AppTheme.marineBlue;
    }
  }

  void _showPaintOptions(BuildContext context) {
    final paintColor = Color(
      int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000,
    );

    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                ),

                // Paint header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: paintColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paint.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${paint.brand} - ${paint.category}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Color details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Color code',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: paintColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      paint.hex,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'RGB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'R: ${paintColor.red} G: ${paintColor.green} B: ${paintColor.blue}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.qr_code, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Barcode:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            paint.id.split('-').last.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                PaintActionButton(
                  icon: Icons.add_to_photos_outlined,
                  label: 'Add to Palette',
                  onTap: () async {
                    // Check if guest user needs to authenticate
                    if (isGuestUser) {
                      bool canProceed = await AuthUtils.checkFeatureAccess(
                        context,
                        requireAuth: true,
                      );
                      if (!canProceed) {
                        Navigator.pop(context);
                        return;
                      }
                    }

                    if (paletteName != null) {
                      _showCreateModal(context);
                    } else {
                      Navigator.pop(context);
                      _showPaletteSelector(context);
                    }
                  },
                  isOutlined: true,
                  paletteName: paletteName,
                ),

                const SizedBox(height: 8),

                PaintActionButton(
                  icon: isInWishlist ? Icons.favorite : Icons.favorite_border,
                  label:
                      isInWishlist ? 'Remove from Wishlist' : 'Add to Wishlist',
                  onTap: () async {
                    // Check if guest user needs to authenticate
                    if (isGuestUser) {
                      bool canProceed = await AuthUtils.checkFeatureAccess(
                        context,
                        requireAuth: true,
                      );
                      if (!canProceed) {
                        Navigator.pop(context);
                        return;
                      }
                    }

                    Navigator.pop(context);
                    if (isInWishlist) {
                      // Si ya está en la wishlist, simplemente la eliminamos
                      onAddToWishlist(paint.id);
                    } else {
                      // Si no está en la wishlist, mostramos el modal con estrellas
                      _showAddToWishlistModal(context);
                    }
                  },
                  isOutlined: true,
                  color: isInWishlist ? Colors.red : null,
                ),

                const SizedBox(height: 8),

                PaintActionButton(
                  icon: Icons.inventory_2_outlined,
                  label: 'Add to Inventory',
                  onTap: () async {
                    // Check if guest user needs to authenticate
                    if (isGuestUser) {
                      bool canProceed = await AuthUtils.checkFeatureAccess(
                        context,
                        requireAuth: true,
                      );
                      if (!canProceed) {
                        Navigator.pop(context);
                        return;
                      }
                    }

                    onAddToInventory(paint);
                    Navigator.pop(context);
                  },
                  isOutlined: true,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _showPaletteSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PaletteSelectorModal(paint: paint),
    );
  }

  void _addToPalette(BuildContext context, Palette palette, Color paintColor) {
    Navigator.pop(context);

    // Muestra un mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${paint.name} added to "${palette.name}" palette'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCreatePaletteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Palette'),
            content: const Text(
              'Palette creation form will be implemented here',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _showAddToWishlistModal(BuildContext context) {
    // Obtenemos una referencia al ScaffoldMessengerState antes de empezar
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    AddToWishlistModal.show(
      context: context,
      paint: paint,
      onAddToWishlist: (paint, priority, _) async {
        // Mostrar loading
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                SizedBox(width: 16),
                Text('Añadiendo a wishlist...'),
              ],
            ),
            duration: Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
        );

        try {
          // Obtener el usuario actual de Firebase
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser == null) {
            // Si no hay usuario, mostrar error
            scaffoldMessenger.hideCurrentSnackBar();
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Debes iniciar sesión para añadir a wishlist'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final userId = firebaseUser.uid;

          // Llamar directamente a la API
          final paintService = PaintService();

          final result = await paintService.addToWishlistDirect(
            paint,
            priority,
            userId,
          );

          scaffoldMessenger.hideCurrentSnackBar();

          if (result['success'] == true) {
            // Actualizar UI localmente con callback
            onAddToWishlist(paint.id);

            // Mostrar mensaje de éxito
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Added ${paint.name} to wishlist (Priority: $priority, ID: ${result['id']})',
                ),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Mostrar error con detalles
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error: ${result['message']}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Detalles',
                  textColor: Colors.white,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Error Details'),
                            content: SingleChildScrollView(
                              child: Text(result.toString()),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ),
            );
          }
        } catch (e) {
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );
  }

  void _showCreateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                ),

                Text(
                  'Create New Palette',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  initialValue:
                      paletteName ?? 'Enter a name for your new palette',
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Palette Name',
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onAddToPalette!(
                      paletteName ?? "",
                      paint.id ?? "",
                      paint.brandId ?? "",
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Create'),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}

// Helper widget for the action buttons in the modal
class PaintActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isOutlined;
  final Color? color;
  final String? paletteName;

  const PaintActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isOutlined = false,
    this.color,
    this.paletteName,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          alignment: Alignment.centerLeft,
          foregroundColor: color,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [Icon(icon), const SizedBox(width: 12), Text(label)],
      ),
    );
  }
}
