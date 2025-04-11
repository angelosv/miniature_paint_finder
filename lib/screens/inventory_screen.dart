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
import 'package:miniature_paint_finder/services/brand_service_manager.dart';
import 'package:miniature_paint_finder/models/paint_brand.dart';
import 'package:miniature_paint_finder/services/paint_brand_service.dart';

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
  final BrandServiceManager _brandManager = BrandServiceManager();
  final PaintBrandService _paintBrandService = PaintBrandService();

  // State management
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Focus nodes
  final FocusNode _notesFocusNode = FocusNode();
  late TextEditingController _notesController;
  late ValueNotifier<String> _tempNotes;
  late ValueNotifier<int> _tempStock;

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

  // Almacenamiento de logotipos de marcas
  final Map<String, String?> _brandLogos = {};

  @override
  void initState() {
    super.initState();
    _filteredInventory = [];
    _paginatedInventory = [];
    _totalPages = 1;
    _uniqueBrands = [];
    _uniqueCategories = [];
    _initializeServices();
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
    _notesFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    print('>>> InventoryScreen: Entrando a _loadInventory()');
    setState(() {
      _isLoading = true;
    });

    try {
      await _inventoryService.loadInventory(
        limit: _currentPageSize,
        page: _currentPage,
        searchQuery: _searchController.text,
        onlyInStock: _onlyShowInStock,
        brand: _selectedBrand,
        category: _selectedCategory,
        minStock: _stockRange.start.toInt(),
        maxStock: _stockRange.end.toInt(),
      );
      _filteredInventory = _inventoryService.inventory;
      _uniqueCategories = _inventoryService.getUniqueCategories();
      _uniqueBrands = await _inventoryService.getUniqueBrands();
      _totalPages = _inventoryService.totalPages;
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
    // Usar directamente _filteredInventory que ya viene paginado de la API
    _paginatedInventory = _filteredInventory;

    // Ya no necesitamos hacer paginación local porque la API ya nos envía los datos paginados
    // final startIndex = (_currentPage - 1) * _currentPageSize;
    // final endIndex = _currentPage * _currentPageSize;
    //
    // if (startIndex >= _filteredInventory.length) {
    //   _paginatedInventory = [];
    // } else {
    //   _paginatedInventory = _filteredInventory.sublist(
    //     startIndex,
    //     endIndex < _filteredInventory.length
    //         ? endIndex
    //         : _filteredInventory.length,
    //   );
    // }
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
    // En lugar de filtrar localmente, recargamos desde la API con los filtros
    setState(() {
      _currentPage = 1; // Reset a primera página al filtrar
      _loadInventory(); // Recargar con los filtros actuales
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
  void _updatePaintStock(PaintInventoryItem item, int newStock) async {
    // Prevent negative stock
    if (newStock < 0) return;

    // Update stock through service
    bool success = await _inventoryService.updateStockFromApi(
      item.id,
      newStock,
    );

    if (success) {
      setState(() {
        // Create a new modifiable list instead of modifying the immutable one
        final newFilteredInventory = List<PaintInventoryItem>.from(
          _filteredInventory,
        );
        final index = newFilteredInventory.indexOf(item);
        if (index != -1) {
          newFilteredInventory[index] = item.copyWith(stock: newStock);
          _filteredInventory = newFilteredInventory;
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
  void _updatePaintNotes(PaintInventoryItem item, String notes) async {
    // Update notes through service
    bool success = await _inventoryService.updateNotesFromApi(item.id, notes);

    if (success) {
      setState(() {
        // Create a new modifiable list instead of modifying the immutable one
        final newFilteredInventory = List<PaintInventoryItem>.from(
          _filteredInventory,
        );
        final index = newFilteredInventory.indexOf(item);
        if (index != -1) {
          newFilteredInventory[index] = item.copyWith(notes: notes);
          _filteredInventory = newFilteredInventory;
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
    // Inicializar el controlador y los ValueNotifier con los valores actuales
    _notesController = TextEditingController(text: item.notes);
    _tempNotes = ValueNotifier<String>(item.notes);
    _tempStock = ValueNotifier<int>(item.stock);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildInventoryItemOptionsModal(
            item,
            _notesController,
            _tempNotes,
            _tempStock,
          ),
    ).then((_) {
      // Limpiar el controlador cuando se cierra el modal
      _notesController.dispose();
    });
  }

  /// Gets a list of palette names using a specific paint.
  ///
  /// Uses the inventory service to retrieve palettes associated with the paint.
  List<String> _getPalettesUsingPaint(String paintId) {
    return _inventoryService.getPalettesUsingPaint(paintId);
  }

  Widget _buildInventoryItemOptionsModal(
    PaintInventoryItem item,
    TextEditingController notesController,
    ValueNotifier<String> tempNotes,
    ValueNotifier<int> tempStock,
  ) {
    final paint = item.paint;
    final paintColor = Color(
      int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000,
    );
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    // Determinar el brandId correcto de forma segura
    final String brandId = _getSafeBrandId(paint);

    // Obtener el nombre oficial de forma segura
    final String officialBrandName = _getSafeBrandName(brandId, paint.brand);

    // Formatear la fecha de forma amigable
    final String addedDate = _formatAddedDate(item);

    // Get palettes using this paint
    final palettesUsingPaint = _getPalettesUsingPaint(paint.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Drag handle y encabezado - no scrollable
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
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
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDarkMode
                                          ? AppTheme.marineOrange
                                          : AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                officialBrandName,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Added $addedDate',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stock indicator
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: _buildStockContainer(item.stock, isDarkMode),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 32),

              // Contenido scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    80,
                  ), // Padding adicional abajo para los botones
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección más pequeña de Stock Management
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? AppTheme.darkSurface
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock Management',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Botón de decrementar
                                Material(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap:
                                        tempStock.value > 0
                                            ? () {
                                              tempStock.value =
                                                  tempStock.value - 1;
                                              HapticFeedback.mediumImpact();
                                            }
                                            : null,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            tempStock.value > 0
                                                ? (isDarkMode
                                                    ? AppTheme.marineOrange
                                                        .withOpacity(0.8)
                                                    : AppTheme.primaryBlue
                                                        .withOpacity(0.9))
                                                : (isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.grey[300]),
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),

                                // Visualización del stock
                                ValueListenableBuilder<int>(
                                  valueListenable: tempStock,
                                  builder: (context, value, child) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isDarkMode
                                                ? Colors.grey[900]
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[800]!
                                                  : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        '$value',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Botón de incrementar
                                Material(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      tempStock.value = tempStock.value + 1;
                                      HapticFeedback.mediumImpact();
                                    },
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            isDarkMode
                                                ? AppTheme.marineOrange
                                                : AppTheme.primaryBlue,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Palettes section
                      Text(
                        'Used in Palettes',
                        style: TextStyle(
                          fontSize: 16,
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
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
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
                                        isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.grey[200],
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 0,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                          ),

                      const SizedBox(height: 24),

                      // Notes section
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: notesController,
                        focusNode: _notesFocusNode,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Add notes about this paint...',
                          hintStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                        maxLines: 3,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: (value) {
                          tempNotes.value = value;
                        },
                        onSubmitted: (value) {
                          tempNotes.value = value;
                          _notesFocusNode.unfocus();
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Botones fijos en la parte inferior
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Botón para añadir a wishlist
                    OutlinedButton.icon(
                      onPressed: () {
                        // Aquí iría la lógica para añadir a wishlist
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${paint.name} added to wishlist'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Add to wishlist'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón de actualizar
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Actualizar stock
                          _updatePaintStock(item, tempStock.value);

                          // Actualizar notas
                          if (tempNotes.value != item.notes) {
                            _updatePaintNotes(item, tempNotes.value);
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${paint.name} updated'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode
                                  ? AppTheme.marineOrange
                                  : AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
    ).then((confirmed) async {
      if (confirmed == true) {
        print('🔄 Iniciando eliminación de ${paint.name} del inventario');

        // Cerrar el modal de opciones primero
        Navigator.of(context).pop();

        // Llamar al servicio para eliminar
        final success = await _inventoryService.deleteInventoryRecord(item.id);

        if (success) {
          print('✅ Pintura eliminada exitosamente del inventario');

          setState(() {
            // Crear una nueva lista modificable
            final newFilteredInventory = List<PaintInventoryItem>.from(
              _filteredInventory,
            );
            final index = newFilteredInventory.indexOf(item);
            if (index != -1) {
              newFilteredInventory.removeAt(index);
            }
            _filteredInventory = newFilteredInventory;
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
            ),
          );
        } else {
          print('❌ Error al eliminar la pintura del inventario');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing ${paint.name} from inventory'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      selectedIndex: 2, // Inventory tab
      title: 'My Inventory',
      body:
          _isLoading
              ? _buildLoader(isDarkMode)
              : _buildBody(context, isDarkMode),
      drawer: const SharedDrawer(currentScreen: 'inventory'),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón principal (agregar pinturas)
          FloatingActionButton(
            heroTag: 'add-button',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LibraryScreen()),
              );
            },
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.marineOrange
                    : AppTheme.primaryBlue,
            tooltip: 'Add paint from library',
            child: const Icon(Icons.add),
          ),
        ],
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

    // Determinar el brandId correcto de forma segura
    final String brandId = _getSafeBrandId(paint);

    // Obtener el nombre oficial de forma segura
    final String officialBrandName = _getSafeBrandName(brandId, paint.brand);

    // Formatear la fecha de forma amigable
    final String addedDate = _formatAddedDate(item);

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
          confirmText: "Remove",
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
                        '${officialBrandName} - Stock: ${item.stock}',
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
      onDismissed: (direction) async {
        print(
          '🔄 Iniciando eliminación de ${paint.name} del inventario (swipe)',
        );

        // Llamar al servicio para eliminar
        final success = await _inventoryService.deleteInventoryRecord(item.id);

        if (success) {
          print('✅ Pintura eliminada exitosamente del inventario');

          setState(() {
            // Crear una nueva lista modificable
            final newFilteredInventory = List<PaintInventoryItem>.from(
              _filteredInventory,
            );
            final index = newFilteredInventory.indexOf(item);
            if (index != -1) {
              newFilteredInventory.removeAt(index);
            }
            _filteredInventory = newFilteredInventory;
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
            ),
          );
        } else {
          print('❌ Error al eliminar la pintura del inventario');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing ${paint.name} from inventory'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                // Avatar con el color de la pintura
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: paintColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1,
                    ),
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
                        'Added $addedDate',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Brand logo o imagen
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildBrandLogo(brandId, officialBrandName, isDarkMode),
                      const SizedBox(height: 4),
                      Text(
                        officialBrandName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Stock tag (tamaño fijo)
                _buildStockContainer(item.stock, isDarkMode),
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

  /// Inicializa todos los servicios necesarios
  Future<void> _initializeServices() async {
    // Cargar datos de marcas en segundo plano para no bloquear la UI
    _loadBrandData().catchError((e) {
      print('⚠️ Error inicializando servicio de marcas: $e');
      // La UI seguirá funcionando aunque falle la carga de marcas
    });
  }

  /// Determina el brand_id correcto de forma segura
  String _getSafeBrandId(Paint paint) {
    try {
      return _brandManager.determineBrandIdForPaint(paint);
    } catch (e) {
      print('⚠️ Error determinando brand_id: $e');
      // Retornar el nombre de la marca como fallback
      return paint.brand;
    }
  }

  /// Obtiene el nombre oficial de una marca de forma segura
  String _getSafeBrandName(String brandId, String fallbackName) {
    try {
      final name = _brandManager.getBrandName(brandId);
      return name ?? fallbackName;
    } catch (e) {
      print('⚠️ Error obteniendo nombre de marca: $e');
      return fallbackName;
    }
  }

  /// Obtiene el logoUrl para un brandId de forma segura
  String? _getSafeLogoUrl(String brandId) {
    try {
      return _brandLogos[brandId];
    } catch (e) {
      print('⚠️ Error obteniendo logo URL: $e');
      return null;
    }
  }

  /// Construye el logo de la marca para la tarjeta
  Widget _buildBrandLogo(String brandId, String brandName, bool isDarkMode) {
    final String? logoUrl = _getSafeLogoUrl(brandId);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        shape: BoxShape.circle,
        image:
            logoUrl != null && logoUrl.isNotEmpty
                ? DecorationImage(
                  image: NetworkImage(logoUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    print('⚠️ Error cargando imagen: $exception');
                  },
                )
                : null,
      ),
      child:
          logoUrl == null || logoUrl.isEmpty
              ? Center(
                child: Text(
                  brandName.isNotEmpty ? brandName[0].toUpperCase() : "?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              )
              : null,
    );
  }

  /// Construye un widget seguro para mostrar el contenedor de stock
  Widget _buildStockContainer(int stock, bool isDarkMode) {
    return Container(
      constraints: const BoxConstraints(minWidth: 38, minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            stock > 0
                ? (isDarkMode ? Colors.green[900] : Colors.green[50])
                : (isDarkMode ? Colors.red[900] : Colors.red[50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              stock > 0
                  ? (isDarkMode ? Colors.green[700]! : Colors.green[300]!)
                  : (isDarkMode ? Colors.red[700]! : Colors.red[300]!),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '$stock',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color:
                stock > 0
                    ? (isDarkMode ? Colors.green[300] : Colors.green[700])
                    : (isDarkMode ? Colors.red[300] : Colors.red[700]),
          ),
        ),
      ),
    );
  }

  /// Carga los datos de marcas y logotipos
  Future<void> _loadBrandData() async {
    await _brandManager.initialize();

    try {
      final brands = await _paintBrandService.getPaintBrands();
      for (final brand in brands) {
        _brandLogos[brand.id] = brand.logoUrl;
      }
      print('✅ Logotipos de marcas cargados: ${_brandLogos.length}');

      // Añadir logotipos predeterminados para marcas conocidas
      _addDefaultBrandLogos();
    } catch (e) {
      print('❌ Error al cargar datos de marcas: $e');

      // Si falla la carga desde API, al menos cargar los logotipos predeterminados
      _addDefaultBrandLogos();
    }
  }

  /// Añade logotipos predeterminados para marcas conocidas
  void _addDefaultBrandLogos() {
    final defaultLogos = {
      'Army_Painter': 'https://i.imgur.com/OuMPZQh.png', // Logo de Army Painter
      'Citadel_Colour': 'https://i.imgur.com/YOXbGGb.png', // Logo de Citadel
      'Vallejo': 'https://i.imgur.com/CDx4LhM.png', // Logo de Vallejo
      'AK': 'https://i.imgur.com/5e8s6Uq.png', // Logo de AK Interactive
      'Scale75': 'https://i.imgur.com/eSLYGMG.png', // Logo de Scale 75
      'P3': 'https://i.imgur.com/4X1YQlH.png', // Logo de P3
      'Green_Stuff_World':
          'https://i.imgur.com/tNlNiWK.png', // Logo de Green Stuff World
    };

    // Solo agregar si no existen ya en el mapa
    defaultLogos.forEach((key, value) {
      if (!_brandLogos.containsKey(key) ||
          _brandLogos[key] == null ||
          _brandLogos[key]!.isEmpty) {
        _brandLogos[key] = value;
      }
    });

    print('✅ Logotipos predeterminados añadidos: ${defaultLogos.length}');
  }

  /// Formatea la fecha de adición de forma amigable
  String _formatAddedDate(PaintInventoryItem item) {
    // En un caso real, se obtendría de item.addedAt
    // Por ahora usamos una fecha aleatoria para mostrar diferentes formatos
    final DateTime now = DateTime.now();
    final int daysAgo = (item.paint.id.hashCode % 30).abs();
    final DateTime addedDate = now.subtract(Duration(days: daysAgo));

    if (daysAgo == 0) {
      return 'today';
    } else if (daysAgo == 1) {
      return 'yesterday';
    } else if (daysAgo < 7) {
      return '$daysAgo days ago';
    } else if (daysAgo < 30) {
      final int weeks = (daysAgo / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${addedDate.day}/${addedDate.month}/${addedDate.year}';
    }
  }
}
