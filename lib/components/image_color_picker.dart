import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miniature_paint_finder/services/image_upload_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:image/image.dart' as img;

// Modelo para representar una marca de pintura
class PaintBrand {
  final String id;
  final String name;
  final String logoUrl;
  bool isSelected;

  PaintBrand({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.isSelected = false,
  });
}

class ImageColorPicker extends StatefulWidget {
  final File? imageFile;
  final Function(List<Color>) onColorsSelected;
  final Function(File) onImageSelected;
  final Function(String)? onImageUploaded;

  const ImageColorPicker({
    super.key,
    this.imageFile,
    required this.onColorsSelected,
    required this.onImageSelected,
    this.onImageUploaded,
  });

  @override
  State<ImageColorPicker> createState() => _ImageColorPickerState();
}

class _ImageColorPickerState extends State<ImageColorPicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  final ImageUploadService _imageUploadService = ImageUploadService();
  List<Color> _selectedColors = [];
  final TransformationController _transformationController = TransformationController();

  // Lista de marcas de pinturas disponibles
  final List<PaintBrand> _availableBrands = [
    PaintBrand(
      id: 'citadel',
      name: 'Citadel',
      logoUrl:
          'https://www.games-workshop.com/resources/catalog/product/920x950/99179950001_CitadelColourContrastPaintsAll.jpg',
    ),
    PaintBrand(
      id: 'vallejo',
      name: 'Vallejo',
      logoUrl:
          'https://m.media-amazon.com/images/I/71FQ+grLCFL._AC_UF1000,1000_QL80_.jpg',
    ),
    PaintBrand(
      id: 'armypainter',
      name: 'Army Painter',
      logoUrl:
          'https://i0.wp.com/www.thearmypainter.com/wp-content/uploads/2022/03/TAP_Logo_on-White.png',
    ),
    PaintBrand(
      id: 'scale75',
      name: 'Scale 75',
      logoUrl:
          'https://i0.wp.com/scalemodellingchannel.com/wp-content/uploads/2018/08/scale75-logo-colored.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        widget.onImageSelected(imageFile);
        
        // Subir la imagen
        setState(() {
          _isUploading = true;
          _selectedColors.clear();
        });

        try {
          final String imageUrl = await _imageUploadService.uploadImage(imageFile);
          if (widget.onImageUploaded != null) {
            widget.onImageUploaded!(imageUrl);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          setState(() {
            _isUploading = false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleImageTap(TapDownDetails details) {
    if (widget.imageFile == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final Size size = box.size;
    
    // Calcular la posición relativa en la imagen
    final double x = localPosition.dx / size.width;
    final double y = localPosition.dy / size.height;

    // Obtener el color en la posición seleccionada
    final image = img.decodeImage(widget.imageFile!.readAsBytesSync());
    if (image != null) {
      final pixelX = (x * image.width).round();
      final pixelY = (y * image.height).round();
      
      if (pixelX >= 0 && pixelX < image.width && pixelY >= 0 && pixelY < image.height) {
        final pixel = image.getPixel(pixelX, pixelY);
        final color = Color.fromARGB(
          255, // Alpha fijo a 255 (opaco)
          pixel.r.toInt(), // Red
          pixel.g.toInt(), // Green
          pixel.b.toInt(), // Blue
        );

        setState(() {
          if (_selectedColors.length < 5) { // Limitar a 5 colores
            _selectedColors.add(color);
            widget.onColorsSelected(_selectedColors);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        if (widget.imageFile != null)
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTapDown: _handleImageTap,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Image.file(
                        widget.imageFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    widget.onImageSelected(File(''));
                    setState(() {
                      _selectedColors.clear();
                    });
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image,
                  size: 48,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  'No image selected',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        if (widget.imageFile != null) ...[
          const SizedBox(height: 8),
          Text(
            'Tap on the image to select colors (max 5)',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOptionButton(
              icon: Icons.photo_camera,
              label: 'Camera',
              onTap: _isUploading ? null : () => _getImage(ImageSource.camera),
            ),
            const SizedBox(width: 40),
            _buildOptionButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onTap: _isUploading ? null : () => _getImage(ImageSource.gallery),
            ),
          ],
        ),
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isLightColor(Color color) {
    return (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) /
            255 >
        0.5;
  }

  // Método para mostrar el diálogo de selección de imagen
  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose image source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class _ColorPoint {
  final double x;
  final double y;
  final Color color;
  final String hex;

  _ColorPoint({
    required this.x,
    required this.y,
    required this.color,
    required this.hex,
  });
}
