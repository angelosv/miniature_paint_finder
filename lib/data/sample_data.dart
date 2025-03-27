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
      Paint(
        id: 'cit-base-006',
        name: 'Bugmans Glow',
        brand: 'Citadel',
        colorHex: '#834F46',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'cit-base-007',
        name: 'Averland Sunset',
        brand: 'Citadel',
        colorHex: '#FBB81C',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'cit-base-008',
        name: 'Zandri Dust',
        brand: 'Citadel',
        colorHex: '#B7975F',
        category: 'Base',
        isMetallic: false,
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
      Paint(
        id: 'cit-layer-002',
        name: 'Evil Sunz Scarlet',
        brand: 'Citadel',
        colorHex: '#BE0B0C',
        category: 'Layer',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'cit-layer-003',
        name: 'Wild Rider Red',
        brand: 'Citadel',
        colorHex: '#FF4D28',
        category: 'Layer',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'cit-layer-004',
        name: 'Lothern Blue',
        brand: 'Citadel',
        colorHex: '#31A2F2',
        category: 'Layer',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'cit-layer-005',
        name: 'Runefang Steel',
        brand: 'Citadel',
        colorHex: '#C0C5C9',
        category: 'Layer',
        isMetallic: true,
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
      Paint(
        id: 'cit-shade-002',
        name: 'Agrax Earthshade',
        brand: 'Citadel',
        colorHex: '#63452A',
        category: 'Shade',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint(
        id: 'cit-shade-003',
        name: 'Reikland Fleshshade',
        brand: 'Citadel',
        colorHex: '#914B28',
        category: 'Shade',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint(
        id: 'cit-shade-004',
        name: 'Druchii Violet',
        brand: 'Citadel',
        colorHex: '#69385C',
        category: 'Shade',
        isMetallic: false,
        isTransparent: true,
      ),

      // Technical paints - Special effects
      Paint(
        id: 'cit-tech-001',
        name: 'Blood for the Blood God',
        brand: 'Citadel',
        colorHex: '#9A0F0F',
        category: 'Technical',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint(
        id: 'cit-tech-002',
        name: 'Nihilakh Oxide',
        brand: 'Citadel',
        colorHex: '#7ABAD4',
        category: 'Technical',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint(
        id: 'cit-tech-003',
        name: 'Typhus Corrosion',
        brand: 'Citadel',
        colorHex: '#3B342E',
        category: 'Technical',
        isMetallic: false,
        isTransparent: false,
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
      Paint(
        id: 'val-model-004',
        name: 'Flat Blue',
        brand: 'Vallejo',
        colorHex: '#2F5C8E',
        category: 'Model Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'val-model-005',
        name: 'Flat Green',
        brand: 'Vallejo',
        colorHex: '#315A45',
        category: 'Model Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'val-model-006',
        name: 'Yellow Ochre',
        brand: 'Vallejo',
        colorHex: '#C88A3D',
        category: 'Model Color',
        isMetallic: false,
        isTransparent: false,
      ),

      // Game Color range - Brighter colors for fantasy miniatures
      Paint(
        id: 'val-game-001',
        name: 'Bloody Red',
        brand: 'Vallejo',
        colorHex: '#B01E23',
        category: 'Game Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'val-game-002',
        name: 'Magic Blue',
        brand: 'Vallejo',
        colorHex: '#2561A4',
        category: 'Game Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'val-game-003',
        name: 'Scorpy Green',
        brand: 'Vallejo',
        colorHex: '#5F823A',
        category: 'Game Color',
        isMetallic: false,
        isTransparent: false,
      ),

      // Metal Color range - High-quality metallics
      Paint(
        id: 'val-metal-001',
        name: 'Aluminum',
        brand: 'Vallejo',
        colorHex: '#D5D6D8',
        category: 'Metal Color',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint(
        id: 'val-metal-002',
        name: 'Gold',
        brand: 'Vallejo',
        colorHex: '#D4AF37',
        category: 'Metal Color',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint(
        id: 'val-metal-003',
        name: 'Copper',
        brand: 'Vallejo',
        colorHex: '#B87333',
        category: 'Metal Color',
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
      Paint(
        id: 'army-warpaints-003',
        name: 'Wolf Grey',
        brand: 'Army Painter',
        colorHex: '#739CC5',
        category: 'Warpaints',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'army-warpaints-004',
        name: 'Goblin Green',
        brand: 'Army Painter',
        colorHex: '#3F6C39',
        category: 'Warpaints',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'army-warpaints-005',
        name: 'Skeleton Bone',
        brand: 'Army Painter',
        colorHex: '#D5C586',
        category: 'Warpaints',
        isMetallic: false,
        isTransparent: false,
      ),

      // Washes range
      Paint(
        id: 'army-wash-001',
        name: 'Dark Tone',
        brand: 'Army Painter',
        colorHex: '#231F20',
        category: 'Wash',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint(
        id: 'army-wash-002',
        name: 'Soft Tone',
        brand: 'Army Painter',
        colorHex: '#A98053',
        category: 'Wash',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint(
        id: 'army-wash-003',
        name: 'Green Tone',
        brand: 'Army Painter',
        colorHex: '#31574A',
        category: 'Wash',
        isMetallic: false,
        isTransparent: true,
      ),

      // Metallics range
      Paint(
        id: 'army-metal-001',
        name: 'Shining Silver',
        brand: 'Army Painter',
        colorHex: '#C9CACB',
        category: 'Metallics',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint(
        id: 'army-metal-002',
        name: 'Weapon Bronze',
        brand: 'Army Painter',
        colorHex: '#CD7F32',
        category: 'Metallics',
        isMetallic: true,
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
      Paint(
        id: 'scale75-fg-003',
        name: 'Navy Blue',
        brand: 'Scale75',
        colorHex: '#0B2B66',
        category: 'Fantasy & Games',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'scale75-fg-004',
        name: 'Ardennes Green',
        brand: 'Scale75',
        colorHex: '#2B473B',
        category: 'Fantasy & Games',
        isMetallic: false,
        isTransparent: false,
      ),

      // Metal n Alchemy range
      Paint(
        id: 'scale75-metal-001',
        name: 'Thrash Metal',
        brand: 'Scale75',
        colorHex: '#5F5F5F',
        category: 'Metal n Alchemy',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint(
        id: 'scale75-metal-002',
        name: 'Dwarven Gold',
        brand: 'Scale75',
        colorHex: '#B5902B',
        category: 'Metal n Alchemy',
        isMetallic: true,
        isTransparent: false,
      ),

      // ==================== TAMIYA ====================

      // Acrylic Paints
      Paint(
        id: 'tamiya-xf-001',
        name: 'Flat Black',
        brand: 'Tamiya',
        colorHex: '#1E1E1E',
        category: 'Acrylic',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'tamiya-xf-002',
        name: 'Flat White',
        brand: 'Tamiya',
        colorHex: '#FFFFFF',
        category: 'Acrylic',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'tamiya-xf-003',
        name: 'Flat Red',
        brand: 'Tamiya',
        colorHex: '#B52A32',
        category: 'Acrylic',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'tamiya-xf-004',
        name: 'Flat Blue',
        brand: 'Tamiya',
        colorHex: '#0F3C7F',
        category: 'Acrylic',
        isMetallic: false,
        isTransparent: false,
      ),

      // Metallic colors
      Paint(
        id: 'tamiya-x-011',
        name: 'Chrome Silver',
        brand: 'Tamiya',
        colorHex: '#C8C8CA',
        category: 'Metallic',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint(
        id: 'tamiya-x-012',
        name: 'Gold Leaf',
        brand: 'Tamiya',
        colorHex: '#CEAA62',
        category: 'Metallic',
        isMetallic: true,
        isTransparent: false,
      ),

      // ==================== P3 (PRIVATEER PRESS) ====================
      Paint(
        id: 'p3-001',
        name: 'Coal Black',
        brand: 'P3',
        colorHex: '#062226',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'p3-002',
        name: 'Khador Red Base',
        brand: 'P3',
        colorHex: '#A0250D',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'p3-003',
        name: 'Cygnar Blue Base',
        brand: 'P3',
        colorHex: '#224F98',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'p3-004',
        name: 'Thornwood Green',
        brand: 'P3',
        colorHex: '#354A37',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),

      // ==================== AK INTERACTIVE ====================
      Paint(
        id: 'ak-001',
        name: 'Dark Rust',
        brand: 'AK Interactive',
        colorHex: '#6E3A21',
        category: 'Weathering',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'ak-002',
        name: 'Track Rust',
        brand: 'AK Interactive',
        colorHex: '#7F4422',
        category: 'Weathering',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'ak-003',
        name: 'Panzer Gray',
        brand: 'AK Interactive',
        colorHex: '#414C52',
        category: 'AFV',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint(
        id: 'ak-004',
        name: 'Olive Green',
        brand: 'AK Interactive',
        colorHex: '#44553A',
        category: 'AFV',
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
  /// - imagePath: Path to an image that inspired this palette
  /// - colors: List of Colors in the palette
  /// - createdAt: When the palette was created
  static List<Palette> getPalettes() {
    print('🎨 SampleData.getPalettes() called');
    const String defaultImagePath = 'assets/images/placeholder1.jpg';

    try {
      final palettes = [
        // Warhammer 40k themed palettes
        Palette(
          id: 'palette-001',
          name: 'Space Marine Ultramarines',
          imagePath: defaultImagePath,
          colors: [
            const Color(0xFF0D407F), // Macragge Blue
            const Color(0xFF231F20), // Abaddon Black
            const Color(0xFFC0C0C0), // Silver
            const Color(0xFFD5D6D8), // Aluminum
            const Color(0xFFD6D5C3), // Screaming Skull
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          paintSelections: [
            PaintSelection(
              colorHex: '#0D407F',
              paintId: 'cit-base-003',
              paintName: 'Macragge Blue',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 100,
              paintColorHex: '#0D407F',
            ),
            PaintSelection(
              colorHex: '#231F20',
              paintId: 'cit-base-001',
              paintName: 'Abaddon Black',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 98,
              paintColorHex: '#231F20',
            ),
            PaintSelection(
              colorHex: '#C0C0C0',
              paintId: 'val-model-003',
              paintName: 'Silver',
              paintBrand: 'Vallejo',
              brandAvatar: 'V',
              matchPercentage: 96,
              paintColorHex: '#C0C0C0',
            ),
            PaintSelection(
              colorHex: '#D6D5C3',
              paintId: 'cit-layer-001',
              paintName: 'Screaming Skull',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 94,
              paintColorHex: '#D6D5C3',
            ),
          ],
        ),
        Palette(
          id: 'palette-002',
          name: 'Tyranid Leviathan Scheme',
          imagePath: defaultImagePath,
          colors: [
            const Color(0xFF9A1115), // Mephiston Red
            const Color(0xFF800000), // Hull Red
            const Color(0xFF00401A), // Caliban Green
            const Color(0xFF231F20), // Abaddon Black
            const Color(0xFFFBB81C), // Averland Sunset
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          paintSelections: [
            PaintSelection(
              colorHex: '#9A1115',
              paintId: 'cit-base-002',
              paintName: 'Mephiston Red',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 95,
              paintColorHex: '#9A1115',
            ),
            PaintSelection(
              colorHex: '#800000',
              paintId: 'val-model-001',
              paintName: 'Hull Red',
              paintBrand: 'Vallejo',
              brandAvatar: 'V',
              matchPercentage: 93,
              paintColorHex: '#800000',
            ),
            PaintSelection(
              colorHex: '#00401A',
              paintId: 'cit-base-004',
              paintName: 'Caliban Green',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 97,
              paintColorHex: '#00401A',
            ),
            PaintSelection(
              colorHex: '#231F20',
              paintId: 'cit-base-001',
              paintName: 'Abaddon Black',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 98,
              paintColorHex: '#231F20',
            ),
            PaintSelection(
              colorHex: '#FBB81C',
              paintId: 'cit-base-007',
              paintName: 'Averland Sunset',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 92,
              paintColorHex: '#FBB81C',
            ),
            PaintSelection(
              colorHex: '#914B28',
              paintId: 'cit-shade-003',
              paintName: 'Reikland Fleshshade',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 88,
              paintColorHex: '#914B28',
            ),
            PaintSelection(
              colorHex: '#69385C',
              paintId: 'cit-shade-004',
              paintName: 'Druchii Violet',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 85,
              paintColorHex: '#69385C',
            ),
            PaintSelection(
              colorHex: '#9A0F0F',
              paintId: 'cit-tech-001',
              paintName: 'Blood for the Blood God',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 90,
              paintColorHex: '#9A0F0F',
            ),
            PaintSelection(
              colorHex: '#7ABAD4',
              paintId: 'cit-tech-002',
              paintName: 'Nihilakh Oxide',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 82,
              paintColorHex: '#7ABAD4',
            ),
            PaintSelection(
              colorHex: '#3B342E',
              paintId: 'cit-tech-003',
              paintName: 'Typhus Corrosion',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 80,
              paintColorHex: '#3B342E',
            ),
          ],
        ),
        Palette(
          id: 'palette-003',
          name: 'Imperial Guard Cadian',
          imagePath: defaultImagePath,
          colors: [
            const Color(0xFF2A3439), // German Grey
            const Color(0xFF85714D), // Retributor Armour
            const Color(0xFF1A1A1A), // Nuln Oil
            const Color(0xFF44553A), // Olive Green
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          paintSelections: [
            PaintSelection(
              colorHex: '#2A3439',
              paintId: 'val-model-002',
              paintName: 'German Grey',
              paintBrand: 'Vallejo',
              brandAvatar: 'V',
              matchPercentage: 95,
              paintColorHex: '#2A3439',
            ),
            PaintSelection(
              colorHex: '#85714D',
              paintId: 'cit-base-005',
              paintName: 'Retributor Armour',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 93,
              paintColorHex: '#85714D',
            ),
          ],
        ),

        // More fantasy-themed palettes
        Palette(
          id: 'palette-004',
          name: 'Necron Dynasty',
          imagePath: defaultImagePath,
          colors: [
            const Color(0xFFC0C0C0), // Silver
            const Color(0xFF2A3439), // German Grey
            const Color(0xFF1A1A1A), // Nuln Oil
            const Color(0xFF00401A), // Caliban Green
            const Color(0xFF7ABAD4), // Nihilakh Oxide
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          paintSelections: [
            PaintSelection(
              colorHex: '#C0C0C0',
              paintId: 'val-model-003',
              paintName: 'Silver',
              paintBrand: 'Vallejo',
              brandAvatar: 'V',
              matchPercentage: 99,
              paintColorHex: '#C0C0C0',
            ),
            PaintSelection(
              colorHex: '#7ABAD4',
              paintId: 'cit-tech-002',
              paintName: 'Nihilakh Oxide',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 92,
              paintColorHex: '#7ABAD4',
            ),
            PaintSelection(
              colorHex: '#1A1A1A',
              paintId: 'cit-shade-001',
              paintName: 'Nuln Oil',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 97,
              paintColorHex: '#1A1A1A',
            ),
          ],
        ),
        Palette(
          id: 'palette-005',
          name: 'Eldar Craftworld Iyanden',
          imagePath: defaultImagePath,
          colors: [
            const Color(0xFFFBB81C), // Averland Sunset
            const Color(0xFF0D407F), // Macragge Blue
            const Color(0xFF9A1115), // Mephiston Red
            const Color(0xFFD6D5C3), // Screaming Skull
            const Color(0xFFC0C0C0), // Silver
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
          paintSelections: [
            PaintSelection(
              colorHex: '#FBB81C',
              paintId: 'cit-base-007',
              paintName: 'Averland Sunset',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 92,
              paintColorHex: '#FBB81C',
            ),
            PaintSelection(
              colorHex: '#0D407F',
              paintId: 'cit-base-003',
              paintName: 'Macragge Blue',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 98,
              paintColorHex: '#0D407F',
            ),
            PaintSelection(
              colorHex: '#9A1115',
              paintId: 'cit-base-002',
              paintName: 'Mephiston Red',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 95,
              paintColorHex: '#9A1115',
            ),
            PaintSelection(
              colorHex: '#D6D5C3',
              paintId: 'cit-layer-001',
              paintName: 'Screaming Skull',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 94,
              paintColorHex: '#D6D5C3',
            ),
            PaintSelection(
              colorHex: '#C0C0C0',
              paintId: 'val-model-003',
              paintName: 'Silver',
              paintBrand: 'Vallejo',
              brandAvatar: 'V',
              matchPercentage: 96,
              paintColorHex: '#C0C0C0',
            ),
            PaintSelection(
              colorHex: '#63452A',
              paintId: 'cit-shade-002',
              paintName: 'Agrax Earthshade',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 89,
              paintColorHex: '#63452A',
            ),
          ],
        ),
        Palette(
          id: 'palette-006',
          name: 'T\'au Sept',
          imagePath: defaultImagePath,
          colors: [
            const Color(0xFF2A3439), // German Grey
            const Color(0xFFC0C0C0), // Silver
            const Color(0xFF00401A), // Caliban Green
            const Color(0xFF9A1115), // Mephiston Red
            const Color(0xFF31A2F2), // Lothern Blue
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 18)),
          paintSelections: [
            PaintSelection(
              colorHex: '#00401A',
              paintId: 'cit-base-004',
              paintName: 'Caliban Green',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 97,
              paintColorHex: '#00401A',
            ),
          ],
        ),

        // Historical themes
        Palette(
          id: 'palette-007',
          name: 'WWII German Panzer',
          imagePath: defaultImagePath,
          colors: [
            const Color(0xFF414C52), // Panzer Gray
            const Color(0xFF6E3A21), // Dark Rust
            const Color(0xFF231F20), // Black
            const Color(0xFFC8C8CA), // Chrome Silver
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 22)),
          paintSelections: [
            PaintSelection(
              colorHex: '#414C52',
              paintId: 'ak-003',
              paintName: 'Panzer Gray',
              paintBrand: 'AK Interactive',
              brandAvatar: 'A',
              matchPercentage: 97,
              paintColorHex: '#414C52',
            ),
            PaintSelection(
              colorHex: '#6E3A21',
              paintId: 'ap-005',
              paintName: 'Dark Rust',
              paintBrand: 'Army Painter',
              brandAvatar: 'A',
              matchPercentage: 94,
              paintColorHex: '#6E3A21',
            ),
            PaintSelection(
              colorHex: '#231F20',
              paintId: 'cit-base-001',
              paintName: 'Abaddon Black',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 98,
              paintColorHex: '#231F20',
            ),
            PaintSelection(
              colorHex: '#C8C8CA',
              paintId: 'val-model-015',
              paintName: 'Chrome',
              paintBrand: 'Vallejo',
              brandAvatar: 'V',
              matchPercentage: 95,
              paintColorHex: '#C8C8CA',
            ),
            PaintSelection(
              colorHex: '#1A1A1A',
              paintId: 'cit-shade-001',
              paintName: 'Nuln Oil',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 93,
              paintColorHex: '#1A1A1A',
            ),
            PaintSelection(
              colorHex: '#63452A',
              paintId: 'cit-shade-002',
              paintName: 'Agrax Earthshade',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 91,
              paintColorHex: '#63452A',
            ),
            PaintSelection(
              colorHex: '#3B342E',
              paintId: 'cit-tech-003',
              paintName: 'Typhus Corrosion',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 88,
              paintColorHex: '#3B342E',
            ),
            PaintSelection(
              colorHex: '#BE0B0C',
              paintId: 'cit-layer-002',
              paintName: 'Evil Sunz Scarlet',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 82,
              paintColorHex: '#BE0B0C',
            ),
          ],
        ),
        Palette(
          id: 'palette-008',
          name: 'US Army Olive Drab',
          imagePath: defaultImagePath,
          colors: [
            const Color(0xFF44553A), // Olive Green
            const Color(0xFFB7975F), // Zandri Dust
            const Color(0xFF7F4422), // Track Rust
            const Color(0xFF85714D), // Retributor Armour
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
          paintSelections: [
            PaintSelection(
              colorHex: '#44553A',
              paintId: 'val-model-034',
              paintName: 'Olive Green',
              paintBrand: 'Vallejo',
              brandAvatar: 'V',
              matchPercentage: 96,
              paintColorHex: '#44553A',
            ),
            PaintSelection(
              colorHex: '#B7975F',
              paintId: 'cit-base-008',
              paintName: 'Zandri Dust',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 94,
              paintColorHex: '#B7975F',
            ),
            PaintSelection(
              colorHex: '#85714D',
              paintId: 'cit-base-005',
              paintName: 'Retributor Armour',
              paintBrand: 'Citadel',
              brandAvatar: 'C',
              matchPercentage: 92,
              paintColorHex: '#85714D',
            ),
          ],
        ),
      ];

      print('🎨 Returning ${palettes.length} sample palettes');
      for (var i = 0; i < palettes.length; i++) {
        print(
          '   ${i + 1}. ${palettes[i].name} (${palettes[i].colors.length} colors)',
        );
      }

      return palettes;
    } catch (e) {
      print('❌ ERROR in SampleData.getPalettes(): $e');
      // Return at least one palette in case of error
      return [
        Palette(
          id: 'palette-emergency',
          name: 'Emergency Sample Palette',
          imagePath: defaultImagePath,
          colors: [
            const Color(0xFF0D407F), // Blue
            const Color(0xFF9A1115), // Red
            const Color(0xFF44553A), // Green
          ],
          createdAt: DateTime.now(),
        ),
      ];
    }
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
