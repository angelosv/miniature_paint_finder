import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart' show Paint;
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
      Paint.fromHex(
        id: 'cit-base-001',
        name: 'Abaddon Black',
        brand: 'Citadel',
        hex: '#231F20',
        set: 'Base',
        code: 'AB',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'cit-base-002',
        name: 'Mephiston Red',
        brand: 'Citadel',
        hex: '#9A1115',
        set: 'Base',
        code: 'MR',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'cit-base-003',
        name: 'Macragge Blue',
        brand: 'Citadel',
        hex: '#0D407F',
        set: 'Base',
        code: 'MB',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'cit-base-004',
        name: 'Caliban Green',
        brand: 'Citadel',
        hex: '#00401A',
        set: 'Base',
        code: 'CG',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'cit-base-005',
        name: 'Retributor Armour',
        brand: 'Citadel',
        hex: '#85714D',
        set: 'Base',
        code: 'RA',
        category: 'Base',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'cit-base-006',
        name: 'Bugmans Glow',
        brand: 'Citadel',
        hex: '#834F46',
        set: 'Base',
        code: 'BG',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'cit-base-007',
        name: 'Averland Sunset',
        brand: 'Citadel',
        hex: '#FBB81C',
        set: 'Base',
        code: 'AS',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'cit-base-008',
        name: 'Zandri Dust',
        brand: 'Citadel',
        hex: '#B7975F',
        set: 'Base',
        code: 'ZD',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),

      // Layer paints - Thinner paints for highlights and details
      Paint.fromHex(
        id: 'cit-layer-001',
        name: 'Screaming Skull',
        brand: 'Citadel',
        hex: '#D6D5C3',
        set: 'Layer',
        code: 'SS',
        category: 'Layer',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'cit-layer-002',
        name: 'Evil Sunz Scarlet',
        brand: 'Citadel',
        hex: '#BE0B0C',
        set: 'Layer',
        code: 'ESS',
        category: 'Layer',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'cit-layer-003',
        name: 'Wild Rider Red',
        brand: 'Citadel',
        hex: '#FF4D28',
        set: 'Layer',
        code: 'WRR',
        category: 'Layer',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'cit-layer-004',
        name: 'Lothern Blue',
        brand: 'Citadel',
        hex: '#31A2F2',
        set: 'Layer',
        code: 'LB',
        category: 'Layer',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'cit-layer-005',
        name: 'Runefang Steel',
        brand: 'Citadel',
        hex: '#C0C5C9',
        set: 'Layer',
        code: 'RS',
        category: 'Layer',
        isMetallic: true,
        isTransparent: false,
      ),

      // Shade paints - Transparent washes for shading and depth
      Paint.fromHex(
        id: 'cit-shade-001',
        name: 'Nuln Oil',
        brand: 'Citadel',
        hex: '#1A1A1A',
        set: 'Shade',
        code: 'NO',
        category: 'Shade',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint.fromHex(
        id: 'cit-shade-002',
        name: 'Agrax Earthshade',
        brand: 'Citadel',
        hex: '#63452A',
        set: 'Shade',
        code: 'AE',
        category: 'Shade',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint.fromHex(
        id: 'cit-shade-003',
        name: 'Reikland Fleshshade',
        brand: 'Citadel',
        hex: '#914B28',
        set: 'Shade',
        code: 'RF',
        category: 'Shade',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint.fromHex(
        id: 'cit-shade-004',
        name: 'Druchii Violet',
        brand: 'Citadel',
        hex: '#69385C',
        set: 'Shade',
        code: 'DV',
        category: 'Shade',
        isMetallic: false,
        isTransparent: true,
      ),

      // Technical paints - Special effects
      Paint.fromHex(
        id: 'cit-tech-001',
        name: 'Blood for the Blood God',
        brand: 'Citadel',
        hex: '#9A0F0F',
        set: 'Technical',
        code: 'BFTBG',
        category: 'Technical',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint.fromHex(
        id: 'cit-tech-002',
        name: 'Nihilakh Oxide',
        brand: 'Citadel',
        hex: '#7ABAD4',
        set: 'Technical',
        code: 'NO',
        category: 'Technical',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint.fromHex(
        id: 'cit-tech-003',
        name: 'Typhus Corrosion',
        brand: 'Citadel',
        hex: '#3B342E',
        set: 'Technical',
        code: 'TC',
        category: 'Technical',
        isMetallic: false,
        isTransparent: true,
      ),

      // ==================== VALLEJO PAINTS ====================

      // Model Color range - Matte acrylic paints
      Paint.fromHex(
        id: 'val-model-001',
        name: 'Hull Red',
        brand: 'Vallejo',
        hex: '#800000',
        set: 'Model Color',
        code: '70.985',
        category: 'Model Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'val-model-002',
        name: 'German Grey',
        brand: 'Vallejo',
        hex: '#2A3439',
        set: 'Model Color',
        code: '70.995',
        category: 'Model Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'val-model-003',
        name: 'Silver',
        brand: 'Vallejo',
        hex: '#C0C0C0',
        set: 'Model Color',
        code: '70.997',
        category: 'Model Color',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'val-model-004',
        name: 'Flat Blue',
        brand: 'Vallejo',
        hex: '#2F5C8E',
        set: 'Model Color',
        code: '70.962',
        category: 'Model Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'val-model-005',
        name: 'Flat Green',
        brand: 'Vallejo',
        hex: '#315A45',
        set: 'Model Color',
        code: '70.968',
        category: 'Model Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'val-model-006',
        name: 'Yellow Ochre',
        brand: 'Vallejo',
        hex: '#C88A3D',
        set: 'Model Color',
        code: '70.913',
        category: 'Model Color',
        isMetallic: false,
        isTransparent: false,
      ),

      // Game Color range - Brighter colors for fantasy miniatures
      Paint.fromHex(
        id: 'val-game-001',
        name: 'Bloody Red',
        brand: 'Vallejo',
        hex: '#B01E23',
        set: 'Game Color',
        code: '72.010',
        category: 'Game Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'val-game-002',
        name: 'Magic Blue',
        brand: 'Vallejo',
        hex: '#2561A4',
        set: 'Game Color',
        code: '72.021',
        category: 'Game Color',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'val-game-003',
        name: 'Scorpy Green',
        brand: 'Vallejo',
        hex: '#5F823A',
        set: 'Game Color',
        code: '72.032',
        category: 'Game Color',
        isMetallic: false,
        isTransparent: false,
      ),

      // Metal Color range - High-quality metallics
      Paint.fromHex(
        id: 'val-metal-001',
        name: 'Aluminum',
        brand: 'Vallejo',
        hex: '#D5D6D8',
        set: 'Metal Color',
        code: '77.701',
        category: 'Metal Color',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'val-metal-002',
        name: 'Gold',
        brand: 'Vallejo',
        hex: '#D4AF37',
        set: 'Metal Color',
        code: '77.702',
        category: 'Metal Color',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'val-metal-003',
        name: 'Copper',
        brand: 'Vallejo',
        hex: '#B87333',
        set: 'Metal Color',
        code: '77.703',
        category: 'Metal Color',
        isMetallic: true,
        isTransparent: false,
      ),

      // ==================== ARMY PAINTER ====================

      // Warpaints range
      Paint.fromHex(
        id: 'army-warpaints-001',
        name: 'Matt Black',
        brand: 'Army Painter',
        hex: '#0F0F0F',
        set: 'Warpaints',
        code: 'WP1101',
        category: 'Warpaints',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'army-warpaints-002',
        name: 'Dragon Red',
        brand: 'Army Painter',
        hex: '#A32431',
        set: 'Warpaints',
        code: 'WP1102',
        category: 'Warpaints',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'army-warpaints-003',
        name: 'Wolf Grey',
        brand: 'Army Painter',
        hex: '#739CC5',
        set: 'Warpaints',
        code: 'WP1103',
        category: 'Warpaints',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'army-warpaints-004',
        name: 'Goblin Green',
        brand: 'Army Painter',
        hex: '#3F6C39',
        set: 'Warpaints',
        code: 'WP1104',
        category: 'Warpaints',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'army-warpaints-005',
        name: 'Skeleton Bone',
        brand: 'Army Painter',
        hex: '#D5C586',
        set: 'Warpaints',
        code: 'WP1105',
        category: 'Warpaints',
        isMetallic: false,
        isTransparent: false,
      ),

      // Washes range
      Paint.fromHex(
        id: 'army-wash-001',
        name: 'Dark Tone',
        brand: 'Army Painter',
        hex: '#231F20',
        set: 'Wash',
        code: 'WP1136',
        category: 'Wash',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint.fromHex(
        id: 'army-wash-002',
        name: 'Soft Tone',
        brand: 'Army Painter',
        hex: '#A98053',
        set: 'Wash',
        code: 'WP1137',
        category: 'Wash',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint.fromHex(
        id: 'army-wash-003',
        name: 'Green Tone',
        brand: 'Army Painter',
        hex: '#31574A',
        set: 'Wash',
        code: 'WP1138',
        category: 'Wash',
        isMetallic: false,
        isTransparent: true,
      ),

      // Metallics range
      Paint.fromHex(
        id: 'army-metal-001',
        name: 'Shining Silver',
        brand: 'Army Painter',
        hex: '#C9CACB',
        set: 'Metallics',
        code: 'WP1201',
        category: 'Metallics',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'army-metal-002',
        name: 'Weapon Bronze',
        brand: 'Army Painter',
        hex: '#CD7F32',
        set: 'Metallics',
        code: 'WP1202',
        category: 'Metallics',
        isMetallic: true,
        isTransparent: false,
      ),

      // ==================== SCALE75 ====================

      // Fantasy & Games range
      Paint.fromHex(
        id: 'scale75-fg-001',
        name: 'Inktense Black',
        brand: 'Scale75',
        hex: '#000000',
        set: 'Fantasy & Games',
        code: 'SFG-01',
        category: 'Fantasy & Games',
        isMetallic: false,
        isTransparent: true,
      ),
      Paint.fromHex(
        id: 'scale75-fg-002',
        name: 'Blood Red',
        brand: 'Scale75',
        hex: '#B40F15',
        set: 'Fantasy & Games',
        code: 'SFG-02',
        category: 'Fantasy & Games',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'scale75-fg-003',
        name: 'Navy Blue',
        brand: 'Scale75',
        hex: '#0B2B66',
        set: 'Fantasy & Games',
        code: 'SFG-03',
        category: 'Fantasy & Games',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'scale75-fg-004',
        name: 'Ardennes Green',
        brand: 'Scale75',
        hex: '#2B473B',
        set: 'Fantasy & Games',
        code: 'SFG-04',
        category: 'Fantasy & Games',
        isMetallic: false,
        isTransparent: false,
      ),

      // Metal n Alchemy range
      Paint.fromHex(
        id: 'scale75-metal-001',
        name: 'Thrash Metal',
        brand: 'Scale75',
        hex: '#5F5F5F',
        set: 'Metal n Alchemy',
        code: 'SMA-01',
        category: 'Metal n Alchemy',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'scale75-metal-002',
        name: 'Dwarven Gold',
        brand: 'Scale75',
        hex: '#B5902B',
        set: 'Metal n Alchemy',
        code: 'SMA-02',
        category: 'Metal n Alchemy',
        isMetallic: true,
        isTransparent: false,
      ),

      // ==================== TAMIYA ====================

      // Acrylic Paints
      Paint.fromHex(
        id: 'tamiya-xf-001',
        name: 'Flat Black',
        brand: 'Tamiya',
        hex: '#1E1E1E',
        set: 'XF',
        code: 'XF-1',
        category: 'Acrylic',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'tamiya-xf-002',
        name: 'Flat White',
        brand: 'Tamiya',
        hex: '#FFFFFF',
        set: 'XF',
        code: 'XF-2',
        category: 'Acrylic',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'tamiya-xf-003',
        name: 'Flat Red',
        brand: 'Tamiya',
        hex: '#B52A32',
        set: 'XF',
        code: 'XF-7',
        category: 'Acrylic',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'tamiya-xf-004',
        name: 'Flat Blue',
        brand: 'Tamiya',
        hex: '#0F3C7F',
        set: 'XF',
        code: 'XF-8',
        category: 'Acrylic',
        isMetallic: false,
        isTransparent: false,
      ),

      // Metallic colors
      Paint.fromHex(
        id: 'tamiya-x-011',
        name: 'Chrome Silver',
        brand: 'Tamiya',
        hex: '#C8C8CA',
        set: 'X',
        code: 'X-11',
        category: 'Metallic',
        isMetallic: true,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'tamiya-x-012',
        name: 'Gold Leaf',
        brand: 'Tamiya',
        hex: '#CEAA62',
        set: 'X',
        code: 'X-12',
        category: 'Metallic',
        isMetallic: true,
        isTransparent: false,
      ),

      // ==================== P3 (PRIVATEER PRESS) ====================
      Paint.fromHex(
        id: 'p3-001',
        name: 'Coal Black',
        brand: 'P3',
        hex: '#062226',
        set: 'Formula P3',
        code: 'P3-001',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'p3-002',
        name: 'Khador Red Base',
        brand: 'P3',
        hex: '#A0250D',
        set: 'Formula P3',
        code: 'P3-002',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'p3-003',
        name: 'Cygnar Blue Base',
        brand: 'P3',
        hex: '#224F98',
        set: 'Formula P3',
        code: 'P3-003',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'p3-004',
        name: 'Thornwood Green',
        brand: 'P3',
        hex: '#354A37',
        set: 'Formula P3',
        code: 'P3-004',
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
      ),

      // ==================== AK INTERACTIVE ====================
      Paint.fromHex(
        id: 'ak-001',
        name: 'Dark Rust',
        brand: 'AK Interactive',
        hex: '#6E3A21',
        set: 'AK Interactive',
        code: 'AK-710',
        category: 'Weathering',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'ak-002',
        name: 'Track Rust',
        brand: 'AK Interactive',
        hex: '#7F4422',
        set: 'AK Interactive',
        code: 'AK-711',
        category: 'Weathering',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'ak-003',
        name: 'Panzer Gray',
        brand: 'AK Interactive',
        hex: '#414C52',
        set: 'AK Interactive',
        code: 'AK-712',
        category: 'AFV',
        isMetallic: false,
        isTransparent: false,
      ),
      Paint.fromHex(
        id: 'ak-004',
        name: 'Olive Green',
        brand: 'AK Interactive',
        hex: '#44553A',
        set: 'AK Interactive',
        code: 'AK-713',
        category: 'AFV',
        isMetallic: false,
        isTransparent: false,
      ),
    ];
  }

  /// Returns a list of palette samples
  static List<Palette> getPalettes() {
    return [
      Palette(
        id: 'palette-001',
        name: 'Space Marines',
        imagePath: 'assets/images/placeholder.jpeg',
        colors: [
          const Color(0xFF0D407F), // Macragge Blue
          const Color(0xFFC0C5C9), // Runefang Steel
          const Color(0xFF834F46), // Bugmans Glow
          const Color(0xFF1A1A1A), // Nuln Oil
          const Color(0xFF31A2F2), // Lothern Blue
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        paintSelections: getSamplePaintSelectionsForSpaceMarines(),
      ),
      Palette(
        id: 'palette-002',
        name: 'Orks Warband',
        imagePath: 'assets/images/placeholder.jpeg',
        colors: [
          const Color(0xFF00401A), // Caliban Green
          const Color(0xFFFBB81C), // Averland Sunset
          const Color(0xFF9A1115), // Mephiston Red
          const Color(0xFF63452A), // Agrax Earthshade
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        paintSelections: getSamplePaintSelectionsForOrks(),
      ),
      Palette(
        id: 'palette-003',
        name: 'Imperial Guard',
        imagePath: 'assets/images/placeholder.jpeg',
        colors: [
          const Color(0xFF2A3439), // German Grey (Vallejo)
          const Color(0xFFB7975F), // Zandri Dust
          const Color(0xFF9A0F0F), // Blood for the Blood God
          const Color(0xFF85714D), // Retributor Armour
          const Color(0xFF69385C), // Druchii Violet
          const Color(0xFF800000), // Hull Red (Vallejo)
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        paintSelections: getSamplePaintSelectionsForImperialGuard(),
      ),
      // Añadir más paletas de ejemplo
      Palette(
        id: 'palette-004',
        name: 'Necron Dynasty',
        imagePath: 'assets/images/placeholder.jpeg',
        colors: [
          const Color(0xFFC0C0C0), // Silver
          const Color(0xFF2A3439), // German Grey
          const Color(0xFF1A1A1A), // Nuln Oil
          const Color(0xFF00401A), // Caliban Green
          const Color(0xFF7ABAD4), // Nihilakh Oxide
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        paintSelections: getSamplePaintSelectionsForNecrons(),
      ),
      Palette(
        id: 'palette-005',
        name: 'Eldar Craftworld',
        imagePath: 'assets/images/placeholder.jpeg',
        colors: [
          const Color(0xFFFBB81C), // Averland Sunset
          const Color(0xFF0D407F), // Macragge Blue
          const Color(0xFF9A1115), // Mephiston Red
          const Color(0xFFD6D5C3), // Screaming Skull
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        paintSelections: getSamplePaintSelectionsForEldar(),
      ),
      Palette(
        id: 'palette-006',
        name: 'T\'au Sept',
        imagePath: 'assets/images/placeholder.jpeg',
        colors: [
          const Color(0xFF2A3439), // German Grey
          const Color(0xFFC0C0C0), // Silver
          const Color(0xFF00401A), // Caliban Green
          const Color(0xFF9A1115), // Mephiston Red
          const Color(0xFF31A2F2), // Lothern Blue
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
        paintSelections: getSamplePaintSelectionsForTau(),
      ),
      Palette(
        id: 'palette-007',
        name: 'Blood Angels',
        imagePath: 'assets/images/placeholder.jpeg',
        colors: [
          const Color(0xFF9A1115), // Mephiston Red
          const Color(0xFF85714D), // Retributor Armour
          const Color(0xFF231F20), // Abaddon Black
          const Color(0xFF63452A), // Agrax Earthshade
          const Color(0xFFBE0B0C), // Evil Sunz Scarlet
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 22)),
        paintSelections: getSamplePaintSelectionsForBloodAngels(),
      ),
      Palette(
        id: 'palette-008',
        name: 'Death Guard',
        imagePath: 'assets/images/placeholder.jpeg',
        colors: [
          const Color(0xFFB7975F), // Zandri Dust
          const Color(0xFF3B342E), // Typhus Corrosion
          const Color(0xFF63452A), // Agrax Earthshade
          const Color(0xFF9A0F0F), // Blood for the Blood God
          const Color(0xFF7ABAD4), // Nihilakh Oxide
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        paintSelections: getSamplePaintSelectionsForDeathGuard(),
      ),
      Palette(
        id: 'palette-009',
        name: 'Tyranid Hive',
        imagePath: 'assets/images/placeholder.jpeg',
        colors: [
          const Color(0xFF9A1115), // Mephiston Red
          const Color(0xFF69385C), // Druchii Violet
          const Color(0xFF00401A), // Caliban Green
          const Color(0xFFFBB81C), // Averland Sunset
          const Color(0xFF231F20), // Abaddon Black
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 28)),
        paintSelections: getSamplePaintSelectionsForTyranids(),
      ),
      Palette(
        id: 'palette-010',
        name: 'Adeptus Custodes',
        imagePath: 'assets/images/placeholder.jpeg',
        colors: [
          const Color(0xFF85714D), // Retributor Armour
          const Color(0xFF914B28), // Reikland Fleshshade
          const Color(0xFF231F20), // Abaddon Black
          const Color(0xFF9A1115), // Mephiston Red
          const Color(0xFFD6D5C3), // Screaming Skull
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 32)),
        paintSelections: getSamplePaintSelectionsForCustodes(),
      ),
    ];
  }

  /// Returns sample paint selections for Space Marines palette
  static List<PaintSelection> getSamplePaintSelectionsForSpaceMarines() {
    return [
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
        colorHex: '#C0C5C9',
        paintId: 'cit-layer-005',
        paintName: 'Runefang Steel',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 95,
        paintColorHex: '#C0C5C9',
      ),
      PaintSelection(
        colorHex: '#834F46',
        paintId: 'cit-base-006',
        paintName: 'Bugmans Glow',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 98,
        paintColorHex: '#834F46',
      ),
      PaintSelection(
        colorHex: '#1A1A1A',
        paintId: 'cit-shade-001',
        paintName: 'Nuln Oil',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 100,
        paintColorHex: '#1A1A1A',
      ),
      PaintSelection(
        colorHex: '#31A2F2',
        paintId: 'cit-layer-004',
        paintName: 'Lothern Blue',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 97,
        paintColorHex: '#31A2F2',
      ),
    ];
  }

  /// Returns sample paint selections for Orks palette
  static List<PaintSelection> getSamplePaintSelectionsForOrks() {
    return [
      PaintSelection(
        colorHex: '#00401A',
        paintId: 'cit-base-004',
        paintName: 'Caliban Green',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 100,
        paintColorHex: '#00401A',
      ),
      PaintSelection(
        colorHex: '#FBB81C',
        paintId: 'cit-base-007',
        paintName: 'Averland Sunset',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 98,
        paintColorHex: '#FBB81C',
      ),
      PaintSelection(
        colorHex: '#9A1115',
        paintId: 'cit-base-002',
        paintName: 'Mephiston Red',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 99,
        paintColorHex: '#9A1115',
      ),
      PaintSelection(
        colorHex: '#63452A',
        paintId: 'cit-shade-002',
        paintName: 'Agrax Earthshade',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 100,
        paintColorHex: '#63452A',
      ),
    ];
  }

  /// Returns sample paint selections for Imperial Guard palette
  static List<PaintSelection> getSamplePaintSelectionsForImperialGuard() {
    return [
      PaintSelection(
        colorHex: '#2A3439',
        paintId: 'val-model-002',
        paintName: 'German Grey',
        paintBrand: 'Vallejo',
        brandAvatar: 'V',
        matchPercentage: 97,
        paintColorHex: '#2A3439',
      ),
      PaintSelection(
        colorHex: '#B7975F',
        paintId: 'cit-base-008',
        paintName: 'Zandri Dust',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 95,
        paintColorHex: '#B7975F',
      ),
      PaintSelection(
        colorHex: '#9A0F0F',
        paintId: 'cit-tech-001',
        paintName: 'Blood for the Blood God',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 100,
        paintColorHex: '#9A0F0F',
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
      PaintSelection(
        colorHex: '#69385C',
        paintId: 'cit-shade-004',
        paintName: 'Druchii Violet',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 99,
        paintColorHex: '#69385C',
      ),
      PaintSelection(
        colorHex: '#800000',
        paintId: 'val-model-001',
        paintName: 'Hull Red',
        paintBrand: 'Vallejo',
        brandAvatar: 'V',
        matchPercentage: 96,
        paintColorHex: '#800000',
      ),
    ];
  }

  /// Returns sample paint selections for Necron Dynasty palette
  static List<PaintSelection> getSamplePaintSelectionsForNecrons() {
    return [
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
        colorHex: '#2A3439',
        paintId: 'val-model-002',
        paintName: 'German Grey',
        paintBrand: 'Vallejo',
        brandAvatar: 'V',
        matchPercentage: 95,
        paintColorHex: '#2A3439',
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
      PaintSelection(
        colorHex: '#00401A',
        paintId: 'cit-base-004',
        paintName: 'Caliban Green',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 94,
        paintColorHex: '#00401A',
      ),
      PaintSelection(
        colorHex: '#7ABAD4',
        paintId: 'cit-tech-002',
        paintName: 'Nihilakh Oxide',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 98,
        paintColorHex: '#7ABAD4',
      ),
    ];
  }

  /// Returns sample paint selections for Eldar Craftworld palette
  static List<PaintSelection> getSamplePaintSelectionsForEldar() {
    return [
      PaintSelection(
        colorHex: '#FBB81C',
        paintId: 'cit-base-007',
        paintName: 'Averland Sunset',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 96,
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
        matchPercentage: 97,
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
    ];
  }

  /// Returns sample paint selections for T'au Sept palette
  static List<PaintSelection> getSamplePaintSelectionsForTau() {
    return [
      PaintSelection(
        colorHex: '#2A3439',
        paintId: 'val-model-002',
        paintName: 'German Grey',
        paintBrand: 'Vallejo',
        brandAvatar: 'V',
        matchPercentage: 96,
        paintColorHex: '#2A3439',
      ),
      PaintSelection(
        colorHex: '#C0C0C0',
        paintId: 'val-model-003',
        paintName: 'Silver',
        paintBrand: 'Vallejo',
        brandAvatar: 'V',
        matchPercentage: 95,
        paintColorHex: '#C0C0C0',
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
        colorHex: '#9A1115',
        paintId: 'cit-base-002',
        paintName: 'Mephiston Red',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 94,
        paintColorHex: '#9A1115',
      ),
      PaintSelection(
        colorHex: '#31A2F2',
        paintId: 'cit-layer-004',
        paintName: 'Lothern Blue',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 98,
        paintColorHex: '#31A2F2',
      ),
    ];
  }

  /// Returns sample paint selections for Blood Angels palette
  static List<PaintSelection> getSamplePaintSelectionsForBloodAngels() {
    return [
      PaintSelection(
        colorHex: '#9A1115',
        paintId: 'cit-base-002',
        paintName: 'Mephiston Red',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 99,
        paintColorHex: '#9A1115',
      ),
      PaintSelection(
        colorHex: '#85714D',
        paintId: 'cit-base-005',
        paintName: 'Retributor Armour',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 95,
        paintColorHex: '#85714D',
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
        colorHex: '#63452A',
        paintId: 'cit-shade-002',
        paintName: 'Agrax Earthshade',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 97,
        paintColorHex: '#63452A',
      ),
      PaintSelection(
        colorHex: '#BE0B0C',
        paintId: 'cit-layer-002',
        paintName: 'Evil Sunz Scarlet',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 96,
        paintColorHex: '#BE0B0C',
      ),
    ];
  }

  /// Returns sample paint selections for Death Guard palette
  static List<PaintSelection> getSamplePaintSelectionsForDeathGuard() {
    return [
      PaintSelection(
        colorHex: '#B7975F',
        paintId: 'cit-base-008',
        paintName: 'Zandri Dust',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 97,
        paintColorHex: '#B7975F',
      ),
      PaintSelection(
        colorHex: '#3B342E',
        paintId: 'cit-tech-003',
        paintName: 'Typhus Corrosion',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 96,
        paintColorHex: '#3B342E',
      ),
      PaintSelection(
        colorHex: '#63452A',
        paintId: 'cit-shade-002',
        paintName: 'Agrax Earthshade',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 98,
        paintColorHex: '#63452A',
      ),
      PaintSelection(
        colorHex: '#9A0F0F',
        paintId: 'cit-tech-001',
        paintName: 'Blood for the Blood God',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 95,
        paintColorHex: '#9A0F0F',
      ),
      PaintSelection(
        colorHex: '#7ABAD4',
        paintId: 'cit-tech-002',
        paintName: 'Nihilakh Oxide',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 94,
        paintColorHex: '#7ABAD4',
      ),
    ];
  }

  /// Returns sample paint selections for Tyranid Hive palette
  static List<PaintSelection> getSamplePaintSelectionsForTyranids() {
    return [
      PaintSelection(
        colorHex: '#9A1115',
        paintId: 'cit-base-002',
        paintName: 'Mephiston Red',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 98,
        paintColorHex: '#9A1115',
      ),
      PaintSelection(
        colorHex: '#69385C',
        paintId: 'cit-shade-004',
        paintName: 'Druchii Violet',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 97,
        paintColorHex: '#69385C',
      ),
      PaintSelection(
        colorHex: '#00401A',
        paintId: 'cit-base-004',
        paintName: 'Caliban Green',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 96,
        paintColorHex: '#00401A',
      ),
      PaintSelection(
        colorHex: '#FBB81C',
        paintId: 'cit-base-007',
        paintName: 'Averland Sunset',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 95,
        paintColorHex: '#FBB81C',
      ),
      PaintSelection(
        colorHex: '#231F20',
        paintId: 'cit-base-001',
        paintName: 'Abaddon Black',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 99,
        paintColorHex: '#231F20',
      ),
    ];
  }

  /// Returns sample paint selections for Adeptus Custodes palette
  static List<PaintSelection> getSamplePaintSelectionsForCustodes() {
    return [
      PaintSelection(
        colorHex: '#85714D',
        paintId: 'cit-base-005',
        paintName: 'Retributor Armour',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 99,
        paintColorHex: '#85714D',
      ),
      PaintSelection(
        colorHex: '#914B28',
        paintId: 'cit-shade-003',
        paintName: 'Reikland Fleshshade',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 96,
        paintColorHex: '#914B28',
      ),
      PaintSelection(
        colorHex: '#231F20',
        paintId: 'cit-base-001',
        paintName: 'Abaddon Black',
        paintBrand: 'Citadel',
        brandAvatar: 'C',
        matchPercentage: 97,
        paintColorHex: '#231F20',
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
        int.parse(paint.hex.substring(1, 7), radix: 16) + 0xFF000000,
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
          'colorHex': paint.hex,
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
