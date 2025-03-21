import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class PaintDetailScreen extends StatelessWidget {
  final Paint paint;

  const PaintDetailScreen({super.key, required this.paint});

  @override
  Widget build(BuildContext context) {
    // Convert hex color to Color object
    final Color paintColor = Color(
      int.parse(paint.colorHex.substring(1, 7), radix: 16) + 0xFF000000,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(paint.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to favorites')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color display
            Container(
              height: 200,
              color: paintColor,
              child: Center(
                child: Text(
                  paint.colorHex,
                  style: TextStyle(
                    color:
                        paintColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Paint information
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paint.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paint.brand,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(paint.category),
                        backgroundColor: AppTheme.marineBlue.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (paint.isMetallic)
                        const Chip(
                          label: Text('Metallic'),
                          backgroundColor: Color(0xFFEEEEEE),
                        ),
                      if (paint.isTransparent)
                        const Chip(
                          label: Text('Transparent'),
                          backgroundColor: Color(0xFFEEEEEE),
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Description'),
                  const SizedBox(height: 12),
                  const Text(
                    'This is a placeholder description for the paint. In a real app, this would contain detailed information about the paint, including its uses, opacity, and other characteristics.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Similar Colors'),
                  const SizedBox(height: 12),

                  // Similar colors would be populated from backend
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SimilarPaintCard(
                          name: 'Similar Paint 1',
                          brand: 'Army Painter',
                          color: paintColor.withRed(
                            (paintColor.red - 10).clamp(0, 255),
                          ),
                        ),
                        SimilarPaintCard(
                          name: 'Similar Paint 2',
                          brand: 'Vallejo',
                          color: paintColor.withGreen(
                            (paintColor.green - 15).clamp(0, 255),
                          ),
                        ),
                        SimilarPaintCard(
                          name: 'Similar Paint 3',
                          brand: 'Scale75',
                          color: paintColor.withBlue(
                            (paintColor.blue - 20).clamp(0, 255),
                          ),
                        ),
                        SimilarPaintCard(
                          name: 'Similar Paint 4',
                          brand: 'Tamiya',
                          color: paintColor.withRed(
                            (paintColor.red + 10).clamp(0, 255),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Usage Tips'),
                  const SizedBox(height: 12),
                  _buildTipCard(
                    'Thinning',
                    'This paint may need to be thinned with water or medium for best results.',
                    Icons.water_drop,
                  ),
                  _buildTipCard(
                    'Coverage',
                    'Good coverage. May need 2 thin coats for optimal results.',
                    Icons.layers,
                  ),
                  _buildTipCard(
                    'Drying Time',
                    'Approximately 15-20 minutes under normal conditions.',
                    Icons.timer,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to your collection')),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Add to My Collection'),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }

  Widget _buildTipCard(String title, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: AppTheme.primaryBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppTheme.textGrey,
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

class SimilarPaintCard extends StatelessWidget {
  final String name;
  final String brand;
  final Color color;

  const SimilarPaintCard({
    super.key,
    required this.name,
    required this.brand,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  brand,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
