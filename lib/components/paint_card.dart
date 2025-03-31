import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_dimensions.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';

class PaintCard extends StatelessWidget {
  final Paint paint;
  final int paletteCount;
  final Function(Paint)? onTap;

  const PaintCard({
    super.key,
    required this.paint,
    this.paletteCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusL),
              topRight: Radius.circular(AppDimensions.radiusL),
            ),
            onTap: () {
              if (onTap != null) {
                onTap!(paint);
              } else {
                // Si no hay onTap personalizado, abre el modal de inventario
                _showPaintInventoryModal(context, paint);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  Container(
                    width: AppDimensions.iconXXL,
                    height: AppDimensions.iconXXL,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(paint.colorHex.substring(1, 7), radix: 16) +
                            0xFF000000,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusS,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.marginL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(paint.name, style: textTheme.titleSmall),
                        const SizedBox(height: AppDimensions.marginXS),
                        Row(
                          children: [
                            Text(
                              paint.brand,
                              style: textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            if (paletteCount > 0) ...[
                              const SizedBox(width: AppDimensions.marginS),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingS,
                                  vertical: AppDimensions.paddingXS,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? AppTheme.drawerOrange.withOpacity(
                                            0.2,
                                          )
                                          : AppTheme.primaryBlue.withOpacity(
                                            0.1,
                                          ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusS,
                                  ),
                                ),
                                child: Text(
                                  'Used in $paletteCount palettes',
                                  style: textTheme.bodySmall?.copyWith(
                                    color:
                                        isDarkMode
                                            ? AppTheme.drawerOrange
                                            : AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textGrey,
                    size: AppDimensions.iconM,
                  ),
                ],
              ),
            ),
          ),
          // Añadimos los botones de acción rápida
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              0,
              AppDimensions.paddingM,
              AppDimensions.paddingM,
            ),
            child: Row(
              children: [
                // Actualizar inventario
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Mostrar un diálogo de confirmación con opciones
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          int quantity = 1;

                          return AlertDialog(
                            title: Text('Update Inventory'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${paint.name} will be added to your inventory.',
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Quantity: '),
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline),
                                      onPressed: () {
                                        if (quantity > 1) {
                                          quantity--;
                                          (context as Element).markNeedsBuild();
                                        }
                                      },
                                    ),
                                    Text(
                                      '$quantity',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        quantity++;
                                        (context as Element).markNeedsBuild();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);

                                  // Mostrar confirmación con SnackBar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Added $quantity ${paint.name} to inventory',
                                      ),
                                      backgroundColor:
                                          isDarkMode
                                              ? AppTheme.drawerOrange
                                              : AppTheme.primaryBlue,
                                      action: SnackBarAction(
                                        label: 'VIEW',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const InventoryScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Text('Confirm'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: const Text(
                      'Update Inventory',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDarkMode
                              ? AppTheme.drawerOrange
                              : AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Añadir a wishlist
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Mostrar un diálogo para añadir a wishlist
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          final notesController = TextEditingController();
                          int priority = 2; // Prioridad media por defecto

                          return AlertDialog(
                            title: Text('Add to Wishlist'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${paint.name} will be added to your wishlist.',
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text('Priority: '),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Slider(
                                        value: priority.toDouble(),
                                        min: 1,
                                        max: 3,
                                        divisions: 2,
                                        label:
                                            priority == 1
                                                ? 'Low'
                                                : priority == 2
                                                ? 'Medium'
                                                : 'High',
                                        onChanged: (double value) {
                                          priority = value.toInt();
                                          (context as Element).markNeedsBuild();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                TextField(
                                  controller: notesController,
                                  decoration: InputDecoration(
                                    labelText: 'Notes (optional)',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);

                                  // Mostrar confirmación con SnackBar
                                  final priorityText =
                                      priority == 1
                                          ? 'Low'
                                          : priority == 2
                                          ? 'Medium'
                                          : 'High';

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Added ${paint.name} to wishlist with $priorityText priority',
                                      ),
                                      backgroundColor: Colors.pink,
                                      action: SnackBarAction(
                                        label: 'VIEW',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const InventoryScreen(), // Cambiar a WishlistScreen cuando esté disponible
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Text('Confirm'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.favorite_border, size: 16),
                    label: const Text(
                      'Add to Wishlist',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaintInventoryModal(BuildContext context, Paint paint) {
    // Crear un objeto de inventario temporal para mostrar en el modal
    final inventoryItem = PaintInventoryItem(
      paint: paint,
      stock: paint.id.hashCode % 5, // Stock simulado
      notes: '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final paintColor = Color(
          int.parse(paint.colorHex.substring(1, 7), radix: 16) + 0xFF000000,
        );

        // Controller para notas
        final notesController = TextEditingController();

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
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Encabezado con detalles de la pintura
              Row(
                children: [
                  // Color swatch
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: paintColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Detalles de la pintura
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paint.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          paint.brand,
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Used in $paletteCount palettes',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? AppTheme.drawerOrange
                                    : AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Separador
              Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[300]),

              const SizedBox(height: 16),

              // Opciones de acción
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // Inventario rápido y opciones de wishlist
              Row(
                children: [
                  // Actualizar inventario
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);

                        // Mostrar un diálogo de confirmación con opciones
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            int quantity = 1;

                            return AlertDialog(
                              title: Text('Update Inventory'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${paint.name} will be added to your inventory.',
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Quantity: '),
                                      SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          if (quantity > 1) {
                                            quantity--;
                                            (context as Element)
                                                .markNeedsBuild();
                                          }
                                        },
                                      ),
                                      Text(
                                        '$quantity',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          quantity++;
                                          (context as Element).markNeedsBuild();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);

                                    // Mostrar confirmación con SnackBar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Added $quantity ${paint.name} to inventory',
                                        ),
                                        backgroundColor:
                                            isDarkMode
                                                ? AppTheme.drawerOrange
                                                : AppTheme.primaryBlue,
                                        action: SnackBarAction(
                                          label: 'VIEW',
                                          textColor: Colors.white,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const InventoryScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('Confirm'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Update Inventory'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDarkMode
                                ? AppTheme.drawerOrange
                                : AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Añadir a wishlist
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);

                        // Mostrar un diálogo para añadir a wishlist
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            final notesController = TextEditingController();
                            int priority = 2; // Prioridad media por defecto

                            return AlertDialog(
                              title: Text('Add to Wishlist'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${paint.name} will be added to your wishlist.',
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Text('Priority: '),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Slider(
                                          value: priority.toDouble(),
                                          min: 1,
                                          max: 3,
                                          divisions: 2,
                                          label:
                                              priority == 1
                                                  ? 'Low'
                                                  : priority == 2
                                                  ? 'Medium'
                                                  : 'High',
                                          onChanged: (double value) {
                                            priority = value.toInt();
                                            (context as Element)
                                                .markNeedsBuild();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  TextField(
                                    controller: notesController,
                                    decoration: InputDecoration(
                                      labelText: 'Notes (optional)',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);

                                    // Mostrar confirmación con SnackBar
                                    final priorityText =
                                        priority == 1
                                            ? 'Low'
                                            : priority == 2
                                            ? 'Medium'
                                            : 'High';

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Added ${paint.name} to wishlist with $priorityText priority',
                                        ),
                                        backgroundColor: Colors.pink,
                                        action: SnackBarAction(
                                          label: 'VIEW',
                                          textColor: Colors.white,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const InventoryScreen(), // Cambiar a WishlistScreen cuando esté disponible
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('Confirm'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Add to Wishlist'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Botón para ir a My Inventory
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('View in My Inventory'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InventoryScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode
                            ? AppTheme.drawerOrange
                            : AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXS,
        vertical: AppDimensions.paddingXS / 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.marineBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      ),
      child: Text(
        paint.category,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.marineBlue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMetallicChip(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: AppDimensions.marginXS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXS,
        vertical: AppDimensions.paddingXS / 2,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      ),
      child: const Text('Metallic', style: TextStyle(fontSize: 10)),
    );
  }
}
