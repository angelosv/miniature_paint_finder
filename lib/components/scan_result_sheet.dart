import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// Resultado del escaneo de un código de barras con acciones rápidas
class ScanResultSheet extends StatefulWidget {
  /// Pintura encontrada después del escaneo
  final Paint paint;

  /// Si la pintura ya está en el inventario del usuario
  final bool isInInventory;

  /// Cantidad en inventario, si aplica
  final int? inventoryQuantity;

  /// Si la pintura está en la wishlist
  final bool isInWishlist;

  /// Paletas que contienen esta pintura
  final List<Palette>? inPalettes;

  /// Lista de paletas del usuario para elegir
  final List<Palette> userPalettes;

  /// Callback cuando se agrega al inventario
  final Function(Paint paint, int quantity, String? note) onAddToInventory;

  /// Callback cuando se modifica el inventario
  final Function(Paint paint, int quantity, String? note) onUpdateInventory;

  /// Callback cuando se agrega a la wishlist
  final Function(Paint paint, bool isPriority) onAddToWishlist;

  /// Callback cuando se agrega a una paleta
  final Function(Paint paint, Palette palette) onAddToPalette;

  /// Callback para buscar equivalencias
  final Function(Paint paint) onFindEquivalents;

  /// Callback para consultar disponibilidad/comprar
  final Function(Paint paint)? onPurchase;

  /// Callback para cerrar el sheet
  final VoidCallback onClose;

