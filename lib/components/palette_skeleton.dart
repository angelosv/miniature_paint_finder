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

class _PaletteSkeletonState extends State<PaletteSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.isHorizontal ? 200.w : null,
          margin: widget.isHorizontal ? EdgeInsets.only(right: 16.w) : null,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
            borderRadius: BorderRadius.circular(ResponsiveGuidelines.radiusL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen de placeholder con efecto de shimmer
              ShimmerContainer(
                animation: _animation,
                isDarkMode: isDarkMode,
                child: Container(
                  height: 120.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(ResponsiveGuidelines.radiusL),
                    ),
                  ),
                ),
              ),

              // Información de la paleta con efecto de shimmer
              Padding(
                padding: EdgeInsets.all(ResponsiveGuidelines.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Círculos de colores shimmer
                    Row(
                      children: [
                        for (int i = 0; i < 5; i++)
                          ShimmerContainer(
                            animation: _animation,
                            isDarkMode: isDarkMode,
                            child: Container(
                              width: 20.r,
                              height: 20.r,
                              margin: EdgeInsets.only(right: 4.w),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    // Texto de placeholder para el número de colores
                    ShimmerContainer(
                      animation: _animation,
                      isDarkMode: isDarkMode,
                      child: Container(
                        width: 80.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
