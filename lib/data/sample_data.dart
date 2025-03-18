import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';

class SampleData {
  static List<Paint> getPaints() {
    return [
      Paint(
        id: '1',
        name: 'Abaddon Black',
        brand: 'Citadel',
        colorHex: '#231F20',
        category: 'Base',
      ),
      Paint(
        id: '2',
        name: 'Retributor Armour',
        brand: 'Citadel',
        colorHex: '#85714D',
        category: 'Base',
        isMetallic: true,
      ),
      Paint(
        id: '3',
        name: 'Mephiston Red',
        brand: 'Citadel',
        colorHex: '#9A1115',
        category: 'Base',
      ),
      Paint(
        id: '4',
        name: 'Macragge Blue',
        brand: 'Citadel',
        colorHex: '#0D407F',
        category: 'Base',
      ),
      Paint(
        id: '5',
        name: 'Caliban Green',
        brand: 'Citadel',
        colorHex: '#00401A',
        category: 'Base',
      ),
      Paint(
        id: '6',
        name: 'Screaming Skull',
        brand: 'Citadel',
        colorHex: '#D6D5C3',
        category: 'Layer',
      ),
      Paint(
        id: '7',
        name: 'Nuln Oil',
        brand: 'Citadel',
        colorHex: '#1A1A1A',
        category: 'Shade',
        isTransparent: true,
      ),
      Paint(
        id: '8',
        name: 'Hull Red',
        brand: 'Vallejo',
        colorHex: '#800000',
        category: 'Model Color',
      ),
      Paint(
        id: '9',
        name: 'German Grey',
        brand: 'Vallejo',
        colorHex: '#2A3439',
        category: 'Model Color',
      ),
      Paint(
        id: '10',
        name: 'Silver',
        brand: 'Vallejo',
        colorHex: '#C0C0C0',
        category: 'Model Color',
        isMetallic: true,
      ),
    ];
  }

  static List<Palette> getPalettes() {
    return [
      Palette(
        id: '1',
        name: 'Space Marine Armor',
        imagePath: 'assets/images/placeholder1.jpg',
        colors: [
          const Color(0xFF0D407F), // Macragge Blue
          const Color(0xFF231F20), // Abaddon Black
          const Color(0xFFC0C0C0), // Silver
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Palette(
        id: '2',
        name: 'Tyranid Scheme',
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
        id: '3',
        name: 'Imperial Guard',
        imagePath: 'assets/images/placeholder3.jpg',
        colors: [
          const Color(0xFF2A3439), // German Grey
          const Color(0xFF85714D), // Retributor Armour
          const Color(0xFF1A1A1A), // Nuln Oil
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Palette(
        id: '4',
        name: 'Necron Warriors',
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
        id: '5',
        name: 'Eldar Aspect Warriors',
        imagePath: 'assets/images/placeholder5.jpg',
        colors: [
          const Color(0xFF0D407F), // Macragge Blue
          const Color(0xFF9A1115), // Mephiston Red
          const Color(0xFFD6D5C3), // Screaming Skull
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Palette(
        id: '6',
        name: 'Tau Fire Warriors',
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
        id: '7',
        name: 'Ork Boyz',
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
        id: '8',
        name: 'Chaos Space Marines',
        imagePath: 'assets/images/placeholder8.jpg',
        colors: [
          const Color(0xFF9A1115), // Mephiston Red
          const Color(0xFF231F20), // Abaddon Black
          const Color(0xFF85714D), // Retributor Armour
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      Palette(
        id: '9',
        name: 'Death Guard',
        imagePath: 'assets/images/placeholder9.jpg',
        colors: [
          const Color(0xFFD6D5C3), // Screaming Skull
          const Color(0xFF00401A), // Caliban Green
          const Color(0xFF1A1A1A), // Nuln Oil
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Palette(
        id: '10',
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
}
