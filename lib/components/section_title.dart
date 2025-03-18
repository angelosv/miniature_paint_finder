import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final bool showViewAll;
  final VoidCallback? onViewAllTap;

  const SectionTitle({
    super.key,
    required this.title,
    this.showViewAll = false,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (showViewAll)
            GestureDetector(
              onTap: onViewAllTap,
              child: Text(
                "View all",
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
