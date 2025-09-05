import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/models/project.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final bool isHorizontal;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isHorizontal ? 200.w : null,
        margin:
            isHorizontal
                ? EdgeInsets.only(right: 16.w)
                : EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del proyecto con status overlay
            _buildProjectImage(context, isDarkMode),

            // Información del proyecto
            Padding(
              padding: EdgeInsets.all(ResponsiveGuidelines.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del proyecto
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  // Status del proyecto
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${project.status.emoji} ${project.status.displayName}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(project.status),
                      ),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Información adicional
                  Row(
                    children: [
                      // Número de imágenes
                      if (project.images.isNotEmpty) ...[
                        Icon(
                          Icons.photo_library_outlined,
                          size: ResponsiveGuidelines.iconXS,
                          color: AppTheme.textGrey,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${project.images.length}',
                          style: TextStyle(
                            fontSize: ResponsiveGuidelines.labelSmall,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        SizedBox(width: 12.w),
                      ],

                      // Número de paletas
                      if (project.paletteIds.isNotEmpty) ...[
                        Icon(
                          Icons.palette_outlined,
                          size: ResponsiveGuidelines.iconXS,
                          color: AppTheme.textGrey,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${project.paletteIds.length}',
                          style: TextStyle(
                            fontSize: ResponsiveGuidelines.labelSmall,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        SizedBox(width: 12.w),
                      ],

                      // Número de pinturas
                      if (project.paints.isNotEmpty) ...[
                        Icon(
                          Icons.brush_outlined,
                          size: ResponsiveGuidelines.iconXS,
                          color: AppTheme.textGrey,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${project.paints.length}',
                          style: TextStyle(
                            fontSize: ResponsiveGuidelines.labelSmall,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectImage(BuildContext context, bool isDarkMode) {
    return Stack(
      children: [
        // Imagen principal
        ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveGuidelines.radiusL),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child:
                project.thumbnailImage != null
                    ? (project.thumbnailImage!.startsWith('http')
                        ? CachedNetworkImage(
                          imageUrl: project.thumbnailImage!,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          cacheKey: 'project_${project.id}_thumbnail',
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        isDarkMode
                                            ? Colors.orange
                                            : Colors.blue,
                                  ),
                                ),
                              ),
                          errorWidget: (context, error, stackTrace) {
                            return _buildFallbackImage(context);
                          },
                        )
                        : Image.asset(
                          project.thumbnailImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackImage(context);
                          },
                        ))
                    : _buildFallbackImage(context),
          ),
        ),

        // Overlay de gradiente para mejor legibilidad del status
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 40.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(ResponsiveGuidelines.radiusL),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackImage(BuildContext context) {
    return Container(
      color: AppTheme.marineBlue.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 36.r,
              color: AppTheme.marineBlue.withOpacity(0.6),
            ),
            SizedBox(height: 8.h),
            Text(
              'Project Image',
              style: TextStyle(
                color: AppTheme.marineBlue.withOpacity(0.6),
                fontSize: ResponsiveGuidelines.bodySmall,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
}

/// Widget para mostrar una lista horizontal de projects
class ProjectHorizontalList extends StatelessWidget {
  final List<Project> projects;
  final String title;
  final VoidCallback? onSeeAll;
  final Function(Project)? onProjectTap;

  const ProjectHorizontalList({
    super.key,
    required this.projects,
    required this.title,
    this.onSeeAll,
    this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con título y botón "Ver todo"
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveGuidelines.spacingL,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppTheme.marineBlue,
                      fontSize: ResponsiveGuidelines.bodySmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // Lista horizontal de proyectos
        SizedBox(
          height: 240.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveGuidelines.spacingL,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return ProjectCard(
                project: project,
                isHorizontal: true,
                onTap: () => onProjectTap?.call(project),
              );
            },
          ),
        ),
      ],
    );
  }
}
