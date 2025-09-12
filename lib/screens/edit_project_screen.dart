import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/models/project.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/screens/paint_selector_screen.dart';
import 'package:miniature_paint_finder/screens/palette_selector_screen.dart';
import 'package:miniature_paint_finder/services/image_upload_service.dart';
import 'package:miniature_paint_finder/repositories/project_repository.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:miniature_paint_finder/repositories/project_repository.dart';
import 'package:provider/provider.dart';

class EditProjectScreen extends StatefulWidget {
  final Project project;

  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late ProjectStatus _selectedStatus;
  late List<String> _selectedTags;
  late List<ProjectImage> _projectImages;
  late List<ProjectPaint> _projectPaints;
  late List<String> _linkedPaletteIds;

  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  final List<String> _newImageRecordIds = [];
  final List<String> _deletedImageItemIds = [];

  final List<String> _availableTags = [
    'warhammer-40k',
    'space-marines',
    'fantasy',
    'orks',
    'elves',
    'chaos',
    'necrons',
    'custodes',
    'weathering',
    'osl',
    'tmm',
    'nmm',
    'dragon',
    'knight',
    'large-miniature',
    'army',
    'character',
    'vehicle',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize controllers and data
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(
      text: widget.project.description ?? '',
    );
    _selectedStatus = widget.project.status;
    _selectedTags = List.from(widget.project.tags);
    _projectImages = List.from(widget.project.images);
    _projectPaints = List.from(widget.project.paints);
    _linkedPaletteIds = List.from(widget.project.paletteIds);

    // Listen for changes
    _nameController.addListener(_onDataChanged);
    _descriptionController.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: AppScaffold(
        title: 'Edit Project',
        showBackButton: true,
        body: Column(
          children: [
            // Tab bar
            Container(
              margin: EdgeInsets.all(ResponsiveGuidelines.spacingL),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(
                  ResponsiveGuidelines.radiusM,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.marineBlue,
                  borderRadius: BorderRadius.circular(
                    ResponsiveGuidelines.radiusM,
                  ),
                ),
                indicatorPadding: EdgeInsets.all(4.w),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textGrey,
                labelStyle: TextStyle(
                  fontSize: ResponsiveGuidelines.bodySmall,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Info'),
                  Tab(text: 'Images'),
                  Tab(text: 'Paints'),
                  Tab(text: 'Palettes'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildImagesTab(),
                  _buildPaintsTab(),
                  _buildPalettesTab(),
                ],
              ),
            ),

            // Save button
            Container(
              padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasChanges ? _saveProject : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _hasChanges ? AppTheme.marineOrange : AppTheme.textGrey,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child:
                      _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            _hasChanges ? 'Save Changes' : 'No Changes',
                            style: TextStyle(
                              fontSize: ResponsiveGuidelines.bodyLarge,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Project Name *',
              prefixIcon: const Icon(Icons.edit),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a project name';
              }
              return null;
            },
          ),

          SizedBox(height: ResponsiveGuidelines.spacingL),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 3,
          ),

          SizedBox(height: ResponsiveGuidelines.spacingL),

          // Status Selection
          Text(
            'Status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: ResponsiveGuidelines.spacingS),
          Wrap(
            spacing: 8.w,
            children:
                ProjectStatus.values.map((status) {
                  final isSelected = _selectedStatus == status;
                  return FilterChip(
                    label: Text('${status.emoji} ${status.displayName}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                      _markChanged();
                    },
                    selectedColor: _getStatusColor(status).withOpacity(0.2),
                    checkmarkColor: _getStatusColor(status),
                  );
                }).toList(),
          ),

          SizedBox(height: ResponsiveGuidelines.spacingL),

          // Tags Selection
          Text(
            'Tags',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: ResponsiveGuidelines.spacingS),
          Text(
            'Select relevant tags to categorize your project',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
          ),
          SizedBox(height: ResponsiveGuidelines.spacingM),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children:
                _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                      _markChanged();
                    },
                    selectedColor: AppTheme.marineOrange.withOpacity(0.2),
                    checkmarkColor: AppTheme.marineOrange,
                  );
                }).toList(),
          ),

          SizedBox(height: ResponsiveGuidelines.spacingXL),
        ],
      ),
    );
  }

  Widget _buildImagesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add image button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploadingImage ? null : _showAddImageDialog,
              icon: const Icon(Icons.add_photo_alternate),
              label:
                  _isUploadingImage
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 16.r,
                            width: 16.r,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8.w),
                          const Text('Uploading...'),
                        ],
                      )
                      : const Text('Add Image'),
            ),
          ),

          SizedBox(height: ResponsiveGuidelines.spacingL),

          if (_isUploadingImage) ...[
            Row(
              children: [
                SizedBox(
                  height: 16.r,
                  width: 16.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Uploading image... please wait',
                  style: TextStyle(
                    fontSize: ResponsiveGuidelines.bodySmall,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveGuidelines.spacingM),
          ],

          // Images grid
          if (_projectImages.isNotEmpty) ...[
            Text(
              'Project Images (${_projectImages.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: ResponsiveGuidelines.spacingM),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 1.0,
              ),
              itemCount: _projectImages.length,
              itemBuilder: (context, index) {
                final image = _projectImages[index];
                return _buildEditableImageCard(image, index);
              },
            ),
          ] else ...[
            _buildEmptyImageState(),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableImageCard(ProjectImage image, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            image.imagePath.startsWith('http')
                ? Image.network(
                  image.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder();
                  },
                )
                : Image.asset(
                  image.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder();
                  },
                ),

            // Actions overlay
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Make main button
                    if (!image.isMain)
                      IconButton(
                        onPressed: () => _setMainImage(index),
                        icon: const Icon(
                          Icons.star_border,
                          color: Colors.white,
                        ),
                        iconSize: 20.r,
                        padding: EdgeInsets.all(4.w),
                        constraints: BoxConstraints(
                          minWidth: 32.w,
                          minHeight: 32.h,
                        ),
                      ),

                    // Delete button
                    IconButton(
                      onPressed: () => _removeImage(index),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      iconSize: 20.r,
                      padding: EdgeInsets.all(4.w),
                      constraints: BoxConstraints(
                        minWidth: 32.w,
                        minHeight: 32.h,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Type and main indicator
            Positioned(
              bottom: 8.h,
              left: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      image.type.icon,
                      style: TextStyle(
                        fontSize: ResponsiveGuidelines.labelSmall,
                      ),
                    ),
                    if (image.isMain) ...[
                      SizedBox(width: 4.w),
                      Icon(Icons.star, color: AppTheme.marineGold, size: 12.r),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppTheme.marineBlue.withOpacity(0.1),
      child: Icon(
        Icons.image_not_supported,
        color: AppTheme.textGrey,
        size: 32.r,
      ),
    );
  }

  Widget _buildEmptyImageState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64.r,
            color: AppTheme.textGrey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No images yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add photos to track your painting progress',
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

  Widget _buildPaintsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add paint button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddPaintDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Paint'),
            ),
          ),

          SizedBox(height: ResponsiveGuidelines.spacingL),

          // Paints list
          if (_projectPaints.isNotEmpty) ...[
            Text(
              'Project Paints (${_projectPaints.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: ResponsiveGuidelines.spacingM),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _projectPaints.length,
              itemBuilder: (context, index) {
                final paint = _projectPaints[index];
                return _buildEditablePaintCard(paint, index);
              },
            ),
          ] else ...[
            _buildEmptyPaintState(),
          ],
        ],
      ),
    );
  }

  Widget _buildEditablePaintCard(ProjectPaint paint, int index) {
    final color = Color(
      int.parse(paint.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
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
                  paint.paintName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2.h),
                Text(
                  paint.paintBrand,
                  style: TextStyle(
                    fontSize: ResponsiveGuidelines.bodySmall,
                    color: AppTheme.textGrey,
                  ),
                ),
                if (paint.notes != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    paint.notes!,
                    style: TextStyle(
                      fontSize: ResponsiveGuidelines.labelSmall,
                      color: AppTheme.textGrey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              // Edit notes button
              IconButton(
                onPressed: () => _editPaintNotes(index),
                icon: const Icon(Icons.edit_note),
                color: AppTheme.marineBlue,
              ),
              // Remove button
              IconButton(
                onPressed: () => _removePaint(index),
                icon: const Icon(Icons.remove_circle),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPaintState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.brush_outlined,
            size: 64.r,
            color: AppTheme.textGrey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No paints added',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add paints used in this project',
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

  Widget _buildPalettesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Link palette button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showLinkPaletteDialog,
              icon: const Icon(Icons.add),
              label: const Text('Link Palette'),
            ),
          ),

          SizedBox(height: ResponsiveGuidelines.spacingL),

          // Linked palettes
          if (_linkedPaletteIds.isNotEmpty) ...[
            Text(
              'Linked Palettes (${_linkedPaletteIds.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: ResponsiveGuidelines.spacingM),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _linkedPaletteIds.length,
              itemBuilder: (context, index) {
                final paletteId = _linkedPaletteIds[index];
                return _buildEditablePaletteCard(paletteId, index);
              },
            ),
          ] else ...[
            _buildEmptyPaletteState(),
          ],
        ],
      ),
    );
  }

  Widget _buildEditablePaletteCard(String paletteId, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Palette preview colors
          Container(
            width: 60.w,
            height: 40.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.marineBlue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8.r),
                        bottomLeft: Radius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                Expanded(child: Container(color: AppTheme.marineOrange)),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.marineGold,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8.r),
                        bottomRight: Radius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 16.w),

          // Palette info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Palette $paletteId',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2.h),
                Text(
                  '5 colors • Main color scheme',
                  style: TextStyle(
                    fontSize: ResponsiveGuidelines.bodySmall,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: () => _unlinkPalette(index),
            icon: const Icon(Icons.remove_circle),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPaletteState() {
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
            'No palettes linked',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Link color palettes to this project',
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

  // Dialog methods
  void _showAddImageDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Image'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('From Gallery'),
                  onTap: () => _addImageFromGallery(),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () => _addImageFromCamera(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _showAddPaintDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Paints'),
            content: const Text(
              'Choose how you want to add paints to your project.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addDemoPaint();
                },
                child: const Text('Demo Paint'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaintSelector();
                },
                child: const Text('From Library'),
              ),
            ],
          ),
    );
  }

  void _showLinkPaletteDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Link Palettes'),
            content: const Text(
              'Choose how you want to link palettes to your project.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _linkDemoPalette();
                },
                child: const Text('Demo Palette'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaletteSelector();
                },
                child: const Text('From Saved'),
              ),
            ],
          ),
    );
  }

  // Action methods
  void _addImageFromGallery() {
    Navigator.pop(context);
    _pickAndUploadImage(ImageSource.gallery);
  }

  void _addImageFromCamera() {
    Navigator.pop(context);
    _pickAndUploadImage(ImageSource.camera);
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        _isUploadingImage = true;
      });

      final imageService = ImageUploadService();
      final uploadedUrl = await imageService.uploadImage(file);
      final recordId = await imageService.registerImage(uploadedUrl);
      setState(() {
        _projectImages.add(
          ProjectImage(
            id: recordId,
            imagePath: uploadedUrl,
            caption: null,
            type: ProjectImageType.reference,
            createdAt: DateTime.now(),
          ),
        );
        _newImageRecordIds.add(recordId);
        _isUploadingImage = false;
      });
      _markChanged();
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    }
  }

  void _setMainImage(int index) {
    setState(() {
      // Remove main from all images
      for (int i = 0; i < _projectImages.length; i++) {
        _projectImages[i] = ProjectImage(
          id: _projectImages[i].id,
          imagePath: _projectImages[i].imagePath,
          caption: _projectImages[i].caption,
          type: _projectImages[i].type,
          isMain: i == index,
          createdAt: _projectImages[i].createdAt,
        );
      }
    });
    _markChanged();
  }

  void _removeImage(int index) {
    final removed = _projectImages[index];
    setState(() {
      _projectImages.removeAt(index);
    });
    _markChanged();
    final recordId = removed.id;
    if ((removed.itemId ?? '').isNotEmpty) {
      _deletedImageItemIds.add(removed.itemId!);
    }
    if (recordId.isNotEmpty) {
      _newImageRecordIds.remove(recordId);
    }
  }

  void _addDemoPaint() {
    final colors = ['#FF5733', '#33FF57', '#3357FF', '#FF33F1', '#F1FF33'];
    final names = [
      'Demo Red',
      'Demo Green',
      'Demo Blue',
      'Demo Purple',
      'Demo Yellow',
    ];
    final brands = ['Citadel', 'Vallejo', 'Army Painter', 'Scale75', 'P3'];

    final random = DateTime.now().millisecondsSinceEpoch % 5;

    final newPaint = ProjectPaint(
      paintId: 'paint_${DateTime.now().millisecondsSinceEpoch}',
      paintName: names[random],
      paintBrand: brands[random],
      brandAvatar: brands[random][0],
      colorHex: colors[random],
      notes: 'Added for demonstration',
      addedAt: DateTime.now(),
    );

    setState(() {
      _projectPaints.add(newPaint);
    });
    _markChanged();
  }

  void _editPaintNotes(int index) {
    final controller = TextEditingController(
      text: _projectPaints[index].notes ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Notes - ${_projectPaints[index].paintName}'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'How did you use this paint?',
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
                    _projectPaints[index] = ProjectPaint(
                      paintId: _projectPaints[index].paintId,
                      paintName: _projectPaints[index].paintName,
                      paintBrand: _projectPaints[index].paintBrand,
                      brandAvatar: _projectPaints[index].brandAvatar,
                      colorHex: _projectPaints[index].colorHex,
                      notes:
                          controller.text.trim().isEmpty
                              ? null
                              : controller.text.trim(),
                      addedAt: _projectPaints[index].addedAt,
                    );
                  });
                  _markChanged();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _removePaint(int index) {
    setState(() {
      _projectPaints.removeAt(index);
    });
    _markChanged();
  }

  void _linkDemoPalette() {
    final newPaletteId = 'palette_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _linkedPaletteIds.add(newPaletteId);
    });
    _markChanged();
  }

  void _unlinkPalette(int index) {
    setState(() {
      _linkedPaletteIds.removeAt(index);
    });
    _markChanged();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes. Do you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  Future<void> _saveProject() async {
    setState(() {
      _isSaving = true;
    });

    final updatedProject = widget.project.copyWith(
      name: _nameController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      status: _selectedStatus,
      tags: List.from(_selectedTags),
      images: List.from(_projectImages),
      paints: List.from(_projectPaints),
      paletteIds: List.from(_linkedPaletteIds),
      updatedAt: DateTime.now(),
    );
    try {
      final repo = Provider.of<ProjectRepository>(context, listen: false);
      await repo.update(updatedProject);

      // Link new uploaded images to the project
      for (final recordId in _newImageRecordIds) {
        await repo.addProjectItem(
          projectId: updatedProject.id,
          table: 'user_color_images',
          tableId: recordId,
        );
      }

      // Delete removed image links from the project
      for (final itemId in _deletedImageItemIds) {
        await repo.deleteProjectItem(itemId: itemId);
      }

      setState(() {
        _isSaving = false;
        _hasChanges = false;
        _deletedImageItemIds.clear();
        _newImageRecordIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${updatedProject.name}" saved successfully!'),
            backgroundColor: AppTheme.greenColor,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, updatedProject);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save project'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return AppTheme.marineBlue;
      case ProjectStatus.inProgress:
        return AppTheme.marineOrange;
      case ProjectStatus.completed:
        return AppTheme.greenColor;
      case ProjectStatus.onHold:
        return AppTheme.textGrey;
    }
  }

  // Paint selector integration
  Future<void> _showPaintSelector() async {
    final result = await Navigator.push<List<ProjectPaint>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaintSelectorScreen(selectedPaints: _projectPaints),
      ),
    );

    if (result != null) {
      setState(() {
        _projectPaints = result;
      });
      _markChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${result.length} paints to project'),
          backgroundColor: AppTheme.greenColor,
        ),
      );
    }
  }

  // Palette selector integration
  Future<void> _showPaletteSelector() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                PaletteSelectorScreen(selectedPaletteIds: _linkedPaletteIds),
      ),
    );

    if (result != null) {
      setState(() {
        _linkedPaletteIds = result;
      });
      _markChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Linked ${result.length} palettes to project'),
          backgroundColor: AppTheme.greenColor,
        ),
      );
    }
  }
}
