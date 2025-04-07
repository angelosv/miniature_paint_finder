import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/paint_grid_card.dart';
import 'package:miniature_paint_finder/components/app_header.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';
import 'package:miniature_paint_finder/controllers/paint_library_controller.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaintLibraryController>().loadPaints();
    });
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

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'Paint Library',
      selectedIndex: -1,
      body: _buildBody(context, isDarkMode, controller),
      drawer: const SharedDrawer(currentScreen: 'library'),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode, PaintLibraryController controller) {
    return Stack(
      children: [
        Column(
          children: [
            _buildSearchBar(isDarkMode, controller),
            _buildResultsBar(isDarkMode, controller),
            Expanded(child: _buildPaintGrid(isDarkMode, controller)),
            _buildPagination(controller),
          ],
        ),
        if (controller.isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDarkMode, PaintLibraryController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => controller.searchPaints(value),
              decoration: InputDecoration(
                hintText: 'Search paints...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          controller.searchPaints('');
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
            onTap: () => _showFilterDialog(context, controller),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? AppTheme.darkSurface : Theme.of(context).cardColor,
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
                    color: isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
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
                      color: controller.pageSize == size ? AppTheme.primaryBlue : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
    return controller.paginatedPaints.isEmpty
        ? const Center(child: Text('No paints found matching your filters'))
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasActiveFilters(controller)) _buildActiveFiltersBar(isDarkMode, controller),
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
                      final mainColor = isDarkMode ? Colors.white : Theme.of(context).primaryColor;
                      final isInWishlist = controller.isPaintInWishlist(paint.id);

                      return PaintGridCard(
                        paint: paint,
                        color: mainColor,
                        onAddToWishlist: controller.toggleWishlist,
                        onAddToInventory: _addToInventory,
                        isInWishlist: isInWishlist,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildActiveFiltersBar(bool isDarkMode, PaintLibraryController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (controller.selectedBrand != 'All')
            _buildFilterChip(
              label: controller.selectedBrand,
              onRemove: () => controller.filterByBrand('All'),
              isDarkMode: isDarkMode,
              icon: Icons.business,
            ),
          if (controller.selectedCategory != 'All')
            _buildFilterChip(
              label: controller.selectedCategory,
              onRemove: () => controller.filterByCategory('All'),
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
              foregroundColor: isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
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
            onPressed: controller.currentPage > 1 ? () => controller.goToPage(1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: controller.currentPage > 1 ? () => controller.goToPreviousPage() : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Page ${controller.currentPage} of ${controller.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: controller.currentPage < controller.totalPages ? () => controller.goToNextPage() : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: controller.currentPage < controller.totalPages ? () => controller.goToPage(controller.totalPages) : null,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, PaintLibraryController controller) {
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
                        color: isDarkMode ? Colors.grey[600] : Colors.grey.withOpacity(0.5),
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
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: controller.selectedBrand,
                      items: controller.availableBrands.map((brand) {
                        return DropdownMenuItem<String>(
                          value: brand,
                          child: Text(brand),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.filterByBrand(value);
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: controller.selectedCategory,
                      items: controller.availableCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.filterByCategory(value);
                        }
                      },
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      underline: Container(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            side: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? AppTheme.marineOrange : AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('APPLY FILTERS'),
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

  void _addToInventory(String paintId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to inventory'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
