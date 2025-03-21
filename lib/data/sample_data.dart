import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';

/// This class provides sample data for the miniature paint finder application
/// Use this for development and testing purposes only
/// In production, this data should be fetched from a backend API
class SampleData {
  /// Returns a list of paint samples from various manufacturers
  ///
  /// The paint data includes:
  /// - id: Unique identifier for the paint
  /// - name: The official name of the paint
  /// - brand: The manufacturer (Citadel, Vallejo, Army Painter, Scale75, etc.)
  /// - colorHex: The hexadecimal color code (e.g., '#RRGGBB')
  /// - category: The type/range of paint (Base, Layer, Shade, Model Color, etc.)
  /// - isMetallic: Whether the paint has metallic pigments
  /// - isTransparent: Whether the paint is transparent (like washes/shades)
  static List<Paint> getPaints() {
    return [
      // ==================== CITADEL PAINTS ====================

      // Base paints - Solid, high-coverage foundation colors
      Paint(
        id: 'cit-base-001',
        name: 'Abaddon Black',
        brand: 'Citadel',
        colorHex: '#231F20',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'cit-base-002',
        name: 'Mephiston Red',
        brand: 'Citadel',
        colorHex: '#9A1115',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'cit-base-003',
        name: 'Macragge Blue',
        brand: 'Citadel',
        colorHex: '#0D407F',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'cit-base-004',
        name: 'Caliban Green',
        brand: 'Citadel',
        colorHex: '#00401A',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'cit-base-005',
        name: 'Retributor Armour',
        brand: 'Citadel',
        colorHex: '#85714D',
        category: 'Base',
        isMetallic: true,
        isTransparent: false,
      ),

      // Layer paints - Thinner paints for highlights and details
      Paint(
        id: 'cit-layer-001',
        name: 'Screaming Skull',
        brand: 'Citadel',
        colorHex: '#D6D5C3',
        category: 'Layer',
        isMetallic: false,
        isTransparent: false,
      ),

      // Shade paints - Transparent washes for shading and depth
      Paint(
        id: 'cit-shade-001',
        name: 'Nuln Oil',
        brand: 'Citadel',
        colorHex: '#1A1A1A',
        category: 'Shade',
        isMetallic: false,
        isTransparent: true,
      ),

      // ==================== VALLEJO PAINTS ====================

      // Model Color range - Matte acrylic paints
      Paint(
        id: 'val-model-001',
        name: 'Hull Red',
        brand: 'Vallejo',
        colorHex: '#800000',
        category: 'Model Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'val-model-002',
        name: 'German Grey',
        brand: 'Vallejo',
        colorHex: '#2A3439',
        category: 'Model Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'val-model-003',
        name: 'Silver',
        brand: 'Vallejo',
        colorHex: '#C0C0C0',
        category: 'Model Color',
        isMetallic: true,
        isTransparent: false,
      ),

      // ==================== ARMY PAINTER ====================

      // Warpaints range
      Paint(
        id: 'army-warpaints-001',
        name: 'Matt Black',
        brand: 'Army Painter',
        colorHex: '#0F0F0F',
        category: 'Warpaints',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'army-warpaints-002',
        name: 'Dragon Red',
        brand: 'Army Painter',
        colorHex: '#A32431',
        category: 'Warpaints',
        isMetallic: false,
        isTransparent: false,
      ),

      // ==================== SCALE75 ====================

      // Fantasy & Games range
      Paint(
        id: 'scale75-fg-001',
        name: 'Inktense Black',
        brand: 'Scale75',
        colorHex: '#000000',
        category: 'Fantasy & Games',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint(
        id: 'scale75-fg-002',
        name: 'Blood Red',
        brand: 'Scale75',
        colorHex: '#B40F15',
        category: 'Fantasy & Games',
        isMetallic: false,
        isTransparent: false,
      ),
    ];
  }

  /// Returns a list of sample palettes that users might create
  ///
  /// Each palette includes:
  /// - id: Unique identifier
  /// - name: User-given name for the palette
  /// - imagePath: Path to an image that inspired the palette
  /// - colors: List of Colors in the palette
  /// - createdAt: When the palette was created
  static List<Palette> getPalettes() {
    return [
      // Warhammer 40k themed palettes
      Palette(
        id: 'palette-001',
        name: 'Space Marine Ultramarines',
        imagePath: 'assets/images/placeholder1.jpg',
        colors: [
          const Color(0xFF0D407F), // Macragge Blue
          const Color(0xFF231F20), // Abaddon Black
          const Color(0xFFC0C0C0), // Silver
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Palette(
        id: 'palette-002',
        name: 'Tyranid Leviathan Scheme',
        imagePath: 'assets/images/placeholder2.jpg',
        colors: [
          const Color(0xFF9A1115), // Mephiston Red
          const Color(0xFF800000), // Hull Red
          const Color(0xFF00401A), // Caliban Green
          const Color(0xFF231F20), // Abaddon Black
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Palette(
        id: 'palette-003',
        name: 'Imperial Guard Cadian',
        imagePath: 'assets/images/placeholder3.jpg',
        colors: [
          const Color(0xFF2A3439), // German Grey
          const Color(0xFF85714D), // Retributor Armour
          const Color(0xFF1A1A1A), // Nuln Oil
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),

      // More fantasy-themed palettes
      Palette(
        id: 'palette-004',
        name: 'Necron Dynasty',
        imagePath: 'assets/images/placeholder4.jpg',
        colors: [
          const Color(0xFFC0C0C0), // Silver
          const Color(0xFF2A3439), // German Grey
          const Color(0xFF1A1A1A), // Nuln Oil
          const Color(0xFF00401A), // Caliban Green
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Palette(
        id: 'palette-005',
        name: 'Eldar Craftworld Iyanden',
        imagePath: 'assets/images/placeholder5.jpg',
        colors: [
          const Color(0xFF0D407F), // Macragge Blue
          const Color(0xFF9A1115), // Mephiston Red
          const Color(0xFFD6D5C3), // Screaming Skull
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Palette(
        id: 'palette-006',
        name: 'T\'au Sept',
        imagePath: 'assets/images/placeholder6.jpg',
        colors: [
          const Color(0xFF2A3439), // German Grey
          const Color(0xFFC0C0C0), // Silver
          const Color(0xFF00401A), // Caliban Green
          const Color(0xFF9A1115), // Mephiston Red
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
      ),
      Palette(
        id: 'palette-007',
        name: 'Ork Goff Clan',
        imagePath: 'assets/images/placeholder7.jpg',
        colors: [
          const Color(0xFF00401A), // Caliban Green
          const Color(0xFF800000), // Hull Red
          const Color(0xFF2A3439), // German Grey
          const Color(0xFF1A1A1A), // Nuln Oil
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 22)),
      ),
      Palette(
        id: 'palette-008',
        name: 'Chaos Space Marines Word Bearers',
        imagePath: 'assets/images/placeholder8.jpg',
        colors: [
          const Color(0xFF9A1115), // Mephiston Red
          const Color(0xFF231F20), // Abaddon Black
          const Color(0xFF85714D), // Retributor Armour
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      Palette(
        id: 'palette-009',
        name: 'Death Guard Plague Marines',
        imagePath: 'assets/images/placeholder9.jpg',
        colors: [
          const Color(0xFFD6D5C3), // Screaming Skull
          const Color(0xFF00401A), // Caliban Green
          const Color(0xFF1A1A1A), // Nuln Oil
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Palette(
        id: 'palette-010',
        name: 'Adeptus Custodes',
        imagePath: 'assets/images/placeholder10.jpg',
        colors: [
          const Color(0xFF85714D), // Retributor Armour
          const Color(0xFF231F20), // Abaddon Black
          const Color(0xFF9A1115), // Mephiston Red
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
      ),
    ];
  }

  /// This method simulates a color matching functionality
  /// that would typically be performed by a backend service
  ///
  /// [targetColor] - The color to find matches for
  /// [brands] - List of brand names to search within
  /// [threshold] - Match percentage threshold (0-100)
  static List<Map<String, dynamic>> getMatchingPaints({
    required Color targetColor,
    required List<String> brands,
    int threshold = 0,
  }) {
    // In a real implementation, this would use a proper color distance algorithm
    // like CIEDE2000 or Delta-E to calculate accurate color matches

    // Simplified implementation for demo
    final List<Map<String, dynamic>> matches = [];
    final List<Paint> allPaints = getPaints();

    // Convert target RGB to HSV for better matching
    final HSVColor targetHsv = HSVColor.fromColor(targetColor);

    for (final paint in allPaints) {
      // Only include requested brands
      if (!brands.contains(paint.brand)) continue;

      // Convert hex to Color
      final Color paintColor = Color(
        int.parse(paint.colorHex.substring(1, 7), radix: 16) + 0xFF000000,
      );

      // Convert paint RGB to HSV
      final HSVColor paintHsv = HSVColor.fromColor(paintColor);

      // Calculate a simple color distance (not accurate but works for demo)
      final double hueDiff = (targetHsv.hue - paintHsv.hue).abs();
      final double satDiff = (targetHsv.saturation - paintHsv.saturation).abs();
      final double valDiff = (targetHsv.value - paintHsv.value).abs();

      // Weighted distance calculation
      final double distance =
          (hueDiff / 360.0) * 0.6 + satDiff * 0.2 + valDiff * 0.2;

      // Convert to match percentage (0-100)
      final int matchPercentage = ((1.0 - distance) * 100).round();

      // Only include if above threshold
      if (matchPercentage >= threshold) {
        // Get first letter of brand for avatar
        final String brandAvatar = paint.brand.substring(0, 1);

        matches.add({
          'id': paint.id,
          'name': paint.name,
          'brand': paint.brand,
          'color': paintColor,
          'colorHex': paint.colorHex,
          'match': matchPercentage,
          'brandAvatar': brandAvatar,
          'colorCode': '${paint.id.split('-').last}', // Just for demo
          'barcode':
              '50119${paint.id.hashCode.abs() % 10000000}', // Fake barcode
          'isMetallic': paint.isMetallic,
          'isTransparent': paint.isTransparent,
          'category': paint.category,
        });
      }
    }

    // Sort by match percentage (highest first)
    matches.sort((a, b) => (b['match'] as int).compareTo(a['match'] as int));

    return matches;
  }
}
