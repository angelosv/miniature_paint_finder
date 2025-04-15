import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/add_to_wishlist_modal.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/services/palette_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Result of a barcode scan with quick actions
class ScanResultSheet extends StatefulWidget {
  /// Paint found after scanning
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

  /// Callback when adding to a palette
  final Function(Paint paint, Palette palette) onAddToPalette;

  /// Callback to find equivalents
  final Function(Paint paint) onFindEquivalents;

  /// Callback to check availability/purchase
  final Function(Paint paint)? onPurchase;

  /// Callback to close the sheet
  final VoidCallback onClose;

  /// Builds a new scan result sheet
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
  List<Map<String, dynamic>> _palettes = [];
  bool _isLoadingPalettes = false;
  final PaletteService _paletteService = PaletteService();

  @override
  void initState() {
    super.initState();
    if (widget.inventoryQuantity != null) {
      _quantity = widget.inventoryQuantity!;
    }
    _loadPalettes();
  }

  Future<void> _loadPalettes() async {
    setState(() {
      _isLoadingPalettes = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken() ?? '';
        final palettes = await _paletteService.getAllPalettesNamesAndIds(token);
        setState(() {
          _palettes = palettes;
          print('🎨 Paletas cargadas: ${palettes.length}');
          if (palettes.isNotEmpty) {
            print('🎨 Paletas cargadas: ${palettes.first['id']}');
            print('🎨 Paletas cargadas: ${palettes.first['name']}');
            _selectedPalette = Palette(
              id: palettes.first['id'],
              name: palettes.first['name'],
              imagePath: 'assets/images/placeholder.jpg',
              colors: [],
              createdAt: DateTime.now(),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando paletas: $e');
    } finally {
      setState(() {
        _isLoadingPalettes = false;
      });
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
      if (_palettes.isNotEmpty) {
        _selectedPalette = Palette(
          id: _palettes.first['id'],
          name: _palettes.first['name'],
          imagePath: 'assets/images/placeholder.jpg',
          colors: [],
          createdAt: DateTime.now(),
        );
      }
    });
  }

  void _showAddToWishlistDialog() {
    Navigator.pop(context);

    AddToWishlistModal.show(
      context: context,
      paint: widget.paint,
      onAddToWishlist: (paint, priority) async {
        print('🔍 Iniciando proceso de añadir a wishlist');
        print('📦 Datos de la pintura: ${paint.toJson()}');
        print('🎯 Prioridad seleccionada: $priority');
        
        try {
          // Obtener el usuario actual de Firebase
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser == null) {
            print('❌ No hay usuario autenticado');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Necesitas iniciar sesión para añadir a wishlist'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }

          final userId = firebaseUser.uid;
          print('🔑 ID de usuario: $userId');

          // Crear instancia del servicio
          final paintService = PaintService();
          
          print('📤 Llamando a addToWishlistDirect...');
          final result = await paintService.addToWishlistDirect(
            paint,
            priority,
            userId,
          );

          print('📥 Respuesta de addToWishlistDirect: $result');

          if (result['success'] == true) {
            print('✅ Pintura añadida a wishlist exitosamente');
            _showSuccessSnackbar(
              result['alreadyExists'] == true
                  ? '${paint.name} ya está en tu wishlist'
                  : '${paint.name} añadido a tu wishlist',
            );
          } else {
            print('❌ Error en la respuesta: ${result['message']}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${result['message']}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e) {
          print('❌ Error al añadir a wishlist: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  }

  void _addToInventory() {
    widget.onAddToInventory(widget.paint, _quantity, _note);
    setState(() {
      _isAddingToInventory = false;
    });
    _showSuccessSnackbar('Paint added to your inventory');
  }

  void _updateInventory() {
    widget.onUpdateInventory(widget.paint, _quantity, _note);
    setState(() {
      _isAddingToInventory = false;
    });
    _showSuccessSnackbar('Inventory updated');
  }

  void _addToPalette() async {
    if (_selectedPalette != null) {
      print('🎨 Iniciando proceso de añadir pintura a paleta');
      print('📦 Datos de la pintura: ${widget.paint.toJson()}');
      print('🎯 Paleta seleccionada: ${_selectedPalette!.toJson()}');
      
      try {
        // Obtener el usuario actual de Firebase
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser == null) {
          print('❌ No hay usuario autenticado');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Necesitas iniciar sesión para añadir a paleta'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        final token = await firebaseUser.getIdToken() ?? '';
        print('🔑 Token de usuario obtenido');
        
        final paletteService = PaletteService();
        
        print('📤 Llamando a addPaintsToPalette...');
        print('🎨 Agregando 1 pintura a la paleta: ${_selectedPalette!.id}');
        await paletteService.addPaintsToPalette(
          _selectedPalette!.id,
          [ { "paint_id": widget.paint.id, "brand_id": widget.paint.brandId } ],
          token,
        );

        print('✅ Pintura añadida a paleta exitosamente');
        widget.onAddToPalette(widget.paint, _selectedPalette!);
        setState(() {
          _isAddingToPalette = false;
        });
        _showSuccessSnackbar('Paint added to palette ${_selectedPalette!.name}');
      } catch (e) {
        print('❌ Error al añadir a paleta: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _addToWishlist() {
    widget.onAddToWishlist(widget.paint, _isPriority);
    setState(() {
      _isAddingToWishlist = false;
    });
    _showSuccessSnackbar('Paint added to your wishlist');
  }

  void _findEquivalents() {
    widget.onFindEquivalents(widget.paint);
    _showSuccessSnackbar('Looking for equivalents...');
  }

  void _purchase() {
    if (widget.onPurchase != null) {
      widget.onPurchase!(widget.paint);
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color paintColor = Color(
      int.parse(widget.paint.hex.substring(1), radix: 16) + 0xFF000000,
    );
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
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
                                    tooltip: 'Close',
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
                                widget.paint.hex,
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
                                'This paint is in your wishlist',
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
                                    'This paint is in ${widget.inPalettes!.length} ${widget.inPalettes!.length == 1 ? 'palette' : 'palettes'}',
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
                      'Quick Actions',
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
            widget.isInInventory ? 'Update in inventory' : 'Add to inventory',
          ),
          subtitle: const Text('Record this paint with quantity'),
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
            title: const Text('Add to wishlist'),
            subtitle: const Text('Save for later purchase'),
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
          title: const Text('Add to palette'),
          subtitle: const Text('Include this paint in a palette'),
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
          title: const Text('Find equivalents'),
          subtitle: const Text('Find similar colors from other brands'),
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
            title: const Text('Purchase'),
            subtitle: const Text('Check availability and prices'),
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
          widget.isInInventory ? 'Update in inventory' : 'Add to inventory',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            shadows: [],
          ),
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
                    widget.isInInventory ? _updateInventory : _addToInventory,
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
          'Add to palette',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            shadows: [],
          ),
        ),
        const SizedBox(height: 16),

        // Palette selector
        if (_isLoadingPalettes)
          const Center(child: CircularProgressIndicator())
        else if (_palettes.isEmpty)
          const Text(
            'You have no palettes. Create a new one to add this paint.',
          )
        else
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
                child: DropdownButton<Map<String, dynamic>>(
                  value: _selectedPalette != null 
                    ? _palettes.firstWhere(
                        (palette) => palette['id'] == _selectedPalette!.id,
                        orElse: () => _palettes.first,
                      )
                    : _palettes.first,
                  isExpanded: true,
                  underline: Container(),
                  items: _palettes.map((palette) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: palette,
                      child: Text(palette['name']),
                    );
                  }).toList(),
                  onChanged: (Map<String, dynamic>? value) {
                    if (value != null) {
                      print('🎨 Paleta seleccionada: ${value['id']}');
                      print('🎨 Paleta seleccionada: ${value['name']}');
                      setState(() {
                        _selectedPalette = Palette(
                          id: value['id'],
                          name: value['name'],
                          imagePath: 'assets/images/placeholder.jpg',
                          colors: [],
                          createdAt: DateTime.now(),
                        );
                      });
                    }
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
              const SnackBar(content: Text('Create new palette (pending)')),
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

  Widget _buildAddToWishlistForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add to wishlist',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            shadows: [],
          ),
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
            const Text('Mark as priority'),
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
                child: const Text('Cancel'),
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
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
