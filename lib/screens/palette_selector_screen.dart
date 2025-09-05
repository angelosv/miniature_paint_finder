import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/controllers/palette_controller.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PaletteSelectorScreen extends StatefulWidget {
  final List<String> selectedPaletteIds;

  const PaletteSelectorScreen({super.key, this.selectedPaletteIds = const []});

  @override
  State<PaletteSelectorScreen> createState() => _PaletteSelectorScreenState();
}

class _PaletteSelectorScreenState extends State<PaletteSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<String> _selectedPaletteIds = [];

  @override
  void initState() {
    super.initState();
    _selectedPaletteIds = List.from(widget.selectedPaletteIds);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<PaletteController>();
      if (!controller.hasInitialLoaded) {
        controller.loadPalettes();
      }
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
    return AppScaffold(
      title: 'Select Palettes',
      showBackButton: true,
      body: Column(
        children: [
          // Search
          _buildSearchField(),

          // Selected palettes count
          _buildSelectedCounter(),

          // Palette grid
          Expanded(child: _buildPaletteGrid()),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search palettes by name...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch();
                    },
                  )
                  : null,
        ),
        onChanged: (_) => _performSearch(),
      ),
    );
  }

  Widget _buildSelectedCounter() {
    if (_selectedPaletteIds.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveGuidelines.spacingL,
        vertical: ResponsiveGuidelines.spacingS,
      ),
      margin: EdgeInsets.symmetric(horizontal: ResponsiveGuidelines.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.marineBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
      ),
      child: Row(
        children: [
          Icon(Icons.palette, color: AppTheme.marineBlue, size: 20.r),
          SizedBox(width: 8.w),
          Text(
            '${_selectedPaletteIds.length} palette${_selectedPaletteIds.length != 1 ? 's' : ''} selected',
            style: TextStyle(
              color: AppTheme.marineBlue,
              fontSize: ResponsiveGuidelines.bodyMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedPaletteIds.clear();
              });
            },
            child: Text(
              'Clear All',
              style: TextStyle(
                color: AppTheme.marineBlue,
                fontSize: ResponsiveGuidelines.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteGrid() {
    return Consumer<PaletteController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null) {
          return _buildErrorState(controller.error!);
        }

        final filteredPalettes = _filterPalettes(controller.palettes);

        if (filteredPalettes.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 0.8,
          ),
          itemCount: filteredPalettes.length,
          itemBuilder: (context, index) {
            final palette = filteredPalettes[index];
            final isSelected = _selectedPaletteIds.contains(palette.id);

            return _buildPaletteCard(palette, isSelected);
          },
        );
      },
    );
  }

  List<Palette> _filterPalettes(List<Palette> palettes) {
    if (_searchController.text.isEmpty) return palettes;

    final query = _searchController.text.toLowerCase();
    return palettes.where((palette) {
      return palette.name.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildPaletteCard(Palette palette, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusL),
        border:
            isSelected
                ? Border.all(color: AppTheme.marineBlue, width: 3.w)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusL),
          onTap: () => _togglePaletteSelection(palette.id),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Palette image
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPaletteImage(palette),

                      // Selection overlay
                      if (isSelected)
                        Container(
                          color: AppTheme.marineBlue.withOpacity(0.3),
                          child: Center(
                            child: Container(
                              width: 40.r,
                              height: 40.r,
                              decoration: const BoxDecoration(
                                color: AppTheme.marineBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24.r,
                              ),
                            ),
                          ),
                        ),

                      // Color swatches overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildColorSwatches(palette.colors),
                      ),
                    ],
                  ),
                ),

                // Palette info
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    color: Theme.of(context).cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          palette.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 4.h),

                        Row(
                          children: [
                            Icon(
                              Icons.palette,
                              size: 16.r,
                              color: AppTheme.textGrey,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${palette.colors.length} colors',
                              style: TextStyle(
                                fontSize: ResponsiveGuidelines.bodySmall,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 4.h),

                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16.r,
                              color: AppTheme.textGrey,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                _formatDate(palette.createdAt),
                                style: TextStyle(
                                  fontSize: ResponsiveGuidelines.labelSmall,
                                  color: AppTheme.textGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildPaletteImage(Palette palette) {
    if (palette.imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: palette.imagePath,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget: (context, error, stackTrace) {
          return _buildFallbackPaletteImage(palette);
        },
      );
    } else {
      return Image.asset(
        palette.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackPaletteImage(palette);
        },
      );
    }
  }

  Widget _buildFallbackPaletteImage(Palette palette) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              palette.colors.isNotEmpty
                  ? palette.colors.take(3).toList()
                  : [
                    AppTheme.marineBlue,
                    AppTheme.marineOrange,
                    AppTheme.marineGold,
                  ],
        ),
      ),
      child: Center(
        child: Icon(Icons.palette, color: Colors.white, size: 48.r),
      ),
    );
  }

  Widget _buildColorSwatches(List<Color> colors) {
    if (colors.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 16.h,
      child: Row(
        children:
            colors.take(6).map((color) {
              return Expanded(child: Container(color: color));
            }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.palette_outlined,
            size: 64.r,
            color: AppTheme.textGrey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No palettes found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try adjusting your search'
                : 'Create your first palette to get started',
            style: TextStyle(
              fontSize: ResponsiveGuidelines.bodySmall,
              color: AppTheme.textGrey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isEmpty) ...[
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/palette');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Palette'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.marineOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.r,
            color: Colors.red.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'Error loading palettes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: TextStyle(
              fontSize: ResponsiveGuidelines.bodySmall,
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              final controller = context.read<PaletteController>();
              controller.loadPalettes();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(width: ResponsiveGuidelines.spacingM),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  _selectedPaletteIds.isNotEmpty ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _selectedPaletteIds.isNotEmpty
                        ? AppTheme.marineOrange
                        : AppTheme.textGrey,
              ),
              child: Text(
                'Link ${_selectedPaletteIds.length} Palette${_selectedPaletteIds.length != 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    setState(() {
      // The filtering is handled in _filterPalettes method
    });
  }

  void _togglePaletteSelection(String paletteId) {
    setState(() {
      if (_selectedPaletteIds.contains(paletteId)) {
        _selectedPaletteIds.remove(paletteId);
      } else {
        _selectedPaletteIds.add(paletteId);
      }
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedPaletteIds);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
