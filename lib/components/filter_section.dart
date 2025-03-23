import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// Componente para la sección de filtros de la biblioteca de pinturas
class FilterSection extends StatelessWidget {
  /// Marcas disponibles para filtrar
  final List<String> brands;

  /// Categorías disponibles para filtrar
  final List<String> categories;

  /// Marca seleccionada actualmente
  final String selectedBrand;

  /// Categoría seleccionada actualmente
  final String selectedCategory;

  /// Color seleccionado actualmente
  final Color? selectedColor;

  /// Función a llamar cuando se selecciona una marca
  final Function(String) onBrandSelected;

  /// Función a llamar cuando se selecciona una categoría
  final Function(String) onCategorySelected;

  /// Función a llamar cuando se selecciona un color
  final Function(Color?) onColorSelected;

  /// Función a llamar para resetear todos los filtros
  final VoidCallback onReset;

  /// Constructor del componente de filtros
  const FilterSection({
    super.key,
    required this.brands,
    required this.categories,
    required this.selectedBrand,
    required this.selectedCategory,
    this.selectedColor,
    required this.onBrandSelected,
    required this.onCategorySelected,
    required this.onColorSelected,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
                onPressed: onReset,
              ),
            ],
          ),
        ),

        // Filtro por marca
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Brand:'),
              const SizedBox(height: 4),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      brands.map((brand) {
                        final isSelected = brand == selectedBrand;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(brand),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                onBrandSelected(brand);
                              }
                            },
                            backgroundColor: Theme.of(context).cardColor,
                            selectedColor: AppTheme.primaryBlue.withOpacity(
                              0.2,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primaryBlue : null,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Filtro por categoría
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category:'),
              const SizedBox(height: 4),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      categories.map((category) {
                        final isSelected = category == selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                onCategorySelected(category);
                              }
                            },
                            backgroundColor: Theme.of(context).cardColor,
                            selectedColor: AppTheme.primaryBlue.withOpacity(
                              0.2,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primaryBlue : null,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Filtro por color
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Color:'),
                  if (selectedColor != null)
                    TextButton(
                      child: const Text('Clear'),
                      onPressed: () => onColorSelected(null),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Colores comunes para elegir
                    _buildColorCircle(Colors.red, 'Red'),
                    _buildColorCircle(Colors.blue, 'Blue'),
                    _buildColorCircle(Colors.green, 'Green'),
                    _buildColorCircle(Colors.yellow, 'Yellow'),
                    _buildColorCircle(Colors.orange, 'Orange'),
                    _buildColorCircle(Colors.purple, 'Purple'),
                    _buildColorCircle(Colors.brown, 'Brown'),
                    _buildColorCircle(Colors.black, 'Black'),
                    _buildColorCircle(Colors.white, 'White'),
                    _buildColorCircle(Colors.grey, 'Grey'),
                    _buildColorCircle(const Color(0xFFc0c0c0), 'Silver'),
                    _buildColorCircle(const Color(0xFFD4AF37), 'Gold'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye un círculo de color seleccionable
  Widget _buildColorCircle(Color color, String label) {
    final isSelected =
        selectedColor != null && selectedColor!.value == color.value;

    return GestureDetector(
      onTap: () => onColorSelected(color),
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Tooltip(
          message: label,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ]
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}
