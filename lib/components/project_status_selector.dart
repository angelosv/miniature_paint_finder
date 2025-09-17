import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/models/project.dart';

class ProjectStatusSelector extends StatelessWidget {
  final ProjectStatus selectedStatus;
  final Function(ProjectStatus) onStatusChanged;

  const ProjectStatusSelector({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  static const Map<ProjectStatus, _StatusStyle> _statusStyles = {
    ProjectStatus.planning: _StatusStyle(
      Colors.blue,
      Icons.assignment,
      'Planning',
    ),
    ProjectStatus.inProgress: _StatusStyle(
      Colors.orange,
      Icons.palette,
      'In Progress',
    ),
    ProjectStatus.completed: _StatusStyle(
      Colors.green,
      Icons.check_circle,
      'Completed',
    ),
    ProjectStatus.onHold: _StatusStyle(
      Colors.grey,
      Icons.pause_circle,
      'On Hold',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flag,
              size: ResponsiveGuidelines.iconS,
              color: AppTheme.marineBlue,
            ),
            SizedBox(width: ResponsiveGuidelines.spacingS),
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveGuidelines.spacingS),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: ProjectStatus.values.map((status) {
            final isSelected = selectedStatus == status;
            final statusStyle = _statusStyles[status]!;
            
            return _StatusChip(
              status: status,
              isSelected: isSelected,
              statusStyle: statusStyle,
              onTap: () => onStatusChanged(status),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ProjectStatus status;
  final bool isSelected;
  final _StatusStyle statusStyle;
  final VoidCallback onTap;

  const _StatusChip({
    required this.status,
    required this.isSelected,
    required this.statusStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 10.h,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? statusStyle.color.withOpacity(0.15)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(
            color: isSelected 
                ? statusStyle.color
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusStyle.icon,
              size: 18.r,
              color: isSelected 
                  ? statusStyle.color
                  : Colors.grey[600],
            ),
            SizedBox(width: 8.w),
            Text(
              statusStyle.displayName,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? statusStyle.color
                    : Colors.grey[700],
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 6.w),
              Icon(
                Icons.check,
                size: 16.r,
                color: statusStyle.color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color color;
  final IconData icon;
  final String displayName;

  const _StatusStyle(this.color, this.icon, this.displayName);
}