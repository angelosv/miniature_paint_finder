import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/add_to_wishlist_modal.dart';
import 'package:miniature_paint_finder/components/add_to_inventory_modal.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';

/// A bottom sheet that displays detailed information about a paint with options to add to inventory or palette
class PaintDetailSheet extends StatefulWidget {
  /// The paint to display details for
  final Paint paint;

  /// Whether the paint is already in the user's inventory
  final bool isInInventory;

  /// Quantity in inventory, if applicable
  final int? inventoryQuantity;

  /// Whether the paint is in the wishlist
  final bool isInWishlist;

  /// Palettes containing this paint
  final List<Palette>? inPalettes;

  /// List of user's palettes to choose from
  final List<Palette> userPalettes;

  /// Callback when adding to inventory
  final Function(Paint paint, int quantity, String? note) onAddToInventory;

  /// Callback when updating inventory
  final Function(Paint paint, int quantity, String? note) onUpdateInventory;

  /// Callback when adding to wishlist
  final Function(Paint paint, bool isPriority) onAddToWishlist;

  /// Callback when removing from wishlist
  final Function(Paint paint) onRemoveFromWishlist;

  /// Callback when adding to a palette
  final Function(Paint paint, Palette palette) onAddToPalette;

  /// Callback to close the sheet
  final VoidCallback onClose;

  /// Creates a paint detail sheet
  const PaintDetailSheet({
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
    required this.onRemoveFromWishlist,
    required this.onAddToPalette,
    required this.onClose,
  });

  @override
  State<PaintDetailSheet> createState() => _PaintDetailSheetState();
}

class _PaintDetailSheetState extends State<PaintDetailSheet> {
  bool _isPriority = false;
  int _quantity = 1;
  String? _note;
  Palette? _selectedPalette;
  bool _isAddingToInventory = false;
  bool _isAddingToPalette = false;

  @override
  void initState() {
    super.initState();
    if (widget.inventoryQuantity != null) {
      _quantity = widget.inventoryQuantity!;
    }
    if (widget.userPalettes.isNotEmpty) {
      _selectedPalette = widget.userPalettes.first;
    }
  }

  void _showAddToInventoryDialog() {
    Navigator.pop(context);

    // Usar el nuevo modal para añadir al inventario
    AddToInventoryModal.show(
      context: context,
      paint: widget.paint,
      onAddToInventory: (paint, quantity, notes) {
        if (widget.isInInventory) {
          widget.onUpdateInventory(paint, quantity, notes);
          _showSuccessSnackbar('Inventory updated');
        } else {
          widget.onAddToInventory(paint, quantity, notes);
          _showSuccessSnackbar('Paint added to your inventory');
        }
      },
    );
  }

  void _showAddToPaletteDialog() {
    setState(() {
      _isAddingToPalette = true;
    });
  }

  void _toggleWishlist() {
    if (widget.isInWishlist) {
      widget.onRemoveFromWishlist(widget.paint);
      _showSuccessSnackbar('Paint removed from wishlist');
    } else {
      Navigator.pop(context);

      AddToWishlistModal.show(
        context: context,
        paint: widget.paint,
        onAddToWishlist: (paint, priority) {
          final isPriority = priority > 0;
          widget.onAddToWishlist(paint, isPriority);
          _showSuccessSnackbar('Paint added to your wishlist');
        },
      );
    }
  }

  void _addToPalette() {
    if (_selectedPalette != null) {
      widget.onAddToPalette(widget.paint, _selectedPalette!);
      setState(() {
        _isAddingToPalette = false;
      });
      _showSuccessSnackbar('Paint added to palette ${_selectedPalette!.name}');
    }
  }

