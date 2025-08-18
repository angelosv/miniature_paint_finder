import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:miniature_paint_finder/screens/palette_screen.dart';

class PaletteCard extends StatelessWidget {
  final Palette palette;
  final VoidCallback? onTap;
  final bool isHorizontal;

  const PaletteCard({
    super.key,
    required this.palette,
    this.onTap,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isHorizontal ? 200.w : null,
        margin: isHorizontal ? EdgeInsets.only(right: 16.w) : null,
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
            // Imagen placeholder con bordes redondeados en la parte superior
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(ResponsiveGuidelines.radiusL),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child:
                    palette.imagePath.startsWith('http')
                        ? CachedNetworkImage(
                          cacheManager: PaletteCacheManager(),
                          imageUrl: palette.imagePath,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          cacheKey: 'palette_${palette.id}_thumbnail',
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
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
                          palette.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackImage(context);
                          },
                        ),
              ),
            ),

            // Información de la paleta
            Padding(
              padding: EdgeInsets.all(ResponsiveGuidelines.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mostrar los colores en fila
                  Row(
                    children: [
                      for (int i = 0; i < palette.colors.length && i < 5; i++)
                        Container(
                          width: 20.r,
                          height: 20.r,
                          margin: EdgeInsets.only(right: 4.w),
                          decoration: BoxDecoration(
                            color: palette.colors[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1.w,
                            ),
                          ),
                        ),

                      // Si hay más de 5 colores, mostrar contador
                      if (palette.colors.length > 5)
                        Container(
                          width: 20.r,
                          height: 20.r,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '+${palette.colors.length - 5}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // Mostrar la cantidad de pinturas
                  Row(
                    children: [
                      Icon(
                        Icons.palette,
                        size: ResponsiveGuidelines.iconXS,
                        color: AppTheme.textGrey,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${palette.colors.length} colors',
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
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: AppTheme.marineBlue.withOpacity(0.1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 36.r,
                color: Colors.grey[400],
              ),
              SizedBox(height: 8.h),
              Text(
                'No image available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: ResponsiveGuidelines.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
