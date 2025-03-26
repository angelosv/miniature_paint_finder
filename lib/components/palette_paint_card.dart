import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/theme/app_responsive.dart';

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

  /// Indica si debe mostrar el porcentaje de coincidencia
  final bool showMatchPercentage;

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
    this.showMatchPercentage = true,
    this.onTap,
    this.onRemove,
  });

  Color _getMatchColor(int matchPercentage) {
    if (matchPercentage >= 90) return Colors.green;
    if (matchPercentage >= 75) return Colors.amber;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Usar utilidades responsive en lugar de cálculos manuales
    final avatarRadius = AppResponsive.getAdaptiveValue(
      context: context,
      defaultValue: 25.0,
      mobile: 20.0,
    );

    final titleFontSize = AppResponsive.getAdaptiveFontSize(
      context,
      18.0,
      minFontSize: 16.0,
    );

    final brandFontSize = AppResponsive.getAdaptiveFontSize(
      context,
      16.0,
      minFontSize: 14.0,
    );

    final badgeFontSize = AppResponsive.getAdaptiveFontSize(
      context,
      14.0,
      minFontSize: 12.0,
    );

    final padding = AppResponsive.getAdaptivePadding(
      context: context,
      defaultPadding: const EdgeInsets.all(12.0),
      mobilePadding: const EdgeInsets.all(8.0),
    );

    final spacing = AppResponsive.getAdaptiveSpacing(context, 12.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar con la primera letra de la marca
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    child: Text(
                      paint.brandAvatar,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Información de la pintura
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paint.paintName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
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

                  // Porcentaje de coincidencia
                  if (showMatchPercentage)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getMatchColor(
                          paint.matchPercentage,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${paint.matchPercentage}% match',
                        style: TextStyle(
                          color: _getMatchColor(paint.matchPercentage),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Sección inferior con código de color y código de barras
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Sección de código de color
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: paint.paintColor,
                            borderRadius: BorderRadius.circular(6),
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
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Sección de código de barras
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
                                fontSize: 14,
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