  void _showSuccessSnackbar(String message) {
    // Verificar si el widget está montado antes de mostrar el SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          action:
              message.contains('wishlist')
                  ? SnackBarAction(
                    label: 'VIEW',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WishlistScreen(),
                        ),
                      );
                    },
                  )
                  : message.contains('inventory')
                  ? SnackBarAction(
                    label: 'VIEW',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InventoryScreen(),
                        ),
                      );
                    },
                  )
                  : null,
        ),
      );
    }
  }

  // Helper to build info rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paintColor = Color(
      int.parse(widget.paint.hex.substring(1), radix: 16) + 0xFF000000,
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

            // Paint color header
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: paintColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand avatar
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: Text(
                        widget.paint.brand.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: paintColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Color code
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.paint.hex,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: paintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Paint details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and favorite button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.paint.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          widget.isInWishlist
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.isInWishlist ? Colors.red : null,
                        ),
                        onPressed: _toggleWishlist,
                        tooltip:
                            widget.isInWishlist
                                ? 'Remove from wishlist'
                                : 'Add to wishlist',
                      ),
                    ],
                  ),

                  Text(
                    widget.paint.brand,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 16),

                  // Paint properties
                  _buildInfoRow(
                    Icons.category_outlined,
                    'Category',
                    widget.paint.category,
                  ),

                  if (widget.paint.isMetallic || widget.paint.isTransparent)
                    _buildInfoRow(
                      Icons.format_paint_outlined,
                      'Type',
                      widget.paint.isMetallic ? 'Metallic' : 'Transparent',
                    ),

                  _buildInfoRow(
                    Icons.qr_code_outlined,
                    'Barcode',
                    'EAN-${widget.paint.id.hashCode.abs() % 10000000000000}',
                  ),

                  // Status indicators
                  if (widget.isInInventory)
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
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
                                  'You already have this paint in your inventory',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Quantity: ${widget.inventoryQuantity}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _showAddToInventoryDialog,
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                    ),

                  // Palettes information
                  if (widget.inPalettes != null &&
                      widget.inPalettes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'In Palettes:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.inPalettes!
                              .map(
                                (palette) => Chip(
                                  label: Text(palette.name),
                                  backgroundColor: Colors.purple.withOpacity(
                                    0.1,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action section
                  const Divider(),
                  const SizedBox(height: 16),

                  // Actions based on state
                  if (!_isAddingToInventory && !_isAddingToPalette)
                    _buildActions(),

                  // Add to inventory form
                  if (_isAddingToInventory) _buildAddToInventoryForm(),

                  // Add to palette form
                  if (_isAddingToPalette) _buildAddToPaletteForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Inventory action
        if (!widget.isInInventory)
          ElevatedButton.icon(
            onPressed: _showAddToInventoryDialog,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Add to Inventory'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

        if (widget.isInInventory)
          ElevatedButton.icon(
            onPressed: _showAddToInventoryDialog,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Update Inventory'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

        const SizedBox(height: 12),

        // Palette action
        ElevatedButton.icon(
          onPressed: _showAddToPaletteDialog,
          icon: const Icon(Icons.palette_outlined),
          label: const Text('Add to Palette'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),

        const SizedBox(height: 24),

        // Close button
        TextButton(onPressed: widget.onClose, child: const Text('Close')),
      ],
    );
  }

  Widget _buildAddToInventoryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.isInInventory ? 'Update Inventory' : 'Add to Inventory',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Quantity selector
        Row(
          children: [
            const Text('Quantity:'),
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
            labelText: 'Note (optional)',
            hintText: 'E.g.: Almost empty, purchased at...',
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
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    widget.isInInventory
                        ? _showAddToInventoryDialog
                        : _showAddToInventoryDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(widget.isInInventory ? 'Update' : 'Add'),
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
          'Add to Palette',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Palette selector
        if (widget.userPalettes.isEmpty)
          const Text(
            'You have no palettes. Create a new one to add this paint.',
          ),

        if (widget.userPalettes.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select palette:'),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create new palette (coming soon)')),
            );
          },
          icon: Icon(
            Icons.add,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.primaryBlue
                    : Colors.white,
          ),
          label: Text(
            'Create new palette',
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.primaryBlue
                      : Colors.white,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.marineOrange
                    : AppTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
                child: const Text('Cancel'),
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
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
