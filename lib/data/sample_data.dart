import 'package:miniature_paint_finder/models/paint.dart';

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
}
