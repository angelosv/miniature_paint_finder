import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/most_used_paint.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/paint_inventory_item.dart';
import 'package:miniature_paint_finder/services/brand_service_manager.dart';
import 'package:miniature_paint_finder/services/inventory_service.dart';
import 'package:miniature_paint_finder/theme/app_dimensions.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';
import 'package:miniature_paint_finder/components/add_to_wishlist_modal.dart';
import 'package:miniature_paint_finder/components/add_to_inventory_modal.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaintCard extends StatefulWidget {
  final Paint paint;
  final int paletteCount;
  final Function(Paint, List<PaletteInfo> paletteInfo)? onTap;
  final List<PaletteInfo> paletteInfo;
  final bool inInventory;
  final bool inWishlist;
  final String? inventoryId;
  final String? wishlistId;

  const PaintCard({
    super.key,
    required this.paint,
    this.paletteCount = 0,
    this.onTap,
    this.paletteInfo = const [],
    this.inInventory = false,
    this.inWishlist = false,
    this.inventoryId,
    this.wishlistId,
  });

  @override
  _PaintCardState createState() => _PaintCardState();
}

class _PaintCardState extends State<PaintCard> {
  final InventoryService _inventoryService = InventoryService();
  final PaintService _paintService = PaintService();

  final BrandServiceManager _brandManager = BrandServiceManager();
  late bool _inInventory;
  String? _inventoryId;

  late bool _inWishlist;
  String? _wishlistId;

