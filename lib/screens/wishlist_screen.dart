import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/components/image_color_picker.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/services/inventory_service.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/services/brand_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/controllers/wishlist_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Screen that displays all paints in the user's wishlist
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});
  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final PaintService _paintService = PaintService();
  final BrandService _brandService = BrandService();
  final InventoryService _inventoryService = InventoryService();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Cargar wishlist cuando se inicia el widget.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistController>().loadWishlist();
      _loadBrandData();
    });
  }

  /// Carga los datos de marcas y logotipos.
  Future<void> _loadBrandData() async {
    print('🔄 Initializing BrandService...');
    final success = await _brandService.initialize();
    print(
      success
          ? '✅ BrandService initialized successfully'
          : '❌ BrandService initialization failed',
    );
  }

  /// Determinar el brandId correcto de forma segura.
  String _getSafeBrandId(Paint paint) {
    try {
      final brandId = _brandService.getBrandId(paint.brand);
      if (brandId != null) return brandId;
      if ((paint.brand.toLowerCase().contains('army') &&
              paint.brand.toLowerCase().contains('painter')) ||
          paint.brand.toLowerCase().contains('warpaint')) {
        return 'Army_Painter';
      }
      if (paint.brand.toLowerCase().contains('citadel')) {
        return 'Citadel_Colour';
      }
      return paint.brand;
    } catch (e) {
      print('⚠️ Error determinando brandId: $e');
      return paint.brand;
    }
  }

  /// Obtener el nombre oficial de marca de forma segura.
  String _getSafeBrandName(String brandId, String fallbackName) {
    try {
      final name = _brandService.getBrandName(brandId);
      return name ?? fallbackName;
    } catch (e) {
      print('⚠️ Error obteniendo nombre de marca: $e');
      return fallbackName;
    }
  }

  /// Construye el logo de la marca para la tarjeta.
  Widget _buildBrandLogo(
    String brandId,
    Map<String, dynamic> brand,
    String brandName,
    bool isDarkMode,
  ) {
    final String? logoUrl = brand["logo_url"];
    return SizedBox(
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child:
            logoUrl != null
                ? ClipOval(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.contain,
                      cacheKey: 'brand_logo_${brandId}',
                      placeholder:
                          (context, url) => Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDarkMode ? Colors.orange : Colors.blue,
                              ),
                            ),
                          ),
                      errorWidget: (ctx, url, err) {
                        print('⚠️ Image load error for $brandId: $err');
                        return Text(
                          brandName.isNotEmpty
                              ? brandName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      },
                    ),
                  ),
                )
                : Center(
                  child: Text(
                    brandName.isNotEmpty ? brandName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
      ),
    );
  }

  /// _togglePriority:
  /// Calcula el nuevo valor de prioridad (0 a 5), donde 0 indica "sin prioridad" y 1 a 5 indica que el ítem es prioritario.
  Future<void> _togglePriority(
    String paintId,
    bool currentPriority,
    String _id, [
    int priorityLevel = 0,
  ]) async {
    try {
      final controller = context.read<WishlistController>();
      // Forzar que priorityLevel esté en el rango [0, 5]
      final int newPriority = priorityLevel.clamp(0, 5);
      // Se considera prioritario si hay al menos 1 estrella.
      final bool newPriorityFlag = newPriority >= 1;
      final result = await controller.updatePriority(
        paintId,
        _id,
        newPriorityFlag,
        newPriority,
      );
      if (mounted && result) {
        final message =
            newPriority >= 1
                ? 'Priority set to $newPriority stars'
                : 'Removed from priority';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating priority'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating priority: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromWishlist(
    String paintId,
    String paintName,
    String _id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Removal'),
            content: Text('Remove $paintName from your wishlist?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('REMOVE'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    final controller = context.read<WishlistController>();
    final result = await controller.removeFromWishlist(paintId, _id);
    if (result && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$paintName removed from wishlist'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              final wishlistItems = controller.wishlistItems;
              final item = wishlistItems.firstWhere(
                (item) => (item['paint'] as Paint).id == paintId,
                orElse: () => {'paint': null, 'isPriority': false},
              );
              if (item['paint'] != null) {
                await controller.addToWishlist(
                  item['paint'] as Paint,
                  item['isPriority'] as bool,
                );
              }
            },
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing paint from wishlist'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addToInventory(String brandId, Paint paint, String _id) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => _AddToInventoryDialog(paint: paint),
    );
    if (result != null) {
      try {
        print(
          '🔄 Adding ${paint.name} to inventory, quantity: ${result['quantity']}',
        );
        final success = await _inventoryService.addInventoryRecord(
          brandId: brandId,
          paintId: paint.id,
          quantity: result['quantity'] as int,
          notes: result['note'] as String?,
        );
        print('✅ Paint added to inventory');
        final controller = context.read<WishlistController>();
        await controller.removeFromWishlist(paint.id, _id);
        if (success) {
          print('✅ Paint removed from wishlist');
        } else {
          print(
            '⚠️ Could not remove paint from wishlist after adding to inventory',
          );
        }
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${paint.name} added to inventory'),
              backgroundColor: Colors.green,
            ),
          );
          await context.read<WishlistController>().loadWishlist();
          await _loadBrandData();
        }
      } catch (e) {
        print('❌ Error adding to inventory: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding to inventory: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      print('ℹ️ User cancelled adding to inventory');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'Wishlist',
      selectedIndex: 2,
      body: _buildBody(),
      drawer: const SharedDrawer(currentScreen: 'wishlist'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor:
            isDarkMode ? AppTheme.marineOrange : Theme.of(context).primaryColor,
        foregroundColor: isDarkMode ? AppTheme.marineBlue : Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add to Wishlist'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody() {
    return Consumer<WishlistController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading wishlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(controller.errorMessage ?? 'Unknown error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadWishlist(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (controller.isEmpty) {
          return _buildEmptyState();
        }
        return Column(
          children: [
            // Barra de búsqueda
            _buildSearchBar(controller),
            // Filtros activos
            _buildActiveFilters(controller),
            // Barra de filtro y ordenamiento
            _buildFilterAndSortBar(controller),
            // Contenido de la wishlist
            Expanded(child: _buildWishlistContent(controller.wishlistItems)),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(WishlistController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final searchController = TextEditingController(
      text: controller.searchQuery,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search paints...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              controller.searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      controller.setSearchQuery('');
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor:
              isDarkMode ? AppTheme.darkSurface : Theme.of(context).cardColor,
        ),
        onChanged: (value) => controller.setSearchQuery(value),
      ),
    );
  }

  Widget _buildActiveFilters(WishlistController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Si no hay filtros activos, no mostramos esta sección
    if (controller.selectedBrand == null &&
        controller.selectedPalette == null &&
        controller.selectedPriority == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filtro de marca
            if (controller.selectedBrand != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(controller.selectedBrand!),
                  onDeleted: () => controller.setBrandFilter(null),
                  backgroundColor:
                      isDarkMode ? AppTheme.darkSurface : Colors.grey[200],
                  deleteIconColor:
                      isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  avatar: Icon(
                    Icons.business,
                    size: 16,
                    color:
                        isDarkMode
                            ? AppTheme.marineOrange
                            : AppTheme.primaryBlue,
                  ),
                ),
              ),

            // Filtro de paleta
            if (controller.selectedPalette != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(controller.selectedPalette!),
                  onDeleted: () => controller.setPaletteFilter(null),
                  backgroundColor:
                      isDarkMode ? AppTheme.darkSurface : Colors.grey[200],
                  deleteIconColor:
                      isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  avatar: Icon(
                    Icons.palette,
                    size: 16,
                    color:
                        isDarkMode
                            ? AppTheme.marineOrange
                            : AppTheme.primaryBlue,
                  ),
                ),
              ),

            // Filtro de prioridad
            if (controller.selectedPriority != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('Priority: ${controller.selectedPriority}'),
                  onDeleted: () => controller.setPriorityFilter(null),
                  backgroundColor:
                      isDarkMode ? AppTheme.darkSurface : Colors.grey[200],
                  deleteIconColor:
                      isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  avatar: Icon(
                    Icons.star,
                    size: 16,
                    color:
                        isDarkMode
                            ? AppTheme.marineOrange
                            : AppTheme.primaryBlue,
                  ),
                ),
              ),

            // Botón para limpiar todos los filtros
            TextButton.icon(
              onPressed: controller.clearFilters,
              icon: Icon(
                Icons.clear_all,
                size: 16,
                color:
                    isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
              ),
              label: Text(
                'Clear filters',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterAndSortBar(WishlistController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          // Botón de filtro
          OutlinedButton.icon(
            onPressed: () => _showFilterDialog(controller),
            icon: const Icon(Icons.filter_list, size: 18),
            label: const Text('Filter'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
              foregroundColor:
                  isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
            ),
          ),

          const SizedBox(width: 8),

          // Botón de ordenamiento
          OutlinedButton.icon(
            onPressed: () => _showSortDialog(controller),
            icon: const Icon(Icons.sort, size: 18),
            label: const Text('Sort'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
              foregroundColor:
                  isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
            ),
          ),

          const Spacer(),

          // Indicador de total de pinturas
          Text(
            '${controller.wishlistItems.length} paints',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(WishlistController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Obtener listas de filtros disponibles
    final brands = controller.getAvailableBrands();
    final palettes = controller.getAvailablePalettes();
    final priorities = controller.getAvailablePriorities();

    // Si no hay datos para filtrar, mostramos un mensaje
    if (brands.isEmpty && palettes.isEmpty && priorities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No filters available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
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

                      // Título
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Filter Wishlist',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Filtro por marca
                      if (brands.isNotEmpty) ...[
                        Text(
                          'Brand',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...brands.map(
                              (brand) => ChoiceChip(
                                label: Text(brand),
                                selected: controller.selectedBrand == brand,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      controller.setBrandFilter(brand);
                                    } else {
                                      controller.setBrandFilter(null);
                                    }
                                  });
                                },
                                backgroundColor:
                                    isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                selectedColor:
                                    isDarkMode
                                        ? AppTheme.marineOrange.withOpacity(0.3)
                                        : AppTheme.primaryBlue.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color:
                                      controller.selectedBrand == brand
                                          ? isDarkMode
                                              ? AppTheme.marineOrange
                                              : AppTheme.primaryBlue
                                          : isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Filtro por paleta
                      if (palettes.isNotEmpty) ...[
                        Text(
                          'Palette',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...palettes.map(
                              (palette) => ChoiceChip(
                                label: Text(palette),
                                selected: controller.selectedPalette == palette,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      controller.setPaletteFilter(palette);
                                    } else {
                                      controller.setPaletteFilter(null);
                                    }
                                  });
                                },
                                backgroundColor:
                                    isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                selectedColor:
                                    isDarkMode
                                        ? AppTheme.marineOrange.withOpacity(0.3)
                                        : AppTheme.primaryBlue.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color:
                                      controller.selectedPalette == palette
                                          ? isDarkMode
                                              ? AppTheme.marineOrange
                                              : AppTheme.primaryBlue
                                          : isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Filtro por prioridad
                      if (priorities.isNotEmpty) ...[
                        Text(
                          'Priority',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...priorities.map(
                              (priority) => ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    priority,
                                    (index) => Icon(
                                      Icons.star,
                                      size: 16,
                                      color:
                                          controller.selectedPriority ==
                                                  priority
                                              ? isDarkMode
                                                  ? AppTheme.marineOrange
                                                  : AppTheme.primaryBlue
                                              : isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                                selected:
                                    controller.selectedPriority == priority,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      controller.setPriorityFilter(priority);
                                    } else {
                                      controller.setPriorityFilter(null);
                                    }
                                  });
                                },
                                backgroundColor:
                                    isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                selectedColor:
                                    isDarkMode
                                        ? AppTheme.marineOrange.withOpacity(0.3)
                                        : AppTheme.primaryBlue.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Botones de acción
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              controller.clearFilters();
                              Navigator.pop(context);
                            },
                            child: const Text('Clear All'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Apply'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDarkMode
                                      ? AppTheme.marineOrange
                                      : AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  void _showSortDialog(WishlistController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Opciones de ordenamiento
    final sortOptions = {
      'date': 'Date Added',
      'name': 'Paint Name',
      'brand': 'Brand',
      'priority': 'Priority',
    };

    String tempSortBy = controller.sortBy;
    bool tempSortAscending = controller.sortAscending;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
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

                    // Título
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Sort Wishlist',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Opciones de ordenamiento
                    Text(
                      'Sort by',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...sortOptions.entries.map(
                      (entry) => RadioListTile<String>(
                        title: Text(entry.value),
                        value: entry.key,
                        groupValue: tempSortBy,
                        onChanged: (value) {
                          setState(() {
                            tempSortBy = value!;
                          });
                        },
                        activeColor:
                            isDarkMode
                                ? AppTheme.marineOrange
                                : AppTheme.primaryBlue,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Dirección de ordenamiento
                    Text(
                      'Direction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    RadioListTile<bool>(
                      title: Text(
                        tempSortBy == 'date'
                            ? 'Newest First'
                            : 'Ascending (A-Z)',
                      ),
                      value: false,
                      groupValue: tempSortAscending,
                      onChanged: (value) {
                        setState(() {
                          tempSortAscending = value!;
                        });
                      },
                      activeColor:
                          isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue,
                    ),

                    RadioListTile<bool>(
                      title: Text(
                        tempSortBy == 'date'
                            ? 'Oldest First'
                            : 'Descending (Z-A)',
                      ),
                      value: true,
                      groupValue: tempSortAscending,
                      onChanged: (value) {
                        setState(() {
                          tempSortAscending = value!;
                        });
                      },
                      activeColor:
                          isDarkMode
                              ? AppTheme.marineOrange
                              : AppTheme.primaryBlue,
                    ),

                    // Botones de acción
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            controller.setSorting(
                              tempSortBy,
                              tempSortAscending,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDarkMode
                                    ? AppTheme.marineOrange
                                    : AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.asset('assets/images/wishlist_palceholder.png'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white : AppTheme.marineBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add paints you want to purchase later',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistContent(List<Map<String, dynamic>> wishlistItems) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      itemCount: wishlistItems.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = wishlistItems[index];
        final paint = item['paint'] as Paint;
        final brand = item['brand'] as Map<String, dynamic>;
        final int priorityLevel = item['priority'] ?? 0;
        final bool itemIsPriority = priorityLevel >= 1 && priorityLevel <= 5;
        final String _id = item['id'] as String;
        final DateTime addedAt = item['addedAt'] as DateTime;
        final String colorCode = paint.hex;
        final Color paintColor = Color(
          int.parse(colorCode.substring(1), radix: 16) + 0xFF000000,
        );
        final String brandId = _getSafeBrandId(paint);
        final String officialBrandName = _getSafeBrandName(
          brandId,
          paint.brand,
        );

        // Display the star row using the actual priority level.
        final starRow = Row(
          children: List.generate(5, (index) {
            return Icon(
              index < priorityLevel ? Icons.star : Icons.star_border,
              size: 16,
              color: AppTheme.marineOrange,
            );
          }),
        );

        final palettes = _paintService.getPalettesContainingPaint(paint.id);

        final card = Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          color: isDarkMode ? AppTheme.darkSurface : Colors.white,
          child: InkWell(
            onTap: () {
              // Here we pass the actual priority level.
              _showPaintDetails(paint, priorityLevel, _id, palettes, brand);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: paintColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paint.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color:
                                    isDarkMode
                                        ? AppTheme.marineOrange
                                        : AppTheme.primaryBlue,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              officialBrandName,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            starRow,
                            if (itemIsPriority)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  'PRIORITY',
                                  style: TextStyle(
                                    color: AppTheme.marineOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isDarkMode
                                            ? AppTheme.primaryBlue.withOpacity(
                                              0.3,
                                            )
                                            : AppTheme.primaryBlue.withOpacity(
                                              0.1,
                                            ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    paint.category,
                                    style: TextStyle(
                                      color:
                                          isDarkMode
                                              ? Colors.lightBlue[100]
                                              : AppTheme.primaryBlue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (paint.isMetallic || paint.isTransparent)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isDarkMode
                                                ? Colors.amber.withOpacity(0.3)
                                                : Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        paint.isMetallic
                                            ? 'Metallic'
                                            : 'Transparent',
                                        style: TextStyle(
                                          color:
                                              isDarkMode
                                                  ? Colors.amber[100]
                                                  : Colors.amber[800],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  'Added ${_formatDate(addedAt)}',
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            if (palettes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Used in palettes:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildPaletteChips(palettes, isDarkMode),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildBrandLogo(
                        brandId,
                        brand,
                        officialBrandName,
                        isDarkMode,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        return Dismissible(
          key: Key(_id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Confirm Removal'),
                        content: Text(
                          'Remove ${paint.name} from your wishlist?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('REMOVE'),
                          ),
                        ],
                      ),
                ) ??
                false;
          },
          onDismissed: (direction) {
            _removeFromWishlist(paint.id, paint.name, _id);
          },
          child: card,
        );
      },
    );
  }

  /// Build palette chips, limiting to 3 initially with a "View more" option.
  Widget _buildPaletteChips(List<Palette> palettes, bool isDarkMode) {
    // State for expanded view.
    bool isExpanded = false;
    final chipColor =
        isDarkMode
            ? Color(0xFF9370DB).withOpacity(0.3)
            : Color(0xFFD8BFD8).withOpacity(0.6);
    final textColor = isDarkMode ? Color(0xFFE6E6FA) : Color(0xFF7B68EE);
    final borderColor =
        isDarkMode
            ? Color(0xFF9370DB).withOpacity(0.5)
            : Color(0xFF9370DB).withOpacity(0.3);
    return StatefulBuilder(
      builder: (context, setState) {
        final displayPalettes =
            isExpanded ? palettes : palettes.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ...displayPalettes.map((palette) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      palette.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
                if (palettes.length > 3 && !isExpanded)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isExpanded = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${palettes.length - 3} more',
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                              fontSize: 11,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 11,
                            color:
                                isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (isExpanded && palettes.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded = false;
                    });
                  },
                  child: Text(
                    'Show less',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Shows a bottom sheet with actions for a paint.
  /// Se modifica el segundo parámetro a `int currentPriority` para pasar el valor actual.
  void _showPaintDetails(
    Paint paint,
    int currentPriority,
    String _id,
    List<Palette> palettes,
    Map<String, dynamic> brand,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final String brandId = _getSafeBrandId(paint);
    final String officialBrandName = _getSafeBrandName(brandId, paint.brand);
    // currentPriority (0 = no priority, 1-5 = active priority)
    int currentPriorityLevel = currentPriority;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Paint info header with brand logo on the right
                      Row(
                        children: [
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(paint.hex.substring(1), radix: 16) +
                                    0xFF000000,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paint.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color:
                                        isDarkMode
                                            ? AppTheme.marineOrange
                                            : AppTheme.primaryBlue,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  officialBrandName,
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.white70
                                            : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.colorize,
                                      size: 14,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Code: ${paint.code}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.qr_code,
                                      size: 14,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Color: ${paint.hex}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildBrandLogo(
                            brandId,
                            brand,
                            officialBrandName,
                            isDarkMode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Palette section
                      _buildPalettesSection(palettes, isDarkMode),
                      const SizedBox(height: 20),
                      // Star rating with sliding gesture
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Priority:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              final RenderBox box =
                                  context.findRenderObject() as RenderBox;
                              final double width = box.size.width;
                              final double position = details.localPosition.dx
                                  .clamp(0, width);
                              final double starWidth = width / 5;
                              int starCount = (position / starWidth).ceil();
                              starCount = starCount.clamp(0, 5);
                              if (5 - starCount != currentPriorityLevel) {
                                setState(() {
                                  currentPriorityLevel = 5 - starCount;
                                });
                              }
                            },
                            onHorizontalDragEnd: (details) {
                              Navigator.pop(context);
                              _togglePriority(
                                paint.id,
                                currentPriorityLevel >= 1,
                                _id,
                                currentPriorityLevel,
                              );
                            },
                            child: Container(
                              color: Colors.transparent,
                              height: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return IconButton(
                                    icon: Icon(
                                      index < currentPriorityLevel
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 28,
                                      color: AppTheme.marineOrange,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (currentPriorityLevel == index + 1) {
                                          currentPriorityLevel = 0;
                                        } else {
                                          currentPriorityLevel = index + 1;
                                        }
                                      });
                                      Navigator.pop(context);
                                      _togglePriority(
                                        paint.id,
                                        currentPriorityLevel >= 1,
                                        _id,
                                        currentPriorityLevel,
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    splashRadius: 20,
                                  );
                                }),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              'Slide to adjust priority',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      // Paint info section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 18,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Type:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                paint.isMetallic
                                    ? 'Metallic'
                                    : paint.isTransparent
                                    ? 'Transparent'
                                    : 'Standard',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _addToInventory(brandId, paint, _id);
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add to Inventory'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor:
                                isDarkMode
                                    ? AppTheme.marineOrange
                                    : AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPalettesSection(List<Palette> palettes, bool isDarkMode) {
    final demoPalettes = [
      {'name': 'Space Marines', 'color': const Color(0xFFD8BFD8)},
      {'name': 'Imperial Guard', 'color': const Color(0xFFD8BFD8)},
      {'name': 'Tau Empire', 'color': const Color(0xFFD8BFD8)},
      {'name': 'Eldar Craftworlds', 'color': const Color(0xFFD8BFD8)},
      {'name': 'Orks', 'color': const Color(0xFFD8BFD8)},
      {'name': 'Tyranids', 'color': const Color(0xFFD8BFD8)},
      {'name': 'Necrons', 'color': const Color(0xFFD8BFD8)},
    ];
    final displayPalettes =
        palettes.isNotEmpty
            ? palettes
            : demoPalettes
                .map(
                  (p) => Palette(
                    id: p['name'] as String,
                    name: p['name'] as String,
                    imagePath: '',
                    colors: [p['color'] as Color],
                    createdAt: DateTime.now(),
                  ),
                )
                .toList();
    if (displayPalettes.isEmpty) return Container();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.palette_outlined,
                size: 18,
                color: Color(0xFF9370DB),
              ),
              const SizedBox(width: 8),
              Text(
                'In Palettes:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...displayPalettes
                  .take(2)
                  .map(
                    (palette) => _buildPaletteChip(palette.name, isDarkMode),
                  ),
              if (displayPalettes.length > 2)
                _buildMorePalettesChip(
                  '${displayPalettes.length - 2} more',
                  isDarkMode,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteChip(String name, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD8BFD8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Color(0xFF673AB7),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMorePalettesChip(String text, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+$text',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[700]),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0)
      return 'Today';
    else if (difference.inDays == 1)
      return 'Yesterday';
    else if (difference.inDays < 7)
      return '${difference.inDays} days ago';
    else
      return '${date.month}/${date.day}/${date.year}';
  }
}

/// Dialog to add a paint to inventory.
class _AddToInventoryDialog extends StatefulWidget {
  final Paint paint;
  const _AddToInventoryDialog({required this.paint});
  @override
  State<_AddToInventoryDialog> createState() => _AddToInventoryDialogState();
}

class _AddToInventoryDialogState extends State<_AddToInventoryDialog> {
  int _quantity = 1;
  String? _note;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.paint.name} to Inventory'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How many do you have?'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({'quantity': _quantity, 'note': _note});
          },
          child: const Text('ADD'),
        ),
      ],
    );
  }
}
