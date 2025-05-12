import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// Skeleton loader para tarjetas de paletas con efecto shimmer
class PaletteSkeleton extends StatefulWidget {
  final bool isHorizontal;

  const PaletteSkeleton({super.key, this.isHorizontal = true});

  @override
  State<PaletteSkeleton> createState() => _PaletteSkeletonState();
}

class _PaletteSkeletonState extends State<PaletteSkeleton> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.grey[200];

    return Container(
      width: widget.isHorizontal ? 200.w : null,
      margin: widget.isHorizontal ? EdgeInsets.only(right: 16.w) : null,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de placeholder estática
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(ResponsiveGuidelines.radiusL),
            ),
            child: Image.asset(
              'assets/images/palette_palceholder.png',
              height: 120.h,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Información de la paleta
          Padding(
            padding: EdgeInsets.all(ResponsiveGuidelines.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Círculos de colores
                Row(
                  children: [
                    for (int i = 0; i < 5; i++)
                      Container(
                        width: 20.r,
                        height: 20.r,
                        margin: EdgeInsets.only(right: 4.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getColorForIndex(i, isDarkMode),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Texto de placeholder
                Container(
                  width: 80.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Colores fijos para los círculos
  Color _getColorForIndex(int index, bool isDarkMode) {
    final List<Color> colors = [
      AppTheme.marineBlue,
      AppTheme.marineOrange,
      AppTheme.marineGold,
      AppTheme.pinkColor,
      AppTheme.greenColor,
    ];

    return colors[index % colors.length];
  }
}

/// Widget helper que añade efecto shimmer a sus hijos
class ShimmerContainer extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final bool isDarkMode;

  const ShimmerContainer({
    super.key,
    required this.animation,
    required this.child,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular el color base y el color brillante basado en la animación
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    final color = Color.lerp(baseColor, highlightColor, animation.value)!;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            child is Container
                ? (child as Container).decoration is BoxDecoration
                    ? ((child as Container).decoration as BoxDecoration)
                        .borderRadius
                    : null
                : null,
        shape:
            child is Container
                ? (child as Container).decoration is BoxDecoration
                    ? ((child as Container).decoration as BoxDecoration)
                            .shape ??
                        BoxShape.rectangle
                    : BoxShape.rectangle
                : BoxShape.rectangle,
      ),
      child: child,
    );
  }
}

/// Widget que muestra varios skeleton loaders para paletas en horizontal
class PaletteSkeletonList extends StatelessWidget {
  final int count;

  const PaletteSkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        itemBuilder: (context, index) {
          return const PaletteSkeleton();
        },
      ),
    );
  }
}
