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

  /// Constructor del componente
  const PalettePaintCard({
    super.key,
    required this.paint,
    this.isInInventory = false,
    this.isInWishlist = false,
    this.isEditMode = false,
    this.onTap,
    this.onRemove,
  });

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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Color de la pintura
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: paint.paintColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),

                // Información de la pintura
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paint.paintName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${paint.paintBrand} · ${paint.paintId.split('-').last}',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Iconos de estado
                Row(
                  children: [
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
                    const SizedBox(width: 8),
                    if (!isEditMode)
                      Icon(
                        Icons.more_vert,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
