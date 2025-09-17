import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/models/project.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:miniature_paint_finder/screens/edit_project_screen.dart';
import 'package:miniature_paint_finder/repositories/project_repository.dart';
import 'package:provider/provider.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedImageIndex = 0;
  late Project _currentProject;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentProject = widget.project;
    _loadFullProject();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFullProject() async {
    try {
      final repo = Provider.of<ProjectRepository>(context, listen: false);
      final full = await repo.getById(_currentProject.id);
      if (full != null && mounted) {
        setState(() {
          _currentProject = full;
          _selectedImageIndex = 0;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: _currentProject.name,
      showBackButton: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with main image and status
            _buildProjectHeader(isDarkMode),

            // Project info section
            _buildProjectInfo(isDarkMode),

            SizedBox(height: ResponsiveGuidelines.spacingL),

            // Tabs for different content
            _buildTabSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _editProject,
        backgroundColor: AppTheme.marineOrange,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildProjectHeader(bool isDarkMode) {
    final hasImages = _currentProject.images.isNotEmpty;

    return Container(
      height: 300.h,
      child: Stack(
        children: [
          // Main image
          if (hasImages)
            PageView.builder(
              itemCount: _currentProject.images.length,
              onPageChanged: (index) {
                setState(() {
                  _selectedImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final image = _currentProject.images[index];
                return _buildProjectImage(image, isDarkMode);
              },
            )
          else
            _buildPlaceholderImage(isDarkMode),

          // Gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ),

          // Status badge
          Positioned(
            top: 16.h,
            right: 16.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _getStatusColor(_currentProject.status).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(_currentProject.status),
                    color: Colors.white,
                    size: 16.r,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    _currentProject.status.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveGuidelines.labelMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Image indicator dots
          if (hasImages && _currentProject.images.length > 1)
            Positioned(
              bottom: 20.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _currentProject.images.length,
                  (index) => Container(
                    width: 8.r,
                    height: 8.r,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _selectedImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),

          // Image type badge
          if (hasImages)
            Positioned(
              bottom: 60.h,
              left: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${_currentProject.images[_selectedImageIndex].type.icon} ${_currentProject.images[_selectedImageIndex].type.displayName}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveGuidelines.labelSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectImage(ProjectImage image, bool isDarkMode) {
    return image.imagePath.startsWith('http')
        ? CachedNetworkImage(
          imageUrl: image.imagePath,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode ? Colors.orange : Colors.blue,
                  ),
                ),
              ),
          errorWidget: (context, error, stackTrace) {
            return _buildPlaceholderImage(isDarkMode);
          },
        )
        : Image.asset(
          image.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage(isDarkMode);
          },
        );
  }

  Widget _buildPlaceholderImage(bool isDarkMode) {
    return Container(
      color: AppTheme.marineBlue.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 64.r,
              color: AppTheme.marineBlue.withOpacity(0.6),
            ),
            SizedBox(height: 16.h),
            Text(
              'No images yet',
              style: TextStyle(
                color: AppTheme.marineBlue.withOpacity(0.6),
                fontSize: ResponsiveGuidelines.bodyLarge,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add photos to track your progress',
              style: TextStyle(
                color: AppTheme.textGrey,
                fontSize: ResponsiveGuidelines.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInfo(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project name
          Text(
            _currentProject.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 8.h),

          // Description
          if (_currentProject.description != null) ...[
            Text(
              _currentProject.description!,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textGrey),
            ),
            SizedBox(height: 16.h),
          ],

          // Stats row
          Row(
            children: [
              _buildStatItem(
                Icons.photo_library_outlined,
                '${_currentProject.images.length}',
                'Images',
              ),
              SizedBox(width: 24.w),
              _buildStatItem(
                Icons.palette_outlined,
                '${_currentProject.palettes.length}',
                'Palettes',
              ),
              SizedBox(width: 24.w),
              _buildStatItem(
                Icons.brush_outlined,
                '${_currentProject.paints.length}',
                'Paints',
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Tags
          if (_currentProject.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  _currentProject.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: AppTheme.marineBlue.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: AppTheme.marineBlue,
                        fontSize: ResponsiveGuidelines.labelSmall,
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: 16.h),
          ],

          // Dates
          Row(
            children: [
              Expanded(
                child: _buildDateInfo(
                  'Created',
                  _currentProject.createdAt,
                  isDarkMode,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildDateInfo(
                  'Updated',
                  _currentProject.updatedAt,
                  isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: ResponsiveGuidelines.iconS,
          color: AppTheme.marineBlue,
        ),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveGuidelines.titleMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.marineBlue,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveGuidelines.labelSmall,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateInfo(String label, DateTime date, bool isDarkMode) {
    final now = DateTime.now();
    final difference = now.difference(date);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inMinutes}m ago';
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveGuidelines.labelSmall,
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: ResponsiveGuidelines.bodyMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      child: Column(
        children: [
          // Tab bar
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveGuidelines.spacingL,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.marineBlue,
                borderRadius: BorderRadius.circular(
                  ResponsiveGuidelines.radiusM,
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.all(4.w),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textGrey,
              labelStyle: TextStyle(
                fontSize: ResponsiveGuidelines.bodySmall,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Images'),
                Tab(text: 'Paints'),
                Tab(text: 'Palettes'),
              ],
            ),
          ),

          SizedBox(height: ResponsiveGuidelines.spacingL),

          // Tab content
          SizedBox(
            height: 400.h,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildImagesTab(),
                _buildPaintsTab(),
                _buildPalettesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesTab() {
    if (_currentProject.images.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No images yet',
        subtitle: 'Add photos to track your painting progress',
      );
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveGuidelines.spacingL),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.0,
      ),
      itemCount: _currentProject.images.length,
      itemBuilder: (context, index) {
        final image = _currentProject.images[index];
        return _buildImageGridItem(image);
      },
    );
  }

  Widget _buildImageGridItem(ProjectImage image) {
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
                ? CachedNetworkImage(
                  imageUrl: image.imagePath,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  errorWidget: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.marineBlue.withOpacity(0.1),
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppTheme.textGrey,
                        size: 32.r,
                      ),
                    );
                  },
                )
                : Image.asset(
                  image.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.marineBlue.withOpacity(0.1),
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppTheme.textGrey,
                        size: 32.r,
                      ),
                    );
                  },
                ),

            // Type badge
            Positioned(
              top: 8.h,
              left: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  image.type.icon,
                  style: TextStyle(fontSize: ResponsiveGuidelines.labelSmall),
                ),
              ),
            ),

            // Caption overlay
            if (image.caption != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    image.caption!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveGuidelines.labelSmall,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaintsTab() {
    if (_currentProject.paints.isEmpty) {
      return _buildEmptyState(
        icon: Icons.brush_outlined,
        title: 'No paints added',
        subtitle: 'Add paints used in this project',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveGuidelines.spacingL),
      itemCount: _currentProject.paints.length,
      itemBuilder: (context, index) {
        final paint = _currentProject.paints[index];
        return _buildPaintListItem(paint);
      },
    );
  }

  Widget _buildPaintListItem(ProjectPaint paint) {
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

          // Brand avatar
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: AppTheme.marineBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                paint.brandAvatar,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveGuidelines.labelMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPalettesTab() {
    if (_currentProject.palettes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.palette_outlined,
        title: 'No palettes linked',
        subtitle: 'Link color palettes to this project',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveGuidelines.spacingL),
      itemCount: _currentProject.palettes.length,
      itemBuilder: (context, index) {
        final palette = _currentProject.palettes[index];
        return _buildPaletteListItem(palette);
      },
    );
  }

  Widget _buildPaletteListItem(ProjectPalette palette) {
    // TODO: Get actual palette data from service
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
                  'Palette ${palette.name}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${palette.total_paints} colors • Used for main scheme',
                  style: TextStyle(
                    fontSize: ResponsiveGuidelines.bodySmall,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),

          // Arrow icon
          // Icon(
            // Icons.arrow_forward_ios,
            // size: ResponsiveGuidelines.iconXS,
            // color: AppTheme.textGrey,
          // ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.r, color: AppTheme.textGrey.withOpacity(0.5)),
          SizedBox(height: 16.h),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: ResponsiveGuidelines.bodySmall,
              color: AppTheme.textGrey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          //SizedBox(height: 24.h),
          //OutlinedButton.icon(
            //onPressed: () {
              //ScaffoldMessenger.of(context).showSnackBar(
                //const SnackBar(
                  //content: Text('Add functionality coming soon!'),
                  //duration: Duration(seconds: 2),
                //),
              //);
            //},
            //icon: const Icon(Icons.add),
            //label: const Text('Add'),
          //),
        ],
      ),
    );
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

  IconData _getStatusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return Icons.assignment;
      case ProjectStatus.inProgress:
        return Icons.palette;
      case ProjectStatus.completed:
        return Icons.check_circle;
      case ProjectStatus.onHold:
        return Icons.pause_circle;
    }
  }

  Future<void> _editProject() async {
    final result = await Navigator.push<Project>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProjectScreen(project: _currentProject),
      ),
    );

    // If the project was updated, refresh the display
    if (result != null) {
      setState(() {
        _currentProject = result;
      });
    }
  }
}
