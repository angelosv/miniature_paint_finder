import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/theme/app_responsive.dart';

class PaintMatchCard extends StatelessWidget {
  final String name;
  final String brand;
  final String brandAvatar;
  final String colorCode;
  final String barcode;
  final int matchPercentage;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showMatchPercentage;
  final bool isDarkMode;
  final Color paintColor;

  const PaintMatchCard({
    Key? key,
    required this.name,
    required this.brand,
    required this.brandAvatar,
    required this.colorCode,
    required this.barcode,
    required this.paintColor,
    this.matchPercentage = 0,
    this.isSelected = false,
    this.onTap,
    this.showMatchPercentage = true,
    required this.isDarkMode,
  }) : super(key: key);

  Color _getMatchColor(int matchPercentage) {
    if (matchPercentage >= 90) {
      return Colors.green;
    } else if (matchPercentage >= 75) {
      return Colors.amber;
    } else {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use responsive utilities
    final cardPadding = AppResponsive.getAdaptivePadding(
      context: context,
      defaultPadding: const EdgeInsets.all(12),
      mobilePadding: const EdgeInsets.all(10),
    );

    final avatarSize = AppResponsive.getAdaptiveValue(
      context: context,
      defaultValue: 50.0,
      mobile: 40.0,
    );

    final avatarFontSize = AppResponsive.getAdaptiveFontSize(
      context,
      24.0,
      minFontSize: 18.0,
    );

    final titleFontSize = AppResponsive.getAdaptiveFontSize(
      context,
      16.0,
      minFontSize: 14.0,
    );

    final brandFontSize = AppResponsive.getAdaptiveFontSize(
      context,
      14.0,
      minFontSize: 12.0,
    );

    final matchFontSize = AppResponsive.getAdaptiveFontSize(
      context,
      13.0,
      minFontSize: 11.0,
    );

    final spacing = AppResponsive.getAdaptiveSpacing(context, 16.0);
    final iconSize = AppResponsive.getAdaptiveValue(
      context: context,
      defaultValue: 22.0,
      mobile: 18.0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color:
              isSelected
                  ? Colors.blue
                  : isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      color:
          isSelected
              ? (isDarkMode
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.05))
              : (isDarkMode ? Colors.grey[850] : null),
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Brand avatar
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      brandAvatar,
                      style: TextStyle(
                        fontSize: avatarFontSize,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing),

                // Paint info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        brand,
                        style: TextStyle(
                          fontSize: brandFontSize,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Match percentage
                if (showMatchPercentage)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppResponsive.getAdaptiveValue(
                        context: context,
                        defaultValue: 10.0,
                        mobile: 8.0,
                      ),
                      vertical: AppResponsive.getAdaptiveValue(
                        context: context,
                        defaultValue: 4.0,
                        mobile: 3.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: _getMatchColor(matchPercentage).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$matchPercentage% match',
                      style: TextStyle(
                        color: _getMatchColor(matchPercentage),
                        fontWeight: FontWeight.bold,
                        fontSize: matchFontSize,
                      ),
                    ),
                  ),

                // Selection indicator
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: iconSize,
                    ),
                  ),
              ],
            ),

            // Color/barcode section with responsive sizing
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.getAdaptiveValue(
                  context: context,
                  defaultValue: 10.0,
                  mobile: 8.0,
                ),
                vertical: AppResponsive.getAdaptiveValue(
                  context: context,
                  defaultValue: 8.0,
                  mobile: 6.0,
                ),
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // Color preview
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Color code:',
                        style: TextStyle(
                          fontSize: AppResponsive.getAdaptiveFontSize(
                            context,
                            12.0,
                            minFontSize: 10.0,
                          ),
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: AppResponsive.getAdaptiveValue(
                              context: context,
                              defaultValue: 24.0,
                              mobile: 20.0,
                            ),
                            height: AppResponsive.getAdaptiveValue(
                              context: context,
                              defaultValue: 24.0,
                              mobile: 20.0,
                            ),
                            decoration: BoxDecoration(
                              color: paintColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(
                            width: AppResponsive.getAdaptiveValue(
                              context: context,
                              defaultValue: 8.0,
                              mobile: 6.0,
                            ),
                          ),
                          Text(
                            colorCode,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: AppResponsive.getAdaptiveFontSize(
                                context,
                                14.0,
                                minFontSize: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    width: AppResponsive.getAdaptiveValue(
                      context: context,
                      defaultValue: 24.0,
                      mobile: 16.0,
                    ),
                  ),
                  // Barcode info
                  if (barcode.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Barcode:',
                          style: TextStyle(
                            fontSize: AppResponsive.getAdaptiveFontSize(
                              context,
                              12.0,
                              minFontSize: 10.0,
                            ),
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: AppResponsive.getAdaptiveValue(
                                context: context,
                                defaultValue: 20.0,
                                mobile: 16.0,
                              ),
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            SizedBox(
                              width: AppResponsive.getAdaptiveValue(
                                context: context,
                                defaultValue: 8.0,
                                mobile: 6.0,
                              ),
                            ),
                            Text(
                              barcode,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: AppResponsive.getAdaptiveFontSize(
                                  context,
                                  14.0,
                                  minFontSize: 12.0,
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
