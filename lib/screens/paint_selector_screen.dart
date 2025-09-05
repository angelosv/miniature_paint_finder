import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/project.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/controllers/paint_library_controller.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:provider/provider.dart';

class PaintSelectorScreen extends StatefulWidget {
  final List<ProjectPaint> selectedPaints;

  const PaintSelectorScreen({super.key, this.selectedPaints = const []});

  @override
  State<PaintSelectorScreen> createState() => _PaintSelectorScreenState();
}

class _PaintSelectorScreenState extends State<PaintSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PaintService _paintService = PaintService();

  List<ProjectPaint> _selectedPaints = [];
  Map<String, String> _paintNotes = {};
  bool _showOnlyInventory = true;
  bool _showOnlyWishlist = false;

  @override
  void initState() {
    super.initState();
    _selectedPaints = List.from(widget.selectedPaints);

    // Initialize notes from existing selected paints
    for (final paint in _selectedPaints) {
      if (paint.notes != null) {
        _paintNotes[paint.paintId] = paint.notes!;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<PaintLibraryController>();
      controller.loadBrands();
      controller.loadCategories();
      controller.loadPaints();
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
      title: 'Select Paints',
      showBackButton: true,
      body: Column(
        children: [
          // Search and filters
          _buildSearchAndFilters(),

          // Selected paints count
          _buildSelectedCounter(),

          // Paint list
          Expanded(child: _buildPaintList()),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search paints by name, brand, or color...',
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

          SizedBox(height: ResponsiveGuidelines.spacingM),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('In Inventory'),
                  selected: _showOnlyInventory,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyInventory = selected;
                      if (selected) _showOnlyWishlist = false;
                    });
                    _performSearch();
                  },
                  selectedColor: AppTheme.greenColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.greenColor,
                ),
                SizedBox(width: 8.w),
                FilterChip(
                  label: const Text('In Wishlist'),
                  selected: _showOnlyWishlist,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyWishlist = selected;
                      if (selected) _showOnlyInventory = false;
                    });
                    _performSearch();
                  },
                  selectedColor: AppTheme.marineOrange.withOpacity(0.2),
                  checkmarkColor: AppTheme.marineOrange,
                ),
                SizedBox(width: 8.w),
                FilterChip(
                  label: const Text('All Paints'),
                  selected: !_showOnlyInventory && !_showOnlyWishlist,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _showOnlyInventory = false;
                        _showOnlyWishlist = false;
                      });
                      _performSearch();
                    }
                  },
                  selectedColor: AppTheme.marineBlue.withOpacity(0.2),
                  checkmarkColor: AppTheme.marineBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCounter() {
    if (_selectedPaints.isEmpty) return const SizedBox.shrink();

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
          Icon(Icons.brush, color: AppTheme.marineBlue, size: 20.r),
          SizedBox(width: 8.w),
          Text(
            '${_selectedPaints.length} paint${_selectedPaints.length != 1 ? 's' : ''} selected',
            style: TextStyle(
              color: AppTheme.marineBlue,
              fontSize: ResponsiveGuidelines.bodyMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_selectedPaints.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedPaints.clear();
                  _paintNotes.clear();
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

  Widget _buildPaintList() {
    return Consumer<PaintLibraryController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredPaints.isEmpty) {
          return _buildEmptyState();
        }

        final filteredPaints = _filterPaints(controller.filteredPaints);

        if (filteredPaints.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveGuidelines.spacingL,
          ),
          itemCount: filteredPaints.length,
          itemBuilder: (context, index) {
            final paint = filteredPaints[index];
            final isSelected = _selectedPaints.any(
              (p) => p.paintId == paint.id,
            );
            final isInInventory = _paintService.isInInventory(paint.id);
            final isInWishlist = _paintService.isInWishlist(paint.id);

            return _buildPaintCard(
              paint,
              isSelected,
              isInInventory,
              isInWishlist,
            );
          },
        );
      },
    );
  }

  List<Paint> _filterPaints(List<Paint> paints) {
    return paints.where((paint) {
      if (_showOnlyInventory && !_paintService.isInInventory(paint.id)) {
        return false;
      }
      if (_showOnlyWishlist && !_paintService.isInWishlist(paint.id)) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildPaintCard(
    Paint paint,
    bool isSelected,
    bool isInInventory,
    bool isInWishlist,
  ) {
    final color = paint.toColor();

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
        border:
            isSelected
                ? Border.all(color: AppTheme.marineBlue, width: 2.w)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
          onTap: () => _togglePaintSelection(paint),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Selection indicator
                Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected ? AppTheme.marineBlue : AppTheme.textGrey,
                      width: 2.w,
                    ),
                    color:
                        isSelected ? AppTheme.marineBlue : Colors.transparent,
                  ),
                  child:
                      isSelected
                          ? Icon(Icons.check, color: Colors.white, size: 16.r)
                          : null,
                ),

                SizedBox(width: 16.w),

                // Color circle
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.w,
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // Paint info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paint.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        paint.brand,
                        style: TextStyle(
                          fontSize: ResponsiveGuidelines.bodySmall,
                          color: AppTheme.textGrey,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Text(
                            paint.hex.toUpperCase(),
                            style: TextStyle(
                              fontSize: ResponsiveGuidelines.labelSmall,
                              color: AppTheme.textGrey,
                              fontFamily: 'monospace',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.marineBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              paint.category,
                              style: TextStyle(
                                fontSize: ResponsiveGuidelines.labelSmall,
                                color: AppTheme.marineBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status indicators
                Column(
                  children: [
                    if (isInInventory)
                      Container(
                        margin: EdgeInsets.only(bottom: 4.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.greenColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Owned',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveGuidelines.labelSmall,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (isInWishlist)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.marineOrange,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Wanted',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveGuidelines.labelSmall,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // Notes button for selected paints
                    if (isSelected) ...[
                      SizedBox(height: 4.h),
                      IconButton(
                        onPressed: () => _editPaintNotes(paint),
                        icon: Icon(
                          _paintNotes.containsKey(paint.id) &&
                                  _paintNotes[paint.id]!.isNotEmpty
                              ? Icons.note
                              : Icons.note_add,
                          color: AppTheme.marineBlue,
                        ),
                        iconSize: 20.r,
                        constraints: BoxConstraints(
                          minWidth: 32.w,
                          minHeight: 32.h,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64.r,
            color: AppTheme.textGrey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No paints found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: ResponsiveGuidelines.bodySmall,
              color: AppTheme.textGrey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
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
              onPressed: _selectedPaints.isNotEmpty ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _selectedPaints.isNotEmpty
                        ? AppTheme.marineOrange
                        : AppTheme.textGrey,
              ),
              child: Text(
                'Add ${_selectedPaints.length} Paint${_selectedPaints.length != 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    final controller = context.read<PaintLibraryController>();
    controller.searchPaints(_searchController.text);
  }

  void _togglePaintSelection(Paint paint) {
    setState(() {
      final existingIndex = _selectedPaints.indexWhere(
        (p) => p.paintId == paint.id,
      );

      if (existingIndex != -1) {
        // Remove from selection
        _selectedPaints.removeAt(existingIndex);
        _paintNotes.remove(paint.id);
      } else {
        // Add to selection
        final projectPaint = ProjectPaint(
          paintId: paint.id,
          paintName: paint.name,
          paintBrand: paint.brand,
          brandAvatar:
              paint.brand.isNotEmpty ? paint.brand[0].toUpperCase() : 'P',
          colorHex: paint.hex,
          notes: _paintNotes[paint.id],
          addedAt: DateTime.now(),
        );
        _selectedPaints.add(projectPaint);
      }
    });
  }

  void _editPaintNotes(Paint paint) {
    final controller = TextEditingController(text: _paintNotes[paint.id] ?? '');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Notes - ${paint.name}'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'How will you use this paint in the project?',
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (controller.text.trim().isEmpty) {
                      _paintNotes.remove(paint.id);
                    } else {
                      _paintNotes[paint.id] = controller.text.trim();
                    }

                    // Update the selected paint if it exists
                    final index = _selectedPaints.indexWhere(
                      (p) => p.paintId == paint.id,
                    );
                    if (index != -1) {
                      _selectedPaints[index] = ProjectPaint(
                        paintId: _selectedPaints[index].paintId,
                        paintName: _selectedPaints[index].paintName,
                        paintBrand: _selectedPaints[index].paintBrand,
                        brandAvatar: _selectedPaints[index].brandAvatar,
                        colorHex: _selectedPaints[index].colorHex,
                        notes:
                            controller.text.trim().isEmpty
                                ? null
                                : controller.text.trim(),
                        addedAt: _selectedPaints[index].addedAt,
                      );
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedPaints);
  }
}
