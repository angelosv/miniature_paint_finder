import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';

/// Callback para las diferentes acciones en el modal
typedef PaintActionCallback = void Function(String paintId);

/// Componente de modal para mostrar opciones de una pintura
class PaintOptionsModal extends StatelessWidget {
  /// Pintura que se está mostrando
  final Paint paint;

  /// Si la pintura está en la wishlist
  final bool isInWishlist;

  /// Callback cuando se añade a la wishlist
  final PaintActionCallback? onAddToWishlist;

  /// Callback cuando se añade al inventario
  final PaintActionCallback? onAddToInventory;

  /// Callback cuando se selecciona 'Añadir a paleta'
  final PaintActionCallback? onAddToPalette;

  /// Constructor del modal de opciones
  const PaintOptionsModal({
    super.key,
    required this.paint,
    required this.isInWishlist,
    this.onAddToWishlist,
    this.onAddToInventory,
    this.onAddToPalette,
  });

  @override
  Widget build(BuildContext context) {
    final paintColor = Color(
      int.parse(paint.colorHex.substring(1, 7), radix: 16) + 0xFF000000,
    );

    return Container(
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
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paint.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                                paint.colorHex,
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
            onTap: () {
              if (onAddToPalette != null) {
                onAddToPalette!(paint.id);
              }
              Navigator.pop(context);
            },
            isOutlined: true,
          ),

          const SizedBox(height: 8),

          PaintActionButton(
            icon: isInWishlist ? Icons.favorite : Icons.favorite_border,
            label: isInWishlist ? 'Remove from Wishlist' : 'Add to Wishlist',
            onTap: () {
              if (onAddToWishlist != null) {
                onAddToWishlist!(paint.id);
              }
              Navigator.pop(context);
            },
            isOutlined: true,
            color: isInWishlist ? Colors.red : null,
          ),

          const SizedBox(height: 8),

          PaintActionButton(
            icon: Icons.inventory_2_outlined,
            label: 'Add to Inventory',
            onTap: () {
              if (onAddToInventory != null) {
                onAddToInventory!(paint.id);
              }
              Navigator.pop(context);
            },
            isOutlined: true,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Método estático para mostrar el modal
  static void show({
    required BuildContext context,
    required Paint paint,
    required bool isInWishlist,
    PaintActionCallback? onAddToWishlist,
    PaintActionCallback? onAddToInventory,
    PaintActionCallback? onAddToPalette,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => PaintOptionsModal(
            paint: paint,
            isInWishlist: isInWishlist,
            onAddToWishlist: onAddToWishlist,
            onAddToInventory: onAddToInventory,
            onAddToPalette: onAddToPalette,
          ),
    );
  }
}

/// Botón de acción para el modal
class PaintActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isOutlined;
  final Color? color;

  const PaintActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isOutlined = false,
    this.color,
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
