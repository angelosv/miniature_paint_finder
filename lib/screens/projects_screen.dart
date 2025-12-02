import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/models/project.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';
import 'package:miniature_paint_finder/components/create_project_modal.dart';
import 'package:miniature_paint_finder/services/project_cache_service.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/screens/project_detail_screen.dart';
import 'package:miniature_paint_finder/screens/edit_project_screen.dart';

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
  int _totalPages = 1;
  int _totalProjects = 0;
  int _totalDone = 0;
  int _totalActive = 0;
  int _totalShown = 0;
  int _limit = 10;
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

    // Listen to cache service changes to refresh UI when projects are created/updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cacheService = Provider.of<ProjectCacheService>(
        context,
        listen: false,
      );
      cacheService.addListener(_onCacheChanged);
    });
  }

  void _onCacheChanged() {
    // Refresh projects list when cache changes (e.g., after creating a project)
    if (mounted) {
      _fetchProjects(forceRefresh: false);
    }
  }

  @override
  void dispose() {
    // Safe to access Provider here because we're checking if mounted
    try {
      if (mounted) {
        final cacheService = Provider.of<ProjectCacheService>(
          context,
          listen: false,
        );
        cacheService.removeListener(_onCacheChanged);
      }
    } catch (e) {
      // Widget already disposed, listener will be garbage collected
    }
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjects({
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheService = Provider.of<ProjectCacheService>(
      context,
      listen: false,
    );

    // Show cached data immediately if available (for smooth UX)
    if (!forceRefresh &&
        cacheService.cachedProjects != null &&
        cacheService.cachedProjects!.isNotEmpty) {
      final cachedProjects = cacheService.cachedProjects!;
      setState(() {
        _currentPage = page;
        _totalPages = (cachedProjects.length / limit).ceil();
        _totalProjects = cachedProjects.length;
        _totalDone =
            cachedProjects
                .where((p) => p.status == ProjectStatus.completed)
                .length;
        _totalActive =
            cachedProjects
                .where((p) => p.status == ProjectStatus.inProgress)
                .length;
        _totalShown = cachedProjects.length;
        _limit = limit;
        _allProjects = cachedProjects;
        _filteredProjects = List.from(_allProjects);
        _isLoading = false; // Don't show loading if we have cache
      });
      _applyFiltersAndSort();

      // Continue loading fresh data in background only if cache is old
      if (cacheService.hasConnection && !cacheService.hasPendingOperations) {
        // Only refresh if cache is older than 5 minutes
        final cacheAge = DateTime.now().difference(
          cacheService.lastCacheUpdate ?? DateTime(2000),
        );
        if (cacheAge.inMinutes > 5) {
          _loadFreshDataInBackground(page, limit, forceRefresh);
        }
      }
      return;
    }

    // No cache available, show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Get projects from cache service (cache-first)
      final projects = await cacheService.getProjects(
        forceRefresh: forceRefresh,
        page: page,
        limit: limit,
      );

      // Parse projects (they're already Project objects from cache)
      final List<Project> parsed = projects;

      setState(() {
        _currentPage = page;
        _totalPages = (parsed.length / limit).ceil();
        _totalProjects = parsed.length;
        _totalDone =
            parsed.where((p) => p.status == ProjectStatus.completed).length;
        _totalActive =
            parsed.where((p) => p.status == ProjectStatus.inProgress).length;
        _totalShown = parsed.length;
        _limit = limit;
        _allProjects = parsed;
        _filteredProjects = List.from(_allProjects);
      });

      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Error fetching projects: $e');
      // keep empty state on error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load fresh data in background without blocking UI
  Future<void> _loadFreshDataInBackground(
    int page,
    int limit,
    bool forceRefresh,
  ) async {
    try {
      final cacheService = Provider.of<ProjectCacheService>(
        context,
        listen: false,
      );

      // Don't refresh from API if there are pending operations
      // This prevents overwriting locally created projects that haven't synced yet
      if (cacheService.hasPendingOperations) {
        debugPrint('⏸️ Skipping background refresh - pending operations exist');
        return;
      }

      // Fetch fresh data (this will update the cache)
      final projects = await cacheService.getProjects(
        forceRefresh: true, // Always refresh in background
        page: page,
        limit: limit,
      );

      // Update UI with fresh data if mounted
      if (mounted) {
        setState(() {
          _currentPage = page;
          _totalPages = (projects.length / limit).ceil();
          _totalProjects = projects.length;
          _totalDone =
              projects.where((p) => p.status == ProjectStatus.completed).length;
          _totalActive =
              projects
                  .where((p) => p.status == ProjectStatus.inProgress)
                  .length;
          _totalShown = projects.length;
          _limit = limit;
          _allProjects = projects;
          _filteredProjects = List.from(_allProjects);
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      debugPrint('Error loading fresh data in background: $e');
      // Silently fail, user already has cached data
    }
  }

  void _goToPage(int page) {
    if (_isLoading) return;
    if (page < 1 || page > _totalPages) return;
    _fetchProjects(page: page, limit: _limit);
  }

  void _applyFiltersAndSort() {
    setState(() {
      _filteredProjects =
          _allProjects.where((project) {
            // Text search
            if (_searchController.text.isNotEmpty) {
              final query = _searchController.text.toLowerCase();
              final matchesName = project.name.toLowerCase().contains(query);
              final matchesDescription =
                  project.description?.toLowerCase().contains(query) ?? false;
              final matchesTags = project.tags.any(
                (tag) => tag.toLowerCase().contains(query),
              );

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
          _filteredProjects.sort(
            (a, b) => a.status.index.compareTo(b.status.index),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cacheService = Provider.of<ProjectCacheService>(context);

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      selectedIndex: 5,
      title: 'My Projects',
      drawer: const SharedDrawer(currentScreen: 'projects'),
      actions: [
        // Sync indicator
        if (cacheService.isSyncing)
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: SizedBox(
              width: 20.w,
              height: 20.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _fetchProjects(forceRefresh: true),
          tooltip: 'Refresh projects',
        ),
      ],
      body: Column(
        children: [
          // Offline indicator banner
          if (!cacheService.hasConnection)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              color: Colors.orange,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 16.r, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(
                    'Offline Mode - Showing cached projects',
                    style: TextStyle(
                      fontSize: ResponsiveGuidelines.bodySmall,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Pending operations indicator
          if (cacheService.hasPendingOperations)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              color: AppTheme.marineBlue.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sync, size: 14.r, color: AppTheme.marineBlue),
                  SizedBox(width: 8.w),
                  Text(
                    '${cacheService.pendingOperationsCount} pending changes',
                    style: TextStyle(
                      fontSize: ResponsiveGuidelines.labelSmall,
                      color: AppTheme.marineBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Search and filters
          _buildSearchAndFilters(),

          // Stats bar
          _buildStatsBar(),

          // Pagination controls (top)
          _buildPaginationBar(),

          // Tab bar
          _buildTabBar(),

          // Content with pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchProjects(forceRefresh: true),
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGridView(),
                          _buildListView(),
                          _buildStatsView(),
                          _buildTagsView(),
                        ],
                      ),
            ),
          ),
          // Pagination controls (bottom)
          //_buildPaginationBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProjectModal,
        backgroundColor: AppTheme.marineOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Project', style: TextStyle(color: Colors.white)),
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
              suffixIcon:
                  _searchController.text.isNotEmpty
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.textGrey.withOpacity(0.3),
                    ),
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
                    items:
                        _sortOptions.map((option) {
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
          _buildStatItem(
            Icons.play_circle,
            inProgressProjects.toString(),
            'Active',
          ),
          _buildStatItem(
            Icons.check_circle,
            completedProjects.toString(),
            'Done',
          ),
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
        indicatorSize: TabBarIndicatorSize.tab,
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

  Widget _buildPaginationBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveGuidelines.spacingL,
        vertical: ResponsiveGuidelines.spacingS,
      ),
      child: Row(
        children: [
          // Page info
          Text(
            'Page $_currentPage of $_totalPages',
            style: TextStyle(
              fontSize: ResponsiveGuidelines.bodySmall,
              color: AppTheme.textGrey,
            ),
          ),
          const Spacer(),
          // Controls
          IconButton(
            tooltip: 'First page',
            onPressed:
                _currentPage > 1 && !_isLoading ? () => _goToPage(1) : null,
            icon: const Icon(Icons.first_page),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed:
                _currentPage > 1 && !_isLoading
                    ? () => _goToPage(_currentPage - 1)
                    : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed:
                _currentPage < _totalPages && !_isLoading
                    ? () => _goToPage(_currentPage + 1)
                    : null,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'Last page',
            onPressed:
                _currentPage < _totalPages && !_isLoading
                    ? () => _goToPage(_totalPages)
                    : null,
            icon: const Icon(Icons.last_page),
          ),
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
            // Project image with options button
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
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(ResponsiveGuidelines.radiusL),
                        topRight: Radius.circular(ResponsiveGuidelines.radiusL),
                      ),
                      child: _buildProjectImage(project),
                    ),
                    // Options button in top-right corner
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: GestureDetector(
                        onTap: () => _showProjectOptions(project),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 16.r,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
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
                        Icon(
                          Icons.photo_library,
                          size: 14.r,
                          color: AppTheme.textGrey,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${project.images.length}',
                          style: TextStyle(
                            fontSize: ResponsiveGuidelines.labelSmall,
                            color: AppTheme.textGrey,
                          ),
                        ),

                        SizedBox(width: 8.w),

                        Icon(
                          Icons.palette,
                          size: 14.r,
                          color: AppTheme.textGrey,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${project.palettes.length}',
                          style: TextStyle(
                            fontSize: ResponsiveGuidelines.labelSmall,
                            color: AppTheme.textGrey,
                          ),
                        ),

                        SizedBox(width: 8.w),

                        Icon(Icons.brush, size: 14.r, color: AppTheme.textGrey),
                        SizedBox(width: 2.w),
                        Text(
                          '${project.paints.length}',
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
          errorBuilder:
              (context, error, stackTrace) => _buildPlaceholderImage(),
        );
      } else {
        return Image.asset(
          mainImage.imagePath,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => _buildPlaceholderImage(),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                project.status,
                              ).withOpacity(0.1),
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
                        Icon(
                          Icons.photo_library,
                          size: 16.r,
                          color: AppTheme.textGrey,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${project.images.length}',
                          style: TextStyle(
                            fontSize: ResponsiveGuidelines.bodySmall,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.brush, size: 16.r, color: AppTheme.textGrey),
                        SizedBox(width: 4.w),
                        Text(
                          '${project.paints.length}',
                          style: TextStyle(
                            fontSize: ResponsiveGuidelines.bodySmall,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(width: 8.w),

                // Options button
                GestureDetector(
                  onTap: () => _showProjectOptions(project),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppTheme.textGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: AppTheme.textGrey,
                      size: 18.r,
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

  Widget _buildStatsView() {
    final statusCounts = <ProjectStatus, int>{
      for (final status in ProjectStatus.values)
        status: _allProjects.where((p) => p.status == status).length,
    };

    return Padding(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Statistics',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                  final percentage =
                      _allProjects.isNotEmpty
                          ? (count / _allProjects.length * 100)
                          : 0;

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

    final sortedTags =
        tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: EdgeInsets.all(ResponsiveGuidelines.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Tags',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          SizedBox(height: ResponsiveGuidelines.spacingL),

          Expanded(
            child:
                sortedTags.isNotEmpty
                    ? Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children:
                          sortedTags.map((entry) {
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
                                        fontSize:
                                            ResponsiveGuidelines.labelSmall,
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
      builder:
          (context) => Container(
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
                  title: const Text(
                    'Delete Project',
                    style: TextStyle(color: Colors.red),
                  ),
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
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Project'),
            content: Text(
              'Are you sure you want to delete "${project.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final cacheService = Provider.of<ProjectCacheService>(
                      context,
                      listen: false,
                    );
                    final ok = await cacheService.deleteProject(project.id);
                    if (ok && mounted) {
                      // No need to call _fetchProjects since cache service will notify listeners
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Project "${project.name}" deleted'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting project: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
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
