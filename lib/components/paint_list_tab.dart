import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miniature_paint_finder/components/category_card.dart';
import 'package:miniature_paint_finder/components/image_color_picker.dart';
import 'package:miniature_paint_finder/components/paint_card.dart';
import 'package:miniature_paint_finder/components/paint_grid_card.dart';
import 'package:miniature_paint_finder/components/palette_card.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class PaintListTab extends StatefulWidget {
  const PaintListTab({super.key});

  @override
  State<PaintListTab> createState() => _PaintListTabState();
}

class _PaintListTabState extends State<PaintListTab> {
  File? _imageFile;
  bool _showColorPicker = false;
  final ImagePicker _picker = ImagePicker();
  Color _selectedColor = Colors.white;
  final List<Color> _pickedColors = [];

  Future<void> _getImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _showColorPicker = true;
      });
    }
  }

  void _onColorPicked(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _onColorsSelected(List<Color> colors) {
    setState(() {
      if (colors.isNotEmpty) {
        _selectedColor = colors.last;
        _pickedColors.clear();
        _pickedColors.addAll(colors);
      }
    });
  }

  void _addColor() {
    if (_selectedColor != Colors.transparent) {
      setState(() {
        if (!_pickedColors.contains(_selectedColor)) {
          _pickedColors.add(_selectedColor);
        }
      });
    }
  }

  void _reset() {
    setState(() {
      _showColorPicker = false;
      _imageFile = null;
      _pickedColors.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paints = SampleData.getPaints();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de puntos (similar a la tarjeta azul en la imagen)
            Card(
              color: AppTheme.primaryBlue,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paint Search',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload an image and find the color palette',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_showColorPicker) {
                          _reset();
                        } else {
                          // Mostrar diálogo para seleccionar entre cámara y galería
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Select Image Source'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: const Text('Take Photo'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _getImage(ImageSource.camera);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
                                      title: const Text('Choose from Gallery'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _getImage(ImageSource.gallery);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                      child: Text(
                        _showColorPicker ? 'Cancel' : 'Search paints',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Color picker section
            if (_showColorPicker && _imageFile != null) ...[
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pick Colors from Image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Componente de selección de color de imagen
                      ImageColorPicker(
                        imageFile: _imageFile!,
                        onColorsSelected: _onColorsSelected,
                      ),

                      const SizedBox(height: 16),

                      // Botón para añadir el color seleccionado a la lista
                      ElevatedButton.icon(
                        onPressed: _addColor,
                        icon: const Icon(Icons.add),
                        label: const Text('Add to selected colors'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Lista de colores seleccionados
                      if (_pickedColors.isNotEmpty) ...[
                        const Text(
                          'Selected Colors:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedColors.length,
                            itemBuilder: (context, index) {
                              final color = _pickedColors[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color,
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    Text(
                                      '#${color.value.toRadixString(16).toUpperCase().substring(2)}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botón para guardar
                        ElevatedButton.icon(
                          onPressed:
                              _pickedColors.isNotEmpty
                                  ? () {
                                    // TODO: Implementar lógica para guardar los colores como pinturas
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Colors saved successfully!',
                                        ),
                                      ),
                                    );
                                    _reset();
                                  }
                                  : null,
                          icon: const Icon(Icons.save),
                          label: const Text('Save as new paints'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            if (!_showColorPicker) ...[
              const SizedBox(height: 24),

              // Sección de Recent Palettes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Palettes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(onPressed: () {}, child: const Text('See all')),
                ],
              ),

              const SizedBox(height: 12),

              // Lista horizontal de paletas
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: SampleData.getPalettes().length,
                  itemBuilder: (context, index) {
                    return PaletteCard(
                      palette: SampleData.getPalettes()[index],
                      onTap: () {
                        // TODO: Implementar acción al tocar una paleta
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Sección de Categorías (como los botones de Subjects en la imagen)
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  CategoryCard(
                    title: 'Citadel',
                    count: 7,
                    color: AppTheme.primaryBlue,
                    onTap: () {},
                  ),
                  CategoryCard(
                    title: 'Vallejo',
                    count: 3,
                    color: AppTheme.pinkColor,
                    onTap: () {},
                  ),
                  CategoryCard(
                    title: 'Army Painter',
                    count: 0,
                    color: AppTheme.purpleColor,
                    onTap: () {},
                  ),
                  CategoryCard(
                    title: 'Scale75',
                    count: 0,
                    color: AppTheme.orangeColor,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Lista de todas las pinturas
              Text(
                'All Paints',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paints.length,
                itemBuilder: (context, index) {
                  final paint = paints[index];
                  return PaintCard(paint: paint);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
