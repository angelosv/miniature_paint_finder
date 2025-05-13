import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/paint_grid_card.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';
import 'package:miniature_paint_finder/controllers/paint_library_controller.dart';
import 'package:miniature_paint_finder/services/inventory_service.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/services/palette_service.dart';
import 'package:miniature_paint_finder/screens/palette_screen.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/services/guest_service.dart';
import 'package:miniature_paint_finder/utils/auth_utils.dart';
import 'package:miniature_paint_finder/widgets/guest_promo_modal.dart';
import 'package:miniature_paint_finder/components/brand_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late InventoryService _inventoryService;
  bool _argsProcessed = false;
  String? _paletteName = null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      // Cargar marcas para la vista inicial
      context.read<PaintLibraryController>().loadBrands();
      context.read<PaintLibraryController>().loadCategories();

      if (args != null) {
        if (args.containsKey('paletteInfo')) {
          final _paletteInfo = args['paletteInfo'] as Map<String, dynamic>;
          _paletteName = _paletteInfo['paletteName'];
          // Si venimos para crear una paleta, mostrar pinturas directamente
          context.read<PaintLibraryController>().setView(false);
          context.read<PaintLibraryController>().loadPaints();
        }
        if (args.containsKey('brandName')) {
          final String brandName = args['brandName'];
          // Si especifican una marca, ir directamente a esa marca
          context.read<PaintLibraryController>().setView(false);
          context.read<PaintLibraryController>().filterByBrand(brandName, true);
        }
      }
    });
    _inventoryService = InventoryService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsProcessed) {
      _argsProcessed = true;

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      // Deferimos la lógica hasta después del primer build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = context.read<PaintLibraryController>();

        // Si vienen argumentos...
        if (args != null) {
          // Si es un filtro de marca
          if (args.containsKey('brandName')) {
            controller.navigateToBrandPaints(args['brandName'] as String);
          }
          // Si venimos desde creación de paleta
          else if (args.containsKey('paletteInfo')) {
            final paletteInfo = args['paletteInfo'] as Map<String, dynamic>;
            if (paletteInfo['isCreatingPalette'] == true) {
              controller.setView(false);
              controller.loadPaints();
            }
          }

          // ¿Mostrar promo de paletas?
          if (args['showPalettesPromo'] == true) {
            final user = FirebaseAuth.instance.currentUser;
            final isGuest = user == null || user.isAnonymous;
            if (isGuest) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  GuestPromoModal.showForRestrictedFeature(context, 'Palettes');
                }
              });
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<PaintLibraryController>();
    final authService = Provider.of<IAuthService>(context, listen: false);

    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;

    // Apply guest mode wrapper to protect restricted features
    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      title: controller.showingBrandsView ? 'Paint Brands' : 'Paint Library',
      selectedIndex: 1,
      body: GuestService.wrapScreenForGuest(
        context: context,
        authService: authService,
        featureKey: 'library', // This is an accessible feature
        child: _buildBody(context, isDarkMode, controller),
      ),
      drawer: const SharedDrawer(currentScreen: 'library'),
      // Mostrar botón flotante promocional para invitados
      floatingActionButton: isGuestUser ? _buildPromoButton() : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDarkMode,
    PaintLibraryController controller,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            // Barra de búsqueda
            _buildSearchBar(isDarkMode, controller),

            // Contenido principal (vista de marcas o pinturas)
            Expanded(
              child:
                  controller.showingBrandsView
                      ? _buildBrandsGrid(isDarkMode, controller)
                      : Column(
                        children: [
                          _buildResultsBar(isDarkMode, controller),
                          Expanded(
                            child: _buildPaintGrid(isDarkMode, controller),
                          ),
                          _buildPagination(controller),
                        ],
                      ),
            ),
          ],
        ),
        if (controller.isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDarkMode, PaintLibraryController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Botón Atrás (solo visible en vista de pinturas)
          if (!controller.showingBrandsView)
            Container(
              margin: const EdgeInsets.only(right: 8),
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
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color:
                      isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
                ),
                onPressed: () {
                  controller.backToBrandsView();
                  _searchController.clear();
                },
                tooltip: 'Back to brands',
              ),
            ),

          // Campo de búsqueda
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                if (!controller.showingBrandsView) {
                  controller.searchPaints(value);
                }
              },
              decoration: InputDecoration(
                hintText:
                    controller.showingBrandsView
                        ? 'Search brands...'
                        : 'Search paints...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            if (!controller.showingBrandsView) {
                              controller.searchPaints('');
                            }
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

          // Botón de filtro (solo visible en vista de pinturas)
          if (!controller.showingBrandsView) const SizedBox(width: 12),

          if (!controller.showingBrandsView)
            InkWell(
              onTap: () => _showFilterDialog(context, controller),
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
                    if (_hasActiveFilters(controller))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
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

  // Vista de cuadrícula de marcas
  Widget _buildBrandsGrid(bool isDarkMode, PaintLibraryController controller) {
    // Filtrar marcas según la búsqueda
    final searchQuery = _searchController.text.toLowerCase();
    final filteredBrands =
        controller.brands.where((brand) {
          final brandName = (brand['name'] as String).toLowerCase();
          return searchQuery.isEmpty || brandName.contains(searchQuery);
        }).toList();

    if (filteredBrands.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No brands found matching your search',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              child: Text(
                'Clear search',
                style: TextStyle(
                  color:
                      isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: filteredBrands.length,
        itemBuilder: (context, index) {
          final brand = filteredBrands[index];
          return BrandCard(
            id: brand['id'] as String,
            name: brand['name'] as String,
            logoUrl: brand['logo_url'] as String?,
            paintCount: brand['paint_count'] as int? ?? 0,
            onTap: () {
              controller.navigateToBrandPaints(brand['name'] as String);
            },
          );
        },
      ),
    );
  }

  bool _hasActiveFilters(PaintLibraryController controller) {
    return controller.selectedBrand != 'All' ||
        controller.selectedCategory != 'All' ||
        controller.selectedColor != null;
  }

  Widget _buildResultsBar(bool isDarkMode, PaintLibraryController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${controller.paginatedPaints.length} paints found',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              const Text('Show: '),
              ...controller.pageSizeOptions.map((size) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$size'),
                    selected: controller.pageSize == size,
                    onSelected: (selected) {
                      if (selected) {
                        controller.setPageSize(size);
                      }
                    },
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color:
                          controller.pageSize == size
                              ? AppTheme.primaryBlue
                              : null,
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
      ),
    );
  }

  Widget _buildPaintGrid(bool isDarkMode, PaintLibraryController controller) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;

    return controller.paginatedPaints.isEmpty
        ? const Center(child: Text('No paints found matching your filters'))
        : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hasActiveFilters(controller))
                _buildActiveFiltersBar(isDarkMode, controller),
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
                  itemCount: controller.paginatedPaints.length,
                  itemBuilder: (context, index) {
                    final paint = controller.paginatedPaints[index];
                    final mainColor =
                        isDarkMode
                            ? Colors.white
                            : Theme.of(context).primaryColor;
                    final isInWishlist = controller.isPaintInWishlist(paint.id);

                    return PaintGridCard(
                      paint: paint,
                      color: mainColor,
                      onAddToWishlist: controller.toggleWishlist,
                      onAddToInventory: _addToInventory,
                      onAddToPalette: _handleAddToPalette,
                      isInWishlist: isInWishlist,
                      paletteName: _paletteName,
                    );
                  },
                ),
              ),
            ],
          ),
        );
  }

  // Add to inventory with guest check
  Future<void> _addToInventory(Paint paint) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;

    if (isGuestUser) {
      GuestPromoModal.showForRestrictedFeature(context, 'Inventory');
      return;
    }

    try {
      await _inventoryService.addPaintToInventory(paint);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${paint.name} to your inventory'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding paint to inventory: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle adding to palette with guest check
  Future<void> _handleAddToPalette(
    String paletteName,
    String paintId,
    String brandId,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;

    if (isGuestUser) {
      GuestPromoModal.showForRestrictedFeature(context, 'Palettes');
      return;
    }

    // Process adding to palette
    try {
      print("paletteName: $paletteName, paintId: $paintId, brandId: $brandId");
      final paletteService = PaletteService();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final result = await paletteService.addPaintToPaletteById(
          paletteName,
          userId,
          paintId,
          brandId,
        );

        if (result['executed']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paint added to palette $paletteName'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding paint to palette: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActiveFiltersBar(
    bool isDarkMode,
    PaintLibraryController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (controller.selectedBrand != 'All')
            _buildFilterChip(
              label: controller.selectedBrand,
              onRemove: () => controller.filterByBrand('All', true),
              isDarkMode: isDarkMode,
              icon: Icons.business,
            ),
          if (controller.selectedCategory != 'All')
            _buildFilterChip(
              label: controller.selectedCategory,
              onRemove: () => controller.filterByCategory('All', true),
              isDarkMode: isDarkMode,
              icon: Icons.category,
            ),
          if (controller.selectedColor != null)
            _buildColorFilterChip(
              color: controller.selectedColor!,
              onRemove: () => controller.filterByColor(null),
              isDarkMode: isDarkMode,
            ),
          TextButton.icon(
            onPressed: controller.resetFilters,
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

  Widget _buildPagination(PaintLibraryController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed:
                controller.currentPage > 1
                    ? () => controller.goToPage(1)
                    : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                controller.currentPage > 1
                    ? () => controller.goToPreviousPage()
                    : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Page ${controller.currentPage} of ${controller.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                controller.currentPage < controller.totalPages
                    ? () => controller.goToNextPage()
                    : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed:
                controller.currentPage < controller.totalPages
                    ? () => controller.goToPage(controller.totalPages)
                    : null,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(
    BuildContext context,
    PaintLibraryController controller,
  ) {
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
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Filter Paints',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode
                                ? Colors.white.withOpacity(0.9)
                                : Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'By Brand',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Brands'),
                          selected: controller.selectedBrand == 'All',
                          onSelected: (selected) {
                            if (selected) {
                              controller.filterByBrand('All', false);
                              setModalState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ...controller.availableBrands
                            .where((brand) => brand != 'All')
                            .map((brand) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(brand),
                                  selected: controller.selectedBrand == brand,
                                  onSelected: (selected) {
                                    if (selected) {
                                      controller.filterByBrand(brand, false);
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              );
                            })
                            .toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'By Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Categories'),
                          selected: controller.selectedCategory == 'All',
                          onSelected: (selected) {
                            if (selected) {
                              controller.filterByCategory('All', false);
                              setModalState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ...controller.availableCategories
                            .where((category) => category != 'All')
                            .map((category) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected:
                                      controller.selectedCategory == category,
                                  onSelected: (selected) {
                                    if (selected) {
                                      controller.filterByCategory(
                                        category,
                                        false,
                                      );
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              );
                            })
                            .toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            controller.resetFilters();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Reset Filters'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            controller.applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
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

  // Botón flotante para mostrar el modal promocional
  Widget _buildPromoButton() {
    return FloatingActionButton.extended(
      onPressed:
          () => GuestPromoModal.showForRestrictedFeature(context, 'Premium'),
      icon: Icon(Icons.star, color: Colors.black87),
      label: Text(
        '¡Regístrate Gratis!',
        style: TextStyle(color: Colors.black87),
      ),
      backgroundColor: AppTheme.marineGold,
    );
  }
}
