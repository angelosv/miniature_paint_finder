import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// Un componente para mostrar una pintura en una paleta
class PalettePaintCard extends StatelessWidget {
  /// La pintura seleccionada
  final PaintSelection paint;

  /// Indica si está en el inventario
  final bool isInInventory;

  /// Indica si está en la lista de deseos
  final bool isInWishlist;

  /// Indica si está en modo de edición
  final bool isEditMode;

  /// Función para manejar el toque
  final VoidCallback? onTap;

  /// Función para manejar la eliminación
  final VoidCallback? onRemove;

  /// Indica si debe mostrar el porcentaje de coincidencia
  final bool showMatchPercentage;

  /// Constructor del componente
  const PalettePaintCard({
    super.key,
    required this.paint,
    this.isInInventory = false,
    this.isInWishlist = false,
    this.isEditMode = false,
    this.onTap,
    this.onRemove,
    this.showMatchPercentage = false,
  });

  Color _getMatchColor(int matchPercentage) {
    if (matchPercentage >= 90) {
      return Colors.green;
    } else if (matchPercentage >= 75) {
      return Colors.amber;
    } else {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(paint.paintId),
      direction:
          isEditMode ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (isEditMode && onRemove != null) {
          onRemove!();
          return true;
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: isEditMode ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Top part with paint info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Brand Avatar
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[200],
                      child: Text(
                        paint.brandAvatar,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Paint name and brand
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paint.paintName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            paint.paintBrand,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Match percentage badge (opcional)
                    if (showMatchPercentage)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getMatchColor(
                            paint.matchPercentage,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${paint.matchPercentage}% match',
                          style: TextStyle(
                            color: _getMatchColor(paint.matchPercentage),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // Status icons (inventory/wishlist)
                    if (isInInventory)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          size: 16,
                          color: Colors.green,
                        ),
                      )
                    else if (isInWishlist)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.marineOrange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite,
                          size: 16,
                          color: AppTheme.marineOrange,
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom part with color code and barcode
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    // Color code with sample
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: paint.paintColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Color code:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              paint.paintId.split('-').last,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Barcode section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Barcode:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.qr_code,
                              size: 16,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '50119${paint.paintId.hashCode.abs() % 10000000}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
