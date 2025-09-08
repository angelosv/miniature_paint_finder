import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/models/project.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';
import 'package:miniature_paint_finder/components/create_project_modal.dart';
import 'package:miniature_paint_finder/repositories/project_repository.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/screens/project_detail_screen.dart';
import 'package:miniature_paint_finder/screens/edit_project_screen.dart';
import 'dart:convert';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Project> _allProjects = [];
  List<Project> _filteredProjects = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalProjects = 0;
  int _totalDone = 0;
  int _totalActive = 0;
  int _totalShown = 0;
  ProjectStatus? _selectedStatus;
  String _selectedSortOption = 'Recent';

  final List<String> _sortOptions = [
    'Recent',
    'Oldest',
    'A-Z',
    'Z-A',
    'Status',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjects({int page = 1, int limit = 10}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = Provider.of<ProjectRepository>(context, listen: false);
      final result = await repo.getUserProjects(page: page, limit: limit);
      final List<Project> parsed = (result['projects'] as List)
          .map((raw) {
            final map = raw as Map<String, dynamic>;
            print(' project: ${map}');
            
            // Map items to palettes and paints
            final items = map['items'] as List? ?? [];
            final paletteIds = items
                .where((item) => item['table'] == 'palettes')
                .map((item) => item['table_id'] as String)
                .toList();
            
            final paints = items
                .where((item) => item['table'] == 'paints')
                .map((item) => ProjectPaint(
                  paintId: item['table_id'] as String,
                  paintName: 'Paint ${item['table_id']}',
                  paintBrand: item['brand_id'] as String? ?? 'Unknown',
                  brandAvatar: (item['brand_id'] as String? ?? 'U')[0],
                  colorHex: '#000000',
                  addedAt: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
                ))
                .toList();
            
            return Project(
              id: map['id'] ?? '',
              name: map['name'] ?? 'Untitled',
              description: map['description'],
              images: const [],
              paletteIds: paletteIds,
              paints: paints,
              createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
              status: ProjectStatus.inProgress,
              userId: map['user_id'] ?? '',
              tags: const [],
            );
          })
          .toList();

      setState(() {
        _currentPage = result['currentPage'] ?? page;
        _totalProjects = result['totalProjects'] ?? 0;
        _totalDone = result['totalDone'] ?? 0;
        _totalActive = result['totalActive'] ?? 0;
        _totalShown = result['totalShown'] ?? parsed.length;
        _allProjects = parsed;
        _filteredProjects = List.from(_allProjects);
      });

      _applyFiltersAndSort();
    } catch (e) {
      // keep empty state on error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFiltersAndSort() {
    setState(() {
      _filteredProjects = _allProjects.where((project) {
        // Text search
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          final matchesName = project.name.toLowerCase().contains(query);
          final matchesDescription = project.description?.toLowerCase().contains(query) ?? false;
          final matchesTags = project.tags.any((tag) => tag.toLowerCase().contains(query));
          
          if (!matchesName && !matchesDescription && !matchesTags) {
            return false;
          }
        }

        // Status filter
        if (_selectedStatus != null && project.status != _selectedStatus) {
          return false;
        }

        return true;
      }).toList();

      // Sort
      switch (_selectedSortOption) {
        case 'Recent':
          _filteredProjects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          break;
        case 'Oldest':
          _filteredProjects.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 'A-Z':
          _filteredProjects.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Z-A':
          _filteredProjects.sort((a, b) => b.name.compareTo(a.name));
          break;
        case 'Status':
          _filteredProjects.sort((a, b) => a.status.index.compareTo(b.status.index));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      key: _scaffoldKey,
      title: 'My Projects',
      drawer: const SharedDrawer(currentScreen: 'projects'),
      body: Column(
        children: [
          // Search and filters
          _buildSearchAndFilters(),
          
          // Stats bar
          _buildStatsBar(),
          
          // Tab bar
          _buildTabBar(),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGridView(),
                _buildListView(),
                _buildStatsView(),
                _buildTagsView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProjectModal,
        backgroundColor: AppTheme.marineOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Project',
          style: TextStyle(color: Colors.white),
        ),
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
              hintText: 'Search projects...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFiltersAndSort();
                      },
                    )
                  : null,
            ),
            onChanged: (_) => _applyFiltersAndSort(),
          ),

          SizedBox(height: ResponsiveGuidelines.spacingM),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status filters
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedStatus == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = null;
                    });
                    _applyFiltersAndSort();
                  },
                  selectedColor: AppTheme.marineBlue.withOpacity(0.2),
                  checkmarkColor: AppTheme.marineBlue,
                ),
                SizedBox(width: 8.w),
                ...ProjectStatus.values.map((status) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: FilterChip(
                      label: Text('${status.emoji} ${status.displayName}'),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = selected ? status : null;
                        });
                        _applyFiltersAndSort();
                      },
                      selectedColor: _getStatusColor(status).withOpacity(0.2),
                      checkmarkColor: _getStatusColor(status),
                    ),
                  );
                }),
                
                SizedBox(width: 16.w),
                
                // Sort dropdown
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.textGrey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSortOption,
                    icon: Icon(Icons.sort, size: 20.r),
                    underline: const SizedBox.shrink(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSortOption = value!;
                      });
                      _applyFiltersAndSort();
                    },
                    items: _sortOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: ResponsiveGuidelines.bodySmall,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final totalProjects = _totalProjects;
    final completedProjects = _totalDone;
    final inProgressProjects = _totalActive;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveGuidelines.spacingL,
        vertical: ResponsiveGuidelines.spacingS,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.folder, totalProjects.toString(), 'Total'),
          _buildStatItem(Icons.play_circle, inProgressProjects.toString(), 'Active'),
          _buildStatItem(Icons.check_circle, completedProjects.toString(), 'Done'),
          _buildStatItem(Icons.filter_list, _totalShown.toString(), 'Shown'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.r, color: AppTheme.marineBlue),
            SizedBox(width: 4.w),
            Text(
              count,
              style: TextStyle(
                fontSize: ResponsiveGuidelines.bodyLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.marineBlue,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveGuidelines.labelSmall,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveGuidelines.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.marineBlue,
          borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
        ),
        indicatorPadding: EdgeInsets.all(4.w),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textGrey,
        labelStyle: TextStyle(
          fontSize: ResponsiveGuidelines.bodySmall,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.grid_view), text: 'Grid'),
          Tab(icon: Icon(Icons.list), text: 'List'),
          Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          Tab(icon: Icon(Icons.tag), text: 'Tags'),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    if (_filteredProjects.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 0.8,
        ),
        itemCount: _filteredProjects.length,
        itemBuilder: (context, index) {
          final project = _filteredProjects[index];
          return _buildProjectGridCard(project);
        },
      ),
    );
  }

  Widget _buildProjectGridCard(Project project) {
    return GestureDetector(
      onTap: () => _openProjectDetail(project),
      onLongPress: () => _showProjectOptions(project),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ResponsiveGuidelines.radiusL),
                    topRight: Radius.circular(ResponsiveGuidelines.radiusL),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ResponsiveGuidelines.radiusL),
                    topRight: Radius.circular(ResponsiveGuidelines.radiusL),
                  ),
                  child: _buildProjectImage(project),
                ),
              ),
            ),
            
            // Project info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(project.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${project.status.emoji} ${project.status.displayName}',
                        style: TextStyle(
                          fontSize: ResponsiveGuidelines.labelSmall,
                          color: _getStatusColor(project.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    Row(
                      children: [
                        Icon(Icons.photo_library, size: 14.r, color: AppTheme.textGrey),
                        SizedBox(width: 2.w),
                        Text('${project.images.length}', style: TextStyle(fontSize: ResponsiveGuidelines.labelSmall, color: AppTheme.textGrey)),
                        
                        SizedBox(width: 8.w),
                        
                        Icon(Icons.palette, size: 14.r, color: AppTheme.textGrey),
                        SizedBox(width: 2.w),
                        Text('${project.paletteIds.length}', style: TextStyle(fontSize: ResponsiveGuidelines.labelSmall, color: AppTheme.textGrey)),
                        
                        SizedBox(width: 8.w),
                        
                        Icon(Icons.brush, size: 14.r, color: AppTheme.textGrey),
                        SizedBox(width: 2.w),
                        Text('${project.paints.length}', style: TextStyle(fontSize: ResponsiveGuidelines.labelSmall, color: AppTheme.textGrey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectImage(Project project) {
    ProjectImage? mainImage;
    
    try {
      mainImage = project.images.firstWhere((img) => img.isMain);
    } catch (e) {
      // If no main image found, use first image if available
      mainImage = project.images.isNotEmpty ? project.images.first : null;
    }

    if (mainImage != null) {
      if (mainImage.imagePath.startsWith('http')) {
        return Image.network(
          mainImage.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        );
      } else {
        return Image.asset(
          mainImage.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        );
      }
    }

    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.marineBlue.withOpacity(0.3),
            AppTheme.marineOrange.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.art_track,
          size: 48.r,
          color: AppTheme.textGrey.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_filteredProjects.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      itemCount: _filteredProjects.length,
      itemBuilder: (context, index) {
        final project = _filteredProjects[index];
        return _buildProjectListCard(project);
      },
    );
  }

  Widget _buildProjectListCard(Project project) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
          onTap: () => _openProjectDetail(project),
          onLongPress: () => _showProjectOptions(project),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Project thumbnail
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: _buildProjectImage(project),
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                // Project info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      if (project.description != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          project.description!,
                          style: TextStyle(
                            fontSize: ResponsiveGuidelines.bodySmall,
                            color: AppTheme.textGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      SizedBox(height: 8.h),
                      
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: _getStatusColor(project.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              '${project.status.emoji} ${project.status.displayName}',
                              style: TextStyle(
                                fontSize: ResponsiveGuidelines.labelSmall,
                                color: _getStatusColor(project.status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          const Spacer(),
                          
                          Text(
                            _formatDate(project.updatedAt),
                            style: TextStyle(
                              fontSize: ResponsiveGuidelines.labelSmall,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                // Stats
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library, size: 16.r, color: AppTheme.textGrey),
                        SizedBox(width: 4.w),
                        Text('${project.images.length}', style: TextStyle(fontSize: ResponsiveGuidelines.bodySmall, color: AppTheme.textGrey)),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.brush, size: 16.r, color: AppTheme.textGrey),
                        SizedBox(width: 4.w),
                        Text('${project.paints.length}', style: TextStyle(fontSize: ResponsiveGuidelines.bodySmall, color: AppTheme.textGrey)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsView() {
    final statusCounts = <ProjectStatus, int>{};
    for (final status in ProjectStatus.values) {
      statusCounts[status] = _allProjects.where((p) => p.status == status).length;
    }

    return Padding(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Statistics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: ResponsiveGuidelines.spacingL),
          
          // Status breakdown
          Container(
            padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'By Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                SizedBox(height: ResponsiveGuidelines.spacingM),
                
                ...ProjectStatus.values.map((status) {
                  final count = statusCounts[status] ?? 0;
                  final percentage = _allProjects.isNotEmpty ? (count / _allProjects.length * 100) : 0;
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      children: [
                        Container(
                          width: 20.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        
                        SizedBox(width: 12.w),
                        
                        Expanded(
                          child: Text(
                            '${status.emoji} ${status.displayName}',
                            style: TextStyle(
                              fontSize: ResponsiveGuidelines.bodyMedium,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        Text(
                          '$count (${percentage.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: ResponsiveGuidelines.bodyMedium,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsView() {
    final allTags = <String>{};
    for (final project in _allProjects) {
      allTags.addAll(project.tags);
    }

    final tagCounts = <String, int>{};
    for (final tag in allTags) {
      tagCounts[tag] = _allProjects.where((p) => p.tags.contains(tag)).length;
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Tags',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: ResponsiveGuidelines.spacingL),
          
          Expanded(
            child: sortedTags.isNotEmpty
                ? Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: sortedTags.map((entry) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.marineBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: ResponsiveGuidelines.bodyMedium,
                                color: AppTheme.marineBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.marineBlue,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  fontSize: ResponsiveGuidelines.labelSmall,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : Center(
                    child: Text(
                      'No tags found',
                      style: TextStyle(
                        fontSize: ResponsiveGuidelines.bodyLarge,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.art_track,
            size: 64.r,
            color: AppTheme.textGrey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            _searchController.text.isNotEmpty || _selectedStatus != null
                ? 'No projects match your filters'
                : 'No projects yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _searchController.text.isNotEmpty || _selectedStatus != null
                ? 'Try adjusting your search or filters'
                : 'Create your first project to get started',
            style: TextStyle(
              fontSize: ResponsiveGuidelines.bodySmall,
              color: AppTheme.textGrey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isEmpty && _selectedStatus == null) ...[
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _showCreateProjectModal,
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
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

  // Helper methods
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  // Actions
  void _openProjectDetail(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    );
  }

  void _showProjectOptions(Project project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _openProjectDetail(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Project'),
              onTap: () {
                Navigator.pop(context);
                _editProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Project', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteProject(project);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editProject(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProjectScreen(project: project),
      ),
    ).then((result) {
      if (result != null) {
        _fetchProjects(page: _currentPage);
      }
    });
  }

  void _deleteProject(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final repo = Provider.of<ProjectRepository>(context, listen: false);
                final ok = await repo.delete(project.id);
                if (ok && mounted) {
                  await _fetchProjects(page: _currentPage);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Project "${project.name}" deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (_) {}
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateProjectModal() {
    CreateProjectModal.show(context).then((created) {
      if (created == true) {
        _fetchProjects(page: _currentPage);
      }
    });
  }
}
