import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/components/color_chip.dart';
import 'package:miniature_paint_finder/components/paint_grid_card.dart';
import 'package:miniature_paint_finder/components/palette_card.dart';
import 'package:miniature_paint_finder/components/section_title.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final palettes = SampleData.getPalettes();
    final paints = SampleData.getPaints();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de My Library
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.marineBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.import_contacts,
                          size: 32,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'My Library',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "My Library",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Sección de paletas
            const SectionTitle(title: "Color Palettes", showViewAll: true),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: palettes.length,
              itemBuilder: (context, index) {
                return PaletteCard(
                  palette: palettes[index],
                  isHorizontal: false,
                  onTap: () {
                    // Navegar a la página de detalles de la paleta
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Sección de colores guardados
            const SectionTitle(title: "Saved Colors", showViewAll: true),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final paint in paints.take(12))
                  ColorChip(
                    label: paint.name,
                    color: Color(
                      int.parse(paint.colorHex.substring(1, 7), radix: 16) +
                          0xFF000000,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección de pinturas recientes
            const SectionTitle(title: "Recent Paints", showViewAll: true),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: paints.length > 6 ? 6 : paints.length,
              itemBuilder: (context, index) {
                final paint = paints[index];
                final color = Color(
                  int.parse(paint.colorHex.substring(1, 7), radix: 16) +
                      0xFF000000,
                );
                return PaintGridCard(paint: paint, color: color);
              },
            ),
          ],
        ),
      ),
    );
  }
}
