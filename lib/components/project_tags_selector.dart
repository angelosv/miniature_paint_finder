import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';

class ProjectTagsSelector extends StatelessWidget {
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;

  const ProjectTagsSelector({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  static const Map<String, _TagStyle> _tagStyles = {
    'warhammer-40k': _TagStyle(Colors.orange, Icons.rocket_launch),
    'space-marines': _TagStyle(Colors.blue, Icons.shield),
    'fantasy': _TagStyle(Colors.purple, Icons.castle),
    'orks': _TagStyle(Colors.green, Icons.emoji_nature),
    'elves': _TagStyle(Colors.teal, Icons.forest),
    'chaos': _TagStyle(Colors.red, Icons.warning),
    'necrons': _TagStyle(Colors.grey, Icons.android),
    'custodes': _TagStyle(Colors.amber, Icons.star),
    'weathering': _TagStyle(Colors.brown, Icons.texture),
    'osl': _TagStyle(Colors.yellow, Icons.lightbulb),
    'tmm': _TagStyle(Colors.blueGrey, Icons.auto_awesome),
    'nmm': _TagStyle(Colors.indigo, Icons.gradient),
    'dragon': _TagStyle(Colors.red, Icons.pets),
    'knight': _TagStyle(Colors.cyan, Icons.security),
    'large-miniature': _TagStyle(Colors.deepOrange, Icons.height),
    'army': _TagStyle(Colors.pink, Icons.groups),
    'character': _TagStyle(Colors.lime, Icons.person),
    'vehicle': _TagStyle(Colors.deepPurple, Icons.directions_car),
  };

  static const List<String> _availableTags = [
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_offer,
              size: ResponsiveGuidelines.iconS,
              color: AppTheme.marineBlue,
            ),
            SizedBox(width: ResponsiveGuidelines.spacingS),
            Text(
              'Tags (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveGuidelines.spacingS),
        Text(
          'Select relevant tags to help categorize your project',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textGrey,
          ),
        ),
        SizedBox(height: ResponsiveGuidelines.spacingM),
        _buildTagsGrid(context),
      ],
    );
  }

  Widget _buildTagsGrid(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200.h),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _availableTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            final tagStyle = _tagStyles[tag] ?? const _TagStyle(Colors.grey, Icons.tag);
            
            return _TagChip(
              tag: tag,
              isSelected: isSelected,
              tagStyle: tagStyle,
              onTap: () => _toggleTag(tag),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _toggleTag(String tag) {
    final updatedTags = List<String>.from(selectedTags);
    if (updatedTags.contains(tag)) {
      updatedTags.remove(tag);
    } else {
      updatedTags.add(tag);
    }
    onTagsChanged(updatedTags);
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final bool isSelected;
  final _TagStyle tagStyle;
  final VoidCallback onTap;

  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.tagStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? tagStyle.color.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected 
                ? tagStyle.color
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tagStyle.icon,
              size: 16.r,
              color: isSelected 
                  ? tagStyle.color
                  : Colors.grey[600],
            ),
            SizedBox(width: 6.w),
            Text(
              tag,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? tagStyle.color
                    : Colors.grey[700],
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 4.w),
              Icon(
                Icons.check_circle,
                size: 14.r,
                color: tagStyle.color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagStyle {
  final Color color;
  final IconData icon;

  const _TagStyle(this.color, this.icon);
}