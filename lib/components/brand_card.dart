import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/utils/cache.dart';

class BrandCard extends StatelessWidget {
  final String id;
  final String name;
  final String? logoUrl;
  final int paintCount;
  final VoidCallback onTap;

  const BrandCard({
    super.key,
    required this.id,
    required this.name,
    this.logoUrl,
    required this.paintCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo container
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                  child: Center(child: _buildBrandLogo(context)),
                ),
              ),
            ),

            // Brand info container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? AppTheme.marineBlue.withOpacity(0.1)
                        : Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color:
                                isDarkMode
                                    ? AppTheme.marineOrange
                                    : AppTheme.marineBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              size: 14,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatPaintCount(paintCount),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color:
                        isDarkMode
                            ? AppTheme.marineOrange
                            : AppTheme.marineBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Logo con cache en disco y fallback sin spinner (evita logs offline)
  Widget _buildBrandLogo(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget fallbackAvatar() => Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
          ),
        ),
      ),
    );

    if (logoUrl == null || logoUrl!.trim().isEmpty) {
      return fallbackAvatar();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CachedNetworkImage(
        imageUrl: logoUrl!.trim(),
        cacheManager: LogosCacheManager.instance, // <- cache disco (TTL largo)
        fit: BoxFit.contain,
        useOldImageOnUrlChange: true,
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: const Duration(milliseconds: 120),
        placeholder: (_, __) => fallbackAvatar(), // no spinner offline
        errorWidget: (_, __, ___) => fallbackAvatar(),
        // hints de memoria para listas
        memCacheWidth: 160,
        memCacheHeight: 160,
      ),
    );
  }

  String _formatPaintCount(int count) {
    if (count < 1000) return '$count paints';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}k paints';
    return '${(count / 1000000).toStringAsFixed(1)}M paints';
  }
}
