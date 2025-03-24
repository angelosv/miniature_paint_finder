import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miniature_paint_finder/components/pagination_controls.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/app_header.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late List<Paint> _paints;
  late List<PaintInventoryItem> _inventory;
  late List<PaintInventoryItem> _filteredInventory;

  // Paginación
  final List<int> _pageSizeOptions = [15, 25, 50];
  int _currentPageSize = 25;
  int _currentPage = 1;
  late int _totalPages;
  late List<PaintInventoryItem> _paginatedInventory;

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
    _updatePaginatedInventory();

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

  void _updatePaginatedInventory() {
    _totalPages = (_filteredInventory.length / _currentPageSize).ceil();

    final startIndex = (_currentPage - 1) * _currentPageSize;
    final endIndex = _currentPage * _currentPageSize;

    if (startIndex >= _filteredInventory.length) {
      _paginatedInventory = [];
    } else {
      _paginatedInventory = _filteredInventory.sublist(
        startIndex,
        endIndex < _filteredInventory.length
            ? endIndex
            : _filteredInventory.length,
      );
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
      _updatePaginatedInventory();
    });
  }

  void _changePageSize(int size) {
    setState(() {
      _currentPageSize = size;
      _currentPage = 1; // Volver a la primera página
      _updatePaginatedInventory();
    });
  }

  void _filterInventory() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredInventory =
          _inventory.where((item) {
            final paint = item.paint;
            final nameMatches = paint.name.toLowerCase().contains(query);
            final brandMatches = paint.brand.toLowerCase().contains(query);
            final categoryMatches = paint.category.toLowerCase().contains(
              query,
            );
            final stockMatches = !_onlyShowInStock || item.stock > 0;

            return (nameMatches || brandMatches || categoryMatches) &&
                stockMatches;
          }).toList();

      _sortInventory();
      _currentPage = 1; // Volver a la primera página al filtrar
      _updatePaginatedInventory();
    });
  }

  void _toggleStockFilter(bool value) {
    setState(() {
      _onlyShowInStock = value;
      _filterInventory();
    });
  }

  void _sortInventory() {
    _filteredInventory.sort((a, b) {
      int result;
      switch (_sortColumn) {
        case 'name':
          result = a.paint.name.compareTo(b.paint.name);
          break;
        case 'brand':
          result = a.paint.brand.compareTo(b.paint.brand);
          break;
        case 'category':
          result = a.paint.category.compareTo(b.paint.category);
          break;
        case 'stock':
          result = a.stock.compareTo(b.stock);
          break;
        default:
          result = a.paint.name.compareTo(b.paint.name);
      }

      return _isAscending ? result : -result;
    });

    _updatePaginatedInventory();
  }

  void _changeSortColumn(String column) {
    setState(() {
      if (_sortColumn == column) {
        _isAscending = !_isAscending;
      } else {
        _sortColumn = column;
        _isAscending = true;
      }
      _sortInventory();
    });
  }

  void _updatePaintStock(PaintInventoryItem item, int newStock) {
    setState(() {
      // Actualizar en ambas listas (filtrada y completa)
      final index = _inventory.indexOf(item);
      if (index != -1) {
        _inventory[index] = item.copyWith(stock: newStock);
      }

      final filteredIndex = _filteredInventory.indexOf(item);
      if (filteredIndex != -1) {
        _filteredInventory[filteredIndex] = item.copyWith(stock: newStock);
      }

      // Si hay filtro de stock, puede que necesitemos actualizar la lista filtrada
      if (_onlyShowInStock) {
        _filterInventory();
      } else {
        _sortInventory();
      }
    });
  }

  void _updatePaintNotes(PaintInventoryItem item, String notes) {
    setState(() {
      // Actualizar en ambas listas
      final index = _inventory.indexOf(item);
      if (index != -1) {
        _inventory[index] = item.copyWith(notes: notes);
      }

      final filteredIndex = _filteredInventory.indexOf(item);
      if (filteredIndex != -1) {
        _filteredInventory[filteredIndex] = item.copyWith(notes: notes);
      }
      _sortInventory();
    });
  }

  // Mostrar detalles del item y opciones para editar
  void _showInventoryItemOptions(PaintInventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInventoryItemOptionsModal(item),
    );
  }

  Widget _buildInventoryItemOptionsModal(PaintInventoryItem item) {
    final paint = item.paint;
    final paintColor = Color(
      int.parse(paint.colorHex.substring(1, 7), radix: 16) + 0xFF000000,
    );
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    // Controller para notas con el valor actual
    final notesController = TextEditingController(text: item.notes);

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
              color:
                  isDarkMode ? Colors.grey[600] : Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
            margin: const EdgeInsets.only(bottom: 16),
          ),

          // Paint info header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: paintColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
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
                        color: isDarkMode ? AppTheme.marineOrange : null,
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

          const SizedBox(height: 24),

          // Stock control
          Text(
            'Current Stock: ${item.stock}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed:
                    item.stock > 0
                        ? () {
                          _updatePaintStock(item, item.stock - 1);
                          Navigator.pop(context);
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.red[isDarkMode ? 400 : 600],
                  disabledBackgroundColor:
                      isDarkMode ? Colors.grey[800] : Colors.grey[300],
                ),
                child: const Icon(Icons.remove, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${item.stock}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _updatePaintStock(item, item.stock + 1);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.green[isDarkMode ? 400 : 600],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notes section
          TextField(
            controller: notesController,
            decoration: InputDecoration(
              labelText: 'Notes',
              border: const OutlineInputBorder(),
              hintText: 'Add notes about this paint...',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            maxLines: 3,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),

          const SizedBox(height: 16),

          // Save button for notes
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _updatePaintNotes(item, notesController.text);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
              ),
              child: const Text('Save Notes'),
            ),
          ),

          const SizedBox(height: 16),

          // Remove from inventory option
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _updatePaintStock(item, 0);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[isDarkMode ? 400 : 600],
              ),
              child: const Text('Set Stock to Zero'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headerColor =
        isDarkMode
            ? AppTheme.marineBlue.withOpacity(0.3)
            : AppTheme.marineBlue.withOpacity(0.1);
    final alternateRowColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final summaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      appBar: AppHeader(
        title: 'My Inventory',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddNewPaintDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtro
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search inventory...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Filtro para mostrar solo items en stock
                    Row(
                      children: [
                        Checkbox(
                          value: _onlyShowInStock,
                          onChanged: (value) {
                            _toggleStockFilter(value ?? false);
                          },
                          activeColor: AppTheme.primaryBlue,
                        ),
                        const Text('Only show in-stock items'),
                      ],
                    ),
                    const Spacer(),
                    // Selector de tamaño de página
                    DropdownButton<int>(
                      value: _currentPageSize,
                      items:
                          _pageSizeOptions.map((size) {
                            return DropdownMenuItem<int>(
                              value: size,
                              child: Text('Show $size'),
                            );
                          }).toList(),
                      onChanged: (size) {
                        if (size != null) {
                          _changePageSize(size);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Resumen del inventario
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredInventory.length} paints in inventory',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: summaryTextColor,
                  ),
                ),
                Text(
                  'Total in stock: ${_filteredInventory.fold<int>(0, (sum, item) => sum + item.stock)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: summaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tabla de inventario
          Expanded(
            child:
                _paginatedInventory.isEmpty
                    ? Center(
                      child: Text(
                        'No paints in inventory',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    )
                    : ListView(
                      children: [
                        // Encabezados de la tabla
                        Container(
                          color: headerColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              // Color
                              const SizedBox(width: 32),
                              // Nombre
                              Expanded(
                                flex: 3,
                                child: GestureDetector(
                                  onTap: () => _changeSortColumn('name'),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_sortColumn == 'name')
                                        Icon(
                                          _isAscending
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Marca
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () => _changeSortColumn('brand'),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Brand',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_sortColumn == 'brand')
                                        Icon(
                                          _isAscending
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Categoría
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () => _changeSortColumn('category'),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Category',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_sortColumn == 'category')
                                        Icon(
                                          _isAscending
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Stock
                              SizedBox(
                                width: 60,
                                child: GestureDetector(
                                  onTap: () => _changeSortColumn('stock'),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Stock',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_sortColumn == 'stock')
                                        Icon(
                                          _isAscending
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Columna de acciones
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),

                        // Filas de la tabla
                        ...List.generate(_paginatedInventory.length, (index) {
                          final item = _paginatedInventory[index];
                          final paint = item.paint;

                          final paintColor = Color(
                            int.parse(
                                  paint.colorHex.substring(1, 7),
                                  radix: 16,
                                ) +
                                0xFF000000,
                          );

                          return InkWell(
                            onTap: () => _showInventoryItemOptions(item),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: borderColor,
                                    width: 1,
                                  ),
                                ),
                                color:
                                    index % 2 == 0
                                        ? Colors.transparent
                                        : alternateRowColor,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  // Color swatch
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: paintColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: borderColor,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Nombre
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      paint.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDarkMode
                                                ? AppTheme.marineOrange
                                                : Theme.of(
                                                  context,
                                                ).primaryColor,
                                      ),
                                    ),
                                  ),

                                  // Marca
                                  Expanded(flex: 2, child: Text(paint.brand)),

                                  // Categoría
                                  Expanded(
                                    flex: 2,
                                    child: Text(paint.category),
                                  ),

                                  // Stock
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '${item.stock}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            item.stock > 0
                                                ? Colors.green[isDarkMode
                                                    ? 400
                                                    : 600]
                                                : Colors.red[isDarkMode
                                                    ? 400
                                                    : 600],
                                      ),
                                    ),
                                  ),

                                  // Acciones
                                  SizedBox(
                                    width: 40,
                                    child: IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed:
                                          () => _showInventoryItemOptions(item),
                                      tooltip: 'Options',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
          ),

          // Paginación
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: PaginationControls(
                currentPage: _currentPage,
                totalPages: _totalPages,
                onPageChanged: _goToPage,
              ),
            ),
        ],
      ),
    );
  }

  void _showAddNewPaintDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final buttonColor =
        isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Paint'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newPaintNameController,
                  decoration: const InputDecoration(
                    labelText: 'Paint Name',
                    hintText: 'Enter paint name',
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPaintBrandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    hintText: 'Enter brand name',
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPaintCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'Enter category',
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPaintColorHexController,
                  decoration: const InputDecoration(
                    labelText: 'Color (Hex)',
                    hintText: 'Enter color hex (#RRGGBB)',
                    prefixText: '#',
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Validar y añadir
                final name = _newPaintNameController.text.trim();
                final brand = _newPaintBrandController.text.trim();
                final category = _newPaintCategoryController.text.trim();
                final colorHex = _newPaintColorHexController.text.trim();

                if (name.isNotEmpty &&
                    brand.isNotEmpty &&
                    category.isNotEmpty &&
                    colorHex.isNotEmpty) {
                  // Crear nuevo paint y añadir al inventario
                  final id = 'custom-${DateTime.now().millisecondsSinceEpoch}';
                  final paint = Paint(
                    id: id,
                    name: name,
                    brand: brand,
                    colorHex: '#$colorHex',
                    category: category,
                  );

                  final newItem = PaintInventoryItem(
                    paint: paint,
                    stock: 1,
                    notes: 'Custom added paint',
                  );

                  setState(() {
                    _inventory.add(newItem);
                    _filterInventory();
                  });

                  // Limpiar controladores
                  _newPaintNameController.clear();
                  _newPaintBrandController.clear();
                  _newPaintCategoryController.clear();
                  _newPaintColorHexController.clear();

                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(foregroundColor: buttonColor),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class PaintInventoryItem {
  final Paint paint;
  final int stock;
  final String notes;

  PaintInventoryItem({
    required this.paint,
    required this.stock,
    required this.notes,
  });

  PaintInventoryItem copyWith({Paint? paint, int? stock, String? notes}) {
    return PaintInventoryItem(
      paint: paint ?? this.paint,
      stock: stock ?? this.stock,
      notes: notes ?? this.notes,
    );
  }
}
