/// Inventory Screen for managing miniature paints.
///
/// This screen provides a complete inventory management system for miniature paints,
/// including:
/// - Browsing all paints in the user's inventory
/// - Filtering and sorting paints by various criteria
/// - Managing stock levels for each paint
/// - Adding notes to paints
/// - Adding new paints to the inventory
/// - Viewing which palettes use each paint
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miniature_paint_finder/components/confirmation_dialog.dart';
import 'package:miniature_paint_finder/components/pagination_controls.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/paint_inventory_item.dart';
import 'package:miniature_paint_finder/services/inventory_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';
import 'package:miniature_paint_finder/screens/library_screen.dart';

/// A screen for managing the user's paint inventory.
///
/// Features:
/// - Modern card-based UI for paint items
/// - Advanced filtering options (brand, category, stock range)
/// - Pagination for large inventories
/// - Stock management
/// - Paint details and notes
/// - Integration with the palette system
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

/// The state for the InventoryScreen widget.
class _InventoryScreenState extends State<InventoryScreen> {
  // Services
  final InventoryService _inventoryService = InventoryService();

  // State management
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Inventory data
  late List<PaintInventoryItem> _filteredInventory;
  late List<PaintInventoryItem> _paginatedInventory;

  // Search and filtering
  final TextEditingController _searchController = TextEditingController();
  bool _onlyShowInStock = false;
  String? _selectedBrand;
  String? _selectedCategory;
  RangeValues _stockRange = const RangeValues(0, 10);
  int _maxPossibleStock = 10;

  // Sorting
  bool _isAscending = true;
  String _sortColumn = 'name';

  // Pagination
  final List<int> _pageSizeOptions = [15, 25, 50];
  int _currentPageSize = 25;
  int _currentPage = 1;
  late int _totalPages;

  // Controllers for adding new paints
  final TextEditingController _newPaintNameController = TextEditingController();
  final TextEditingController _newPaintBrandController =
      TextEditingController();
  final TextEditingController _newPaintColorHexController =
      TextEditingController();
  final TextEditingController _newPaintCategoryController =
      TextEditingController();

  // Lists for filter dropdowns
  late List<String> _uniqueBrands;
  late List<String> _uniqueCategories;

  @override
  void initState() {
    super.initState();
    _filteredInventory = [];
    _paginatedInventory = [];
    _totalPages = 1;
    _uniqueBrands = [];
    _uniqueCategories = [];
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
    print('>>> InventoryScreen: Entrando a _loadInventory()');
    setState(() {
      _isLoading = true;
    });

    try {
      await _inventoryService.loadInventory(limit: _currentPageSize, page: _currentPage);
      _filteredInventory = _inventoryService.inventory;
      _uniqueCategories = _inventoryService.getUniqueCategories();
      _uniqueBrands = await _inventoryService.getUniqueBrands();
      _updatePaginatedInventory();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading inventory: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updatePaginatedInventory() {
    _totalPages = (_filteredInventory.length / _currentPageSize).ceil();
    if (_totalPages == 0) _totalPages = 1; // Always have at least 1 page

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

  /// Changes the active page in pagination.
  ///
  /// [page] must be within valid range (1 to _totalPages).
  /// Updates the UI to display items for the new page.
  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
      _loadInventory(); // Recargar con la nueva página
    });
  }

  /// Changes the number of items displayed per page.
  ///
  /// Resets to the first page when changing page size.
  void _changePageSize(int size) {
    setState(() {
      _currentPageSize = size;
      _currentPage = 1; // Reset a primera página
      _loadInventory(); // Recargar con el nuevo tamaño
    });
  }

  /// Filters the inventory based on current filter settings and search text.
  ///
  /// Applies all active filters:
  /// - Text search
  /// - Brand filter
  /// - Category filter
  /// - Stock range filter
  /// - In-stock only filter
  ///
  /// Then sorts the results and updates pagination.
  void _filterInventory() {
    if (_filteredInventory.isEmpty) return;
    
    setState(() {
      _currentPage = 1; // Reset a primera página al filtrar
      _filteredInventory = _inventoryService.filterInventory(
        searchQuery: _searchController.text,
        onlyInStock: _onlyShowInStock,
        brand: _selectedBrand,
        category: _selectedCategory,
        minStock: _stockRange.start.toInt(),
        maxStock: _stockRange.end.toInt(),
      );
      _updatePaginatedInventory();
    });
  }

