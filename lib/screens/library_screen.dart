import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/paint_grid_card.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';

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
            final nameMatches =
                paint.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                paint.brand.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                );

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
                int.parse(paint.colorHex.substring(1, 7), radix: 16) +
                    0xFF000000,
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
      drawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
          drawerTheme: DrawerThemeData(
            backgroundColor:
                isDarkMode ? AppTheme.marineBlueDark : Colors.white,
            scrimColor: Colors.black54,
          ),
        ),
        child: Drawer(
          elevation: 10,
          width: MediaQuery.of(context).size.width * 0.75,
          backgroundColor: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
              boxShadow:
                  isDarkMode
                      ? [
                        BoxShadow(
                          color: Colors.black26,
                          offset: const Offset(1, 0),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ]
                      : [],
            ),
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Cabecera del Drawer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? AppTheme.marineBlueDark : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDarkMode
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MiniPaint Finder',
                          style: TextStyle(
                            color:
                                isDarkMode ? Colors.white : AppTheme.marineBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your painting companion',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Opciones de navegación
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    isSelected: false,
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.palette_outlined,
                    title: 'Palettes',
                    isSelected: false,
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/palettes');
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Divider(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      thickness: 1,
                    ),
                  ),

                  _buildDrawerItem(
                    context: context,
                    icon: Icons.format_paint_outlined,
                    title: 'Library',
                    isSelected: true,
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    title: 'My Inventory',
                    isSelected: false,
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/inventory');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.favorite_outline,
                    title: 'Wishlist',
                    isSelected: false,
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/wishlist');
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Divider(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      thickness: 1,
                    ),
                  ),

                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    isSelected: false,
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: 'Paint Library',
      selectedIndex: 2, // Profile tab since it's in profile section
      actions: [
        IconButton(
          icon: Icon(
            _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
          ),
          onPressed: () {
            setState(() {
              _isFilterExpanded = !_isFilterExpanded;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          tooltip: 'View Wishlist',
          onPressed: () {
            // Mostrar wishlist
            showDialog(
              context: context,
              builder: (context) => buildWishlistDialog(context),
            );
          },
        ),
      ],
      body: Column(
        children: [
          // Área de búsqueda siempre visible
          Padding(
            padding: const EdgeInsets.all(16.0),
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

          // Panel de filtros expandible
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isFilterExpanded ? 210 : 0,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reset'),
                            onPressed: _resetFilters,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Filtro por marca
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Brand:'),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                _brands.map((brand) {
                                  final isSelected = brand == _selectedBrand;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(brand),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _selectedBrand = brand;
                                          });
                                          _filterPaints();
                                        }
                                      },
                                      backgroundColor:
                                          Theme.of(context).cardColor,
                                      selectedColor: AppTheme.primaryBlue
                                          .withOpacity(0.2),
                                      labelStyle: TextStyle(
                                        color:
                                            isSelected
                                                ? AppTheme.primaryBlue
                                                : null,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Filtro por categoría
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category:'),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                _categories.map((category) {
                                  final isSelected =
                                      category == _selectedCategory;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(category),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _selectedCategory = category;
                                          });
                                          _filterPaints();
                                        }
                                      },
                                      backgroundColor:
                                          Theme.of(context).cardColor,
                                      selectedColor: AppTheme.primaryBlue
                                          .withOpacity(0.2),
                                      labelStyle: TextStyle(
                                        color:
                                            isSelected
                                                ? AppTheme.primaryBlue
                                                : null,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Filtro por color
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Color:'),
                            if (_selectedColor != null)
                              TextButton(
                                child: const Text('Clear'),
                                onPressed: () {
                                  setState(() {
                                    _selectedColor = null;
                                  });
                                  _filterPaints();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Colores comunes para elegir
                              _buildColorCircle(Colors.red, 'Red'),
                              _buildColorCircle(Colors.blue, 'Blue'),
                              _buildColorCircle(Colors.green, 'Green'),
                              _buildColorCircle(Colors.yellow, 'Yellow'),
                              _buildColorCircle(Colors.orange, 'Orange'),
                              _buildColorCircle(Colors.purple, 'Purple'),
                              _buildColorCircle(Colors.brown, 'Brown'),
                              _buildColorCircle(Colors.black, 'Black'),
                              _buildColorCircle(Colors.white, 'White'),
                              _buildColorCircle(Colors.grey, 'Grey'),
                              _buildColorCircle(
                                const Color(0xFFc0c0c0),
                                'Silver',
                              ),
                              _buildColorCircle(
                                const Color(0xFFD4AF37),
                                'Gold',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Resultados
          Expanded(
            child:
                _filteredPaints.isEmpty
                    ? const Center(
                      child: Text('No paints found matching your filters'),
                    )
                    : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Control de paginación y tamaño de página
                          Row(
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
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
                                              _currentPageSize == size
                                                  ? AppTheme.primaryBlue
                                                  : null,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Expanded(
                            child: GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemCount: _paginatedPaints.length,
                              itemBuilder: (context, index) {
                                final paint = _paginatedPaints[index];
                                final mainColor =
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Theme.of(context).primaryColor;
                                final isInWishlist = _wishlist.contains(
                                  paint.id,
                                );

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
                                    onPressed:
                                        _currentPage > 1
                                            ? () => _goToPage(1)
                                            : null,
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                    ),
          ),
        ],
      ),
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
                      int.parse(paint.colorHex.substring(1, 7), radix: 16) +
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

  // Construye un elemento del menú lateral con el estilo adecuado
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: (isDarkMode ? AppTheme.marineGold : AppTheme.marineBlue)
              .withOpacity(0.2),
          highlightColor: (isDarkMode
                  ? AppTheme.marineGold
                  : AppTheme.marineBlue)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? (isDarkMode
                          ? AppTheme.marineGold.withOpacity(0.2)
                          : AppTheme.marineBlue.withOpacity(0.1))
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color:
                      isSelected
                          ? (isDarkMode
                              ? AppTheme.marineGold
                              : AppTheme.marineBlue)
                          : (isDarkMode ? Colors.white70 : Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color:
                        isSelected
                            ? (isDarkMode
                                ? AppTheme.marineGold
                                : AppTheme.marineBlue)
                            : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
