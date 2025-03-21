import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late List<Paint> _paints;
  late List<PaintInventoryItem> _inventory;
  late List<PaintInventoryItem> _filteredInventory;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newPaintNameController = TextEditingController();
  final TextEditingController _newPaintBrandController =
      TextEditingController();
  final TextEditingController _newPaintColorHexController =
      TextEditingController();
  final TextEditingController _newPaintCategoryController =
      TextEditingController();

  bool _onlyShowInStock = false;
  bool _isAscending = true;
  String _sortColumn = 'name';

  @override
  void initState() {
    super.initState();
    _paints = SampleData.getPaints();

    // Crear inventario inicial con stock aleatorio
    _inventory =
        _paints.map((paint) {
          return PaintInventoryItem(
            paint: paint,
            stock: (paint.id.hashCode % 5), // Stock aleatorio entre 0 y 4
            notes: '',
          );
        }).toList();

    _filteredInventory = List.from(_inventory);

    // Listener para búsqueda
    _searchController.addListener(_filterInventory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newPaintNameController.dispose();
    _newPaintBrandController.dispose();
    _newPaintColorHexController.dispose();
    _newPaintCategoryController.dispose();
    super.dispose();
  }

  void _filterInventory() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredInventory = List.from(_inventory);
      } else {
        final query = _searchController.text.toLowerCase();
        _filteredInventory =
            _inventory.where((item) {
              return item.paint.name.toLowerCase().contains(query) ||
                  item.paint.brand.toLowerCase().contains(query) ||
                  item.paint.category.toLowerCase().contains(query) ||
                  (item.notes.isNotEmpty &&
                      item.notes.toLowerCase().contains(query));
            }).toList();
      }

      // Aplicar filtro de stock si es necesario
      if (_onlyShowInStock) {
        _filteredInventory =
            _filteredInventory.where((item) => item.stock > 0).toList();
      }

      // Ordenar
      _sortInventory();
    });
  }

  void _sortInventory() {
    _filteredInventory.sort((a, b) {
      int comparison;
      switch (_sortColumn) {
        case 'name':
          comparison = a.paint.name.compareTo(b.paint.name);
          break;
        case 'brand':
          comparison = a.paint.brand.compareTo(b.paint.brand);
          break;
        case 'category':
          comparison = a.paint.category.compareTo(b.paint.category);
          break;
        case 'stock':
          comparison = a.stock.compareTo(b.stock);
          break;
        default:
          comparison = a.paint.name.compareTo(b.paint.name);
      }

      return _isAscending ? comparison : -comparison;
    });
  }

  void _sortBy(String column) {
    setState(() {
      if (_sortColumn == column) {
        // Cambiar dirección si se hace clic en la misma columna
        _isAscending = !_isAscending;
      } else {
        _sortColumn = column;
        _isAscending = true;
      }

      _sortInventory();
    });
  }

  void _updateStock(PaintInventoryItem item, int change) {
    setState(() {
      item.stock += change;
      if (item.stock < 0) item.stock = 0;
    });
  }

  void _updateNotes(PaintInventoryItem item, String notes) {
    setState(() {
      item.notes = notes;
    });
  }

  void _removeFromInventory(String paintId) {
    setState(() {
      _inventory.removeWhere((item) => item.paint.id == paintId);
      _filterInventory();
    });
  }

  void _removePaint(PaintInventoryItem item) {
    _removeFromInventory(item.paint.id);
  }

  void _showAddPaintDialog() {
    // Limpiar controladores
    _newPaintNameController.clear();
    _newPaintBrandController.clear();
    _newPaintColorHexController.text = '#000000';
    _newPaintCategoryController.clear();

    Color selectedColor = Colors.black;
    int stock = 1;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Add New Paint'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _newPaintNameController,
                        decoration: const InputDecoration(
                          labelText: 'Paint Name*',
                          hintText: 'E.g. Mephiston Red',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _newPaintBrandController,
                        decoration: const InputDecoration(
                          labelText: 'Brand*',
                          hintText: 'E.g. Citadel',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _newPaintCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category*',
                          hintText: 'E.g. Base, Layer, Wash',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text('Color:'),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              // Aquí se mostraría un selector de color completo
                              // Para simplificar, solo cambiamos entre algunos colores predefinidos
                              setState(() {
                                if (selectedColor == Colors.black) {
                                  selectedColor = Colors.red;
                                  _newPaintColorHexController.text = '#FF0000';
                                } else if (selectedColor == Colors.red) {
                                  selectedColor = Colors.blue;
                                  _newPaintColorHexController.text = '#0000FF';
                                } else if (selectedColor == Colors.blue) {
                                  selectedColor = Colors.green;
                                  _newPaintColorHexController.text = '#00FF00';
                                } else {
                                  selectedColor = Colors.black;
                                  _newPaintColorHexController.text = '#000000';
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selectedColor,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _newPaintColorHexController,
                              decoration: const InputDecoration(
                                labelText: 'Hex Code',
                                hintText: '#RRGGBB',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text('Initial Stock:'),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed:
                                stock > 0
                                    ? () => setState(() => stock--)
                                    : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('$stock'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => stock++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text('Add'),
                    onPressed: () {
                      if (_newPaintNameController.text.isEmpty ||
                          _newPaintBrandController.text.isEmpty ||
                          _newPaintCategoryController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please fill all required fields (*)',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final newPaint = Paint(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _newPaintNameController.text,
                        brand: _newPaintBrandController.text,
                        colorHex: _newPaintColorHexController.text,
                        category: _newPaintCategoryController.text,
                      );

                      final newInventoryItem = PaintInventoryItem(
                        paint: newPaint,
                        stock: stock,
                        notes: '',
                      );

                      setState(() {
                        _inventory.add(newInventoryItem);
                        _filterInventory();
                      });

                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paint Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Options',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Sort By'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('Name'),
                            trailing: Icon(
                              _sortColumn == 'name'
                                  ? (_isAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward)
                                  : null,
                            ),
                            onTap: () {
                              _sortBy('name');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('Brand'),
                            trailing: Icon(
                              _sortColumn == 'brand'
                                  ? (_isAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward)
                                  : null,
                            ),
                            onTap: () {
                              _sortBy('brand');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('Category'),
                            trailing: Icon(
                              _sortColumn == 'category'
                                  ? (_isAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward)
                                  : null,
                            ),
                            onTap: () {
                              _sortBy('category');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('Stock'),
                            trailing: Icon(
                              _sortColumn == 'stock'
                                  ? (_isAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward)
                                  : null,
                            ),
                            onTap: () {
                              _sortBy('stock');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search paints...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Only In Stock'),
                      selected: _onlyShowInStock,
                      onSelected: (selected) {
                        setState(() {
                          _onlyShowInStock = selected;
                          _filterInventory();
                        });
                      },
                      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryBlue,
                    ),
                    Text('${_filteredInventory.length} paints'),
                    Chip(
                      label: Text(
                        'Sort: ${_sortColumn.substring(0, 1).toUpperCase()}${_sortColumn.substring(1)} ${_isAscending ? '↑' : '↓'}',
                      ),
                      backgroundColor: AppTheme.marineBlue.withOpacity(0.1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Encabezados de la tabla
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [_buildTableHeader(context)]),
            ),
          ),

          // Tabla de inventario
          Expanded(
            child:
                _filteredInventory.isEmpty
                    ? const Center(child: Text('No paints found'))
                    : ListView.builder(
                      itemCount: _filteredInventory.length,
                      itemBuilder: _buildInventoryItem,
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPaintDialog,
        tooltip: 'Add Paint',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInventoryItem(BuildContext context, int index) {
    final inventoryItem = _filteredInventory[index];
    final paint = inventoryItem.paint;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color:
            index % 2 == 0 ? Colors.grey.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTableCell(
              width: 150,
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(paint.colorHex.substring(1, 7), radix: 16) +
                            0xFF000000,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(paint.name, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            _buildTableCell(
              width: 100,
              child: Text(paint.brand, overflow: TextOverflow.ellipsis),
            ),
            _buildTableCell(
              width: 100,
              child: Text(paint.category, overflow: TextOverflow.ellipsis),
            ),
            _buildTableCell(
              width: 100,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                      onPressed:
                          inventoryItem.stock <= 0
                              ? null
                              : () => _updateStock(inventoryItem, -1),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${inventoryItem.stock}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      onPressed: () => _updateStock(inventoryItem, 1),
                    ),
                  ),
                ],
              ),
            ),
            _buildTableCell(
              width: 120,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inventoryItem.notes,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => _showEditNotesDialog(inventoryItem),
                    ),
                  ),
                ],
              ),
            ),
            _buildTableCell(
              width: 50,
              alignment: Alignment.center,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                onPressed: () => _removePaint(inventoryItem),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTableHeaderCell(
            label: 'Name',
            width: 150,
            sorted: _sortColumn == 'name',
            ascending: _isAscending,
            onTap: () => _sortBy('name'),
          ),
          _buildTableHeaderCell(
            label: 'Brand',
            width: 100,
            sorted: _sortColumn == 'brand',
            ascending: _isAscending,
            onTap: () => _sortBy('brand'),
          ),
          _buildTableHeaderCell(
            label: 'Category',
            width: 100,
            sorted: _sortColumn == 'category',
            ascending: _isAscending,
            onTap: () => _sortBy('category'),
          ),
          _buildTableHeaderCell(
            label: 'Stock',
            width: 100,
            sorted: _sortColumn == 'stock',
            ascending: _isAscending,
            onTap: () => _sortBy('stock'),
          ),
          _buildTableHeaderCell(
            label: 'Notes',
            width: 120,
            sorted: false,
            onTap: null,
          ),
          _buildTableHeaderCell(
            label: '',
            width: 50,
            sorted: false,
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell({
    required String label,
    required double width,
    required bool sorted,
    bool ascending = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (sorted)
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell({
    required double width,
    required Widget child,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Align(alignment: alignment, child: child),
    );
  }

  // Method to show notes dialog
  void _showEditNotesDialog(PaintInventoryItem item) {
    final notesController = TextEditingController(text: item.notes);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(item.paint.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notes:'),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    hintText: 'Add notes about this paint...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Save'),
                onPressed: () {
                  _updateNotes(item, notesController.text);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }
}

class PaintInventoryItem {
  final Paint paint;
  int stock;
  String notes;

  PaintInventoryItem({
    required this.paint,
    required this.stock,
    required this.notes,
  });
}
