import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final Function(List<Color> colors) onColorsSelected;
  final Function(File)? onImageSelected;

  const ImageColorPicker({
    Key? key,
    this.imageFile,
    required this.onColorsSelected,
    this.onImageSelected,
  }) : super(key: key);

  @override
  State<ImageColorPicker> createState() => _ImageColorPickerState();
}

class _ImageColorPickerState extends State<ImageColorPicker> {
  ui.Image? _image;
  ByteData? _imageBytes;
  int _imageWidth = 0;
  int _imageHeight = 0;
  bool _isLoading = false;
  List<_ColorPoint> _selectedColors = [];
  File? _currentImageFile;
  final ImagePicker _picker = ImagePicker();

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

  // Para zoom
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _currentImageFile = widget.imageFile;
    if (_currentImageFile != null) {
      _loadImage();
    }
  }

  @override
  void didUpdateWidget(ImageColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageFile != oldWidget.imageFile && widget.imageFile != null) {
      _currentImageFile = widget.imageFile;
      _loadImage();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedColors.clear();
        _currentImageFile = File(image.path);
      });

      if (widget.onImageSelected != null) {
        widget.onImageSelected!(File(image.path));
      }

      _loadImage();
    }
  }

  Future<void> _getImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedColors.clear();
        _currentImageFile = File(image.path);
      });

      if (widget.onImageSelected != null) {
        widget.onImageSelected!(File(image.path));
      }

      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (_currentImageFile == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final bytes = await _currentImageFile!.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      setState(() {
        _image = image;
        _imageBytes = byteData;
        _imageWidth = image.width;
        _imageHeight = image.height;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading image: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color? _getPixelColor(double relativeX, double relativeY) {
    if (_image == null || _imageBytes == null) return null;

    try {
      // Calcular la posición del pixel en la imagen original
      int pixelX = (relativeX * _imageWidth).round();
      int pixelY = (relativeY * _imageHeight).round();

      // Verificar límites
      if (pixelX < 0 ||
          pixelX >= _imageWidth ||
          pixelY < 0 ||
          pixelY >= _imageHeight) {
        return null;
      }

      // Calcular la posición en bytes (4 bytes por pixel: RGBA)
      int bytePosition = 4 * (pixelY * _imageWidth + pixelX);

      // Verificar que no nos pasamos del tamaño
      if (bytePosition < 0 || bytePosition + 3 >= _imageBytes!.lengthInBytes) {
        return null;
      }

      // Leer los valores RGBA
      int r = _imageBytes!.getUint8(bytePosition);
      int g = _imageBytes!.getUint8(bytePosition + 1);
      int b = _imageBytes!.getUint8(bytePosition + 2);
      int a = _imageBytes!.getUint8(bytePosition + 3);

      return Color.fromARGB(a, r, g, b);
    } catch (e) {
      print('Error getting pixel color: $e');
      return null;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _handleImageTap(TapDownDetails details) {
    if (_image == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);

    // Obtener el tamaño del widget
    final renderSize = box.size;

    // Ajustar según el zoom actual
    final Matrix4 transform = _transformationController.value;
    final Matrix4 inverseTransform = Matrix4.inverted(transform);
    final Offset adjustedPosition = MatrixUtils.transformPoint(
      inverseTransform,
      localPosition,
    );

    // Calcular la posición relativa
    final double relativeX = adjustedPosition.dx / renderSize.width;
    final double relativeY = adjustedPosition.dy / renderSize.height;

    // Verificar que está dentro de los límites
    if (relativeX < 0 || relativeX > 1 || relativeY < 0 || relativeY > 1) {
      return;
    }

    // Obtener el color
    final color = _getPixelColor(relativeX, relativeY);

    if (color != null) {
      setState(() {
        _selectedColors.add(
          _ColorPoint(
            x: relativeX,
            y: relativeY,
            color: color,
            hex: _colorToHex(color),
          ),
        );
      });

      widget.onColorsSelected(_selectedColors.map((p) => p.color).toList());
    }
  }

  void _removeColor(int index) {
    setState(() {
      _selectedColors.removeAt(index);
    });
    widget.onColorsSelected(_selectedColors.map((p) => p.color).toList());
  }

  void _clearColors() {
    setState(() {
      _selectedColors.clear();
    });
    widget.onColorsSelected([]);
  }

  void _toggleBrandSelection(String brandId) {
    setState(() {
      final index = _availableBrands.indexWhere((brand) => brand.id == brandId);
      if (index != -1) {
        _availableBrands[index].isSelected =
            !_availableBrands[index].isSelected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mostrar imagen o selector de imagen
        _currentImageFile == null
            ? _buildImageSelector()
            : _buildImageContent(),
      ],
    );
  }

  Widget _buildImageSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_search,
            size: 80,
            color: isDarkMode ? Colors.grey[500] : Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            'Select an image to find matching colors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[300] : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionButton(
                icon: Icons.photo_camera,
                label: 'Camera',
                onTap: _getImageFromCamera,
              ),
              const SizedBox(width: 40),
              _buildOptionButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: _getImageFromGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: isDarkMode ? Colors.grey[850] : null,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              IconButton(
                icon: Icon(
                  Icons.photo_camera,
                  color: isDarkMode ? Colors.grey[300] : null,
                ),
                tooltip: 'Take photo',
                onPressed: _getImageFromCamera,
              ),
              IconButton(
                icon: Icon(
                  Icons.photo_library,
                  color: isDarkMode ? Colors.grey[300] : null,
                ),
                tooltip: 'Select from gallery',
                onPressed: _getImageFromGallery,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.zoom_out_map,
                  color: isDarkMode ? Colors.grey[300] : null,
                ),
                tooltip: 'Reset zoom',
                onPressed: () {
                  setState(() {
                    _transformationController.value = Matrix4.identity();
                  });
                },
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Use two fingers to zoom • Tap to select a color',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),

        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: GestureDetector(
            onTapDown: _handleImageTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              child: Stack(
                children: [
                  Center(
                    child: Image.file(_currentImageFile!, fit: BoxFit.contain),
                  ),

                  for (int i = 0; i < _selectedColors.length; i++)
                    Positioned(
                      left:
                          _selectedColors[i].x *
                              MediaQuery.of(context).size.width -
                          10,
                      top: _selectedColors[i].y * 300 - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedColors[i].color,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  _isLightColor(_selectedColors[i].color)
                                      ? Colors.black
                                      : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
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
                    _getImageFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImageFromCamera();
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
