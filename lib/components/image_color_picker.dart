import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ImageColorPicker extends StatefulWidget {
  final File imageFile;
  final Function(List<Color> colors) onColorsSelected;

  const ImageColorPicker({
    Key? key,
    required this.imageFile,
    required this.onColorsSelected,
  }) : super(key: key);

  @override
  State<ImageColorPicker> createState() => _ImageColorPickerState();
}

class _ImageColorPickerState extends State<ImageColorPicker> {
  ui.Image? _image;
  ByteData? _imageBytes;
  int _imageWidth = 0;
  int _imageHeight = 0;
  bool _isLoading = true;
  List<_ColorPoint> _selectedColors = [];

  // Para zoom
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final bytes = await widget.imageFile.readAsBytes();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        // Instrucciones
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Utiliza dos dedos para hacer zoom • Toca para seleccionar un color',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),

        // Imagen con zoom
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: GestureDetector(
            onTapDown: _handleImageTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              child: Stack(
                children: [
                  // Imagen
                  Center(
                    child: Image.file(widget.imageFile, fit: BoxFit.contain),
                  ),

                  // Puntos de color
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

        // Lista de colores
        Container(
          height: 100,
          color: Colors.grey[200],
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Colores seleccionados (${_selectedColors.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_selectedColors.isNotEmpty)
                    TextButton(
                      onPressed: _clearColors,
                      child: const Text('Limpiar todo'),
                    ),
                ],
              ),

              Expanded(
                child:
                    _selectedColors.isEmpty
                        ? const Center(
                          child: Text(
                            'Toca la imagen para seleccionar colores',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        )
                        : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedColors.length,
                          itemBuilder: (context, index) {
                            final point = _selectedColors[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12, top: 4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: point.color,
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: -5,
                                        top: -5,
                                        child: GestureDetector(
                                          onTap: () => _removeColor(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 12,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    point.hex,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
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
