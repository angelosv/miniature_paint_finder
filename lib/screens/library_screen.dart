import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/paint_grid_card.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final List<Paint> _allPaints = SampleData.getPaints();
  late List<Paint> _filteredPaints;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Paginación
  final List<int> _pageSizeOptions = [25, 50, 100];
  int _currentPageSize = 25;
  int _currentPage = 1;
  late int _totalPages;
  late List<Paint> _paginatedPaints;
  final ScrollController _scrollController = ScrollController();

  // Lista de favoritos
  final Set<String> _wishlist = {
    'cit-base-002', // Mephiston Red
    'val-model-003', // Silver
    'army-warpaints-001', // Matt Black
  };

  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String _selectedBrand = 'All';
  String _selectedCategory = 'All';
  Color? _selectedColor;

  // Opciones para los filtros
  late List<String> _brands;
  late List<String> _categories;

  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _filteredPaints = _allPaints;
    _updatePaginatedPaints();

    // Extraer marcas únicas
    _brands = ['All']
      ..addAll(_allPaints.map((paint) => paint.brand).toSet().toList()..sort());

    // Extraer categorías únicas
    _categories = ['All']..addAll(
      _allPaints.map((paint) => paint.category).toSet().toList()..sort(),
    );

    // Listener para la búsqueda por texto
    _searchController.addListener(_filterPaints);

    // Listener para scroll infinito
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _currentPage < _totalPages) {
      // Cargar la siguiente página cuando nos acercamos al final
      setState(() {
        _currentPage++;
        _updatePaginatedPaints();
      });
    }
  }

  void _updatePaginatedPaints() {
    _totalPages = (_filteredPaints.length / _currentPageSize).ceil();

    final startIndex = (_currentPage - 1) * _currentPageSize;
    final endIndex = _currentPage * _currentPageSize;

    _paginatedPaints = _filteredPaints.sublist(
      startIndex < _filteredPaints.length ? startIndex : 0,
      endIndex < _filteredPaints.length ? endIndex : _filteredPaints.length,
    );
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
      _updatePaginatedPaints();
    });

    // Volver al inicio de la lista
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _changePageSize(int pageSize) {
    setState(() {
      _currentPageSize = pageSize;
      _currentPage = 1; // Volver a la primera página
      _updatePaginatedPaints();
    });
  }

  void _toggleWishlist(String paintId) {
    setState(() {
      if (_wishlist.contains(paintId)) {
        _wishlist.remove(paintId);
      } else {
        _wishlist.add(paintId);
      }
    });

    // Mostrar una notificación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _wishlist.contains(paintId)
              ? 'Added to wishlist'
              : 'Removed from wishlist',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Método para filtrar pinturas
  void _filterPaints() {
    setState(() {
      _filteredPaints =
          _allPaints.where((paint) {
            // Filtrar por texto de búsqueda
            final searchText = _searchController.text.toLowerCase();
            final nameMatches =
                paint.name.toLowerCase().contains(searchText) ||
                paint.brand.toLowerCase().contains(searchText) ||
                paint.category.toLowerCase().contains(searchText);

            // Filtrar por marca
            final brandMatches =
                _selectedBrand == 'All' || paint.brand == _selectedBrand;

            // Filtrar por categoría
            final categoryMatches =
                _selectedCategory == 'All' ||
                paint.category == _selectedCategory;

            // Filtrar por color (si hay un color seleccionado)
            bool colorMatches = true;
            if (_selectedColor != null) {
              final paintColor = Color(
                int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000,
              );
              // Comprobar si el color es similar (usando una tolerancia)
              const tolerance = 50; // Ajustar según necesidad

              final redDiff = (paintColor.red - _selectedColor!.red).abs();
              final greenDiff =
                  (paintColor.green - _selectedColor!.green).abs();
              final blueDiff = (paintColor.blue - _selectedColor!.blue).abs();

              colorMatches =
                  redDiff < tolerance &&
                  greenDiff < tolerance &&
                  blueDiff < tolerance;
            }

            return nameMatches &&
                brandMatches &&
                categoryMatches &&
                colorMatches;
          }).toList();

      // Reiniciar paginación
      _currentPage = 1;
      _updatePaginatedPaints();
    });
  }

  // Método para resetear todos los filtros
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedBrand = 'All';
      _selectedCategory = 'All';
      _selectedColor = null;
      _filteredPaints = _allPaints;
      _currentPage = 1;
      _updatePaginatedPaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'Paint Library',
      selectedIndex: -1, // Not a bottom tab item
      body: _buildBody(context, isDarkMode),
      drawer: const SharedDrawer(currentScreen: 'library'),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        // Search and filter bar
        _buildSearchBar(isDarkMode),

        // Results stats and filter count
        _buildResultsBar(isDarkMode),

        // Main paint grid
        Expanded(child: _buildPaintGrid(isDarkMode)),
      ],
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
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
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _showFilterDialog(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? AppTheme.darkSurface
                        : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.filter_list,
                    color:
                        isDarkMode
                            ? AppTheme.marineOrange
                            : AppTheme.primaryBlue,
                  ),
                  if (_hasActiveFilters())
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Verificar si hay filtros activos
  bool _hasActiveFilters() {
    return _selectedBrand != 'All' ||
        _selectedCategory != 'All' ||
        _selectedColor != null;
  }

  Widget _buildResultsBar(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_filteredPaints.length} paints found',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            const Text('Show: '),
            ..._pageSizeOptions.map((size) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('$size'),
                  selected: _currentPageSize == size,
                  onSelected: (selected) {
                    if (selected) {
                      _changePageSize(size);
                    }
                  },
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color:
                        _currentPageSize == size ? AppTheme.primaryBlue : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildPaintGrid(bool isDarkMode) {
    return _filteredPaints.isEmpty
        ? const Center(child: Text('No paints found matching your filters'))
        : Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
          ), // Reduced margin
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active filters bar
              if (_hasActiveFilters()) _buildActiveFiltersBar(isDarkMode),

              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _paginatedPaints.length,
                  itemBuilder: (context, index) {
                    final paint = _paginatedPaints[index];
                    final mainColor =
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).primaryColor;
                    final isInWishlist = _wishlist.contains(paint.id);

                    return PaintGridCard(
                      paint: paint,
                      color: mainColor,
                      onAddToWishlist: _toggleWishlist,
                      onAddToInventory: _addToInventory,
                      isInWishlist: isInWishlist,
                    );
                  },
                ),
              ),

              // Controles de paginación
              if (_totalPages > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.first_page),
                        onPressed: _currentPage > 1 ? () => _goToPage(1) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed:
                            _currentPage > 1
                                ? () => _goToPage(_currentPage - 1)
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Page $_currentPage of $_totalPages',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed:
                            _currentPage < _totalPages
                                ? () => _goToPage(_currentPage + 1)
                                : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.last_page),
                        onPressed:
                            _currentPage < _totalPages
                                ? () => _goToPage(_totalPages)
                                : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
  }

  // Construir barra de filtros activos
  Widget _buildActiveFiltersBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedBrand != 'All')
            _buildFilterChip(
              label: _selectedBrand,
              onRemove: () {
                setState(() {
                  _selectedBrand = 'All';
                  _filterPaints();
                });
              },
              isDarkMode: isDarkMode,
              icon: Icons.business,
            ),
          if (_selectedCategory != 'All')
            _buildFilterChip(
              label: _selectedCategory,
              onRemove: () {
                setState(() {
                  _selectedCategory = 'All';
                  _filterPaints();
                });
              },
              isDarkMode: isDarkMode,
              icon: Icons.category,
            ),
          if (_selectedColor != null)
            _buildColorFilterChip(
              color: _selectedColor!,
              onRemove: () {
                setState(() {
                  _selectedColor = null;
                  _filterPaints();
                });
              },
              isDarkMode: isDarkMode,
            ),
          TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Clear All'),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  // Construir chip de filtro
  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
    required bool isDarkMode,
    required IconData icon,
  }) {
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
      ),
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      labelStyle: TextStyle(
        fontSize: 12,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      deleteIconColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // Construir chip de filtro de color
  Widget _buildColorFilterChip({
    required Color color,
    required VoidCallback onRemove,
    required bool isDarkMode,
  }) {
    return Chip(
      avatar: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      label: const Text('Color filter'),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      labelStyle: TextStyle(
        fontSize: 12,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      deleteIconColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildColorCircle(Color color, String label) {
    final isSelected = _selectedColor == color;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
        _filterPaints();
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 2,
                          ),
                        ]
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AlertDialog buildWishlistDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Your Wishlist'),
      content: SizedBox(
        width: double.maxFinite,
        child:
            _wishlist.isEmpty
                ? const Center(child: Text('Your wishlist is empty'))
                : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _wishlist.length,
                  itemBuilder: (context, index) {
                    final paint = _allPaints.firstWhere(
                      (p) => p.id == _wishlist.elementAt(index),
                    );
                    final paintColor = Color(
                      int.parse(paint.hex.substring(1, 7), radix: 16) +
                          0xFF000000,
                    );

                    return ListTile(
                      leading: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: paintColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      title: Text(paint.name),
                      subtitle: Text('${paint.brand} - ${paint.category}'),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            _wishlist.remove(paint.id);
                          });
                          Navigator.pop(context);
                          // Mostrar el diálogo de nuevo para actualizar la lista
                          if (_wishlist.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => buildWishlistDialog(context),
                              );
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
      ),
      actions: [
        TextButton(
          child: const Text('Close'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // Método para agregar pinturas al inventario
  void _addToInventory(String paintId) {
    // Aquí implementaríamos la lógica para agregar al inventario
    // Por ahora, solo mostraremos una notificación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to inventory'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Método para mostrar el diálogo de filtros avanzados
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
                      'Filter Paints',
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
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedBrand,
                      items:
                          _brands.map((brand) {
                            return DropdownMenuItem<String>(
                              value: brand,
                              child: Text(brand),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            _selectedBrand = value;
                          });
                        }
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
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCategory,
                      items:
                          _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      underline: Container(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Filtro por color
                  Text(
                    'Color Filter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Color picker
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Opción para quitar el filtro de color
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _selectedColor = null;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? Colors.grey[600]!
                                        : Colors.grey[300]!,
                                width: 1,
                              ),
                              color:
                                  isDarkMode ? Colors.grey[800] : Colors.white,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.not_interested,
                                size: 20,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),

                        // Opciones de colores predefinidos
                        _buildColorOption(
                          Colors.red,
                          setModalState,
                          isDarkMode,
                        ),
                        _buildColorOption(
                          Colors.orange,
                          setModalState,
                          isDarkMode,
                        ),
                        _buildColorOption(
                          Colors.yellow,
                          setModalState,
                          isDarkMode,
                        ),
                        _buildColorOption(
                          Colors.green,
                          setModalState,
                          isDarkMode,
                        ),
                        _buildColorOption(
                          Colors.blue,
                          setModalState,
                          isDarkMode,
                        ),
                        _buildColorOption(
                          Colors.purple,
                          setModalState,
                          isDarkMode,
                        ),
                        _buildColorOption(
                          Colors.pink,
                          setModalState,
                          isDarkMode,
                        ),
                        _buildColorOption(
                          Colors.brown,
                          setModalState,
                          isDarkMode,
                        ),
                        _buildColorOption(
                          Colors.grey,
                          setModalState,
                          isDarkMode,
                        ),
                        _buildColorOption(
                          Colors.black,
                          setModalState,
                          isDarkMode,
                        ),
                        _buildColorOption(
                          Colors.white,
                          setModalState,
                          isDarkMode,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botones de acción
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
                            _filterPaints();
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
                          child: const Text(
                            'APPLY FILTERS',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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

  // Construir opción de color para el filtro
  Widget _buildColorOption(
    Color color,
    StateSetter setModalState,
    bool isDarkMode,
  ) {
    final isSelected = _selectedColor == color;
    final borderColor = isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;

    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isSelected
                    ? (isDarkMode
                        ? AppTheme.marineOrange
                        : AppTheme.primaryBlue)
                    : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: (isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue)
                          .withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
      ),
    );
  }
}
