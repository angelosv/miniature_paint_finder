import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miniature_paint_finder/components/pagination_controls.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';
import 'package:miniature_paint_finder/components/confirmation_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late List<Paint> _paints;
  late List<PaintInventoryItem> _inventory;
  late List<PaintInventoryItem> _filteredInventory;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;

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

  // Filtros
  bool _onlyShowInStock = false;
  bool _isAscending = true;
  String _sortColumn = 'name';
  String? _selectedBrand;
  String? _selectedCategory;
  RangeValues _stockRange = const RangeValues(0, 10);
  int _maxPossibleStock = 10;

  // Lista de marcas y categorías únicas para filtros
  late List<String> _uniqueBrands;
  late List<String> _uniqueCategories;

  @override
  void initState() {
    super.initState();
    _loadInventory();

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

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

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

    // Extraer marcas y categorías únicas para filtros
    _uniqueBrands = _extractUniqueBrands();
    _uniqueCategories = _extractUniqueCategories();

    // Determinar el stock máximo para el filtro de rango
    _maxPossibleStock = _inventory.fold(
      0,
      (max, item) => item.stock > max ? item.stock : max,
    );
    _stockRange = RangeValues(0, _maxPossibleStock.toDouble());

    _filteredInventory = List.from(_inventory);
    _updatePaginatedInventory();

    setState(() {
      _isLoading = false;
    });
  }

  void _updatePaginatedInventory() {
    _totalPages = (_filteredInventory.length / _currentPageSize).ceil();
    if (_totalPages == 0) _totalPages = 1; // Siempre al menos 1 página

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

            // Filtro de texto
            final nameMatches = paint.name.toLowerCase().contains(query);
            final brandMatches = paint.brand.toLowerCase().contains(query);
            final categoryMatches = paint.category.toLowerCase().contains(
              query,
            );
            final textMatch = (nameMatches || brandMatches || categoryMatches);

            // Filtro de stock
            final stockMatches = !_onlyShowInStock || item.stock > 0;
            final stockRangeMatches =
                item.stock >= _stockRange.start.toInt() &&
                item.stock <= _stockRange.end.toInt();

            // Filtro de marca y categoría
            final brandFilterMatches =
                _selectedBrand == null || paint.brand == _selectedBrand;
            final categoryFilterMatches =
                _selectedCategory == null ||
                paint.category == _selectedCategory;

            return textMatch &&
                stockMatches &&
                stockRangeMatches &&
                brandFilterMatches &&
                categoryFilterMatches;
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

  void _updateStockRange(RangeValues values) {
    setState(() {
      _stockRange = values;
      _filterInventory();
    });
  }

  void _updateBrandFilter(String? brand) {
    setState(() {
      _selectedBrand = brand;
      _filterInventory();
    });
  }

  void _updateCategoryFilter(String? category) {
    setState(() {
      _selectedCategory = category;
      _filterInventory();
    });
  }

  void _resetFilters() {
    setState(() {
      _onlyShowInStock = false;
      _selectedBrand = null;
      _selectedCategory = null;
      _stockRange = RangeValues(0, _maxPossibleStock.toDouble());
      _searchController.clear();
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
      if (_onlyShowInStock ||
          newStock < _stockRange.start ||
          newStock > _stockRange.end) {
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
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder:
                (_, controller) => SingleChildScrollView(
                  controller: controller,
                  child: _buildInventoryItemOptionsModal(item),
                ),
          ),
    );
  }

  // Get palettes using a specific paint
  List<String> _getPalettesUsingPaint(String paintId) {
    // In a real app, this would fetch data from a repository or service
    // For demo purposes, we'll return sample data based on the paintId
    final List<String> palettes = [];

    // Generate some sample palette names based on the paintId hash
    final hashCode = paintId.hashCode;

    if (hashCode % 3 == 0) {
      palettes.add('Space Marines');
    }

    if (hashCode % 5 == 0) {
      palettes.add('Imperial Guard');
    }

    if (hashCode % 7 == 0) {
      palettes.add('Chaos Warriors');
    }

    if (hashCode % 11 == 0) {
      palettes.add('Necrons');
    }

    if (hashCode % 13 == 0) {
      palettes.add('Eldar');
    }

    // Ensure some paints have no palettes
    if (hashCode % 17 == 0) {
      palettes.clear();
    }

    return palettes;
  }

  Widget _buildInventoryItemOptionsModal(PaintInventoryItem item) {
    final paint = item.paint;
    final paintColor = Color(
      int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000,
    );
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    // Controller for notes with current value
    final notesController = TextEditingController(text: item.notes);

    // Get palettes using this paint
    final palettesUsingPaint = _getPalettesUsingPaint(paint.id);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? Colors.grey[600]
                        : Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 20),
            ),
          ),

          // Header with paint info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color swatch
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: paintColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 0,
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
                    Text(
                      paint.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode
                                ? AppTheme.marineOrange
                                : AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${paint.brand}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Category: ${paint.category}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    if (paint.code.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Code: ${paint.code}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // Stock control
          Text(
            'Stock Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkSurface : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Material(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        item.stock > 0
                            ? () {
                              _updatePaintStock(item, item.stock - 1);
                              // Haptic feedback if available
                              HapticFeedback.mediumImpact();
                            }
                            : null,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            item.stock > 0
                                ? (isDarkMode
                                    ? AppTheme.marineOrange.withOpacity(0.8)
                                    : AppTheme.primaryBlue.withOpacity(0.9))
                                : (isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[300]),
                        boxShadow:
                            item.stock > 0
                                ? [
                                  BoxShadow(
                                    color: (isDarkMode
                                            ? AppTheme.marineOrange
                                            : AppTheme.primaryBlue)
                                        .withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : null,
                      ),
                      child: const Icon(
                        Icons.remove,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${item.stock}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                Material(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _updatePaintStock(item, item.stock + 1);
                      // Haptic feedback if available
                      HapticFeedback.mediumImpact();
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isDarkMode
                                ? AppTheme.marineOrange
                                : AppTheme.primaryBlue,
                        boxShadow: [
                          BoxShadow(
                            color: (isDarkMode
                                    ? AppTheme.marineOrange
                                    : AppTheme.primaryBlue)
                                .withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // Palettes section
          Text(
            'Used in Palettes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          palettesUsingPaint.isEmpty
              ? Text(
                'Not used in any palette',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              )
              : Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    palettesUsingPaint.map((palette) {
                      return Chip(
                        label: Text(palette),
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
              ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // Notes section
          Text(
            'Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: notesController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Add notes about this paint...',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            maxLines: 3,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),

          const SizedBox(height: 32),

          // Update button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _updatePaintNotes(item, notesController.text);
                Navigator.pop(context);

                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${paint.name} updated'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor:
                        isDarkMode ? Colors.grey[800] : Colors.grey[900],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'UPDATE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Remove from inventory option
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _showRemoveConfirmationDialog(item);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[isDarkMode ? 400 : 600],
                side: BorderSide(color: Colors.red[isDarkMode ? 400 : 600]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'REMOVE FROM INVENTORY',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmationDialog(PaintInventoryItem item) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final paint = item.paint;

    ConfirmationDialog.show(
      context: context,
      title: "Remove from Inventory?",
      message:
          "Are you sure you want to remove ${paint.name} from your inventory?",
      confirmText: "REMOVE",
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(
                  int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paint.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue,
                    ),
                  ),
                  Text(
                    '${paint.brand} - Stock: ${item.stock}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        // Remove from inventory
        setState(() {
          final index = _inventory.indexOf(item);
          if (index != -1) {
            _inventory.removeAt(index);
          }
          _filterInventory();
        });

        // Close bottom sheet
        Navigator.of(context).pop();

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${paint.name} removed from inventory'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[900],
            action: SnackBarAction(
              label: 'UNDO',
              textColor: isDarkMode ? AppTheme.marineOrange : Colors.white,
              onPressed: () {
                setState(() {
                  _inventory.add(item);
                  _filterInventory();
                });
              },
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      selectedIndex: -1, // Not a bottom nav item
      title: 'My Inventory',
      body:
          _isLoading
              ? _buildLoader(isDarkMode)
              : _buildBody(context, isDarkMode),
      drawer: const SharedDrawer(currentScreen: 'inventory'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNewPaintDialog,
        backgroundColor:
            isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
        child: const Icon(Icons.add),
        tooltip: 'Add paint to inventory',
      ),
    );
  }

  Widget _buildLoader(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading inventory...',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search inventory...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
              filled: true,
              fillColor: isDarkMode ? AppTheme.darkSurface : Colors.white,
            ),
          ),
        ),

        // Chips para filtros rápidos y botón de filtros avanzados
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Chip para solo mostrar items en stock
              FilterChip(
                label: const Text('In Stock'),
                selected: _onlyShowInStock,
                onSelected: _toggleStockFilter,
                backgroundColor:
                    isDarkMode ? AppTheme.darkSurface : Colors.grey[200],
                selectedColor:
                    isDarkMode
                        ? AppTheme.marineOrange.withOpacity(0.3)
                        : AppTheme.primaryBlue.withOpacity(0.2),
                checkmarkColor:
                    isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
                labelStyle: TextStyle(
                  color:
                      _onlyShowInStock
                          ? isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue
                          : isDarkMode
                          ? Colors.white70
                          : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),

              // Más filtros (desplegables)
              TextButton.icon(
                onPressed: _showFilterDialog,
                icon: Icon(
                  Icons.filter_list,
                  color:
                      isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
                  size: 20,
                ),
                label: Text(
                  'Filters',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppTheme.marineOrange
                            : AppTheme.primaryBlue,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  backgroundColor:
                      isDarkMode
                          ? AppTheme.marineOrange.withOpacity(0.1)
                          : AppTheme.primaryBlue.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const Spacer(),

              // Selector de visualización por página
              DropdownButton<int>(
                value: _currentPageSize,
                items:
                    _pageSizeOptions.map((size) {
                      return DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size / page'),
                      );
                    }).toList(),
                onChanged: (size) {
                  if (size != null) {
                    _changePageSize(size);
                  }
                },
                dropdownColor: isDarkMode ? AppTheme.darkSurface : Colors.white,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                underline: Container(height: 0),
              ),
            ],
          ),
        ),

        // Indicadores de filtros activos
        if (_selectedBrand != null ||
            _selectedCategory != null ||
            _stockRange.start > 0 ||
            _stockRange.end < _maxPossibleStock)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Text(
                  'Active filters:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),

                if (_selectedBrand != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      label: Text(_selectedBrand!),
                      onDeleted: () => _updateBrandFilter(null),
                      backgroundColor:
                          isDarkMode ? AppTheme.darkSurface : Colors.grey[200],
                      deleteIconColor:
                          isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                if (_selectedCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      label: Text(_selectedCategory!),
                      onDeleted: () => _updateCategoryFilter(null),
                      backgroundColor:
                          isDarkMode ? AppTheme.darkSurface : Colors.grey[200],
                      deleteIconColor:
                          isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                if (_stockRange.start > 0 ||
                    _stockRange.end < _maxPossibleStock)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      label: Text(
                        'Stock: ${_stockRange.start.toInt()}-${_stockRange.end.toInt()}',
                      ),
                      onDeleted:
                          () => setState(() {
                            _stockRange = RangeValues(
                              0,
                              _maxPossibleStock.toDouble(),
                            );
                            _filterInventory();
                          }),
                      backgroundColor:
                          isDarkMode ? AppTheme.darkSurface : Colors.grey[200],
                      deleteIconColor:
                          isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                IconButton(
                  icon: Icon(
                    Icons.clear_all,
                    size: 18,
                    color:
                        isDarkMode
                            ? AppTheme.marineOrange
                            : AppTheme.primaryBlue,
                  ),
                  onPressed: _resetFilters,
                  tooltip: 'Clear all filters',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                ),
              ],
            ),
          ),

        // Resumen del inventario
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredInventory.length} paints',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                'Total in stock: ${_filteredInventory.fold<int>(0, (sum, item) => sum + item.stock)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Lista de inventario
        Expanded(
          child:
              _paginatedInventory.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color:
                              isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No paints in inventory',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                        if (_selectedBrand != null ||
                            _selectedCategory != null ||
                            _onlyShowInStock ||
                            _searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: _resetFilters,
                            child: Text(
                              'Clear filters',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppTheme.marineOrange
                                        : AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: _paginatedInventory.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final item = _paginatedInventory[index];
                      return _buildInventoryCard(item, isDarkMode);
                    },
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
    );
  }

  Widget _buildInventoryCard(PaintInventoryItem item, bool isDarkMode) {
    final paint = item.paint;
    final paintColor = Color(
      int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000,
    );

    return Dismissible(
      key: Key(item.paint.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await ConfirmationDialog.show(
          context: context,
          title: "Remove from Inventory?",
          message:
              "Are you sure you want to remove ${paint.name} from your inventory?",
          confirmText: "REMOVE",
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: paintColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paint.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? AppTheme.marineOrange
                                  : AppTheme.primaryBlue,
                        ),
                      ),
                      Text(
                        '${paint.brand} - Stock: ${item.stock}',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      onDismissed: (direction) {
        setState(() {
          final index = _inventory.indexOf(item);
          if (index != -1) {
            _inventory.removeAt(index);
          }
          _filterInventory();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${paint.name} removed from inventory'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[900],
            action: SnackBarAction(
              label: 'UNDO',
              textColor: isDarkMode ? AppTheme.marineOrange : Colors.white,
              onPressed: () {
                setState(() {
                  _inventory.add(item);
                  _filterInventory();
                });
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
        child: InkWell(
          onTap: () => _showInventoryItemOptions(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Brand logo or first letter of brand
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      paint.brand.isNotEmpty
                          ? paint.brand[0].toUpperCase()
                          : "?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Paint info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paint.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              isDarkMode
                                  ? AppTheme.marineOrange
                                  : AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${paint.brand} • ${paint.category}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stock tag (smaller)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        item.stock > 0
                            ? (isDarkMode
                                ? Colors.green[900]
                                : Colors.green[50])
                            : (isDarkMode ? Colors.red[900] : Colors.red[50]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          item.stock > 0
                              ? (isDarkMode
                                  ? Colors.green[700]!
                                  : Colors.green[300]!)
                              : (isDarkMode
                                  ? Colors.red[700]!
                                  : Colors.red[300]!),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${item.stock}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color:
                          item.stock > 0
                              ? (isDarkMode
                                  ? Colors.green[300]
                                  : Colors.green[700])
                              : (isDarkMode
                                  ? Colors.red[300]
                                  : Colors.red[700]),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Color swatch
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: paintColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                    ),
                  ),

                  // Header
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Filter Inventory',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Filtro por marca
                  Text(
                    'Brand',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                    ),
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _selectedBrand,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Brands'),
                        ),
                        ..._uniqueBrands.map((brand) {
                          return DropdownMenuItem<String?>(
                            value: brand,
                            child: Text(brand),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          _selectedBrand = value;
                        });
                      },
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      underline: Container(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Filtro por categoría
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                    ),
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _selectedCategory,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._uniqueCategories.map((category) {
                          return DropdownMenuItem<String?>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          _selectedCategory = value;
                        });
                      },
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      underline: Container(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Filtro por rango de stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? AppTheme.darkSurface
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_stockRange.start.toInt()} - ${_stockRange.end.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color:
                                isDarkMode
                                    ? AppTheme.marineOrange
                                    : AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      activeTrackColor:
                          isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue,
                      inactiveTrackColor:
                          isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      thumbColor:
                          isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue,
                      overlayColor: (isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue)
                          .withOpacity(0.2),
                      valueIndicatorColor:
                          isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue,
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    child: RangeSlider(
                      values: _stockRange,
                      min: 0,
                      max: _maxPossibleStock.toDouble(),
                      divisions: _maxPossibleStock,
                      labels: RangeLabels(
                        _stockRange.start.toInt().toString(),
                        _stockRange.end.toInt().toString(),
                      ),
                      onChanged: (values) {
                        setModalState(() {
                          _stockRange = values;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                            side: BorderSide(
                              color:
                                  isDarkMode
                                      ? Colors.grey[600]!
                                      : Colors.grey[300]!,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _filterInventory();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDarkMode
                                    ? AppTheme.marineOrange
                                    : AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddNewPaintDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                    ),
                  ),

                  // Header
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Add New Paint to Inventory',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Campos para el nuevo paint
                  Text(
                    'Paint Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPaintNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter paint name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      fillColor:
                          isDarkMode ? AppTheme.darkSurface : Colors.white,
                      filled: true,
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Brand',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPaintBrandController,
                    decoration: InputDecoration(
                      hintText: 'Enter brand name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      fillColor:
                          isDarkMode ? AppTheme.darkSurface : Colors.white,
                      filled: true,
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPaintCategoryController,
                    decoration: InputDecoration(
                      hintText: 'Enter category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      fillColor:
                          isDarkMode ? AppTheme.darkSurface : Colors.white,
                      filled: true,
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Color (Hex)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPaintColorHexController,
                    decoration: InputDecoration(
                      hintText: 'Enter color hex (RRGGBB)',
                      prefixText: '#',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      fillColor:
                          isDarkMode ? AppTheme.darkSurface : Colors.white,
                      filled: true,
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                            side: BorderSide(
                              color:
                                  isDarkMode
                                      ? Colors.grey[600]!
                                      : Colors.grey[300]!,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Validar y añadir
                            final name = _newPaintNameController.text.trim();
                            final brand = _newPaintBrandController.text.trim();
                            final category =
                                _newPaintCategoryController.text.trim();
                            final colorHex =
                                _newPaintColorHexController.text.trim();

                            if (name.isNotEmpty &&
                                brand.isNotEmpty &&
                                category.isNotEmpty &&
                                colorHex.isNotEmpty) {
                              // Crear nuevo paint y añadir al inventario
                              final id =
                                  'custom-${DateTime.now().millisecondsSinceEpoch}';
                              final paint = Paint.fromHex(
                                id: id,
                                name: name,
                                brand: brand,
                                hex: '#$colorHex',
                                category: category,
                                set: 'Custom',
                                code: id.substring(0, 8),
                              );

                              final newItem = PaintInventoryItem(
                                paint: paint,
                                stock: 1,
                                notes: 'Custom added paint',
                              );

                              setState(() {
                                _inventory.add(newItem);

                                // Actualizar listas de marcas y categorías únicas
                                if (!_uniqueBrands.contains(brand)) {
                                  _uniqueBrands.add(brand);
                                  _uniqueBrands.sort();
                                }

                                if (!_uniqueCategories.contains(category)) {
                                  _uniqueCategories.add(category);
                                  _uniqueCategories.sort();
                                }

                                _filterInventory();
                              });

                              // Limpiar controladores
                              _newPaintNameController.clear();
                              _newPaintBrandController.clear();
                              _newPaintCategoryController.clear();
                              _newPaintColorHexController.clear();

                              Navigator.pop(context);

                              // Mostrar confirmación
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$name added to inventory'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor:
                                      isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[900],
                                  action: SnackBarAction(
                                    label: 'VIEW',
                                    textColor:
                                        isDarkMode
                                            ? AppTheme.marineOrange
                                            : Colors.white,
                                    onPressed: () {
                                      // Scroll to the newly added item
                                      // This is a placeholder - would need actual implementation
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDarkMode
                                    ? AppTheme.marineOrange
                                    : AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ADD PAINT',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Método para extraer marcas únicas
  List<String> _extractUniqueBrands() {
    final brands = _inventory.map((item) => item.paint.brand).toSet().toList();
    brands.sort();
    return brands;
  }

  // Método para extraer categorías únicas
  List<String> _extractUniqueCategories() {
    final categories =
        _inventory.map((item) => item.paint.category).toSet().toList();
    categories.sort();
    return categories;
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