  /// Construye una nueva hoja de resultados de escaneo
  const ScanResultSheet({
    super.key,
    required this.paint,
    this.isInInventory = false,
    this.inventoryQuantity,
    this.isInWishlist = false,
    this.inPalettes,
    required this.userPalettes,
    required this.onAddToInventory,
    required this.onUpdateInventory,
    required this.onAddToWishlist,
    required this.onAddToPalette,
    required this.onFindEquivalents,
    this.onPurchase,
    required this.onClose,
  });

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet> {
  bool _isPriority = false;
  int _quantity = 1;
  String? _note;
  Palette? _selectedPalette;
  bool _isAddingToInventory = false;
  bool _isAddingToPalette = false;
  bool _isAddingToWishlist = false;

  @override
  void initState() {
    super.initState();
    if (widget.inventoryQuantity != null) {
      _quantity = widget.inventoryQuantity!;
    }
  }

  void _showAddToInventoryDialog() {
    setState(() {
      _isAddingToInventory = true;
    });
  }

  void _showAddToPaletteDialog() {
    setState(() {
      _isAddingToPalette = true;
      _selectedPalette =
          widget.userPalettes.isNotEmpty ? widget.userPalettes.first : null;
    });
  }

  void _showAddToWishlistDialog() {
    setState(() {
      _isAddingToWishlist = true;
    });
  }

  void _addToInventory() {
    widget.onAddToInventory(widget.paint, _quantity, _note);
    setState(() {
      _isAddingToInventory = false;
    });
    _showSuccessSnackbar('Pintura añadida a tu inventario');
  }

  void _updateInventory() {
    widget.onUpdateInventory(widget.paint, _quantity, _note);
    setState(() {
      _isAddingToInventory = false;
    });
    _showSuccessSnackbar('Inventario actualizado');
  }

  void _addToPalette() {
    if (_selectedPalette != null) {
      widget.onAddToPalette(widget.paint, _selectedPalette!);
      setState(() {
        _isAddingToPalette = false;
      });
      _showSuccessSnackbar(
        'Pintura añadida a paleta ${_selectedPalette!.name}',
      );
    }
  }

  void _addToWishlist() {
    widget.onAddToWishlist(widget.paint, _isPriority);
    setState(() {
      _isAddingToWishlist = false;
    });
    _showSuccessSnackbar('Pintura añadida a tu wishlist');
  }

  void _findEquivalents() {
    widget.onFindEquivalents(widget.paint);
    _showSuccessSnackbar('Buscando equivalencias...');
  }

  void _purchase() {
    if (widget.onPurchase != null) {
      widget.onPurchase!(widget.paint);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color paintColor = Color(
      int.parse(widget.paint.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with paint info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Paint color swatch
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: paintColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Paint details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.paint.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: widget.onClose,
                                  tooltip: 'Cerrar',
                                ),
                              ],
                            ),
                            Text(
                              widget.paint.brand,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.paint.category,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (widget.paint.isMetallic ||
                                    widget.paint.isTransparent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      widget.paint.isMetallic
                                          ? 'Metallic'
                                          : 'Transparent',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: Colors.amber[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.paint.colorHex,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Status indicators
                  const SizedBox(height: 16),
                  if (widget.isInInventory)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ya tienes esta pintura en tu inventario',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Cantidad: ${widget.inventoryQuantity}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _showAddToInventoryDialog,
                            child: const Text('Editar'),
                          ),
                        ],
                      ),
                    ),

                  if (widget.isInWishlist)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta pintura está en tu wishlist',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (widget.inPalettes != null &&
                      widget.inPalettes!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.palette,
                                color: Colors.purple,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Esta pintura está en ${widget.inPalettes!.length} ${widget.inPalettes!.length == 1 ? 'paleta' : 'paletas'}',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                widget.inPalettes!
                                    .map(
                                      (palette) => Chip(
                                        label: Text(palette.name),
                                        backgroundColor: Colors.purple
                                            .withOpacity(0.1),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Acciones rápidas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  if (!_isAddingToInventory &&
                      !_isAddingToPalette &&
                      !_isAddingToWishlist)
                    _buildActionButtons(),

                  // Add to inventory form
                  if (_isAddingToInventory) _buildAddToInventoryForm(),

                  // Add to palette form
                  if (_isAddingToPalette) _buildAddToPaletteForm(),

                  // Add to wishlist form
                  if (_isAddingToWishlist) _buildAddToWishlistForm(),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Inventory action
        ListTile(
          leading: Icon(
            Icons.inventory_2_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            widget.isInInventory
                ? 'Actualizar en inventario'
                : 'Añadir al inventario',
          ),
          subtitle: const Text('Registra esta pintura con cantidad'),
          onTap: _showAddToInventoryDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Wishlist action (only if not already in wishlist)
        if (!widget.isInWishlist)
          ListTile(
            leading: Icon(
              Icons.star_border_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: const Text('Añadir a wishlist'),
            subtitle: const Text('Guarda para comprar más tarde'),
            onTap: _showAddToWishlistDialog,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ),
            ),
          ),
        const SizedBox(height: 8),

        // Palette action
        ListTile(
          leading: Icon(Icons.palette_outlined, color: Colors.purple),
          title: const Text('Añadir a paleta'),
          subtitle: const Text('Incluye esta pintura en una paleta'),
          onTap: _showAddToPaletteDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.purple.withOpacity(0.2)),
          ),
        ),
        const SizedBox(height: 8),

        // Find equivalents
        ListTile(
          leading: Icon(Icons.compare_arrows, color: Colors.blue[700]),
          title: const Text('Buscar equivalencias'),
          subtitle: const Text('Encuentra colores similares de otras marcas'),
          onTap: _findEquivalents,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.blue[700]!.withOpacity(0.2)),
          ),
        ),
        const SizedBox(height: 8),

        // Purchase (if available)
        if (widget.onPurchase != null)
          ListTile(
            leading: Icon(
              Icons.shopping_cart_outlined,
              color: Colors.green[700],
            ),
            title: const Text('Comprar'),
            subtitle: const Text('Ver disponibilidad y precios'),
            onTap: _purchase,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.green[700]!.withOpacity(0.2)),
            ),
          ),
      ],
    );
  }

  Widget _buildAddToInventoryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.isInInventory
              ? 'Actualizar en inventario'
              : 'Añadir al inventario',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Quantity selector
        Row(
          children: [
            const Text('Cantidad:'),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed:
                  _quantity > 1
                      ? () {
                        setState(() {
                          _quantity--;
                        });
                      }
                      : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _quantity.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() {
                  _quantity++;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Note field
        TextField(
          decoration: const InputDecoration(
            labelText: 'Nota (opcional)',
            hintText: 'Ej: Casi vacío, comprado en...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (value) {
            setState(() {
              _note = value.isEmpty ? null : value;
            });
          },
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isAddingToInventory = false;
                  });
                },
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    widget.isInInventory ? _updateInventory : _addToInventory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(widget.isInInventory ? 'Actualizar' : 'Añadir'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddToPaletteForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Añadir a paleta',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Palette selector
        if (widget.userPalettes.isEmpty)
          const Text(
            'No tienes paletas. Crea una nueva para añadir esta pintura.',
          ),

        if (widget.userPalettes.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Seleccionar paleta:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<Palette>(
                  value: _selectedPalette,
                  isExpanded: true,
                  underline: Container(),
                  items:
                      widget.userPalettes.map((Palette palette) {
                        return DropdownMenuItem<Palette>(
                          value: palette,
                          child: Text(palette.name),
                        );
                      }).toList(),
                  onChanged: (Palette? value) {
                    setState(() {
                      _selectedPalette = value;
                    });
                  },
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        // "Create new palette" button
        TextButton.icon(
          onPressed: () {
            // TODO: Logic to create a new palette
            // This would typically navigate to a palette creation screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Crear nueva paleta (pendiente)')),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Crear nueva paleta'),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isAddingToPalette = false;
                  });
                },
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.userPalettes.isEmpty ? null : _addToPalette,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Añadir'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddToWishlistForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Añadir a wishlist',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Priority checkbox
        Row(
          children: [
            Checkbox(
              value: _isPriority,
              onChanged: (value) {
                setState(() {
                  _isPriority = value ?? false;
                });
              },
              activeColor: Theme.of(context).colorScheme.secondary,
            ),
            const Text('Marcar como prioritario'),
          ],
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isAddingToWishlist = false;
                  });
                },
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _addToWishlist,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Añadir'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
