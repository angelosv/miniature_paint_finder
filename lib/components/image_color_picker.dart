import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorPoint {
  final Offset position;
  final Color color;
  final String hexCode;
  final String rgbCode;

  ColorPoint({
    required this.position,
    required this.color,
    required this.hexCode,
    required this.rgbCode,
  });
}

class ImageColorPicker extends StatefulWidget {
  final File imageFile;
  final Function(Color color) onColorPicked;

  const ImageColorPicker({
    Key? key,
    required this.imageFile,
    required this.onColorPicked,
  }) : super(key: key);

  @override
  State<ImageColorPicker> createState() => _ImageColorPickerState();
}

class _ImageColorPickerState extends State<ImageColorPicker> {
  ui.Image? _image;
  List<ColorPoint> _selectedPoints = [];
  bool _isImageLoading = true;
  final TransformationController _transformationController =
      TransformationController();

  final GlobalKey _imageKey = GlobalKey();

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
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();

      setState(() {
        _image = frameInfo.image;
        _isImageLoading = false;
      });
    } catch (e) {
      print('Error al cargar la imagen: $e');
    }
  }

  Future<Color> _getImagePixelColor(
    BuildContext context,
    Offset globalPosition,
  ) async {
    if (_image == null) return Colors.transparent;

    // Obtenemos el widget de imagen
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;

    // Convertimos la posición global a local
    final localPosition = renderBox.globalToLocal(globalPosition);

    // Calculamos la posición relativa (0-1) dentro del widget
    double dx = localPosition.dx / size.width;
    double dy = localPosition.dy / size.height;

    // Nos aseguramos de que estamos dentro de los límites
    if (dx < 0 || dx > 1 || dy < 0 || dy > 1) {
      return Colors.transparent;
    }

    try {
      // Calculamos la posición en pixels en la imagen original
      int px = (dx * _image!.width).floor();
      int py = (dy * _image!.height).floor();

      // Corregimos los límites
      px = math.max(0, math.min(px, _image!.width - 1));
      py = math.max(0, math.min(py, _image!.height - 1));

      // Obtenemos los datos de la imagen
      final ByteData? byteData = await _image!.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return Colors.transparent;

      // Calculamos el índice en el array de bytes
      final int index = (py * _image!.width + px) * 4;

      // Obtenemos los componentes RGBA
      final int r = byteData.getUint8(index);
      final int g = byteData.getUint8(index + 1);
      final int b = byteData.getUint8(index + 2);
      final int a = byteData.getUint8(index + 3);

      return Color.fromARGB(a, r, g, b);
    } catch (e) {
      print('Error al obtener el color: $e');
      return Colors.transparent;
    }
  }

  void _handleTapDown(TapDownDetails details) async {
    if (_image == null) return;

    try {
      final color = await _getImagePixelColor(
        _imageKey.currentContext!,
        details.globalPosition,
      );

      if (color != Colors.transparent) {
        final String hexCode =
            '#${color.value.toRadixString(16).toUpperCase().substring(2)}';
        final String rgbCode =
            'RGB(${color.red}, ${color.green}, ${color.blue})';

        // Convertimos la posición global a posición relativa al widget
        final RenderBox renderBox =
            _imageKey.currentContext!.findRenderObject() as RenderBox;
        final Offset localPosition = renderBox.globalToLocal(
          details.globalPosition,
        );

        setState(() {
          _selectedPoints.add(
            ColorPoint(
              position: localPosition,
              color: color,
              hexCode: hexCode,
              rgbCode: rgbCode,
            ),
          );
        });

        widget.onColorPicked(color);
      }
    } catch (e) {
      print('Error en tap: $e');
    }
  }

  void _removePoint(int index) {
    setState(() {
      _selectedPoints.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isImageLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Procesando imagen...'),
          ],
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.5; // 50% de la altura de la pantalla

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: imageHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: GestureDetector(
                    key: _imageKey,
                    onTapDown: _handleTapDown,
                    child: Center(
                      child: Image.file(widget.imageFile, fit: BoxFit.contain),
                    ),
                  ),
                ),
                // Puntos seleccionados
                for (final point in _selectedPoints)
                  Positioned(
                    left: point.position.dx - 10,
                    top: point.position.dy - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: point.color.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Haz zoom con dos dedos y toca para seleccionar colores',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_selectedPoints.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Colores Seleccionados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedPoints.clear();
                  });
                },
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Limpiar Todo'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 30), // Para ícono de eliminar
                      const SizedBox(width: 8),
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Color',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: const [
                            Text(
                              'Hex',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.copy, size: 14),
                          ],
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'RGB',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedPoints.length,
                  itemBuilder: (context, index) {
                    final point = _selectedPoints[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: GestureDetector(
                          onTap: () => _removePoint(index),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: point.color,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: point.hexCode),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Código hex copiado al portapapeles',
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Text(
                                  point.hexCode,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                point.rgbCode,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
