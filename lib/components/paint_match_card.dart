import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Brand avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      brandAvatar,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

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
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        brand,
                        style: TextStyle(
                          fontSize: 14,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
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
                      size: 22,
                    ),
                  ),
              ],
            ),

            // Color info and barcode section
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Color swatch and code
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: paintColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Color code:',
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                          Text(
                            colorCode,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Barcode
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Barcode:',
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: 14,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                barcode,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