  @override
  void initState() {
    super.initState();
    _inInventory = widget.inInventory;
    _inventoryId = widget.inventoryId;

    _inWishlist = widget.inWishlist;
    _wishlistId = widget.wishlistId;
  }

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
              if (widget.onTap != null) {
                widget.onTap!(widget.paint, widget.paletteInfo);
              } else {
                // Si no hay onTap personalizado, abre el modal de inventario
                _showPaintInventoryModal(context, widget.paint);
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
                        int.parse(widget.paint.hex.substring(1, 7), radix: 16) +
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
                        Text(widget.paint.name, style: textTheme.titleSmall),
                        const SizedBox(height: AppDimensions.marginXS),
                        Row(
                          children: [
                            Text(
                              widget.paint.brand,
                              style: textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            if (widget.paletteCount > 0) ...[
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
                                  'Used in ${widget.paletteCount} palettes',
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
                      // Mostrar el nuevo modal de inventario
                      AddToInventoryModal.show(
                        context: context,
                        paint: widget.paint,
                        inventoryId: _inventoryId,
                        initialQuantity: 1,
                        initialNotes: null,
                        onAddToInventory: (
                          paint,
                          quantity,
                          notes,
                          inventoryId,
                        ) async {
                          String? newId = inventoryId;

                          if (inventoryId != null) {
                            // ─── ACTUALIZAR EXISTENTE ───
                            bool success = await _inventoryService
                                .updateInventoryRecord(
                                  inventoryId,
                                  quantity,
                                  notes as String,
                                );

                            if (!success) {
                              return null;
                            }
                          } else {
                            final brandId = _brandManager
                                .determineBrandIdForPaint(paint);
                            final inventoryId = await _inventoryService
                                .addInventoryRecordReturningId(
                                  brandId: brandId,
                                  paintId: paint.id,
                                  quantity: quantity,
                                  notes: (notes as String?) ?? '',
                                );
                            if (inventoryId != null) {
                              newId = inventoryId;
                            } else {
                              return null;
                            }
                          }

                          // ─── ACTUALIZAR ESTADO LOCAL ───

                          setState(() {
                            _inWishlist = false;
                            _wishlistId = "";
                          });

                          setState(() {
                            _inInventory = true;
                            _inventoryId = newId;
                          });

                          // ─── MOSTRAR SNACKBAR ───
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                inventoryId != null
                                    ? 'Inventory updated'
                                    : 'Added $quantity ${paint.name} to inventory',
                              ),
                              backgroundColor:
                                  isDarkMode
                                      ? AppTheme.drawerOrange
                                      : AppTheme.primaryBlue,
                              action: SnackBarAction(
                                label: 'VIEW',
                                textColor: Colors.white,
                                onPressed:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const InventoryScreen(),
                                      ),
                                    ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: Text(
                      _inInventory ? 'Update Inventory' : 'Add to Inventory',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          _inInventory
                              ? (isDarkMode
                                  ? AppTheme.drawerOrange
                                  : AppTheme.primaryBlue)
                              : Colors.transparent,
                      foregroundColor:
                          _inInventory
                              ? Colors.white
                              : (isDarkMode
                                  ? AppTheme.drawerOrange
                                  : AppTheme.primaryBlue),
                      side: BorderSide(
                        color:
                            isDarkMode
                                ? AppTheme.drawerOrange
                                : AppTheme.primaryBlue,
                      ),
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
                      AddToWishlistModal.show(
                        context: context,
                        paint: widget.paint,
                        isUpdate: _inWishlist,
                        wishlistId: _wishlistId,
                        onAddToWishlist: (
                          paint,
                          priority,
                          existingWishlistId,
                        ) async {
                          String? newId = existingWishlistId;
                          final user = FirebaseAuth.instance.currentUser!;
                          final token = await user.getIdToken();

                          if (existingWishlistId != null) {
                            // ─── ACTUALIZAR EXISTENTE ───
                            bool success = await _paintService
                                .updateWishlistPriority(
                                  paint.id,
                                  existingWishlistId,
                                  priority > 0,
                                  token as String,
                                  priority,
                                );
                            if (!success) {
                              return null;
                            }
                          } else {
                            // ─── AÑADIR NUEVO ───
                            final result = await _paintService
                                .addToWishlistDirect(paint, priority, user.uid);
                            if (result['success'] == true) {
                              newId = result['id']?.toString();
                            } else {
                              return null;
                            }
                          }

                          // ─── LIMPIAR ESTADO DE INVENTARIO ───
                          setState(() {
                            _inInventory = false;
                            _inventoryId = null;
                          });

                          // ─── ACTUALIZAR ESTADO LOCAL DE WISHLIST ───
                          setState(() {
                            _inWishlist = true;
                            _wishlistId = newId;
                          });

                          // ─── MOSTRAR SNACKBAR ───
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                existingWishlistId != null
                                    ? 'Wishlist updated'
                                    : 'Added ${paint.name} to wishlist',
                              ),
                              backgroundColor: Colors.pink,
                              action: SnackBarAction(
                                label: 'VIEW',
                                textColor: Colors.white,
                                onPressed:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const WishlistScreen(),
                                      ),
                                    ),
                              ),
                            ),
                          );

                          // igual que en inventario, no devolvemos nada
                          return null;
                        },
                      );
                    },
                    icon: const Icon(Icons.favorite_border, size: 16),
                    label: Text(
                      _inWishlist ? 'Update Wishlist' : 'Add to Wishlist',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          _inWishlist ? Colors.redAccent : Colors.transparent,
                      foregroundColor:
                          _inWishlist ? Colors.white : Colors.redAccent,
                      side: BorderSide(
                        color:
                            _inWishlist ? Colors.redAccent : Colors.redAccent,
                      ),
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
      id: paint.id,
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
          int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000,
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
                          'Used in ${widget.paletteCount} palettes',
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
                        AddToInventoryModal.show(
                          context: context,
                          paint: paint,
                          inventoryId: _inventoryId,
                          initialQuantity: 1,
                          initialNotes: null,
                          onAddToInventory: (
                            paint,
                            quantity,
                            notes,
                            inventoryId,
                          ) async {
                            String? newId = inventoryId;

                            if (inventoryId != null) {
                              // ─── ACTUALIZAR EXISTENTE ───
                              bool success = await _inventoryService
                                  .updateStockFromApi(inventoryId, quantity);

                              if (!success) {
                                return null;
                              }
                            } else {
                              final inventoryId = await _inventoryService
                                  .addInventoryRecordReturningId(
                                    brandId: paint.brandId as String,
                                    paintId: paint.id,
                                    quantity: quantity,
                                    notes: notes as String,
                                  );
                              if (inventoryId != null) {
                                newId = inventoryId;
                              } else {
                                return null;
                              }
                            }

                            // ─── ACTUALIZAR ESTADO LOCAL ───
                            setState(() {
                              _inWishlist = false;
                              _wishlistId = "";
                            });

                            setState(() {
                              _inInventory = true;
                              _inventoryId = newId;
                            });

                            // ─── MOSTRAR SNACKBAR ───
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  inventoryId != null
                                      ? 'Inventory updated'
                                      : 'Added $quantity ${paint.name} to inventory',
                                ),
                                backgroundColor:
                                    isDarkMode
                                        ? AppTheme.drawerOrange
                                        : AppTheme.primaryBlue,
                                action: SnackBarAction(
                                  label: 'VIEW',
                                  textColor: Colors.white,
                                  onPressed:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => const InventoryScreen(),
                                        ),
                                      ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: Text(
                        _inInventory ? 'Update Inventory' : 'Add to Inventory',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            _inInventory
                                ? (isDarkMode
                                    ? AppTheme.drawerOrange
                                    : AppTheme.primaryBlue)
                                : Colors.transparent,
                        foregroundColor:
                            _inInventory
                                ? Colors.white
                                : (isDarkMode
                                    ? AppTheme.drawerOrange
                                    : AppTheme.primaryBlue),
                        side: BorderSide(
                          color:
                              isDarkMode
                                  ? AppTheme.drawerOrange
                                  : AppTheme.primaryBlue,
                        ),
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
                        AddToWishlistModal.show(
                          context: context,
                          paint: paint,
                          isUpdate: _inWishlist,
                          wishlistId: _wishlistId,
                          onAddToWishlist: (
                            paint,
                            priority,
                            existingWishlistId,
                          ) async {
                            String? newId = existingWishlistId;
                            final user = FirebaseAuth.instance.currentUser!;
                            final token = await user.getIdToken();

                            if (existingWishlistId != null) {
                              // ─── ACTUALIZAR EXISTENTE ───
                              bool success = await _paintService
                                  .updateWishlistPriority(
                                    paint.id,
                                    existingWishlistId,
                                    priority > 0,
                                    token as String,
                                    priority,
                                  );
                              if (!success) {
                                return null;
                              }
                            } else {
                              // ─── AÑADIR NUEVO ───
                              final result = await _paintService
                                  .addToWishlistDirect(
                                    paint,
                                    priority,
                                    user.uid,
                                  );
                              if (result['success'] == true) {
                                newId = result['id']?.toString();
                              } else {
                                return null;
                              }
                            }

                            // ─── LIMPIAR ESTADO DE INVENTARIO ───
                            setState(() {
                              _inInventory = false;
                              _inventoryId = null;
                            });

                            // ─── ACTUALIZAR ESTADO LOCAL DE WISHLIST ───
                            setState(() {
                              _inWishlist = true;
                              _wishlistId = newId;
                            });

                            // ─── MOSTRAR SNACKBAR ───
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  existingWishlistId != null
                                      ? 'Wishlist updated'
                                      : 'Added ${paint.name} to wishlist',
                                ),
                                backgroundColor: Colors.pink,
                                action: SnackBarAction(
                                  label: 'VIEW',
                                  textColor: Colors.white,
                                  onPressed:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => const WishlistScreen(),
                                        ),
                                      ),
                                ),
                              ),
                            );

                            // igual que en inventario, no devolvemos nada
                            return null;
                          },
                        );
                      },
                      icon: const Icon(Icons.favorite_border),
                      label: Text(
                        _inWishlist ? 'Update Wishlist' : 'Add to Wishlist',
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            _inWishlist ? Colors.redAccent : Colors.transparent,
                        foregroundColor:
                            _inWishlist ? Colors.white : Colors.redAccent,
                        side: BorderSide(
                          color:
                              _inWishlist ? Colors.redAccent : Colors.redAccent,
                        ),
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
        widget.paint.category,
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

  // Helper method to get priority text
  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return "Low";
      case 2:
        return "Somewhat Important";
      case 3:
        return "Important";
      case 4:
        return "Very Important";
      case 5:
        return "Highest";
      default:
        return "";
    }
  }
}
