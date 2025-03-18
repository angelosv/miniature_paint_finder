import 'dart:io';
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/components/color_chip.dart';
import 'package:miniature_paint_finder/components/image_color_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/basic_image_viewer.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _getImage(ImageSource.camera),
                    color: AppTheme.primaryBlue,
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _getImage(ImageSource.gallery),
                    color: AppTheme.pinkColor,
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    Navigator.pop(context);
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedImage != null) {
      return ColorSearchView(
        imageFile: _selectedImage!,
        onReset: () {
          setState(() {
            _selectedImage = null;
          });
        },
      );
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find Paints by Color',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Enter color name or hex code',
                  prefixIcon: Icon(Icons.color_lens),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Or use an image to match colors',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'Popular Colors',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ColorChip(color: Colors.red[900]!, label: 'Red'),
                  ColorChip(color: Colors.blue[800]!, label: 'Blue'),
                  ColorChip(color: Colors.green[700]!, label: 'Green'),
                  ColorChip(color: Colors.amber[600]!, label: 'Yellow'),
                  ColorChip(color: Colors.purple[500]!, label: 'Purple'),
                  ColorChip(color: Colors.black, label: 'Black'),
                  ColorChip(color: Colors.white, label: 'White'),
                  ColorChip(color: Colors.grey, label: 'Grey'),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: _showImageSourceModal,
            shape: const CircleBorder(),
            backgroundColor: AppTheme.primaryBlue,
            child: const Icon(Icons.camera_alt, size: 28, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class ColorSearchView extends StatefulWidget {
  final File imageFile;
  final VoidCallback onReset;

  const ColorSearchView({
    super.key,
    required this.imageFile,
    required this.onReset,
  });

  @override
  State<ColorSearchView> createState() => _ColorSearchViewState();
}

class _ColorSearchViewState extends State<ColorSearchView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Color Finder',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onReset,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Ruta de la imagen: ${widget.imageFile.path}'),
                Text(
                  'Tamaño del archivo: ${(widget.imageFile.lengthSync() / 1024).toStringAsFixed(2)} KB',
                ),
                Text(
                  '¿Existe el archivo? ${widget.imageFile.existsSync() ? 'Sí' : 'No'}',
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      widget.imageFile,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text('Error: $error'),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Intentando mostrar imagen en: ${widget.imageFile.path}',
                        ),
                      ),
                    );
                  },
                  child: const Text('Verificar imagen'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400,
                  child: BasicImageViewer(imageFile: widget.imageFile),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