  /// Toggles the "only show in-stock items" filter.
  void _toggleStockFilter(bool value) {
    setState(() {
      _onlyShowInStock = value;
      _filterInventory();
    });
  }

  /// Updates the stock range filter.
  void _updateStockRange(RangeValues values) {
    setState(() {
      _stockRange = values;
      _filterInventory();
    });
  }

  /// Updates the brand filter.
  void _updateBrandFilter(String? brand) {
    setState(() {
      _selectedBrand = brand;
      _filterInventory();
    });
  }

  /// Updates the category filter.
  void _updateCategoryFilter(String? category) {
    setState(() {
      _selectedCategory = category;
      _filterInventory();
    });
  }

  /// Resets all filters to their default values.
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

  /// Sorts the filtered inventory by the specified column.
  ///
  /// If the same column is selected again, reverses the sort direction.
  void _sortInventory() {
    _filteredInventory = _inventoryService.sortInventory(
      _filteredInventory,
      _sortColumn,
      _isAscending,
    );

    _updatePaginatedInventory();
  }

  /// Changes the column used for sorting.
  ///
  /// If the same column is selected again, reverses the sort direction.
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

  /// Updates the stock level for a paint inventory item.
  ///
  /// Updates both the UI state and the inventory service data.
  /// May trigger filtering if the new stock level doesn't match current filters.
  void _updatePaintStock(PaintInventoryItem item, int newStock) {
    // Prevent negative stock
    if (newStock < 0) return;

    // Update stock through service
    bool success = _inventoryService.updateStock(item.paint.id, newStock);

    if (success) {
      setState(() {
        // Update local item reference for the UI
        final index = _filteredInventory.indexOf(item);
        if (index != -1) {
          _filteredInventory[index] = item.copyWith(stock: newStock);
        }

        // If there's a stock filter, we might need to update the filtered list
        if (_onlyShowInStock ||
            newStock < _stockRange.start.toInt() ||
            newStock > _stockRange.end.toInt()) {
          _filterInventory();
        } else {
          _sortInventory();
        }
      });
    }
  }

  /// Updates the notes for a paint inventory item.
  ///
  /// Updates both the UI state and the inventory service data.
  void _updatePaintNotes(PaintInventoryItem item, String notes) {
    // Update notes through service
    bool success = _inventoryService.updateNotes(item.paint.id, notes);

    if (success) {
      setState(() {
        // Update local item reference for the UI
        final index = _filteredInventory.indexOf(item);
        if (index != -1) {
          _filteredInventory[index] = item.copyWith(notes: notes);
        }
        _sortInventory();
      });
    }
  }

  /// Shows a modal bottom sheet with paint details and management options.
  ///
  /// The modal allows:
  /// - Viewing paint details
  /// - Managing stock level
  /// - Adding/editing notes
  /// - Viewing palette usage
  /// - Removing the paint from inventory
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

  /// Gets a list of palette names using a specific paint.
  ///
  /// Uses the inventory service to retrieve palettes associated with the paint.
  List<String> _getPalettesUsingPaint(String paintId) {
    return _inventoryService.getPalettesUsingPaint(paintId);
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
          final index = _filteredInventory.indexOf(item);
          if (index != -1) {
            _filteredInventory.removeAt(index);
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
                  _filteredInventory.add(item);
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LibraryScreen(),
            ),
          );
        },
        backgroundColor: isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
        child: const Icon(Icons.add),
        tooltip: 'Add paint from library',
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
          final index = _filteredInventory.indexOf(item);
          if (index != -1) {
            _filteredInventory.removeAt(index);
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
                  _filteredInventory.add(item);
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
}
