import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/paint_grid_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final List<Paint> _allPaints = SampleData.getPaints();
  late List<Paint> _filteredPaints;

  // Paginación
  final int _itemsPerPage = 20;
  int _currentPage = 1;
  late int _totalPages;
  late List<Paint> _paginatedPaints;
  final ScrollController _scrollController = ScrollController();

  // Lista de favoritos
  final Set<String> _wishlist = {};

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
    _totalPages = (_filteredPaints.length / _itemsPerPage).ceil();

    final startIndex = 0;
    final endIndex = _currentPage * _itemsPerPage;

    _paginatedPaints = _filteredPaints.sublist(
      startIndex,
      endIndex < _filteredPaints.length ? endIndex : _filteredPaints.length,
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paint Library'),
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
                builder:
                    (context) => AlertDialog(
                      title: const Text('Your Wishlist'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child:
                            _wishlist.isEmpty
                                ? const Center(
                                  child: Text('Your wishlist is empty'),
                                )
                                : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _wishlist.length,
                                  itemBuilder: (context, index) {
                                    final paint = _allPaints.firstWhere(
                                      (p) => p.id == _wishlist.elementAt(index),
                                    );
                                    return ListTile(
                                      leading: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Color(
                                            int.parse(
                                                  paint.colorHex.substring(
                                                    1,
                                                    7,
                                                  ),
                                                  radix: 16,
                                                ) +
                                                0xFF000000,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      title: Text(paint.name),
                                      subtitle: Text(paint.brand),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () {
                                          setState(() {
                                            _wishlist.remove(paint.id);
                                          });
                                          Navigator.pop(context);
                                          // Mostrar el diálogo de nuevo para actualizar la lista
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (context) =>
                                                          buildWishlistDialog(
                                                            context,
                                                          ),
                                                );
                                              });
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
                    ),
              );
            },
          ),
        ],
      ),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              '${_filteredPaints.length} paints found (showing ${_paginatedPaints.length})',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              controller: _scrollController,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemCount:
                                  _paginatedPaints.length +
                                  (_currentPage < _totalPages ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Si estamos en el último elemento y hay más páginas, mostrar indicador de carga
                                if (index == _paginatedPaints.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final paint = _paginatedPaints[index];
                                final color = Color(
                                  int.parse(
                                        paint.colorHex.substring(1, 7),
                                        radix: 16,
                                      ) +
                                      0xFF000000,
                                );

                                return Stack(
                                  children: [
                                    PaintGridCard(paint: paint, color: color),
                                    // Botón de favorito
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            _wishlist.contains(paint.id)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color:
                                                _wishlist.contains(paint.id)
                                                    ? Colors.red
                                                    : Colors.grey,
                                            size: 20,
                                          ),
                                          onPressed:
                                              () => _toggleWishlist(paint.id),
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                          iconSize: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
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
                    return ListTile(
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(
                                  paint.colorHex.substring(1, 7),
                                  radix: 16,
                                ) +
                                0xFF000000,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(paint.name),
                      subtitle: Text(paint.brand),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() {
                            _wishlist.remove(paint.id);
                          });
                          Navigator.pop(context);
                          // Mostrar el diálogo de nuevo para actualizar la lista
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => buildWishlistDialog(context),
                            );
                          });
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
}
