import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/screens/paint_detail_screen.dart';

class PaintGridCard extends StatelessWidget {
  final Paint paint;
  final Color color;

  const PaintGridCard({super.key, required this.paint, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaintDetailScreen(paint: paint),
          ),
        );
      },
      child: Card(
        color: color.withOpacity(0.1),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paint.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(paint.brand, style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(paint.colorHex.substring(1, 7), radix: 16) +
                            0xFF000000,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    paint.category,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
