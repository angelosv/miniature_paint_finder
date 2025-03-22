import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/screens/paint_detail_screen.dart';
import 'package:miniature_paint_finder/theme/app_dimensions.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class PaintCard extends StatelessWidget {
  final Paint paint;

  const PaintCard({super.key, required this.paint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginS),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaintDetailScreen(paint: paint),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Container(
                width: AppDimensions.iconXXL,
                height: AppDimensions.iconXXL,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(paint.colorHex.substring(1, 7), radix: 16) +
                        0xFF000000,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
              ),
              const SizedBox(width: AppDimensions.marginL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(paint.name, style: textTheme.titleSmall),
                    const SizedBox(height: AppDimensions.marginXS),
                    Row(
                      children: [
                        Text(paint.brand, style: textTheme.bodySmall),
                        const SizedBox(width: AppDimensions.marginS),
                        _buildCategoryChip(context),
                        if (paint.isMetallic) _buildMetallicChip(context),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textGrey,
                size: AppDimensions.iconM,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXS,
        vertical: AppDimensions.paddingXS / 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.marineBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      ),
      child: Text(
        paint.category,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.marineBlue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMetallicChip(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: AppDimensions.marginXS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXS,
        vertical: AppDimensions.paddingXS / 2,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      ),
      child: const Text('Metallic', style: TextStyle(fontSize: 10)),
    );
  }
}
